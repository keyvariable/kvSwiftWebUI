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
//  LocalizedHelloView.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 14.02.2024.
//

import kvSwiftWebUI



struct LocalizedHelloView : View {

    /// Current localization context is available in the environment at `\.localization` key path.
    ///
    /// Here it's used to print current language tag.
    @KvEnvironment(\.localization) private var localization


    var body: some View {
        VStack(spacing: 0) {
            Text("HELLO")
                .font(.largeTitle)
                .padding(.vertical, .em(2))

            Text(verbatim: ".languageTag == \(localization.languageTag.map { "\"\($0)\"" } ?? "nil")")
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.label.secondary)
        }
        .padding(.bottom, .em(2))
    }

}
