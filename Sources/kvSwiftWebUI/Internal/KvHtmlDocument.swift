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
//  KvHtmlDocument.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 07.11.2023.
//

import kvHttpKit



struct KvHtmlDocument { private init() { }

    static func htmlBytes(headers: KvHtmlBytes, with body: KvHtmlRepresentation) -> KvHtmlBytes {
        let titleBytes = body.title.map { KvHtmlBytes.joined("<title>", $0, "</title>") } ?? .empty
        let bodyBytes = body.bytes

        return .joined(
            "<!DOCTYPE html><html><head>",
            titleBytes,
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />",
            "<meta name=\"format-detection\" content=\"telephone=no\" /><meta name=\"format-detection\" content=\"date=no\" /><meta name=\"format-detection\" content=\"address=no\" /><meta name=\"format-detection\" content=\"email=no\" />",
            headers,
            "</head>",
            bodyBytes,
            "</html>"
        )
    }

}
