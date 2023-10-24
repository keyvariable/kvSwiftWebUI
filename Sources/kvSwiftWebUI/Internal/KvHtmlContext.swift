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

    private(set) var headers: [KvHtmlBytes] = .init()


    private var _resources: Set<KvHtmlResource> = .init()

    private var generatedCSS: GeneratedCSS = .init()

    private var gFonts: GFonts = .init()



    // MARK: Operations

    func insert(headers: KvHtmlBytes) {
        self.headers.append(headers)
    }


    func resources() -> AnySequence<KvHtmlResource> {
        .init([
            AnySequence(_resources.sorted(by: { $0.uri < $1.uri })),
            gFonts.resources
        ].joined())
    }


    func insert(_ resource: KvHtmlResource) {
        _resources.insert(resource)
    }


    func insert<S>(_ resources: S) where S : Sequence, S.Element == KvHtmlResource {
        _resources.formUnion(resources)
    }


    /// - Note: It's used to insert resources expricitely.
    func insert(_ cssAsset: KvCssAsset) {
        insert(cssAsset.resource)
    }


    private func insert(_ cssDeclaration: CssDeclaration) {
        switch cssDeclaration {
        case .asset(let cssAsset):
            insert(cssAsset)

        case .generated(let entry):
            _resources.insert(KvCssAsset.Resource.generated({ self.generatedCSS.bytes }))
            generatedCSS.insert(entry)
        }
    }



    // MARK: .CssDeclaration

    enum CssDeclaration {

        /// Value is declared in an asset.
        case asset(KvCssAsset)

        case generated(GeneratedCssEntry)

    }



    // MARK: .GeneratedCssEntry

    struct GeneratedCssEntry {

        /// `Nil` means global scope.
        let selector: String?
        /// Identifier used to filter duplicates and provide the same CSS for the same declarations.
        let id: ID
        let `default`: () -> String
        /// - Parameter dark: Optional CSS code producing value in dark environment.
        let dark: (() -> String)?


        init(selector: String?, id: ID, default: @escaping () -> String, dark: (() -> String)? = nil) {
            self.selector = selector
            self.id = id
            self.default = `default`
            self.dark = dark
        }


        // MARK: .ID

        enum ID : Hashable, Comparable {

            case color(id: String)
            case flexClasses
            case fontResource(name: String, key: KvFontResource.Face.Key)


            // MARK: : Comparable

            private var groupOrderKey: GroupOrderKey {
                switch self {
                case .color(_): .color
                case .flexClasses: .flexClasses
                case .fontResource(_, _): .font
                }
            }


            static func <(lhs: Self, rhs: Self) -> Bool {
                switch lhs {
                case .color(let lhs):
                    guard case .color(let rhs) = rhs else { return GroupOrderKey.color < rhs.groupOrderKey }
                    return lhs < rhs

                case .flexClasses:
                    return lhs.groupOrderKey < rhs.groupOrderKey

                case .fontResource(name: let lName, key: let lKey):
                    guard case .fontResource(name: let rName, key: let rKey) = rhs else { return GroupOrderKey.color < rhs.groupOrderKey }

                    switch lName.compare(rName) {
                    case .orderedAscending: return true
                    case .orderedDescending: return false
                    case .orderedSame: break
                    }

                    if lKey.weight < rKey.weight { return true }
                    else if rKey.weight < lKey.weight { return false }

                    return !lKey.isItalic && rKey.isItalic // false is 0, true is 1
                }
            }


            // MARK: .GroupOrderKey

            private enum GroupOrderKey: UInt, Comparable {

                case color
                case flexClasses
                case font

                // MARK: : Comparable

                static func <(lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

            }

        }

    }



    // MARK: .GeneratedCSS

    private struct GeneratedCSS {

        /// [Selector : [ID : CSS]].
        /// - Note: Empty key means global scope.
        private typealias Container = [String : [GeneratedCssEntry.ID : String]]


        private var `default`: Container = .init()
        private var dark: Container = .init()


        // MARK: Operations

        var isEmpty: Bool { `default`.isEmpty && dark.isEmpty }


        var bytes: KvHtmlBytes { .joined(
            GeneratedCSS.bytes(of: `default`),
            GeneratedCSS.bytes(of: dark, mediaQuery: "@media(prefers-color-scheme: dark)")
        ) }


        /// - Parameter environment: E.g. "@media (prefers-color-scheme: dark) {" including "{".
        private static func bytes(of container: Container, mediaQuery: String? = nil) -> KvHtmlBytes {
            guard !container.isEmpty else { return .empty }

            return .joined(container.lazy.map { selector, declarations in
                return .joined(declarations.values.lazy.map(KvHtmlBytes.from(_:)))
                    .wrap {
                        switch !selector.isEmpty {
                        case true: .joined(.from(selector), "{", $0, "}")
                        case false: $0
                        }
                    }
            })
            .wrap {
                switch mediaQuery {
                case .none: $0
                case .some(let mediaQuery): .joined(.from(mediaQuery), "{", $0, "}")
                }
            }
        }


        mutating func insert(_ entry: GeneratedCssEntry) {
            GeneratedCSS.insert(entry.default, into: &`default`, selector: entry.selector, id: entry.id)

            if let declaration = entry.dark {
                GeneratedCSS.insert(declaration, into: &dark, selector: entry.selector, id: entry.id)
            }
        }


        private static func insert(_ cssProvider: () -> String, into container: inout Container, selector: String?, id: GeneratedCssEntry.ID) {
            _ = { scope -> Void in
                let declaration = scope[id]

                guard declaration == nil else {
                    assert(declaration! == cssProvider(), "Attempt to replace CSS `\(declaration!)` with `\(cssProvider())` with «\(id)» ID for «\(selector ?? "`nil`")» selector")
                    return
                }

                let css = cssProvider()

                guard !css.isEmpty else { return }

                scope[id] = css
            }(&container[selector ?? "", default: .init()])
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
        let declaration: CssDeclaration = .generated(.init(
            selector: nil,
            id: .flexClasses,
            default: KvHtmlContext.cssFlexClasses,
            dark: nil
        ))

        insert(declaration)

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
        let declaration: CssDeclaration?
        let expression: String

        switch color.dark {
        case .none:
            declaration = nil
            expression = ColorKit.cssExpression(color.light, opacity: color.opacity)

        case .some(let dark):
            let id = ColorKit.cssID(light: color.light, dark: dark)

            let needsAlpha = color.light.alpha != nil || dark.alpha != nil

            declaration = .generated(.init(
                selector: ":root",
                id: .color(id: id),
                default: { ColorKit.cssDeclaration(of: color.light, forceAlpha: needsAlpha, id: id) },
                dark: { ColorKit.cssDeclaration(of: dark, forceAlpha: needsAlpha, id: id) }
            ))

            expression = ColorKit.cssExpression(id: id,
                                                opacity: color.opacity,
                                                options: needsAlpha ? .useAplhaVariable : [ ])
        }

        if let declaration {
            insert(declaration)
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
                            self._resources.insert(htmlResource)
                        }
                        return cssFontFaceSource
                    }
                    .joined(separator: ",")

                insert(.generated(.init(
                    selector: nil,
                    id: .fontResource(name: resource.name, key: faceKey),
                    default: { "@font-face{font-family:\"\(resource.name)\";src:\(cssSources);font-weight:\(faceKey.weight.cssValue);font-style:\(faceKey.isItalic ? "italic" : "normal");}" }
                )))
            }

            familyID = "'\(resource.name)'"

        case .system(let design):
            familyID = design.cssFamilyID
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
        var resources: AnySequence<KvHtmlResource> {
            var urlComponents = URLComponents(string: "https://fonts.googleapis.com/css2")!

            return .init(elements.lazy.map { family, query in
                let tuples = query
                    .sorted()
                    .lazy.map { "\($0.italic ? "1" : "0"),\($0.weight)" }
                    .joined(separator: ";")

                urlComponents.queryItems = [ .init(name: "family", value: "\(family):ital,wght@\(tuples)") ]

                return .css(uri: urlComponents.url!.absoluteString)
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
                        htmlResource: .init(content: .url(url), contentType: contentType, uri: uri))
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

            _resources.insert(.init(content: .url(url), contentType: .from(url), uri: uri))

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
