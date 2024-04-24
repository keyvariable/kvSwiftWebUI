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
//  KvSitemap.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 24.04.2024.
//

import Foundation

import kvHttpKit



public struct KvSitemap { private init() { }

    // MARK: .Format

    public enum Format {

        case plainText


        public var pathExtension: String {
            switch self {
            case .plainText:
                "txt"
            }
        }

    }



    // MARK: .Constants

    private struct Constants {

        static let byteLimit = 50 << 20 // 50 Mb

    }



    // MARK: Operations

    @inlinable
    public static func pathComponent(fileName: String, format: Format) -> String {
        "\(fileName).\(format.pathExtension)"
    }



    // MARK: .TextEncoder

    /// Accumulator of the sitemap content in text format.
    struct TextEncoder {

        private var content: Data = .init()



        // MARK: Operations

        var isEmpty: Bool { content.isEmpty }



        /// - Returns: A boolean value indicating whether *url* has been appended to the receiver.
        mutating func append(_ url: URL) -> Result<Void, EncodingError> {
            guard let line = url.absoluteString.data(using: .utf8) else {
                print("WARNING: unable to encode «\(url.absoluteString)» URL for the sitemap response")
                return .failure(.unableToEncodeURL(url))
            }

            guard content.count + line.count + 1 <= Constants.byteLimit else {
                print("WARNING: size of the sitemap response has been trimmed to meet 50 Mb limit")
                return .failure(.totalByteLimitExceeded)
            }

            content.append(line)
            content.append(0x0A)

            return .success(())
        }


        func response() -> KvHttpResponseContent {
            // TODO: Use callbacks instead of accumulation of whole response.
            return .binary { content }
                .contentType(.text(.plain))
                .contentLength(content.count)
        }

    }



    // MARK: .EncodingError

    enum EncodingError : LocalizedError {
        case totalByteLimitExceeded
        case unableToEncodeURL(URL)
    }

}
