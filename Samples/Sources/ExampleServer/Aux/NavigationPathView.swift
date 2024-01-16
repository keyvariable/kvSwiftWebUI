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
//  NavigationPathView.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 16.01.2024.
//

import kvSwiftWebUI



struct NavigationPathView : View {

    @Environment(\.navigationPath) private var navigationPath


    var body: some View {
        HStack(spacing: .em(0.25)) {
            let n = navigationPath.count - 1
            
            ForEach(0 ..< navigationPath.count) { index in
                let pathPrefix: KvNavigationPath = {
                    var path = navigationPath
                    path.removeLast(n - index)
                    return path
                }()

                // Separator
                if index > 0 {
                    Text(verbatim: "/")
                        .fontWeight(.thin)
                }

                // Link
                do {
                    let element = pathPrefix.elements.last!

                    switch element.data != nil {
                    case true:
                        /// Regular navigation element.
                        if let title = element.title {
                            NavigationLink(path: pathPrefix) { title }
                        }
                    case false:
                        /// Root navigation element.
                        NavigationLink("Main", path: pathPrefix)
                    }
                }
            }
        }
    }

}
