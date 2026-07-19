# Liya - Cooperative Digital Assistant

## Project Overview

**Liya** is a Flutter-based cooperative digital assistant application with BYOK (Bring Your Own Key) support for AI providers. Currently supports Google Gemini with a clean, minimalist black-and-white UI inspired by ChatGPT, Gemini, and Grok apps.

## Vision & Goals

### What We Are Building
- A privacy-first AI chat application where users bring their own API keys
- Clean, distraction-free chat interface (black/white theme only)
- Multi-provider support starting with Google Gemini
- Secure local storage of API keys using platform keystore (Keychain/Keystore)
- Streaming responses with markdown rendering
- Cross-platform: Android, iOS, Web, Desktop

### Target Experience
- **ChatGPT-like simplicity**: Single chat view, minimal chrome
- **Gemini-like model flexibility**: Easy model switching, custom model support
- **Grok-like personality**: Direct, helpful, no unnecessary friction
- **Privacy by default**: Keys never leave device, no telemetry

## Current Stage

### Completed (v1.0.5)
- ✅ Core chat interface with streaming responses
- ✅ Gemini provider integration (google_generative_ai)
- ✅ Secure storage for API keys (flutter_secure_storage)
- ✅ Model selection (default + custom/fetched models)
- ✅ Settings screen (API key, models, theme, chat features)
- ✅ Black/white theme system (light/dark/system)
- ✅ Markdown rendering with code blocks
- ✅ Message actions (copy, regenerate, share)
- ✅ Riverpod state management

### In Progress
- 🔄 Polish & bug fixes
- 🔄 Release APK generation

### Planned
- 📋 Multi-provider support (OpenAI, Anthropic, local models)
- 📋 Conversation history/sessions
- 📋 File upload & multimodal support
- 📋 System prompts & personas
- 📋 Export/import conversations
- 📋 Widget/quick actions

## Architecture

```
lib/
├── main.dart                    # App entry, theming, routing
├── models/
│   └── chat_message.dart        # Freezed message model
├── providers/
│   └── chat_providers.dart      # Riverpod providers (chat + settings)
├── screens/
│   ├── chat_screen.dart         # Main chat UI
│   └── settings_screen.dart     # Settings UI
└── services/
    ├── ai_provider_service.dart # Provider abstraction + Gemini impl
    └── secure_storage_service.dart # Platform keystore wrapper
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | Flutter 3.x, Material 3 |
| State | Riverpod (flutter_riverpod, riverpod_annotation) |
| AI | google_generative_ai |
| Storage | flutter_secure_storage (Keychain/Keystore) |
| Markdown | flutter_markdown |
| Code Gen | freezed, json_serializable, riverpod_generator |

## Development Rules

### 1. GitHub Sync Policy
**After EVERY edit, feature addition, or bug fix:**
- Stage all changes (`git add .`)
- Commit with descriptive message
- Push to origin (`git push`)
- Verify sync on GitHub

### 2. Release Process
**After completing a milestone/feature set:**
- Build release APK: `flutter build apk --release`
- Create GitHub Release with:
  - Tag: `v{version}` (e.g., `v1.0.6`)
  - Title: `Liya v{version}`
  - Notes: Changelog
  - Attach: `build/app/outputs/flutter-apk/app-release.apk`

### 3. Version Numbering (Semantic Versioning)

| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| **Bug fix** | Patch: `1.0.x` → `1.0.{x+1}` | `1.0.5` → `1.0.6` |
| **Minor feature** | Minor: `1.x.0` → `1.{x+1}.0` | `1.0.5` → `1.1.0` |
| **Major breaking** | Major: `x.0.0` → `{x+1}.0.0` | `1.0.5` → `2.0.0` |

**Decision Authority**: AI determines change type based on:
- **Patch**: Typos, crash fixes, UI tweaks, config changes
- **Minor**: New features, new models, new settings, non-breaking API additions
- **Major**: Breaking API changes, architecture rewrites, data format changes

### 4. Version Files to Update
On every version bump, update:
- `pubspec.yaml`: `version: {major}.{minor}.{patch}+{build}`
- `android/app/build.gradle`: `versionCode`, `versionName`
- `CHANGELOG.md`: Add entry under `## [v{version}] - {date}`

### 5. Code Quality Standards
- Run `flutter analyze` before commit (must pass)
- Run `flutter test` before release
- Format with `dart format .`
- No unused imports, no deprecated APIs

### 6. Commit Message Format
```
{type}: {short description}

{longer description if needed}

Version: {new_version}
```
Types: `feat`, `fix`, `refactor`, `style`, `docs`, `chore`, `release`

### 7. Branch Strategy
- `main`: Production-ready, tagged releases only
- Feature branches: `feat/{name}`, `fix/{name}`
- PR required for merging to main

## Current Version
**v1.0.5+1** (as of 2026-07-19)

## Build Commands
```bash
# Debug
flutter run

# Release APK
flutter build apk --release

# Release App Bundle (Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Environment Setup
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Security Notes
- API keys stored ONLY in platform secure enclave
- No keys in SharedPreferences, no logging, no cloud sync
- `flutter_secure_storage` uses:
  - Android: EncryptedSharedPreferences + Keystore
  - iOS: Keychain (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)