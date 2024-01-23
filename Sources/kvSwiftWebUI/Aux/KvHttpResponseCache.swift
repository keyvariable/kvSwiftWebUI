//===----------------------------------------------------------------------===//
//
//  Copyright (c) 2024 Svyatoslav Popov (info@keyvar.com).
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
//  KvHttpResponseCache.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 18.01.2024.
//

import Foundation

import kvHttpKit
import kvKit



// TODO: DOC
public class KvHttpResponseCache<Key : Hashable> {

    typealias Response = KvHttpResponseContent



    /// Initializes an empty instance.
    init(maximumByteSize: UInt64) {
        assert(maximumByteSize > 0)

        self.maximumByteSize = maximumByteSize
        self.byteSizeThreshold = UInt64(round((1.0 - Constants.cleanupReserveRatio) * Double(maximumByteSize)))
    }



    private var underlying: [Key : Element] = .init()

    private let condition = NSCondition()

    private var accessList = AccessList()

    private let maximumByteSize: UInt64
    /// This value is less then `maximumByteSize` to drop little more bytes. This approach reduces frequency of cleanup invocations.
    private let byteSizeThreshold: UInt64

    private var isCleanupActive = false



    // MARK: .Constants

    private struct Constants { private init() { }

        static var cleanupReserveRatio: Double { 0.1 }

    }



    // MARK: .Element

    private enum Element {

        case pending
        case value(value: Response, access: AccessList.Node)

    }



    // MARK: Subscripts

    /// A waiting subscript.
    ///
    /// If value for *key* is available then it is returned.
    /// Otherwise *key* is locked until *default* block is invoked and the resulting value is saved.
    /// If any other thread trying to get value for a locked *key* then the thread is suspended until *key* is unlocked.
    ///
    /// - Important: Assuming *default* block is always the same for the same key.
    subscript (key: Key, default fabric: () -> Response?) -> Response? {
        condition.withLock {
            switch underlying[key] {
            case .value(value: let value, access: let accessNode):
                accessList.touch(accessNode)
                return value

            case .none:
                underlying[key] = .pending

                // Unlocking the receiver while long-running tasks are being performed.
                condition.unlock()
                let response = fabric()
                let element = response.flatMap { self.element(with: $0, for: key) }
                condition.lock()

                underlying[key] = element

                condition.broadcast()

                scheduleCleanup()

                return response

            case .pending:
                while true {
                    condition.wait()

                    switch underlying[key] {
                    case .value(value: let value, access: _):
                        // Assuming value is accesses just after it's unlocked so it's not important to touch the access node.
                        return value
                    case .pending:
                        break
                    case .none:
                        return nil
                    }
                }

                assertionFailure("This code must never be executed")
                return nil
            }
        }
    }


    // MARK: Operations

    /// - Important: The condition must be locked.
    private func scheduleCleanup() {
        guard accessList.totalByteSize > byteSizeThreshold,
              !isCleanupActive
        else { return }

        isCleanupActive = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?._cleanup()
        }
    }


    /// - Warning: This method must be called from `scheduleCleanup` method only.
    private func _cleanup() {
        condition.withLock {
            guard isCleanupActive else { return }

            var dropped = accessList.dropLast(maxTotalByteSize: byteSizeThreshold)

            do {
                // Condition is unlocked to allow other threads to read remaining elements while the cleanup is being executed.
                condition.unlock()
                defer { condition.lock() }

                while let node = dropped {
                    condition.withLock {
                        // Assuming key is associated with an existing value so nobody is waiting for it and it can be just removed.
                        _ = underlying.removeValue(forKey: node.key)
                    }

                    dropped = node.next
                }
            }

            isCleanupActive = false
        }
    }


    /// - Note: This method can return nil if *response* hasn't *contentLength* value.
    private func element(with response: Response, for key: Key) -> Element? {
        guard let contentLength = response.contentLength
        else { return KvDebug.pause(code: nil, "Warning: response cache ignored response having nil contentLength") }

        // Assuming response.contentLength is correct when available.
        return .value(value: response, access: accessList.insert(byteSize: contentLength, key: key))
    }



    // MARK: .AccessList

    /// A double-linked list holding value sizes and access order (recent node is at the beginning).
    private struct AccessList {

        private var first, last: Node?

        private(set) var totalByteSize: UInt64 = 0


        // MARK: .Node

        class Node {

            let byteSize: UInt64
            let key: Key

            private(set) var next: Node?
            /// This reference is unowned to prevent retain cycles.
            private(set) unowned var prev: Node?


            init(byteSize: UInt64, key: Key) {
                assert(byteSize >= 0)

                self.byteSize = byteSize
                self.key = key
            }


            // MARK: Operations

            func insertBefore(_ next: Node) {
                assert(self.next == nil)

                let prev = next.prev

                self.prev = prev
                prev?.next = self

                self.next = next
                next.prev = self
            }


            func removeFromList() {
                next?.prev = prev
                prev?.next = next

                next = nil
                prev = nil
            }


            func breakPrevLink() {
                prev?.next = nil
                prev = nil
            }

        }


        // MARK: Operations

        mutating func insert(byteSize: UInt64, key: Key) -> Node {
            let node = Node(byteSize: byteSize, key: key)

            insert(node)
            totalByteSize += byteSize

            return node
        }


        private mutating func insert(_ node: Node) {
            switch first {
            case .some(let first):
                node.insertBefore(first)
                self.first = node
            case .none:
                first = node
                last = node
            }
        }


        /// Moves given *node* to the beginning of the receiver.
        ///
        /// - Important: The receiver must contain given *node*.
        mutating func touch(_ node: Node) {
            guard node !== first else { return }

            /// Assuming list contains atleast 2 nodes due to it contains `node` and `first` is not equal to `node`.

            if node === last {
                last = last?.prev
            }

            node.removeFromList()

            insert(node)
        }


        mutating func removeAll() {
            last = nil
            first = nil

            totalByteSize = 0
        }


        /// Removes elements from the end of the receiver while the total byte size is greater then *maxTotalByteSize*.
        ///
        /// - Returns: First element in chain of dropped nodes.
        mutating func dropLast(maxTotalByteSize: UInt64) -> Node? {
            var dropped: Node?

            while totalByteSize > maxTotalByteSize, let node = last {
                totalByteSize -= node.byteSize

                dropped = node
                last = node.prev
            }

            dropped?.breakPrevLink()

            if last == nil {
                first = nil
            }

            assert(last?.next == nil)

            return dropped
        }

    }

}
