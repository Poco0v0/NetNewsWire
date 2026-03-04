# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Upstream Repository

This repo is a fork of [Ranchero-Software/NetNewsWire](https://github.com/Ranchero-Software/NetNewsWire) with custom modifications. When investigating original code implementation details, use DeepWiki (`mcp__deepwiki`) and Context7 (`mcp__context7`) to query `Ranchero-Software/NetNewsWire`.

## Build and Development Commands

### Building and Testing
- **Full build and test**: `./buildscripts/build_and_test.sh` - Builds both macOS and iOS targets and runs all tests
- **Quiet build and test**: `./buildscripts/quiet_build_and_test.sh` - Same as above with less verbose output
- **Manual Xcode builds**:
  - macOS: `xcodebuild -project NetNewsWire.xcodeproj -scheme NetNewsWire -destination "platform=macOS,arch=arm64" build`
  - iOS: `xcodebuild -project NetNewsWire.xcodeproj -scheme NetNewsWire-iOS -destination "platform=iOS Simulator,name=iPhone 17" build`

### Testing
- **All macOS tests**: `xcodebuild -project NetNewsWire.xcodeproj -scheme NetNewsWire -destination "platform=macOS,arch=arm64" test`
- **All iOS tests** (skips AccountTests): `xcodebuild -project NetNewsWire.xcodeproj -scheme NetNewsWire-iOS -destination "platform=iOS Simulator,name=iPhone 17" -skip-testing:AccountTests test`
- **Single test class**: `xcodebuild -project NetNewsWire.xcodeproj -scheme NetNewsWire -destination "platform=macOS,arch=arm64" -only-testing:NetNewsWireTests/ArticleSorterTests test`
- **Single module's tests**: `swift test` from within that module's directory (e.g., `cd Modules/RSParser && swift test`)
- Test plans: `NetNewsWire.xctestplan` (macOS, 7 test targets) and `NetNewsWire-iOS.xctestplan` (iOS)

### Linting
- `swiftlint` from project root (configuration in `.swiftlint.yml`)

### Setup
- **Unsigned debug build (recommended for this fork)**: No setup needed — pass `CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO` to xcodebuild. See `doc/开发环境搭建.md` for details.
- **Signed build**: Run `./setup.sh` or manually create `SharedXcodeSettings/DeveloperSettings.xcconfig` in parent directory (`../SharedXcodeSettings/`)

## Project Architecture

### High-Level Structure
NetNewsWire is a multi-platform RSS reader with separate targets for macOS and iOS, organized as a modular architecture with shared business logic.

### Module Dependency Layers (in /Modules)

Bottom layer (no added dependencies allowed — designed for reuse in other apps):
- **RSCore**: Core utilities, extensions, and shared infrastructure
- **RSDatabase**: SQLite database abstraction layer using FMDB
- **RSParser**: Feed parsing (RSS, Atom, JSON Feed, RSS-in-JSON). Depends on RSMarkdown.
- **RSTree**: Tree data structure utilities
- **RSWeb**: HTTP networking, downloading, caching. Depends on RSParser, RSCore.
- **RSMarkdown**: Markdown processing. External dep: Apple's swift-markdown.

Middle layer:
- **Articles**: Article and author data models (immutable structs). Depends on RSCore.
- **ArticlesDatabase**: Article storage and search (SQLite). Depends on Articles, RSCore, RSParser, RSDatabase.
- **SyncDatabase**: Cross-device synchronization state. Depends on Articles, RSCore, RSDatabase.
- **CloudKitSync**: iCloud sync implementation. Depends on RSCore.
- **FeedFinder**: Feed autodiscovery from URLs. Depends on RSWeb, RSParser, RSCore.
- **Secrets**: API key management (generated from .gyb template).
- **NewsBlur**: NewsBlur service integration. Depends on Secrets, RSWeb, RSParser, RSCore.

Top layer:
- **Account**: Main coordinator — account management (Local, Feedbin, Feedly, NewsBlur, Reader API, CloudKit). Depends on most modules above.

Swift tools version: 6.2. Platforms: macOS 15.0+, iOS 26.0+. Upcoming features enabled: `NonisolatedNonsendingByDefault`, `InferIsolatedConformances`.

### Platform-Specific Code
- **Mac/**: macOS-specific UI (AppKit), preferences, main window management
- **iOS/**: iOS-specific UI (UIKit), settings, navigation. `SceneCoordinator.swift` is the main navigation coordinator.
- **Shared/**: Cross-platform business logic, article rendering, smart feeds, OPML import/export

### Key Architectural Patterns
- **Account System**: Pluggable account delegates for different sync services (each in Account/Sources/Account/<ServiceName>/)
- **Feed Management**: Hierarchical folder/feed organization with OPML import/export
- **Article Rendering**: Template-based HTML rendering with custom CSS themes (Shared/Article Rendering/, Shared/ArticleStyles/)
- **Smart Feeds**: Virtual feeds (Today, All Unread, Starred) implemented as PseudoFeed protocol
- **Timeline/Detail**: Classic three-pane interface (sidebar, timeline, detail)
- **Account Data Storage**: `~/Library/Containers/.../NetNewsWire/Accounts/` — per-account: Settings.plist, DB.sqlite3, FeedMetadata.plist, Subscriptions.opml

### Extension Points
- Share extensions for both platforms
- Safari extension for feed subscription
- Widget support for iOS
- AppleScript support on macOS
- Intent extensions for Siri shortcuts

### Development Notes
- Uses Xcode project with Swift Package Manager for module dependencies
- Requires `xcbeautify` for formatted build output in scripts
- API keys are managed through buildscripts/updateSecrets.sh (runs during builds)
- Some features disabled in development builds due to private API keys
- Code signing configured through SharedXcodeSettings for development
- Documentation and technical notes are located in the `Technotes/` folder (especially `CodingGuidelines.md`)

## Coding Rules

### Swift Style
- Idiomatic modern Swift. All Swift classes must be marked `final`. No subclasses (except inevitable AppKit/UIKit subclasses).
- Prefer `if let x` and `guard let x` over `if let x = x` and `guard let x = x`.
- Guard statements: put `return` on a separate line.
- Don't use `...` or `…` in Logger messages. No console output (`print`/`NSLog`) in committed code.
- Don't do force unwrapping of optionals.
- Properties go at the top, then functions, then extensions for protocol conformances, then a private extension for private functions.
- Import `AppKit` rather than `Cocoa`. If you see `Cocoa`, change it to `AppKit`.
- Protocol conformance should be implemented in extensions.
- Mark things `private` as often as possible.
- Tabs for indentation (not spaces).

### Architecture Rules
- **No KVO.** Use NotificationCenter and `didSet` instead. All notifications posted on main queue.
- **Main thread by default.** Background work only for isolated tasks (parsing, database). Background tasks must call back on main queue. No locks.
- **No Core Data.** Model objects are plain structs/classes. Prefer immutable Swift structs.
- **Protocols and delegates over inheritance.** No default protocol implementations unless done carefully.
- **Stock UI elements.** Minimal custom UI. Auto layout everywhere except table/outline view cells (performance-critical). No stack views in table/outline cells.
- Use `AppDefaults` for UI parameters (sizes, colors, etc.).

### Commit Messages
Every commit message begins with a present-tense verb (e.g., "Fix typo.", "Update status.", "Draw a traditional sidebar unread count pill.").

## Things to Know

Just because unit tests pass doesn't mean a given bug is fixed. It may not have a test. It may not even be testable — it may require manual testing.
