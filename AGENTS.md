# Repository Guidelines

## Project Structure & Module Organization
- `graphhopper/` is a Git submodule tracking the `ios_compatibility` branch of GraphHopper; keep it in sync before changing bindings.
- `make/` hosts the j2objc build recipes, while `src/` collects generated Objective-C sources—never edit files in `src/` by hand.
- `dependencies/` caches translated Java libraries, and `build/` plus `xcframeworks/` hold the compiled static libraries and XCFrameworks.
- `graphhopper-ios-sample/` contains the demo app, import script, and XCTest target; use it to reproduce routing scenarios.

## Build, Test, and Development Commands
- `make cleanall && make class.list` regenerates the Java translation manifest after dependency or submodule changes.
- `make translate && make` runs j2objc translation and produces `build/*-libgraphhopper.a` for simulator and device.
- `./graphhopper-ios-sample/import-sample.sh` downloads example map data so the sample app runs offline.
- `xcodebuild -project graphhopper-ios-sample/graphhopper-ios-sample.xcodeproj -scheme graphhopper-ios-sample -destination "platform=iOS Simulator,name=iPhone 15" build` validates the sample app in CI-friendly fashion.

## Coding Style & Naming Conventions
- Objective-C code follows the Xcode defaults: 4-space indentation, braces on the same line, and `#import` grouping as Foundation, third-party, then project headers.
- Generated files in `src/` mirror GraphHopper Java naming; keep custom categories or adapters in the sample app with descriptive prefixes (e.g. `GHRoute`).
- When extending Swift-facing APIs, expose only umbrella headers listed in `GraphHopperLib.h` to keep the module lightweight.

## Testing Guidelines
- Unit tests live in `graphhopper-ios-sample/graphhopper-ios-sampleTests` and use XCTest; add targeted cases alongside features.
- Prefer scenario-based tests that load fixtures through the bundled `vienna.bundle` or temporary GraphHopper graph directories.
- Run `xcodebuild test ...` on the simulator noted above before submitting, and call out any gaps (e.g. routing data dependencies) in the PR description.

## Commit & Pull Request Guidelines
- Follow the existing history style: short, imperative summaries (e.g. `Update build scripts`, `Add target platform flag`).
- One logical change per commit; include regenerated artifacts (`src/`, `build/`) only when required and note the source commit in the message body.
- Pull requests should describe the problem, the solution, and platform impact, link related issues, and include screenshots or routing traces when UI changes.
- Confirm that `make cleanall`, `make`, and the sample app build succeed locally before requesting review; mention any deviations explicitly.

## Generated Bindings Workflow
Document any manual adjustments you apply to j2objc outputs or `class.list`. Commit the updated instructions alongside code so future regenerations stay reproducible.
