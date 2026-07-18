# Gemini Chat - Flutter App

A beautiful ChatGPT-like Flutter application for chatting with Google's Gemini AI models. Features **Bring Your Own Key (BYOK)** architecture where users provide their own API keys stored securely on-device.

## Features

- 🎨 **ChatGPT-like UI** - Streaming responses, markdown rendering, code syntax highlighting
- 🔐 **Secure API Key Storage** - Keys stored in platform keystore (iOS Keychain / Android Keystore)
- 🤖 **Gemini Models** - Support for Flash, Pro, and experimental models
- 📱 **Cross Platform** - Android, iOS, Web, Desktop (Windows/macOS/Linux)
- ⚡ **Streaming Responses** - Real-time typewriter effect like ChatGPT
- 🌙 **Dark/Light Theme** - System, Light, or Dark mode
- 💾 **Local First** - No backend required, direct API communication
- 🏷️ **Open Source** - MIT License

## Architecture

```
lib/
├── main.dart                    # App entry point with Material3 theming
├── models/
│   └── chat_message.dart        # Freezed models for messages
├── providers/
│   └── chat_providers.dart      # Riverpod state management
├── screens/
│   ├── chat_screen.dart         # Main chat interface
│   └── settings_screen.dart     # API key & model configuration
├── services/
│   ├── ai_provider_service.dart # Abstract provider + Gemini implementation
│   └── secure_storage_service.dart # Platform secure storage wrapper
```

## Quick Start

### Prerequisites
- Flutter SDK 3.22+
- Dart 3.4+
- Android Studio / Xcode for mobile development
- Google AI Studio API Key (free tier available)

### Installation

```bash
# Clone and navigate
cd flutter_chat_app

# Install dependencies
flutter pub get

# Generate code (freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run
```

### API Key Setup
1. Get your API key from [Google AI Studio](https://aistudio.google.com/apikey)
2. Open app → Settings → Enter your API key
3. Start chatting!

## Building Release APK

### Option 1: Automated Script (Recommended)
```bash
cd flutter_chat_app
./build_release.sh 1.0.0
```

### Option 2: Manual Build
```bash
cd flutter_chat_app

# Clean and get dependencies
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Build APKs (split per ABI for smaller downloads)
flutter build apk --release --split-per-abi

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### Output Locations
- **APKs**: `build/app/outputs/flutter-apk/`
  - `app-arm64-v8a-release.apk` (modern 64-bit devices)
  - `app-armeabi-v7a-release.apk` (older 32-bit devices)
  - `app-x86_64-release.apk` (emulators)
- **App Bundle**: `build/app/outputs/bundle/release/app-release.aab`

## GitHub Release

### Automatic (GitHub Actions)
1. Push a version tag:
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```
2. GitHub Actions will:
   - Build APKs and App Bundle
   - Create a GitHub Release with artifacts
   - Generate release notes

### Manual Release
```bash
# Build first
./build_release.sh 1.0.0

# Create release on GitHub
gh release create v1.0.0 \
  build/app/outputs/flutter-apk/*.apk \
  build/app/outputs/bundle/release/*.aab \
  --title "Gemini Chat v1.0.0" \
  --notes "Release notes here"
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_gen_ai_chat_ui` | ChatGPT-like UI components |
| `google_generative_ai` | Official Gemini Dart SDK |
| `flutter_secure_storage` | Encrypted key storage |
| `flutter_riverpod` | State management |
| `freezed` | Immutable data classes |
| `uuid` | Unique message IDs |
| `intl` | Date formatting |
| `url_launcher` | Open AI Studio link |

## Security

- **API keys never leave device** - Stored in hardware-backed keystore
- **No backend/server** - Direct client-to-Gemini communication
- **App Check ready** - Can add Firebase App Check for production
- **Biometric optional** - Can add biometric unlock for keys

## Configuration

### Android (build.gradle.kts)
- Min SDK: 24 (Android 7.0)
- Target SDK: 34
- Kotlin 1.9.24
- Java 17

### iOS (Podfile)
- Min iOS: 13.0
- Uses Firebase pods for App Check (optional)

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Run tests: `flutter test`
5. Submit PR

## Support

- Issues: GitHub Issues
- API Key Help: [Google AI Studio](https://aistudio.google.com/apikey)
- Flutter Docs: [flutter.dev](https://flutter.dev)