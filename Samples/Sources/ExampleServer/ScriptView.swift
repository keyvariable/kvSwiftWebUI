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
//  ScriptView.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 02.02.2024.
//

import kvSwiftWebUI



struct ScriptView : View {

    var body: some View {
        Page(title: Text("Scripts"),
             subtitle: Text("Some examples of working with scripts"),
             sourceFilePath: "ScriptView.swift"
        ) {
            Section1(header: Text("Head Scripts")) {
                Section2(header: Text("External")) {
                    Text("...")
                }
                .script("window.alert(\"Hello world!\");")
            }
        }
    }

}
