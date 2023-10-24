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
//  KvViewBuilder.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 24.10.2023.
//

public typealias ViewBuilder = KvViewBuilder



@resultBuilder
public struct KvViewBuilder {

    @inlinable
    public static func buildBlock() -> KvEmptyView { KvEmptyView() }


    @inlinable
    public static func buildBlock<Component>(_ component: Component) -> Component
    where Component : KvView
    { component }


    @inlinable
    public static func buildOptional<Component>(_ component: Component?) -> ConditionalView<Component, KvEmptyView>
    where Component : KvView
    {
        component.map { .init(trueView: $0) } ?? .init(falseView: .init())
    }


    @inlinable
    public static func buildEither<TrueComponent, FalseComponent>(first component: TrueComponent) -> ConditionalView<TrueComponent, FalseComponent>
    where TrueComponent : KvView, FalseComponent : KvView
    { .init(trueView: component) }


    @inlinable
    public static func buildEither<TrueComponent, FalseComponent>(second component: FalseComponent) -> ConditionalView<TrueComponent, FalseComponent>
    where TrueComponent : KvView, FalseComponent : KvView
    { .init(falseView: component) }


    @inlinable
    public static func buildPartialBlock<Component>(first: Component) -> Component
    where Component : KvView
    { first }


    @inlinable
    public static func buildPartialBlock<C0, C1>(accumulated: C0, next: C1) -> GroupOfTwo<C0, C1>
    where C0 : KvView, C1 : KvView
    { GroupOfTwo(accumulated, next) }

    @inlinable
    public static func buildPartialBlock<C0, C1, C2>(accumulated: GroupOfTwo<C0, C1>, next: C2) -> GroupOfThree<C0, C1, C2>
    where C0 : KvView, C1 : KvView, C2 : KvView
    { GroupOfThree(accumulated, next) }

    @inlinable
    public static func buildPartialBlock<C0, C1, C2, C3>(accumulated: GroupOfThree<C0, C1, C2>, next: C3) -> GroupOfFour<C0, C1, C2, C3>
    where C0 : KvView, C1 : KvView, C2 : KvView, C3 : KvView
    { GroupOfFour(accumulated, next) }

    @inlinable
    public static func buildPartialBlock<C0, C1, C2, C3, C4>(accumulated: GroupOfFour<C0, C1, C2, C3>, next: C4) -> GroupOfTwo<GroupOfFour<C0, C1, C2, C3>, C4>
    where C0 : KvView, C1 : KvView, C2 : KvView, C3 : KvView, C4 : KvView
    { GroupOfTwo(accumulated, next) }



    // MARK: .ConditionalView

    public struct ConditionalView<TrueView, FalseView> : KvView, KvHtmlRenderable
    where TrueView : KvView, FalseView : KvView
    {

        let content: Content


        @usableFromInline
        init(trueView: TrueView) {
            content = .trueView(trueView)
        }


        @usableFromInline
        init(falseView: FalseView) {
            content = .falseView(falseView)
        }


        // MARK: .Content

        enum Content {
            case trueView(TrueView)
            case falseView(FalseView)
        }


        // MARK: : KvView

        public var body: KvNeverView { KvNeverView() }


        // MARK: : KvHtmlRenderable

        func renderHTML(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation {
            switch content {
            case .trueView(let trueView):
                return trueView.htmlRepresentation(in: context)
            case .falseView(let falseView):
                return falseView.htmlRepresentation(in: context)
            }
        }

    }


    // MARK: - GroupOfTwo

    public struct GroupOfTwo<V0, V1> : KvView, KvHtmlRenderable
    where V0 : KvView, V1 : KvView
    {

        let v0: V0
        let v1: V1


        @usableFromInline
        init(_ v0: V0, _ v1: V1) {
            self.v0 = v0
            self.v1 = v1
        }


        // MARK: : KvView

        public var body: KvNeverView { KvNeverView() }


        // MARK: : KvHtmlRenderable

        func renderHTML(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation {
            .joined(v0.htmlRepresentation(in: context),
                    v1.htmlRepresentation(in: context))
        }

    }



    // MARK: - GroupOfThree

    public struct GroupOfThree<V0, V1, V2> : KvView, KvHtmlRenderable
    where V0 : KvView, V1 : KvView, V2 : KvView
    {

        let v0: V0
        let v1: V1
        let v2: V2


        @usableFromInline
        init(_ g: GroupOfTwo<V0, V1>, _ v2: V2) {
            self.v0 = g.v0
            self.v1 = g.v1
            self.v2 = v2
        }


        // MARK: : KvView

        public var body: KvNeverView { KvNeverView() }


        // MARK: : KvHtmlRenderable

        func renderHTML(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation {
            .joined(v0.htmlRepresentation(in: context),
                    v1.htmlRepresentation(in: context),
                    v2.htmlRepresentation(in: context))
        }

    }



    // MARK: - GroupOfFour

    public struct GroupOfFour<V0, V1, V2, V3> : KvView, KvHtmlRenderable
    where V0 : KvView, V1 : KvView, V2 : KvView, V3 : KvView
    {

        let v0: V0
        let v1: V1
        let v2: V2
        let v3: V3


        @usableFromInline
        init(_ g: GroupOfThree<V0, V1, V2>, _ v3: V3) {
            self.v0 = g.v0
            self.v1 = g.v1
            self.v2 = g.v2
            self.v3 = v3
        }


        // MARK: : KvView

        public var body: KvNeverView { KvNeverView() }


        // MARK: : KvHtmlRenderable

        func renderHTML(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation {
            .joined(v0.htmlRepresentation(in: context),
                    v1.htmlRepresentation(in: context),
                    v2.htmlRepresentation(in: context),
                    v3.htmlRepresentation(in: context))
        }

    }

}
