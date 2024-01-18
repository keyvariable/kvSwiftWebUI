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
//  KvHtmlBundle.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 25.10.2023.
//

import kvHttpKit



// TODO: DOC
public class KvHtmlBundle {

    // TODO: DOC
    public init<RootView : KvView>(at rootPath: KvUrlPath? = nil, icon: KvApplicationIcon? = nil, @KvViewBuilder rootView: @escaping () -> RootView) throws {
        icon?.htmlResources.forEach(assets.insert(_:))
        
        navigationController = .init(
            for: rootView(),
            with: .init(rootPath: rootPath,
                        iconHeaders: icon?.htmlHeaders,
                        assets: assets)
        )
    }



    private let assets = KvHtmlBundleAssets()

    private let navigationController: KvNavigationController



    // MARK: Operations

    /// See ``response(at:)-3g2a5`` for details.
    public func response(at path: KvUrlPath.Slice) -> KvHttpResponseContent? {
        navigationController.htmlResponse(at: path)
        ?? assets[path]
    }

}
