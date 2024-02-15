//
//  KvHtmlBundle.swift
//  kvSwiftWebUI_kvServerKit
//
//  Created by Svyatoslav Popov on 11.02.2024.
//

import kvHttpKit
import kvServerKit
import kvSwiftWebUI
import NIOHTTP1



extension KvHtmlBundle {

    /// - Returns: A group with configured HTTP response.
    @inlinable
    public var httpResponseGroup: some KvResponseGroup {
        /// Contents of this group are responded on GET and HEAD requests.
        KvGroup(httpMethods: .get) {
            KvHttpResponse.with
                .requestHeaders
                .subpath
                .content { input in
                    self.response(
                        for: KvHtmlBundle.Request(path: input.subpath)
                            .headerIterator(input.requestHeaders.makeIterator())
                    )
                }
        }
    }

}



extension KvResponseGroupBuilder {

    /// Extends `KvResponseGroupBuilder` allowing `KvHtmlBundle` to be used as an expression in the group declarations:
    /// ```swift
    /// KvGroup {
    ///     htmlBundle
    /// }
    /// ```
    @inlinable
    public static func buildExpression(_ htmlBundle: KvHtmlBundle) -> some Group {
        htmlBundle.httpResponseGroup
    }

}



extension KvResponseRootGroupBuilder {

    /// Extends `KvResponseRootGroupBuilder` allowing `KvHtmlBundle` to be used as an expression in the group declarations:
    /// ```swift
    /// KvGroup {
    ///     htmlBundle
    /// }
    /// ```
    @inlinable
    public static func buildExpression(_ htmlBundle: KvHtmlBundle) -> some Group {
        buildExpression(htmlBundle.httpResponseGroup)
    }

}
