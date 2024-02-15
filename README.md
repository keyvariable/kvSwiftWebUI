# kvSwiftWebUI

*kvSwiftWebUI* is a cross-platform framework providing API to declare web-interfaces in a way very close to *SwiftUI* framework.
It allows to implement web interfaces in a declarative paradigm.
*kvSwiftWebUI* minimizes efforts to create and maintain boilerplate code
allowing developer to focus on the design of the interface and the source code.

*kvSwiftWebUI* supports:
- dynamic navigation destinations, e.g. `/user/1234`;
- favicons, the home screen icons and tint color, etc;
- localization;
- dark theme;
- caching of responses;
- scripts.

A significant difference from *SwiftUI* is that lengths are in CSS units.
It's possible to declare padding of `.em(1.5)` or a view of `min(.vw(100), 1024)` width.

See [*Samples*](./Samples) package for examples.
Also *ExampleServer* is running at [example.swiftwebui.keyvar.com](https://example.swiftwebui.keyvar.com).


## Licence

This version of *kvSwiftWebUI* is licensed under GNU General Public License v3.0.


## Supported Platforms

Although there are no explicit restrictions for any platform, the development is focused on Linux and Apple platforms.


## Getting Started

#### Package Dependencies:
```swift
.package(url: "https://github.com/keyvariable/kvSwiftWebUI.git", from: "0.2.0")
```
#### Target Dependencies:
```swift
.product(name: "kvSwiftWebUI", package: "kvSwiftWebUI")
```
#### Import:
```swift
import kvSwiftWebUI
import kvCssKit     // Optional import for CSS expressions like `.em(1) + .rem(0.5)`.
```


## Overview

As in *SwiftUI*, interface declarations are based on basic views like `Text`, `Image`, `Link` and it's modifications.
Modified basic views are organized to hierarchies using various layout container views like `HStack`, `VStack`, `Grid`, etc.
The root view of a view hierarchy is a navigation destination.
Navigation destinations are also organized to hierarchy.

All views have to conform to `View` protocol.
Any fragment of a view hierarchy can be incapsulated into a Swift structure, a method or a computed property.

Simple example of a `HelloWorldView` can be implemented this way:
```swift
struct HelloWorldView : View {
    var body: some View {
        Text("Hello world!")
            .font(.system(.largeTitle))
            .frame(width: .vw(100), height: .vw(100))
    }
}
```
Note modifiers applied to label.
The font modifier makes label to be presented as a primary title.
The frame modifier places label into a container having the same size as the viewport.
By default frame container centers it's contents.

See [*Samples*](./Samples) package for more examples.
Also *ExampleServer* is running at [example.swiftwebui.keyvar.com](https://example.swiftwebui.keyvar.com).


## Authors

- Svyatoslav Popov ([@sdpopov-keyvariable](https://github.com/sdpopov-keyvariable), [info@keyvar.com](mailto:info@keyvar.com)).
