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
//  Sections.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 10.01.2024.
//

import kvSwiftWebUI



struct Section1<Header: View, Content : View> : View {

    private init(header: Header, content: Content) {
        self.header = header
        self.content = content
    }


    init(@ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.init(header: header(), content: content())
    }


    init(header: Text, @ViewBuilder content: () -> Content) where Header == Text {
        self.init(header: header, content: content())
    }


    private let header: Header
    private let content: Content


    // MARK: : View

    var body: some View {
        VStack(alignment: .leading, spacing: .em(1.5)) {
            header.font(.title)
            content
        }
        .fixedSize(horizontal: false, vertical: true)
    }

}



struct Section2<Header: View, Content : View> : View {

    private init(header: Header, content: Content) {
        self.header = header
        self.content = content
    }


    init(@ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.init(header: header(), content: content())
    }


    init(header: Text, @ViewBuilder content: () -> Content) where Header == Text {
        self.init(header: header, content: content())
    }


    private let header: Header
    private let content: Content


    // MARK: : View

    var body: some View {
        VStack(alignment: .leading, spacing: .em(0.75)) {
            header.font(.title2)
            content
        }
        .fixedSize(horizontal: false, vertical: true)
    }

}



struct BodySection<Content : View> : View {

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }


    private let content: Content


    // MARK: : View

    var body: some View {
        VStack(alignment: .leading, spacing: .em(0.5)) {
            content
        }
        .fixedSize(horizontal: false, vertical: true)
    }

}
