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
//  KvLinearGradient.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 30.11.2023.
//

import Foundation



public typealias LinearGradient = KvLinearGradient



// TODO: DOC
public struct KvLinearGradient : KvShapeStyle, KvView {

    @usableFromInline
    let gradient: KvGradient

    @usableFromInline
    let axis: Axis



    // TODO: DOC
    @inlinable
    public init(gradient: KvGradient, axis: Axis) {
        self.gradient = gradient
        self.axis = axis
    }


    // TODO: DOC
    @inlinable
    public init(gradient: KvGradient, endPoint: Anchor) {
        self.init(gradient: gradient, axis: .anchor(endPoint))
    }


    // TODO: DOC
    @inlinable
    public init(colors: [KvColor], endPoint: Anchor) {
        self.init(gradient: .init(colors: colors), endPoint: endPoint)
    }


    // TODO: DOC
    @inlinable
    public init(stops: [KvGradient.Stop], endPoint: Anchor) {
        self.init(gradient: .init(stops: stops), endPoint: endPoint)
    }



    // MARK: .Axis

    // TODO: DOC
    public enum Axis {

        /// Adaptive axis containing the element's center and given *anchor*.
        case anchor(Anchor)
        /// Static axis evaluated by rotation of vector from the center to trailing anchor by given angle (in radians) in direction to top anchor.
        /// E.g. 0 produce the trailing anchor axis, `0.5 * .pi` produce the top anchor axis.
        case angle(Double)


        // MARK: CSS

        var cssExpression: String {
            switch self {
            case .anchor(let anchor):
                anchor.cssExpression
            case .angle(let angle):
                String(format: "%.1grad", -angle + 0.5 * .pi)
            }
        }

    }



    // MARK: .Anchor

    // TODO: DOC
    public enum Anchor : Hashable {

        // TODO: DOC
        case topLeading
        // TODO: DOC
        case top
        // TODO: DOC
        case topTrailing
        // TODO: DOC
        case leading
        // TODO: DOC
        case trailing
        // TODO: DOC
        case bottomLeading
        // TODO: DOC
        case bottom
        // TODO: DOC
        case bottomTrailing


        // MARK: CSS

        var cssExpression: String {
            switch self {
            case .topLeading: "to left top"
            case .top: "to top"
            case .topTrailing: "to right top"
            case .leading: "to left"
            case .trailing: "to right"
            case .bottomLeading: "to left bottom"
            case .bottom: "to bottom"
            case .bottomTrailing: "to right bottom"
            }
        }

    }



    // MARK: : KvShapeStyle

    public func eraseToAnyShapeStyle() -> KvAnyShapeStyle {
        let firstColor = gradient.stops.first?.color

        let bottomColor: KvColor? = switch axis {
        case .anchor(let anchor):
            switch anchor {
            case .bottom, .bottomLeading, .bottomTrailing: gradient.stops.last?.color
            case .leading, .top, .topLeading, .topTrailing, .trailing: gradient.stops.first?.color
            }
        case .angle(let angle):
            sin(angle) >= 0 ? gradient.stops.first?.color : gradient.stops.last?.color
        }

        return .init(
            cssBackgroundStyle: { context, property in
                "\(property ?? "background-image"):\(cssBackgroundExpression(in: context))"
            },
            cssForegroundStyle: { context, property in
                "\(property ?? "color"):\(context.cssExpression(for: firstColor ?? .label))"
            },
            backgroundColor: { firstColor },
            bottomBackgroundColor: { bottomColor }
        )
    }



    // MARK: : KvView

    public typealias Body = KvShapeStyleView



    // MARK: CSS

    func cssBackgroundExpression(in context: KvHtmlContext) -> String {
        let cssStops = gradient.cssStops(in: context).map { ",\($0)" } ?? ""

        return "linear-gradient(\(axis.cssExpression)\(cssStops))"
    }

}



// MARK: KvShapeStyle Integration

extension KvShapeStyle where Self == KvLinearGradient {

    // TODO: DOC
    @inlinable
    public static func linearGradient(_ gradient: KvGradient, axis: KvLinearGradient.Axis) -> Self {
        .init(gradient: gradient, axis: axis)
    }


    // TODO: DOC
    @inlinable
    public static func linearGradient(_ gradient: KvGradient, endPoint: KvLinearGradient.Anchor) -> Self {
        .init(gradient: gradient, endPoint: endPoint)
    }

    
    // TODO: DOC
    @inlinable
    public static func linearGradient(colors: [KvColor], endPoint: KvLinearGradient.Anchor) -> Self {
        .init(colors: colors, endPoint: endPoint)
    }


    // TODO: DOC
    @inlinable
    public static func linearGradient(stops: [KvGradient.Stop], endPoint: KvLinearGradient.Anchor) -> Self {
        .init(stops: stops, endPoint: endPoint)
    }

}
