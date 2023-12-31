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
//  KvApplicationIcon.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 13.12.2023.
//

import Foundation

import kvHttpKit



public typealias ApplicationIcon = KvApplicationIcon



// TODO: DOC
public struct KvApplicationIcon {

    @usableFromInline
    let resource: Resource

    // TODO: Apply toolbar tint color by default.
    @usableFromInline
    let tintColor: KvColor?



    @inlinable
    public init(_ resource: Resource, tintColor: KvColor? = nil) {
        self.resource = resource
        self.tintColor = tintColor
    }



    // MARK: .Resource

    public enum Resource {

        /// All images and manifests having standard names are located in directory at given URL.
        ///
        /// For example prepared icon assets can be generated with [icon generator](https://realfavicongenerator.net/ ).
        case prepared(directoryURL: URL)

        // TODO: `case generated(...)` producing all variants from origin image(s) and parameters.

    }



    // MARK: HTML

    var htmlResources: Set<KvHtmlResource> {
        var htmlResources = Set<KvHtmlResource>()

        switch resource {
        case .prepared(directoryURL: let directoryURL):
            FileManager.default.enumerator(at: directoryURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)?.forEach { element in
                guard let url = element as? URL else { return }

                let contentType: KvHttpContentType? = .from(url)

                enumerateLinkAttributes(forFileAt: url, contentType: contentType) {
                    htmlResources.insert(
                        .init(content: .url(url), contentType: contentType, uri: url.lastPathComponent, linkAttributes: $0)
                    )
                }
            }
        }

        return htmlResources
    }

    var htmlHeaders: KvHtmlBytes? {
        var headers: [KvHtmlBytes] = .init()

        enumerateTintColorValues { tintColor in
            guard let tintColor else { return }

            if !tintColor.darkTheme {
                headers.append(.tag(.meta, attributes: .name("msapplication-TileColor"), .content(tintColor.value)))
            }

            headers.append(.tag(.meta, attributes: .name("theme-color"), .content(tintColor.value), tintColor.darkTheme ? .media(colorScheme: "dark") : nil))
        }

        guard !headers.isEmpty else { return nil }

        return .joined(headers)
    }



    // MARK: Auxiliaries

    /// - Parameter body: A block invoked with attributes of each link header tag. If link tag is not provided then *body* is invoked once with `nil` argument.
    private func enumerateLinkAttributes(forFileAt url: URL, contentType: KvHttpContentType?, body: ([KvHtmlKit.Attribute]?) -> Void) {
        let fileName = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension

        switch (fileName, fileExtension) {
        case ("apple-touch-icon", _):
            return body([ .linkRel("apple-touch-icon") ])

        case ("safari-pinned-tab", "svg"):
            enumerateTintColorValues { tintColor in
                body([ .linkRel("mask-icon"),
                       tintColor.map { .raw("color", $0.value) },
                       tintColor?.darkTheme == true ? .media(colorScheme: "dark") : nil
                     ].compactMap { $0 })
            }

        case (_, "webmanifest"):
            return body([ .linkRel("manifest") ])

        default:
            break
        }

        if let match = try? #/favicon-(\d+)x(\d+)/#.wholeMatch(in: fileName) {
            return body([ .linkRel("icon"), .raw("sizes", "\(match.1)x\(match.2)"), contentType.map(KvHtmlKit.Attribute.type(_:)) ].compactMap { $0 })
        }

        return body(nil)
    }


    /// - Parameter body: A block invoked with value of tint color for provided color scmenes. If there is no tint color value then *body* is invoked once with `nil` argument.
    private func enumerateTintColorValues(body: ((value: KvHtmlBytes, darkTheme: Bool)?) -> Void) {
        // TODO: Extract HEX from any color when it will be possible.

        guard let tintColor else { return body(nil) }

        body((value: "#\(tintColor.light.hexString)", darkTheme: false))

        if let dark = tintColor.dark {
            body((value: "#\(dark.hexString)", darkTheme: true))
        }
    }

}
