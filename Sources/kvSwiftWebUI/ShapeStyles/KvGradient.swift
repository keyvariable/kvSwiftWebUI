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
//  KvGradient.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 30.11.2023.
//

import kvCssKit

import kvKit



public typealias Gradient = KvGradient



// TODO: DOC
public struct KvGradient : KvShapeStyle, Hashable {

    // TODO: DOC
    public var stops: [Stop]



    // TODO: DOC
    @inlinable
    public init(stops: [Stop]) {
        self.stops = stops
    }


    // TODO: DOC
    @inlinable
    public init(colors: [KvColor]) {
        switch colors.count > 0 {
        case true:
            self.init(
                stops: zip(colors, stride(from: 0.0, through: 100.0 + 1e-3, by: 100.0 / Double(colors.count - 1)))
                    .map { Stop(color: $0, location: .percents($1)) }
            )

        case false:
            self.init(stops: [ ])
        }
    }



    // MARK: .Stop

    // TODO: DOC
    public struct Stop : Hashable {

        // TODO: DOC
        public var color: KvColor

        // TODO: DOC
        public var location: KvCssLength


        @inlinable
        public init(color: Color, location: KvCssLength) {
            self.color = color
            self.location = location
        }


        /// - Parameter location: Location of a color stop in normalized space where 0.0 is 0%, 1.0 is 100%.
        @inlinable
        public init(color: Color, location: Double) {
            self.init(color: color, location: .percents(1e2 * location))
        }


        /// - Parameter location: Location of a color stop in normalized space where 0.0 is 0%, 1.0 is 100%.
        @inlinable
        public init<L : BinaryFloatingPoint>(color: Color, location: L) {
            self.init(color: color, location: Double(location))
        }


        /// - Parameter location: Location of a color stop in percents.
        @inlinable
        public init<L : BinaryInteger>(color: Color, location: L) {
            self.init(color: color, location: .percents(Double(location)))
        }


        // MARK: CSS

        func cssStop(in context: borrowing KvHtmlContext) -> String {
            "\(context.cssExpression(for: color)) \(location.css)"
        }

    }



    // MARK: : KvShapeStyle

    public func eraseToAnyShapeStyle() -> KvAnyShapeStyle {
        KvLinearGradient(gradient: self, endPoint: .bottom).eraseToAnyShapeStyle()
    }



    // MARK: CSS

    func cssStops(in context: borrowing KvHtmlContext) -> String? {
        stops
            .reduce(into: KvStringKit.Accumulator(separator: ",")) { accumulator, stop in
                accumulator.append(stop.cssStop(in: context))
            }
            .string
    }

}
