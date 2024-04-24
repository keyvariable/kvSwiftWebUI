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
//  KvUrlKit.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 06.05.2024.
//

import Foundation



struct KvUrlKit { private init() { } }


// MARK: URL Query

extension KvUrlKit {

    static func append(_ urlComponents: inout URLComponents, withUrlQueryItem urlQueryItem: URLQueryItem) {
        urlComponents.queryItems?.append(urlQueryItem)
        ?? (urlComponents.queryItems = [ urlQueryItem ])
    }


    /// E.g. removes empty array of URL query items.
    static func normalizeUrlQueryItems(in urlComponents: inout URLComponents) {
        if urlComponents.queryItems?.isEmpty == true {
            urlComponents.queryItems = nil
        }
    }

}
