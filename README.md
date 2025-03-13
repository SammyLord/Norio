# Norio Browser

Norio is a WebKit-based browser for Apple platforms (macOS, iOS, and iPadOS) that supports Chrome and Firefox extensions.

## Features

- WebKit rendering engine for fast and efficient browsing
- Support for Chrome extensions
- Support for Firefox extensions
- Seamless synchronization across Apple devices
- Modern, clean user interface
- Privacy-focused features

## Requirements

- Xcode 15.0+
- Swift 5.9+
- macOS 14.0+ (for development)
- macOS 13.0+, iOS 17.0+, iPadOS 17.0+ (for deployment)

## Architecture

The browser is built on the following components:

1. **WebKit** - Apple's web rendering engine
2. **Browser Engine** - Custom implementation for tab management, history, bookmarks
3. **Extension System** - Compatibility layers for Chrome and Firefox extensions
4. **User Interface** - Native SwiftUI interface for each platform

## Getting Started

1. Clone the repository
2. Open `Norio.xcodeproj` in Xcode
3. Select the appropriate target (macOS, iOS, or iPadOS)
4. Build and run

## License

This project is licensed under the MIT License - see the LICENSE file for details. 