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
//  KvLocalization.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 05.02.2024.
//

import Foundation

import kvHttpKit



/// This class provides various stuff related to localization of the resources.
///
/// *KvLocalization* caches locales used to translate for language IDs and bundles.
public class KvLocalization {

    init(_ bundle: Bundle) {
        self.bundle = bundle

        languageTags = bundle.localizations
        defaultLanguageTag = bundle.preferredLocalizations.first ?? bundle.localizations.first
    }



    private typealias AcceptLanguageIterator = KvHttpAcceptLanguage.Iterator


    private let bundle: Bundle

    /// Language tags ([RFC 5646](https://www.rfc-editor.org/rfc/rfc5646.html )).
    private let languageTags: [String]
    private let defaultLanguageTag: String?



    // MARK: Operations

    private static func selectLanguageTag(for languageTag: String, in languageTags: [String]) -> Match<MatchRate>? {
        languageTags
            .lazy.compactMap { lt in MatchRate.ofLanguageTags(lt, languageTag).map { Match(languageTag: lt, rate: $0) } }
            .max()
    }


    func selectLanguageTag(forAcceptLanguageHeader value: String) -> String? {
        IteratorSequence(KvLocalization.AcceptLanguageIterator(value))
            .lazy.compactMap { element -> Match<MatchCompositeRate>? in
                switch element.languageTag {
                case .some(let languageTag):
                    KvLocalization.selectLanguageTag(for: languageTag, in: self.languageTags)?
                        .mapRate { .init(rate: $0, languageRank: element.rank) }

                case .wildcard:
                    self.defaultLanguageTag.map {
                        Match(languageTag: $0, rate: .init(rate: .exact, languageRank: element.rank))
                    }
                }
            }
            .max()?
            .languageTag
        ?? defaultLanguageTag
    }


    func forEachLanguageTag(_ body: (String) -> Void) {
        languageTags.forEach(body)
    }


    func context(languageTag: String?) -> Context {
        .init(languageTag: languageTag, bundle: bundle)
    }



    // MARK: .Match

    private struct Match<Rate : Comparable> : Comparable {

        let languageTag: String?
        let rate: Rate


        // MARK: : Equatable

        static func ==(lhs: borrowing Match, rhs: borrowing Match) -> Bool { lhs.rate == rhs.rate }


        // MARK: : Comparable

        static func <(lhs: borrowing Match, rhs: borrowing Match) -> Bool { lhs.rate < rhs.rate }


        // MARK: Operations

        func mapRate<R : Comparable>(_ block: (Rate) -> R) -> Match<R> {
            .init(languageTag: languageTag, rate: block(rate))
        }

    }



    // MARK: .MatchRate

    /// - Note: It's internal to provide access from unit-tests.
    enum MatchRate : Comparable {

        case exact
        /// Associated value is a number of matching leading subtags.
        case partial(Int)


        // MARK: Fabrics

        /// Initializes result of matching two language tags.
        static func ofLanguageTags(_ lhs: String, _ rhs: String) -> MatchRate? {
            var numberOfSubtags = 0


            func MakeResult() -> MatchRate? {
                numberOfSubtags > 0 ? .partial(numberOfSubtags) : nil
            }


            var lhs = lhs.makeIterator()
            var rhs = rhs.makeIterator()

            while let lc = lhs.next() {
                switch rhs.next() {
                case .some(let rc):
                    switch (lc, rc) {
                    case ("-", "-"):
                        numberOfSubtags += 1
                    case ("-", _), (_, "-"):
                        return MakeResult()
                    default:
                        guard lc == rc || String(lc).caseInsensitiveCompare(String(rc)) == .orderedSame
                        else { return MakeResult() }
                    }

                case .none:
                    return lc == "-" ? .partial(numberOfSubtags + 1) : MakeResult()
                }
            }

            switch rhs.next() {
            case nil:
                return .exact
            case "-":
                numberOfSubtags += 1
            default:
                break
            }

            return MakeResult()
        }


        // MARK: : Comparable

        static func <(lhs: MatchRate, rhs: MatchRate) -> Bool {
            switch (lhs, rhs) {
            case (.exact, _): false
            case (.partial(_), .exact): true
            case (.partial(let lhs), .partial(let rhs)): lhs < rhs
            }
        }


        // MARK: Operations

        func compare(_ rhs: MatchRate) -> ComparisonResult {
            switch (self, rhs) {
            case (.exact, .exact): .orderedSame
            case (.exact, .partial(_)): .orderedDescending
            case (.partial(_), .exact): .orderedAscending
            case (.partial(let lhs), .partial(let rhs)):
                lhs < rhs ? .orderedAscending : (lhs == rhs ? .orderedSame : .orderedDescending)
            }
        }

    }



    // MARK: .MatchCompositeRate

    private struct MatchCompositeRate : Comparable {

        let rate: MatchRate
        let languageRank: AcceptLanguageIterator.Element.Rank


        // MARK: : Comparable

        static func <(lhs: borrowing MatchCompositeRate, rhs: borrowing MatchCompositeRate) -> Bool {
            switch lhs.rate.compare(rhs.rate) {
            case .orderedAscending: true
            case .orderedDescending: false
            case .orderedSame: lhs.languageRank < rhs.languageRank
            }
        }

    }



    // MARK: .Context

    /// A context of localization. It resolves localized string resources according to the context's locale.
    ///
    /// Below is an example of common usage:
    /// ```swift
    /// struct HelloView : View {
    ///     @Environment(\.localization) private var localization
    ///
    ///     var body: some View {
    ///         let hello = localization.string(forKey: "hello!")
    ///         Text(verbatim: hello.uppercased())
    ///     }
    /// }
    /// ```
    ///
    /// - Note: ``Text`` view supports localization so in most cases there is no need to access localization context.
    public class Context {

        /// Selected language tag in the primary bundle or `nil` whether localization is enabled.
        /// When localization is disabled, keys of localized resources are used as resolved strings.
        public let languageTag: String?


        fileprivate init(languageTag: String?, bundle: Bundle) {
            assert(languageTag == nil || bundle.localizations.contains(languageTag!))

            self.languageTag = languageTag
            self.bundle = bundle
            self.resolvedBundle = Context.resolve(languageTag, bundle)
        }


        /// Primary bundle.
        private let bundle: Bundle
        /// Resolved primary bundle.
        private let resolvedBundle: Bundle

        /// Cache of resolved bundles for non-primary bundle URLs.
        ///
        /// If a bundle contains localizations
        private var resolvedBundles: [URL : Bundle] = .init()


        // MARK: Fabrics

        /// - Returns: A context providing no localization. It just returns the keys.
        static var disabled: Context { .init(languageTag: nil, bundle: .main) }


        // MARK: Operations

        struct Options : OptionSet {

            /// If specified then arguments of type ``KvText`` are replaced with `"%n$T"`.
            static let textPlaceholders = Self(rawValue: 1 << 0)

            let rawValue: UInt

        }


        /// - Parameter defaultBundle: Bundle to use when the *resource*'s bundle is `nil`.
        borrowing func string(_ resource: borrowing StringResource, defaultBundle: Bundle? = nil, options: Options = [ ]) -> String {

            func Localized(_ key: String) -> String {
                string(forKey: key,
                       defaultValue: resource.defaultValue,
                       table: resource.table,
                       bundle: resource.bundle ?? defaultBundle)
            }


            switch resource.key.value {
            case .final(let key):
                return Localized(key)

            case .formatted(let format, let arguments):
                let format = Localized(format)

                return .init(format: Localized(format), arguments: arguments.enumerated().map { (offset, value) in
                    switch value {
                    case .cVarArg(let value, format: _):
                        value
                    case .text(let text): 
                        !options.contains(.textPlaceholders)
                        ? text.plainText(in: self, defaultBundle: defaultBundle)
                        : "%\(offset + 1)$T"
                    }
                })
            }
        }


        // TODO: stringgen
        /// - Parameter bundle: Optional bundle to take localized string from. If `nil` then the primary bundle is used.
        /// 
        /// - Returns: A resolved localized string in the localization context.
        ///
        /// Method returns first available string of:
        /// 1. localized string from the bundle for the locale;
        /// 2. localized string from the bundle for the first preferred locale;
        /// 3. *defaultValue*;
        /// 4. *key*.
        ///
        /// See documentation of ``Context`` for examples.
        public borrowing func string(forKey key: String,
                                     defaultValue: String? = nil,
                                     table: String? = nil,
                                     bundle: Bundle? = nil,
                                     comment: StaticString? = nil
        ) -> String {
            let bundle = resolved(bundle ?? self.bundle)

            return bundle.localizedString(forKey: key, value: defaultValue, table: table)
        }


        /// - Returns: Cached result of ``resolve(_:)`` for given *bundle*.
        private borrowing func resolved(_ bundle: Bundle) -> Bundle {
            guard bundle != self.bundle else { return resolvedBundle }
            guard let languageTag else { return bundle }

            return {
                switch $0 {
                case .some(let bundle):
                    return bundle

                case .none:
                    let bundle = Context.resolve(languageTag, bundle)
                    $0 = bundle
                    return bundle
                }
            }(&resolvedBundles[bundle.bundleURL])
        }


        /// - Returns: A child bundle containing localized resources for given *languageTag* or *bundle* otherwise.
        private static func resolve(_ languageTag: String?, _ bundle: Bundle) -> Bundle {
            guard let languageTag = languageTag.map({
                KvLocalization.selectLanguageTag(for: $0, in: bundle.localizations)?.languageTag
                ?? bundle.preferredLocalizations.first
                ?? bundle.localizations.first
            })
            else { return bundle }

            guard let url = bundle.url(forResource: languageTag, withExtension: "lproj"),
                  let bundle = Bundle(url: consume url)
            else { return bundle }

            return bundle
        }

    }



    // MARK: .StringResource

    @usableFromInline
    struct StringResource : Equatable {

        var key: KvLocalizedStringKey
        var defaultValue: String?

        var table: String?
        var bundle: Bundle?


        @usableFromInline
        init(key: KvLocalizedStringKey, defaultValue: String? = nil, table: String? = nil, bundle: Bundle? = nil) {
            self.key = key
            self.defaultValue = defaultValue
            self.table = table
            self.bundle = bundle
        }

    }

}
