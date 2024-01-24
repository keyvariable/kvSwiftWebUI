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
//  SourceLink.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 11.01.2024.
//

import kvSwiftWebUI



struct SourceLink : View {

    init(to sourceFilePath: String) {
        self.sourceFilePath = sourceFilePath
    }


    private let sourceFilePath: String


    var body: some View {
        Text("Source")
        + Text(verbatim: ": ")
        + Text(verbatim: sourceFilePath)
            .link(Constants.kvSwiftWebUI_GitHubURL.appendingPathComponent("blob/main/Samples/Sources/ExampleServer/\(sourceFilePath)"))
    }

}
