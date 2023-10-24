//===----------------------------------------------------------------------===//
//
//  Copyright (c) 2023 Svyatoslav Popov (info@keyvar.com).
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
//  License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
//  later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
//  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program.
//  If not, see <https://www.gnu.org/licenses/>.
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
//===----------------------------------------------------------------------===//
//
//  KvHtmlBytes.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 26.10.2023.
//

import Foundation

import Crypto



/// Lazy provider of bytes. It provides joined bytes from multiple storages with minimum of temporary allocations.
public struct KvHtmlBytes : ExpressibleByStringLiteral, ExpressibleByStringInterpolation {

    /// Tuple of pointer to a byte region and number of bytes in the region.
    public typealias Element = (pointer: UnsafeRawPointer, count: Int)

    public typealias Iterator = AnyIterator<Element>



    @usableFromInline
    typealias IteratorProvider = (borrowing AuxBuffers) -> Iterator



    @usableFromInline
    let iteratorProvider: IteratorProvider



    @usableFromInline
    init(iteratorProvider: @escaping IteratorProvider) {
        self.iteratorProvider = iteratorProvider
    }



    // MARK: Fabrics

    static let empty: Self = .init(iteratorProvider: { _ in .init { nil } })


    static func from<D>(_ data: D) -> Self where D : DataProtocol {
        .init { _ in KvHtmlBytes.dataIterator(data) }
    }


    static func from<S>(_ string: S) -> Self where S : StringProtocol {
        guard !string.isEmpty else { return .empty }

        return .init { auxBuffers in KvHtmlBytes.stringIterator(string, auxBuffers) }
    }


    static func joined<S>(_ elements: S, separator: KvHtmlBytes? = nil) -> Self
    where S : Sequence, S.Element == KvHtmlBytes
    {
        switch separator {
        case .none:
            return .init { auxBuffers in .init(elements
                .lazy.flatMap { IteratorSequence($0.iteratorProvider(auxBuffers)) }
                .makeIterator()
            ) }

        case .some(let separator):
            return .init { auxBuffers in .init(elements
                .lazy.map(CollectionOfOne.init(_:))
                .joined(separator: CollectionOfOne(separator))
                .lazy.flatMap { IteratorSequence($0.iteratorProvider(auxBuffers)) }
                .makeIterator()
            ) }
        }
    }


    static func joined(_ elements: KvHtmlBytes?..., separator: KvHtmlBytes? = nil) -> Self {
        .joined(elements.lazy.compactMap { $0 }, separator: separator)
    }


    static func joined<S>(_ strings: S, separator: KvHtmlBytes? = nil) -> Self
    where S : Sequence, S.Element : StringProtocol
    {
        .joined(strings.lazy.map(Self.from(_:)), separator: separator)
    }


    static func joined<S>(_ strings: S..., separator: KvHtmlBytes? = nil) -> Self
    where S : StringProtocol
    {
        .joined(strings.lazy.map(Self.from(_:)), separator: separator)
    }


    static func tag(_ tag: KvHtmlKit.Tag, css: KvHtmlKit.CssAttributes? = nil, attributes: KvHtmlKit.Attribute?..., innerHTML: KvHtmlBytes? = nil) -> Self {
        self.tag(tag, css: css, attributes: attributes.lazy.compactMap { $0 }, innerHTML: innerHTML)
    }


    static func tag<Attributes>(_ tag: KvHtmlKit.Tag, css: KvHtmlKit.CssAttributes? = nil, attributes: Attributes, innerHTML: KvHtmlBytes? = nil) -> Self
    where Attributes : Sequence, Attributes.Element == KvHtmlKit.Attribute
    {
        let attributes: KvHtmlBytes = .joined(
            .joined(attributes.lazy.map { .joined(" ", $0.htmlBytes) }),
            (css?.classAttribute).map { .joined(" ", $0.htmlBytes) },
            (css?.styleAttribute).map { .joined(" ", $0.htmlBytes) }
        )

        let name = tag.name

        return if let innerHTML = innerHTML {
            .joined("<\(name)", attributes, ">", innerHTML, "</\(name)>")
        }
        else if tag.properties.contains(.requiresEndingTag) {
            .joined("<\(name)", attributes, "></\(name)>")
        }
        else { .joined("<\(name)", attributes, " />") }
    }



    // MARK: : ExpressibleByStringLiteral

    @inlinable
    public init(stringLiteral value: StringLiteralType) {
        switch value.isEmpty {
        case false:
            self.init { auxBuffers in KvHtmlBytes.stringIterator(value, auxBuffers) }
        case true:
            self.init(iteratorProvider: { _ in .init { nil } })
        }
    }



    // MARK: Operations

    /// - Returns: The collected receiver's bytes and accumulated hash digest.
    @inlinable
    public func accumulate(_ auxBuffers: borrowing AuxBuffers = .threadLocal) -> (data: Data, hash: SHA256.Digest) {
        var data = Data()
        var hasher = SHA256()

        forEach { (pointer, count) in
            data.append(pointer.assumingMemoryBound(to: UInt8.self), count: count)
            hasher.update(bufferPointer: .init(start: pointer, count: count))
        }

        return (data, hasher.finalize())
    }


    /// - Returns: A block taking portions from the receiver's content and returning number of actually taken bytes or an error.
    @inlinable
    public func contentProvider(_ auxBuffers: borrowing AuxBuffers = .threadLocal) -> ((UnsafeMutableRawBufferPointer) -> Result<Int, Error>) {
        let iterator = makeIterator()

        guard var (src, count) = iterator.next() else { return { _ in .success(0) } }

        return { destBuffer in
            var dest = destBuffer.baseAddress!
            var writeLimit = destBuffer.count

            while writeLimit > 0 {
                guard count > 0 else {
                    guard let next = iterator.next() else { break }
                    (src, count) = next
                    continue
                }

                let bytesToWrite = min(count, writeLimit)
                assert(bytesToWrite > 0)

                dest.copyMemory(from: src, byteCount: bytesToWrite)

                dest = dest.advanced(by: bytesToWrite)
                writeLimit -= bytesToWrite
                count -= bytesToWrite
                assert(writeLimit >= 0)
            }

            return .success(destBuffer.count - writeLimit)
        }
    }


    func flatMap<Elements>(_ transform: @escaping (Element, AuxBuffers) -> Elements) -> KvHtmlBytes
    where Elements: Sequence, Elements.Element == Element
    {
        .init { auxBuffers in Iterator(
            self.iteratorProvider(auxBuffers)
                .lazy.flatMap { transform($0, auxBuffers) }
                .makeIterator()
        ) }
    }


    func flatMap(_ transform: @escaping (Element) -> KvHtmlBytes) -> KvHtmlBytes {
        flatMap { transform($0).makeIterator($1) }
    }


    /// - Returns: The result of *transform* passed with the receiver.
    ///
    /// This method is designated to be used in building chains. It consumes the receiver.
    consuming func wrap(_ transform: (KvHtmlBytes) -> KvHtmlBytes) -> KvHtmlBytes {
        transform(self)
    }


    
    // MARK: Enumeration

    /// - Returns: Iterator of byte regions that make the receiver's content.
    ///
    /// - SeeAlso: ``forEach(_:_:)``.
    @inlinable
    public func makeIterator(_ auxBuffers: borrowing AuxBuffers = .threadLocal) -> Iterator {
        iteratorProvider(auxBuffers)
    }


    /// Calls *body* for each region of bytes that make the receiver's content.
    ///
    /// - Parameter body: A callback passed with pointer to and size of a byte region.
    ///
    /// - SeeAlso: ``makeIterator(_:)``.
    @inlinable
    public func forEach(_ auxBuffers: borrowing AuxBuffers = .threadLocal, _ body: (Element) -> Void) {
        let iterator = iteratorProvider(auxBuffers)

        while let element = iterator.next() {
            body(element)
        }
    }



    // MARK: .AuxBuffers

    public class AuxBuffers {

        public internal(set) var array: [UInt8] = .init(unsafeUninitializedCapacity: Constants.auxArrayLength) { _, length in
            length = Constants.auxArrayLength
        }


        /// - SeeAlso: ``threadLocal``.
        @inlinable
        public init() { }


        // MARK: Fabrics

        @inlinable
        public static var threadLocal: AuxBuffers {
            let storage = Thread.current.threadDictionary

            switch storage[Constants.ThreadDictionaryKey.shared] {
            case .some(let value):
                return value as! AuxBuffers
            case .none:
                let value = AuxBuffers()
                storage[Constants.ThreadDictionaryKey.shared] = value
                return value
            }
        }


        // MARK: .Constants

        @usableFromInline
        struct Constants {

            static var auxArrayLength: Int { 1<<12 /* 4 KiB */ }

            @usableFromInline
            class ThreadDictionaryKey : NSObject, NSCopying {

                @usableFromInline
                static let shared: ThreadDictionaryKey = .init()


                @usableFromInline
                func copy(with zone: NSZone? = nil) -> Any { return self }

            }

        }


        // MARK: Operations

        func withArray<T>(_ body: (inout [UInt8]) -> T) -> T { body(&array) }

    }



    // MARK: Auxiliaries

    static func dataIterator<D>(_ data: D) -> Iterator
    where D : DataProtocol
    {
        .init(data.regions
            .lazy.map { region in region.withUnsafeBytes { Element($0.baseAddress!, region.count) } }
            .makeIterator()
        )
    }


    @usableFromInline
    static func stringIterator<S>(_ string: S, _ auxBuffers: AuxBuffers = .threadLocal) -> Iterator
    where S : StringProtocol
    {
        var range = string.startIndex ..< string.endIndex
        var bytesWritten: Int = 0

        return .init {
            return auxBuffers.withArray { dest -> Element? in
                guard !range.isEmpty else { return nil }

                return string.getBytes(&dest, maxLength: dest.count, usedLength: &bytesWritten, encoding: .utf8, range: range, remaining: &range)
                ? dest.withUnsafeBytes { ($0.baseAddress!, bytesWritten) }
                : nil
            }
        }
    }

}
