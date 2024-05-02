//
//  KvHttpBundle.swift
//  kvSwiftWebUI_kvServerKit
//
//  Created by Svyatoslav Popov on 11.02.2024.
//

import kvSwiftWebUI

import kvHttpKit
import kvServerKit
import NIOHTTP1



extension KvHttpBundle {

    /// - Returns: A group with configured HTTP response.
    @inlinable
    public var httpResponseGroup: some KvResponseGroup {
        /// Contents of this group are responded on GET and HEAD requests.
        KvGroup(httpMethods: .get) {
            KvHttpResponse.with
                .requestHeaders
                .queryMap { $0 ?? [ ] }
                .subpath
                .content { input in
                    let request = KvHttpBundle.Request(path: input.subpath, query: input.query)
                        .headerIterator(input.requestHeaders.makeIterator())

                    return self.response(for: request)
                }
        }
    }

}



extension KvResponseGroupBuilder {

    /// Extends `KvResponseGroupBuilder` allowing `KvHttpBundle` to be used as an expression in the group declarations:
    /// ```swift
    /// KvGroup {
    ///     httpBundle
    /// }
    /// ```
    @inlinable
    public static func buildExpression(_ httpBundle: KvHttpBundle) -> some Group {
        httpBundle.httpResponseGroup
    }

}



extension KvResponseRootGroupBuilder {

    /// Extends `KvResponseRootGroupBuilder` allowing `KvHttpBundle` to be used as an expression in the group declarations:
    /// ```swift
    /// KvGroup {
    ///     httpBundle
    /// }
    /// ```
    @inlinable
    public static func buildExpression(_ httpBundle: KvHttpBundle) -> some Group {
        buildExpression(httpBundle.httpResponseGroup)
    }

}
