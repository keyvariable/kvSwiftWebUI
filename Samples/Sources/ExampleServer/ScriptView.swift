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

import Foundation

import kvSwiftWebUI



struct ScriptView : View {

    var body: some View {
        Page(title: Text("Scripts"),
             subtitle: Text("Some examples of working with scripts"),
             sourceFilePath: "ScriptView.swift"
        ) {
            BodySection {
                Text("""
                Scripts are widely used to provide various functionality in HTML documents. \
                For example, scripts are used to embed analytics trackers and handle various events like user input.
                """)
                Text("Use") + .space
                + Text("View.tag(_:)").font(.system(.body, design: .monospaced))
                + .space + Text("to refer to views in scripts.")
            }

            Section2(header: Text("Script References")) {
                Text("""
                    Scripts can be stored in files and referenced from HTML. \
                    It's convenient to edit scripts in dedicated editors and store them as resources in the bundles. \
                    Also referenced scripts are cached by clients so documents are loaded faster and the server load is decreased.
                    """)
                Text("Below is a view presenting random numbers generated periodically in script:")
                Text(verbatim: "—")
                    .tag(Tag.randomInt)
                    .padding()
                    .frame(minWidth: .em(6))
                    .background(.gray.quaternary)
                    .clipShape(.rect(cornerRadius: .em(0.35)))
            }
            .script(.resource("RandomNumberTimer", withExtension: "js", subdirectory: "js"))

            Section2(header: Text("Embedded Scripts")) {
                Text("Scripts can be passed as source code. In this case the source code is embedded into HTML.")
                Text("Below is an example of embedded script that sets click handler and changes background color of the view when it's clicked.")
                Text("Click here")
                    .padding()
                    .background(.gray)
                    .foregroundStyle(.white)
                    .tag(Tag.colorClickable)
                    .clipShape(.rect(cornerRadius: .em(0.35)))
                    .script("""
                        document.addEventListener("DOMContentLoaded", function() {
                            var isBlue = false;

                            document.getElementById('\(Tag.colorClickable.rawValue)').onclick = function() {
                                this.style.backgroundColor = isBlue ? 'green' : 'blue';
                                isBlue = !isBlue;
                            }
                        });
                        """)
            }
        }
        /// This modifier provides keyword metadata for the resulting navigation destination.
        /// If several views declare keyword metadata in a navigation destination then all the keywords are joined.
        .metadata(keywords: Text("scripts"))
    }


    private enum Tag : String {
        case colorClickable
        case randomInt
    }

}
