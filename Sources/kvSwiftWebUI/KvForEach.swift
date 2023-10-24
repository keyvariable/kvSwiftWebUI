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
//  KvForEach.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 27.11.2023.
//

public typealias ForEach = KvForEach



// TODO: DOC
public struct KvForEach<Data, ID, Content>
where Data : RandomAccessCollection, ID : Hashable
{

    // TODO: DOC
    public var data: Data

    // TODO: DOC
    public var content: (Data.Element) -> Content

}



extension ForEach where ID == Data.Element.ID, Content : KvView, Data.Element : Identifiable {

    // TODO: DOC
    @inlinable
    public init(_ data: Data, @KvViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

}



extension ForEach where Content : KvView {

    // TODO: DOC
    @inlinable
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @KvViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }

}



extension ForEach where Data == Range<Int>, ID == Int, Content : KvView {

    // TODO: DOC
    @inlinable
    public init(_ data: Range<Int>, @KvViewBuilder content: @escaping (Int) -> Content) {
        self.data = data
        self.content = content
    }
}



// MARK: : KvView

extension KvForEach : KvView where Content : KvView {

    public var body: KvNeverView { Body() }

}



// MARK: : KvHtmlRenderable

extension KvForEach : KvHtmlRenderable where Content : KvView {

    func renderHTML(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation {
        var representation = KvHtmlRepresentation.empty

        var iterator = data.makeIterator()


        func NextRepresentation() -> KvHtmlRepresentation? {
            iterator.next().map { content($0).htmlRepresentation(in: context) }
        }


        while let r0 = NextRepresentation() {
            guard let r1 = NextRepresentation() else {
                representation = .joined(representation, r0)
                break
            }
            guard let r2 = NextRepresentation() else {
                representation = .joined(representation, r0, r1)
                break
            }
            representation = .joined(representation, r0, r1, r2)
        }

        return representation
    }

}
