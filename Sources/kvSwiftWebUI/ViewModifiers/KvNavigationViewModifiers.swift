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
//  KvNavigationViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 21.11.2023.
//

// MARK: Navigation Modifiers

extension KvView {

    /// This modifier provides title for navigation bars and the window title.
    /// If several views declare navigation title in a navigation destination then the first title is used and others are ignored.
    @inlinable
    public consuming func navigationTitle(_ title: KvText) -> some KvView { mapConfiguration {
        $0!.navigationTitle = title
    } }
    

    // TODO: stringgen function
    /// This modifier provides title for navigation bars and the window title.
    /// If several views declare navigation title in a navigation destination then the first title is used and others are ignored.
    @inlinable
    public consuming func navigationTitle(_ titleKey: KvLocalizedStringKey) -> some KvView { mapConfiguration {
        $0!.navigationTitle = KvText(titleKey)
    } }


    /// This modifier provides title for navigation bars and the window title.
    /// If several views declare navigation title in a navigation destination then the first title is used and others are ignored.
    @_disfavoredOverload
    @inlinable
    public consuming func navigationTitle<S>(_ title: S) -> some KvView
    where S : StringProtocol
    { mapConfiguration {
        $0!.navigationTitle = KvText(title)
    } }


    
    @usableFromInline
    consuming func navigationDestination<S, C>(staticData: S = [ ], destinationProvider: @escaping (String) -> (view: C, value: Any)?) -> some KvView
    where S : Sequence, S.Element == String, C : KvView
    {
        mapConfiguration {
            $0!.appendNavigationDestinations(staticData: staticData, destinationProvider: destinationProvider)
        }
    }


    /// This modifier provides a view on next navigation level.
    ///
    /// Simple example:
    /// ```swift
    /// enum Pet : String, CaseIterable { case cat, dog }
    ///
    /// VStack {
    ///     ForEach(Pet.allCases, id: \.self) { pet in
    ///         NavigationLink(pet.rawValue, value: pet)
    ///     }
    /// }
    /// .navigationDestination(for: Pet.self) { pet in
    ///     switch pet {
    ///     case .cat: CatView()
    ///     case .dog: DogView()
    ///     }
    /// }
    /// ```
    ///
    /// Any type conforming to `LosslessStringConvertible` or `RawRepresentable` having `LosslessStringConvertible` raw value can be used. For example:
    /// ```swift
    /// SomeView()
    ///     .navigationDestination(for: Int.self) { value in
    ///         Text("\(value) as Int")
    ///     }
    /// ```
    ///
    /// Current navigation path is available in the environment:
    /// ```swift
    /// @Environment(\.navigationPath) private var navigationPath
    /// ```
    ///
    /// - Tip: If `D` type conforms to `CaseIterable` protocol then navigation destinations are preprocessed and requests are handled faster.
    ///
    /// - SeeAlso: ``NavigationLink``, ``NavigationPath``.
    public consuming func navigationDestination<D, Content>(for data: D.Type, @KvViewBuilder destination: @escaping (D) -> Content) -> some KvView
    where D : LosslessStringConvertible, Content : KvView
    {
        navigationDestination { data in D(data).map { value in
            (destination(value), value: value)
        } }
    }


    /// This modifier provides a view on next navigation level.
    ///
    /// Simple example:
    /// ```swift
    /// enum Pet : String, CaseIterable { case cat, dog }
    ///
    /// VStack {
    ///     ForEach(Pet.allCases, id: \.self) { pet in
    ///         NavigationLink(pet.rawValue, value: pet)
    ///     }
    /// }
    /// .navigationDestination(for: Pet.self) { pet in
    ///     switch pet {
    ///     case .cat: CatView()
    ///     case .dog: DogView()
    ///     }
    /// }
    /// ```
    ///
    /// Any type conforming to `LosslessStringConvertible` or `RawRepresentable` having `LosslessStringConvertible` raw value can be used. For example:
    /// ```swift
    /// SomeView()
    ///     .navigationDestination(for: Int.self) { value in
    ///         Text("\(value) as Int")
    ///     }
    /// ```
    ///
    /// Current navigation path is available in the environment:
    /// ```swift
    /// @Environment(\.navigationPath) private var navigationPath
    /// ```
    ///
    /// - Tip: If `D` type conforms to `CaseIterable` protocol then navigation destinations are preprocessed and requests are handled faster.
    ///
    /// - SeeAlso: ``NavigationLink``, ``NavigationPath``.
    public consuming func navigationDestination<D, Content>(for data: D.Type, @KvViewBuilder destination: @escaping (D) -> Content) -> some KvView
    where D : CaseIterable, D : LosslessStringConvertible, Content : KvView
    {
        navigationDestination(
            staticData: data.allCases.lazy.map { $0.description },
            destinationProvider: { data in D(data).map { value in
                (destination(value), value: value)
            } }
        )
    }


    /// This modifier provides a view on next navigation level.
    ///
    /// Simple example:
    /// ```swift
    /// enum Pet : String, CaseIterable { case cat, dog }
    ///
    /// VStack {
    ///     ForEach(Pet.allCases, id: \.self) { pet in
    ///         NavigationLink(pet.rawValue, value: pet)
    ///     }
    /// }
    /// .navigationDestination(for: Pet.self) { pet in
    ///     switch pet {
    ///     case .cat: CatView()
    ///     case .dog: DogView()
    ///     }
    /// }
    /// ```
    ///
    /// Any type conforming to `LosslessStringConvertible` or `RawRepresentable` having `LosslessStringConvertible` raw value can be used. For example:
    /// ```swift
    /// SomeView()
    ///     .navigationDestination(for: Int.self) { value in
    ///         Text("\(value) as Int")
    ///     }
    /// ```
    ///
    /// Current navigation path is available in the environment:
    /// ```swift
    /// @Environment(\.navigationPath) private var navigationPath
    /// ```
    ///
    /// - Tip: If `D` type conforms to `CaseIterable` protocol then navigation destinations are preprocessed and requests are handled faster.
    ///
    /// - SeeAlso: ``NavigationLink``, ``NavigationPath``.
    public consuming func navigationDestination<D, Content>(for data: D.Type, @KvViewBuilder destination: @escaping (D) -> Content) -> some KvView
    where D : RawRepresentable, D.RawValue : LosslessStringConvertible, Content : KvView
    {
        navigationDestination { data in D.RawValue(data).flatMap(D.init(rawValue:)).map { value in
            (destination(value), value: value)
        } }
    }


    /// This modifier provides a view on next navigation level.
    ///
    /// Simple example:
    /// ```swift
    /// enum Pet : String, CaseIterable { case cat, dog }
    ///
    /// VStack {
    ///     ForEach(Pet.allCases, id: \.self) { pet in
    ///         NavigationLink(pet.rawValue, value: pet)
    ///     }
    /// }
    /// .navigationDestination(for: Pet.self) { pet in
    ///     switch pet {
    ///     case .cat: CatView()
    ///     case .dog: DogView()
    ///     }
    /// }
    /// ```
    ///
    /// Any type conforming to `LosslessStringConvertible` or `RawRepresentable` having `LosslessStringConvertible` raw value can be used. For example:
    /// ```swift
    /// SomeView()
    ///     .navigationDestination(for: Int.self) { value in
    ///         Text("\(value) as Int")
    ///     }
    /// ```
    ///
    /// Current navigation path is available in the environment:
    /// ```swift
    /// @Environment(\.navigationPath) private var navigationPath
    /// ```
    ///
    /// - Tip: If `D` type conforms to `CaseIterable` protocol then navigation destinations are preprocessed and requests are handled faster.
    ///
    /// - SeeAlso: ``NavigationLink``, ``NavigationPath``.
    public consuming func navigationDestination<D, Content>(for data: D.Type, @KvViewBuilder destination: @escaping (D) -> Content) -> some KvView
    where D : CaseIterable, D : RawRepresentable, D.RawValue : LosslessStringConvertible, Content : KvView
    {
        navigationDestination(
            staticData: data.allCases.lazy.map { $0.rawValue.description },
            destinationProvider: { data in D.RawValue(data).flatMap(D.init(rawValue:)).map { value in
                (destination(value), value: value)
            } }
        )
    }

}
