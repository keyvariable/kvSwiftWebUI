# Samples of *kvSwiftWebUI*

This package contains samples of [*kvSwiftWebUI*](../) framework.


## ExampleServer

*ExampleServer* is a sample server application with HTML frontend on [*kvSwiftWebUI*](../) framework
served with backend on [*kvServerKit*](https://github.com/keyvariable/kvServerKit.swift.git) framework.

*ExampleServer* is running at [example.swiftwebui.keyvar.com](https://example.swiftwebui.keyvar.com).

Note: `swift run ExampleServer` command builds and runs *ExampleServer* sample.

#### Some references:
- [RootView.swift](Sources/ExampleServer/RootView.swift) — root of frontend view hierarchy;
- [BasicsView.swift](Sources/ExampleServer/BasicsView.swift) — a view containing small examples of working with views and view modifiers;
- [ColorCatalogView.swift](Sources/ExampleServer/ColorCatalogView.swift) — color library view using grids to present color previews
  and `\.horizontalSizeClass` environment value to adapt UI to width of viewport;
- [ScriptView.swift](Sources/ExampleServer/ScriptView.swift) - a view containing simple examples of java scripts.
- [Aux/](Sources/ExampleServer/Aux) — collection of auxiliary views;
- [ExampleServer.swift](Sources/ExampleServer/ExampleServer.swift) — HTTP server also providing the main function.


## LocalizedHello

Localization is an important part of developing user-friendly interfaces.
This example displays «Hello!» greeting in English, Chinese, Hindi and many other languages.
By default, language is evaluated from *Accept-Language* HTTP header.

*LocalizedHello* is running at [hello.swiftwebui.keyvar.com](https://hello.swiftwebui.keyvar.com).

Note: `swift run LocalizedHello` command builds and runs *LocalizedHello* sample.


## Authors

- Svyatoslav Popov ([@sdpopov-keyvariable](https://github.com/sdpopov-keyvariable), [info@keyvar.com](mailto:info@keyvar.com)).
