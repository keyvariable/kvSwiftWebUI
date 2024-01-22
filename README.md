# kvSwiftWebUI

*kvSwiftWebUI* is a cross-platform framework providing API to declare web-interfaces in a way very close to *SwiftUI*.

See [*Samples*](./Samples) package for an example.
Also *ExampleServer* is running at [example.swiftwebui.keyvar.com](https://example.swiftwebui.keyvar.com).


## Licence

This package is licensed under GNU General Public License v3.0.
Contact [info@keyvar.com](mailto:info@keyvar.com) for version of *kvSwiftWebUI* under other license if needed.


## Getting Started

#### Package Dependencies:
```swift
.package(url: "https://github.com/keyvariable/kvSwiftWebUI.git", from: "0.1.0")
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


## Authors

- Svyatoslav Popov ([@sdpopov-keyvariable](https://github.com/sdpopov-keyvariable), [info@keyvar.com](mailto:info@keyvar.com)).
