# Liya — Cooperative Digital Assistant

A privacy-first, BYOK (Bring Your Own Key) AI assistant powered by Google Gemini.

## Project Structure

- `liya/` — Main Flutter application
- `.github/workflows/release.yml` — GitHub Actions for automated releases

## Quick Start

```bash
cd liya
flutter pub get
flutter run
```

## Building Releases

### Automated (GitHub Actions)
Push a version tag:
```bash
git tag -a v1.0.2 -m "Release v1.0.2"
git push origin v1.0.2
```

### Manual
```bash
cd liya
./build_release.sh 1.0.2
```

## Features

- 🤖 **Liya** — Your cooperative digital assistant
- 🔐 **Secure BYOK** — API keys stored in platform keystore (Keychain/Keystore)
- ⚡ **Streaming responses** — ChatGPT-like typewriter effect
- 📝 **Markdown & code rendering** — Syntax highlighting, copy buttons
- 🌙 **Theme support** — System / Light / Dark mode
- 🏷️ **Custom models** — Add any Gemini model ID in Settings
- 📱 **Cross-platform** — Android, iOS, Web, Desktop