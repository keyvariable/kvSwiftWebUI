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
//  KvHtmlContext.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 06.11.2023.
//

import Foundation

import Crypto
import kvHttpKit
import kvKit



class KvHtmlContext {

    let assets: KvHtmlBundleAssets

    private(set) var cssAsset: KvCssAsset


    let rootPath: KvUrlPath?
    let navigationPath: KvUrlPath.Slice

    

    init(_ assets: KvHtmlBundleAssets,
         cssAsset: KvCssAsset.Prototype? = nil,
         rootPath: KvUrlPath?,
         navigationPath: KvUrlPath.Slice,
         extraHeaders: KvHtmlBytes? = nil
    ) {
        self.assets = assets
        self.cssAsset = .init(parent: cssAsset)
        self.rootPath = rootPath
        self.navigationPath = navigationPath

        if let extraHeaders {
            self.extraHeaders.append(extraHeaders)
        }
    }



    private var extraHeaders: [KvHtmlBytes] = .init()

    // TODO: Use ordered set
    private var resourceLinks: Set<KvHtmlResource.HtmlLink> = .init()

    private var gFonts: GFonts = .init()



    // MARK: Operations

    /// Joined `.rootPath` and `navigationPath`.
    var absolutePath: KvUrlPath {
        rootPath.map { $0 + navigationPath } ?? .init(navigationPath)
    }


    /// All HTML headers registered in the receiver.
    var headers: KvHtmlBytes {
        let inlinedCSS: KvHtmlBytes? = (!cssAsset.isEmpty
                                        ? cssAsset.bytes.wrap { .tag(.style, innerHTML: $0) }
                                        : nil)

        let resourceLinks = KvHtmlBytes.joined(
            .joined(resourceLinks.sorted(by: { $0.uri < $1.uri })
                .lazy.map { $0.bytes(basePath: self.rootPath) }),
            inlinedCSS
        )

        return .joined(resourceLinks, gFonts.resourceLinks, .joined(extraHeaders))
    }


    /// Extracts the receiver's CSS asset, inserts it as a resource asset and clears the receiver's CSS asset.
    func makeCssResource() -> KvCssAsset.Prototype {
        let bytes = cssAsset.bytes

        let (data, digest) = bytes.accumulate()
        let id = digest.withUnsafeBytes {
            KvBase64.encodeAsString($0, alphabet: .urlSafe)
        }

        let resource: KvHtmlResource = .css(.local(.data(data, digest), .init(path: "\(id).css")))
        let prototype = cssAsset.asPrototype(resource: resource)

        cssAsset = .init(parent: prototype)

        assets.insert(resource)

        return prototype
    }


    func insert(headers: KvHtmlBytes) {
        self.extraHeaders.append(headers)
    }


    func insert(_ resource: KvHtmlResource) {
        assets.insert(resource)

        if let htmlLink = resource.htmlLink {
            resourceLinks.insert(htmlLink)
        }
    }


    func insert<S>(_ resources: S) where S : Sequence, S.Element == KvHtmlResource {
        resources.forEach(self.insert(_:))
    }


    /// - Note: It's used to insert resources explicitly.
    func insert(_ cssAsset: KvCssAsset.Prototype) {
        insert(cssAsset.resource)
    }


    private func insert(_ cssEntry: KvCssAsset.Entry) {
        let cssResource = cssAsset.insert(cssEntry)?.resource

        // If the resource is returned then `cssEntry` has already been insrted.
        if let cssResource {
            insert(cssResource)
        }
    }

}



// MARK: Alignment

extension KvHtmlContext {

    /// - Returns: A CSS class defining given horizontal *alignment* for flex and grid layouts.
    func cssFlexClass(for alignment: KvHorizontalAlignment, as flexAlignment: FlexAlignment) -> String {
        let base: FlexClassBase = switch alignment {
        case .leading: .start
        case .center: .center
        case .trailing: .end
        }

        return cssFlexClass(base, flexAlignment)
    }


    /// - Returns: A CSS class defining given vertical *alignment* for flex and grid layouts.
    func cssFlexClass(for alignment: KvVerticalAlignment, as flexAlignment: FlexAlignment) -> String {
        let base: FlexClassBase = switch alignment {
        case .center: .center
        case .bottom: .end
        case .firstTextBaseline: .firstTextBaseline
        case .lastTextBaseline: .lastTextBaseline
        case .top: .start
        }

        return cssFlexClass(base, flexAlignment)
    }


    private func cssFlexClass(_ base: FlexClassBase, _ flexAlignment: FlexAlignment) -> String {
        insert(KvCssAsset.Entry(
            id: .flexClasses,
            default: KvHtmlContext.cssFlexClasses
        ))

        return "\(flexAlignment.cssClassPrefix)\(base.rawValue)"
    }


    private static func cssFlexClasses() -> String {
        FlexAlignment.allCases.lazy.flatMap { prefix in
            FlexClassBase.allCases.lazy.map { base in
                let key: String = switch prefix {
                case .crossItems: "align-items"
                case .crossSelf: "align-self"
                case .mainContent: "justify-content"
                case .mainItems: "justify-items"
                case .mainSelf: "justify-self"
                }

                let value: String = switch base {
                case .center: "center"
                case .end: "flex-end"
                case .firstTextBaseline: "first baseline"
                case .lastTextBaseline: "last baseline"
                case .start: "flex-start"
                }

                return ".\(prefix.cssClassPrefix)\(base.rawValue){\(key):\(value);}"
            }
        }
        .joined()
    }



    // MARK: .FlexAlignment

    enum FlexAlignment : CaseIterable {

        case mainContent, mainItems, mainSelf
        case crossItems, crossSelf


        // MARK: Operations

        var cssClassPrefix: String {
            switch self {
            case .crossItems: "flexCi"
            case .crossSelf: "flexCs"
            case .mainContent: "flexMc"
            case .mainItems: "flexMi"
            case .mainSelf: "flexMs"
            }
        }

    }



    // MARK: .FlexClassBase

    private enum FlexClassBase : String, CaseIterable {
        case center = "C"
        case end = "E"
        case firstTextBaseline = "FB"
        case lastTextBaseline = "LB"
        case start = "S"
    }

}



// MARK: Colors

extension KvHtmlContext {

    func cssExpression(for color: KvColor) -> String {
        let expression: String

        switch color.dark {
        case .none:
            expression = ColorKit.cssExpression(color.light, opacity: color.opacity)

        case .some(let dark):
            let id = ColorKit.cssID(light: color.light, dark: dark)

            let needsAlpha = color.light.alpha != nil || dark.alpha != nil

            insert(KvCssAsset.Entry(
                selector: ":root",
                id: .color(id: id),
                default: { ColorKit.cssDeclaration(of: color.light, forceAlpha: needsAlpha, id: id) },
                dark: { ColorKit.cssDeclaration(of: dark, forceAlpha: needsAlpha, id: id) }
            ))

            expression = ColorKit.cssExpression(id: id,
                                                opacity: color.opacity,
                                                options: needsAlpha ? .useAplhaVariable : [ ])
        }

        return expression
    }


    // MARK: .ColorKit

    private struct ColorKit {

        private init() { }



        static func cssID(light: KvColor.sRGB, dark: KvColor.sRGB) -> String {
            let light = light.bytes
            let dark = dark.bytes

            let bytes: [UInt8] = (light.alpha == nil && dark.alpha == nil
                                  ? [ light.red, light.green, light.blue, dark.red, dark.green, dark.blue ]
                                  : [ light.red, light.green, light.blue, light.alpha ?? 0xFF, dark.red, dark.green, dark.blue, dark.alpha ?? 0xFF ])

            return KvBase64.encodeAsString(bytes, alphabet: .urlSafe)
        }


        static func cssDeclaration(of srgb: KvColor.sRGB, forceAlpha: Bool, id: String) -> String {
            let (red, green, blue, _) = srgb.bytes
            let rgb = "\(variableName(id: id, suffix: .rgb)):\(red),\(green),\(blue);"
            let alpha = srgb.alpha.map { "\(variableName(id: id, suffix: .a)):\(String(format: "%.3g", $0));" } ?? ""

            return "\(rgb)\(alpha)"
        }


        static func cssExpression(id: String, opacity: Double?, options: CssOptions = [ ]) -> String {
            let alpha = opacity.map { String(format: "%.3g", $0) }
            ?? (options.contains(.useAplhaVariable) ? "var(\(ColorKit.variableName(id: id, suffix: .a)))" : nil)

            switch alpha {
            case .some(let alpha):
                return "rgba(var(\(ColorKit.variableName(id: id, suffix: .rgb))),\(alpha))"
            case .none:
                return "rgb(var(\(ColorKit.variableName(id: id, suffix: .rgb))))"
            }
        }


        static func cssExpression(_ color: KvColor.sRGB, opacity: Double?) -> String {
            switch opacity ?? color.alpha {
            case .some(let alpha):
                let (red, green, blue, _) = color.bytes
                return "rgb(\(red) \(green) \(blue) / \(String(format: "%.3g", alpha)))"

            case .none:
                return "#\(color.hexString)"
            }
        }


        private static func variableName(id: String, suffix: VariableSuffix) -> String { "--\(id)-\(suffix.css)" }


        // MARK: .CssOptions

        struct CssOptions : OptionSet {

            static let useAplhaVariable = Self(rawValue: 1 << 0)

            let rawValue: UInt

        }


        // MARK: .VariableSuffix

        private enum VariableSuffix {

            case rgb, a

            var css: String {
                switch self {
                case .a: "a"
                case .rgb: "rgb"
                }
            }

        }

    }

}



// MARK: Fonts

extension KvHtmlContext {

    func cssExpression(for font: KvFont) -> String {
        let familyID: String

        switch font.family {
        case .gFont(name: let family):
            gFonts.insert(family: family, italic: font.isItalic, weight: font.weight.cssValue)

            familyID = "'\(family)'"

        case .resource(let resource):
            resource.faces.forEach { (faceKey, sources) in
                let cssSources: String = sources
                    .lazy.map { source in
                        let (cssFontFaceSource, htmlResource) = FontResourceKit.processSource(source)
                        // - NOTE: SIDE EFFECT: font resource is inserted here.
                        if let htmlResource {
                            self.insert(htmlResource)
                        }
                        return cssFontFaceSource
                    }
                    .joined(separator: ",")

                insert(KvCssAsset.Entry(
                    id: .fontResource(name: resource.name, key: faceKey),
                    default: { "@font-face{font-family:\"\(resource.name)\";src:\(cssSources);font-weight:\(faceKey.weight.cssValue);font-style:\(faceKey.isItalic ? "italic" : "normal");}" }
                ))
            }

            familyID = "'\(resource.name)'"

        case .system(let design):
            let cssAsset: KvCssAsset.Prototype?

            (familyID, cssAsset) = switch design {
            case .default: ("system-ui", nil)
            case .monospaced: ("var(--ui-monospace)", .foundation)
            case .rounded: ("var(--ui-rounded)", .foundation)
            case .serif: ("var(--ui-serif)", .foundation)
            }

            if let cssAsset {
                insert(cssAsset)
            }
        }

        let lineHeight: String = font.leading.map { "/\($0.cssLineHeight)" } ?? ""

        return "\(font.isItalic ? "italic " : "")\(font.weight.cssValue) \(font.size.css)\(lineHeight) \(familyID)"
    }


    // MARK: .GFonts

    fileprivate struct GFonts {

        /// [Family : Query].
        private var elements: [String : Set<QueryItem>] = .init()


        // MARK: .QueryItem

        /// - Note: Query items are sorted to meet the 
        private struct QueryItem : Hashable, Comparable {

            var italic: Bool
            var weight: UInt16


            // MARK: : Comparable

            static func <(lhs: Self, rhs: Self) -> Bool {
                switch (lhs.italic, rhs.italic) {
                case (false, true):
                    return true
                case (true, false):
                    return false
                case (false, false), (true, true):
                    return lhs.weight < rhs.weight
                }
            }

        }


        // MARK: Operations

        /// Sequence of URIs of the required fonts.
        var resourceLinks: KvHtmlBytes {
            var urlComponents = URLComponents(string: "https://fonts.googleapis.com/css2")!

            return .joined(elements.lazy.compactMap { family, query in
                let tuples = query
                    .sorted()
                    .lazy.map { "\($0.italic ? "1" : "0"),\($0.weight)" }
                    .joined(separator: ";")

                urlComponents.queryItems = [ .init(name: "family", value: "\(family):ital,wght@\(tuples)") ]

                return KvHtmlResource.css(.external(urlComponents.url!))
                    .htmlLink?
                    .bytes(basePath: nil) // URLs to external resources are not resolved against base URL.
            })
        }


        mutating func insert(family: String, italic: Bool, weight: UInt16) {
            elements[family, default: .init()].insert(.init(italic: italic, weight: weight))
        }

    }


    // MARK: .FontResourceKit

    private struct FontResourceKit { private init() { }

        static func processSource(_ source: KvFontResource.Source) -> (cssFontFaceSource: String, htmlResource: KvHtmlResource?) {
            switch source {
            case .local(name: let name):
                return ("local(\"\(name)\")", nil)

            case .url(let url, let format):
                let url = URL(string: url)!

                guard let fontID = FileKit.id(forFileAt: url)
                else { return KvDebug.pause(code: ("error://", nil), "Failed to access font at «\(url)» URL") }

                let uri = FileKit.uri(forFileID: fontID, relativeTo: "font/", extension: url.pathExtension)
                let (format, contentType) = processSourceFormat(url, format)

                // - NOTE: Assuming path .. leads to the bundle's root.
                return (cssFontFaceSource: "url(\"../\(uri)\")\(format?.css ?? "")",
                        htmlResource: .init(content: .local(.url(url), .init(path: uri)), contentType: contentType))
            }
        }


        private static func processSourceFormat(
            _ url: URL, _ format: KvFontResource.Source.Format?
        ) -> (KvFontResource.Source.Format?, KvHttpContentType?)
        {
            switch format {
            case .some(let format):
                return (format, format.contentType ?? .from(url))

            case .none:
                let contentType = KvHttpContentType.from(url)
                return (contentType.flatMap(KvFontResource.Source.Format.init(_:)), contentType)
            }
        }

    }

}



// MARK: Images

extension KvHtmlContext {

    func uri(for imageResource: ImageResource) -> String {
        if let url = imageResource.bundle.url(forResource: imageResource.name, withExtension: nil) {
            guard let uri = FileKit.uri(forFileAt: url, relativeTo: "img/", preserveExtension: true)
            else { return KvDebug.pause(code: "error://", "Failed to access image at «\(url)» URL") }

            insert(.init(content: .local(.url(url), .init(path: uri)), contentType: .from(url)))

            return uri
        }
        else if let url = URL(string: imageResource.name) {
            return url.absoluteString
        }

        return KvDebug.pause(code: "error://", "Failed to find image for resource \(imageResource)")
    }

}



// MARK: .FileKit

extension KvHtmlContext {

    /// Auxiliary code for arbitrary files like images, fonts etc.
    private struct FileKit { private init() { }

        private static var data = Data(count: 4 << 10)


        static func uri(forFileAt url: URL, relativeTo basePath: String? = nil, preserveExtension: Bool = false) -> String? {
            guard let id = id(forFileAt: url) else { return nil }

            return uri(forFileID: id, relativeTo: basePath, extension: preserveExtension ? url.pathExtension : nil)
        }


        static func uri(forFileID id: String, relativeTo basePath: String? = nil, extension: String? = nil) -> String {
            var uri = id

            if let `extension`, !`extension`.isEmpty {
                uri = "\(uri).\(`extension`)"
            }

            if let basePath {
                uri = basePath.last != "/" ? "\(basePath)/\(uri)" : "\(basePath)\(uri)"
            }

            return uri
        }


        /// - Returns: A file identifier (based on the content's hash) to be used in public URLs.
        static func id(forFileAt url: URL) -> String? {
            guard let stream = InputStream(url: url) else { return nil }

            let count = data.count

            let digest = data.withUnsafeMutableBytes { buffer -> SHA256.Digest? in
                if stream.streamStatus == .notOpen {
                    stream.open()
                }

                let buffer = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                var hasher = SHA256()
                var bytesRead: Int

                while true {
                    bytesRead = stream.read(buffer, maxLength: count)

                    guard bytesRead > 0 else {
                        guard bytesRead == 0 else { return nil }
                        break
                    }

                    hasher.update(bufferPointer: .init(start: buffer, count: bytesRead))
                }

                return hasher.finalize()
            }

            guard let id = digest?.withUnsafeBytes({ buffer in
                KvBase64.encodeAsString(buffer, alphabet: .urlSafe)
            })
            else { return nil }

            return id
        }

    }

}
