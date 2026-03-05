# Repository Guidelines

## Project Structure & Module Organization
NetNewsWire is a multi-platform feed reader (`NetNewsWire.xcodeproj`) with app
targets plus modular Swift packages.
- `Mac/`: macOS AppKit UI.
- `iOS/`: iOS UIKit UI, settings, and share/intent flows.
- `Shared/`: shared logic (timeline, rendering, themes, import/export).
- `Modules/`: reusable packages. Foundation layer includes `RSCore`,
  `RSDatabase`, `RSParser`, `RSTree`, `RSWeb`; higher layers include
  `Articles`, `ArticlesDatabase`, `SyncDatabase`, `FeedFinder`, `Account`.
- `Tests/`: app XCTest targets (`NetNewsWireTests`, `NetNewsWire-iOSTests`).
- `Technotes/` and `doc/`: coding rules, architecture notes, and local setup.

This repository is a fork of `Ranchero-Software/NetNewsWire`; align behavior
with upstream docs/changelogs when details are unclear.

## Build, Test, and Run (No Project Scripts)
Do not run repository scripts (`setup.sh`, `buildscripts/*.sh`). Use direct
`xcodebuild` commands.
- macOS unsigned debug build:
```bash
xcodebuild -project NetNewsWire.xcodeproj -scheme NetNewsWire \
  -configuration Debug \
  -destination "platform=macOS,arch=arm64" \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build
```
- macOS unsigned tests:
```bash
xcodebuild -project NetNewsWire.xcodeproj -scheme NetNewsWire \
  -destination "platform=macOS,arch=arm64" \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  test
```
- iOS simulator tests:
```bash
xcodebuild -project NetNewsWire.xcodeproj -scheme NetNewsWire-iOS \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -skip-testing:AccountTests test
```
- Run built app from DerivedData (unsigned):
```bash
xattr -cr ~/Library/Developer/Xcode/DerivedData/NetNewsWire-*/Build/Products/Debug/NetNewsWire.app
open ~/Library/Developer/Xcode/DerivedData/NetNewsWire-*/Build/Products/Debug/NetNewsWire.app
```
- Lint: `swiftlint` (config in `.swiftlint.yml`).

## Coding Style & Naming Conventions
- Write new code in Swift; keep Objective-C mainly for C API edges.
- Indent with tabs (`.editorconfig`).
- Follow `Technotes/CodingGuidelines.md`: small focused types, composition over
  inheritance, and minimal API surface (`private` by default).
- Prefer `final` classes where subclassing is not required.
- Organize files as: properties, methods, protocol-conformance extensions, then
  private extensions.
- Use `AppKit` imports on macOS (avoid `Cocoa`), avoid KVO, and callback to the
  main queue after background work.
- Do not commit compiler warnings, `print`, or debug console noise.

## Upstream Sync Constraint (Required)
- For new requirements and feature changes, keep modifications minimally
  invasive.
- Strongly prefer reusing/extending existing code paths over introducing new
  components or abstractions.
- Keep diffs small and localized to reduce merge conflicts when syncing
  upstream changes.

## Testing Guidelines
- Add unit tests for bug fixes, especially in lower-level modules.
- App test plans: `NetNewsWire.xctestplan` (macOS) and
  `NetNewsWire-iOS.xctestplan` (iOS).
- Module tests: run `swift test` inside a package directory (for example,
  `Modules/RSParser`).
- Keep test files and types in `*Tests.swift` with behavior-focused method names.

## Commit & Pull Request Guidelines
- Commit messages start with a present-tense verb (for example: `Fix`, `Update`,
  `Add`, `Draw`).
- Keep PRs small, warning-free, and cleanly mergeable to `main`.
- For non-trivial features, discuss first in the Discourse Work area noted in
  `CONTRIBUTING.md`.
- PR descriptions should include problem, approach, verification commands, and
  screenshots for UI changes.
