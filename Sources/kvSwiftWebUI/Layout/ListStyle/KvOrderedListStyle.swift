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
//  KvOrderedListStyle.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 22.05.2024.
//

public typealias OrderedListStyle = KvOrderedListStyle



/// List style that describes the behavior and appearance of a list where each item is prefixed with a counting marks, e.g. numbers.
/// See ``Numbering`` enumeration for available numbering types.
///
/// - SeeAlso: ``KvListStyle/ordered``, ``KvListStyle/ordered(_:)``.
public struct KvOrderedListStyle : KvListStyle {

    public static let automatic = KvOrderedListStyle(numbering: .automatic)



    @usableFromInline
    let numbering: Numbering



    @inlinable
    public init(numbering: Numbering) {
        self.numbering = numbering
    }



    // MARK: : KvListStyle

    public func eraseToAnyListStyle() -> KvAnyListStyle {
        return .init(listContainerBlock: { context, rowSpacing, innerFragmentBlock in
            context.representation(
                htmlAttributes: .init {
                    $0.insert(optionalClasses: context.html.cssItemSpacingClass(rowSpacing ?? KvDefaults.htmlListSpacing))
                    if let listStyleTypes = numbering.listStyleTypeCSS {
                        $0.append(styles: listStyleTypes.lazy.map { "list-style-type:\($0)" })
                    }
                }
            ) { context, htmlAttributes in
                let context = context.descendant(containerAttributes: .htmlList)
                let innerFragment = innerFragmentBlock(context)

                return .tag(
                    .ol,
                    attributes: htmlAttributes ?? .empty,
                    innerHTML: innerFragment
                )
            }
        })
    }



    // MARK: .Numbering

    /// Enumeration of available numbering types.
    public enum Numbering {

        case automatic

        /// Arabic-Indic numbers (e.g., ١‎, ٢‎, ٣‎, ٤‎, ..., ٩٨‎, ٩٩‎, ١٠٠‎).
        case arabicIndic
        /// Armenian numbering (e.g., Ա, Բ, Գ, ..., ՂԸ, ՂԹ, Ճ).
        case armenian(case: KvText.Case = .uppercase)
        /// Bengali numbering (e.g., ১, ২, ৩, ..., ৯৮, ৯৯, ১০০).
        case bengali
        /// Cambodian/Khmer numbering (e.g., ១, ២, ៣, ..., ៩៨, ៩៩, ១០០).
        case cambodian
        /// Chinese numbering.
        case chinese(_ script: Chinese = .hanDecimal)
        /// Decimal numbers (e.g., 1, 2, 3, ..., 98, 99, 100).
        case decimal(options: DecimalOptions = [ ])
        /// Devanagari numbering (e.g., १, २, ३, ..., ९८, ९९, १००).
        case devanagari
        /// Ethiopic numbering.
        case ethiopic(_ script: Ethiopic = .numeric)
        /// Traditional Georgian numbering (e.g., ა, ბ, გ, ..., ჟჱ, ჟთ, რ).
        case georgian
        /// Lowercase classical Greek.
        case greekLowercase
        /// Gujarati numbering (e.g., ૧, ૨, ૩, ..., ૯૮, ૯૯, ૧૦૦).
        case gujarati
        /// Gurmukhi numbering (e.g., ੧, ੨, ੩, ..., ੯੮, ੯੯, ੧੦੦).
        case gurmukhi
        /// Traditional Hebrew numbering (e.g., א‎, ב‎, ג‎, ..., צח‎, צט‎, ק‎).
        case hebrew
        /// Japanese numbering.
        case japanese(_ script: Japanese = .kanji())
        /// Kannada numbering (e.g., ೧, ೨, ೩, ..., ೯೮, ೯೯, ೧೦೦).
        case kannada
        /// Cambodian/Khmer numbering (e.g., ១, ២, ៣, ..., ៩៨, ៩៩, ១០០).
        case khmer
        /// Korean numbering.
        case korean(_ script: Korean = .hangulFormal)
        /// Laotian numbering (e.g., ໑, ໒, ໓, ..., ໙໘, ໙໙, ໑໐໐).
        case lao
        /// Latin letters (e.g. a, b, c, ..., x, y, z).
        case latin(case: KvText.Case = .lowercase)
        /// Malayalam numbering (e.g., ൧, ൨, ൩, ..., ൯൮, ൯൯, ൧൦൦).
        case malayalam
        /// Mongolian numbering (e.g., ᠑, ᠒, ᠓, ..., ᠙᠘, ᠙᠙, ᠑᠐᠐).
        case mongolian
        /// Myanmar (Burmese) numbering (e.g., ၁, ၂, ၃, ..., ၉၈, ၉၉, ၁၀၀).
        case myanmar
        /// Oriya (Odia) numbering (e.g., ୧, ୨, ୩, ..., ୯୮, ୯୯, ୧୦୦).
        case oriya
        /// Persian numbering (e.g., ۱, ۲, ۳, ۴, ..., ۹۸, ۹۹, ۱۰۰).
        case persian
        /// Roman numerals.
        case roman(case: KvText.Case = .lowercase)
        /// Tamil numbering (e.g., ௧, ௨, ௩, ..., ௯௮, ௯௯, ௧௦௦).
        case tamil
        /// Telugu numbering (e.g., ౧, ౨, ౩, ..., ౯౮, ౯౯, ౧౦౦).
        case telugu
        /// Thai (Siamese) numbering (e.g., ๑, ๒, ๓, ..., ๙๘, ๙๙, ๑๐๐).
        case thai
        /// Tibetan numbering (e.g., ༡, ༢, ༣, ..., ༩༨, ༩༩, ༡༠༠).
        case tibetan
        /// Urdu numbering.
        case urdu


        // MARK: .Chinese

        public enum Chinese {
            /// Han decimal numbers (e.g., 一, 二, 三, ..., 九八, 九九, 一〇〇).
            case hanDecimal
            /// Han "Earthly Branch" ordinals.
            case hanEarthlyBranch
            /// Han "Heavenly Stem" ordinals.
            case hanHeavenlyStem
            case simplified(formal: Bool = false)
            case traditional(formal: Bool = false)
        }


        // MARK: .DecimalOptions

        public struct DecimalOptions : OptionSet {

            /// Numbers padded by initial zeros (e.g., 01, 02, 03, ..., 98, 99).
            static let leadingZeros = DecimalOptions(rawValue: 1 << 0)


            // MARK: : OptionSet

            public let rawValue: UInt8

            @inlinable public init(rawValue: UInt8) { self.rawValue = rawValue }

        }


        // MARK: .Ethiopic

        public enum Ethiopic {
            case halehame
            case halehame_am
            case halehame_ti_er
            case halehame_ti_et
            case numeric
        }


        // MARK: .Japanese

        public enum Japanese {

            case hiragana(_ lettering: Lettering = .dictionaryOrder)
            case kanji(formal: Bool = false)
            case katakana(_ lettering: Lettering = .dictionaryOrder)


            // MARK: .Lettering

            public enum Lettering {
                /// Dictionary-order lettering.
                case dictionaryOrder
                /// [Iroha-order](https://wikipedia.org/wiki/Iroha) lettering.
                case irohaOrder
            }

        }


        // MARK: .Korean

        public enum Korean {
            case hangulFormal
            case hanja(formal: Bool = false)
        }


        // MARK: CSS

        var listStyleTypeCSS: [String]? {
            switch self {
            case .arabicIndic: [ "arabic-indic" ]
            case .armenian(case: .lowercase): [ "lower-armenian" ]
            case .armenian(case: .uppercase): [ "upper-armenian" ]
            case .automatic: nil
            case .bengali: [ "bengali" ]
            case .cambodian: [ "cambodian" ]
            case .chinese(.hanDecimal): [ "cjk-decimal" ]
            case .chinese(.hanEarthlyBranch): [ "-moz-cjk-earthly-branch", "cjk-earthly-branch" ]
            case .chinese(.hanHeavenlyStem): [ "-moz-cjk-heavenly-stem", "cjk-heavenly-stem" ]
            case .chinese(.simplified(formal: let isFormal)): [ "simp-chinese-\(isFormal ? "formal" : "informal")" ]
            case .chinese(.traditional(formal: let isFormal)): [ "trad-chinese-\(isFormal ? "formal" : "informal")" ]
            case .decimal(let options): !options.contains(.leadingZeros) ? [ "decimal" ] : [ "decimal-leading-zero" ]
            case .devanagari: [ "-moz-devanagari", "devanagari" ]
            case .ethiopic(.halehame): [ "-moz-ethiopic-halehame", "ethiopic-halehame" ]
            case .ethiopic(.halehame_am): [ "-moz-ethiopic-halehame-am", "ethiopic-halehame-am" ]
            case .ethiopic(.halehame_ti_er): [ "-moz-ethiopic-halehame-ti-er", "ethiopic-halehame-ti-er" ]
            case .ethiopic(.halehame_ti_et): [ "-moz-ethiopic-halehame-ti-et", "ethiopic-halehame-ti-et" ]
            case .ethiopic(.numeric): [ "-moz-ethiopic-numeric", "ethiopic-numeric" ]
            case .georgian: [ "georgian" ]
            case .greekLowercase: [ "lower-greek" ]
            case .gujarati: [ "-moz-gujarati", "gujarati" ]
            case .gurmukhi: [ "-moz-gurmukhi", "gurmukhi" ]
            case .hebrew: [ "hebrew" ]
            case .japanese(.hiragana(.dictionaryOrder)): [ "hiragana" ]
            case .japanese(.hiragana(.irohaOrder)): [ "hiragana-iroha" ]
            case .japanese(.kanji(formal: let isFormal)): [ "japanese-\(isFormal ? "formal" : "informal")" ]
            case .japanese(.katakana(.dictionaryOrder)): [ "katakana" ]
            case .japanese(.katakana(.irohaOrder)): [ "hiragana-iroha" ]
            case .kannada: [ "kannada" ]
            case .khmer: [ "khmer" ]
            case .korean(.hangulFormal): [ "korean-hangul-formal" ]
            case .korean(.hanja(formal: let isFormal)): [ "korean-hanja-\(isFormal ? "formal" : "informal")" ]
            case .lao: [ "-moz-lao", "lao" ]
            case .latin(case: .lowercase): [ "lower-latin" ]
            case .latin(case: .uppercase): [ "upper-latin" ]
            case .malayalam: [ "-moz-malayalam", "malayalam" ]
            case .mongolian: [ "mongolian" ]
            case .myanmar: [ "-moz-myanmar", "myanmar" ]
            case .oriya: [ "-moz-oriya", "oriya" ]
            case .persian: [ "-moz-persian", "persian" ]
            case .roman(case: .lowercase): [ "lower-roman" ]
            case .roman(case: .uppercase): [ "upper-roman" ]
            case .tamil: [ "-moz-tamil", "tamil" ]
            case .telugu: [ "-moz-telugu", "telugu" ]
            case .thai: [ "-moz-thai", "thai" ]
            case .tibetan: [ "tibetan" ]
            case .urdu: [ "-moz-urdu", "urdu" ]
            }
        }

    }

}



// MARK: - KvListStyle

extension KvListStyle where Self == KvOrderedListStyle {

    public static var ordered: KvOrderedListStyle { .automatic }


    public static func ordered(_ numbering: KvOrderedListStyle.Numbering) -> KvOrderedListStyle {
        .init(numbering: numbering)
    }

}
