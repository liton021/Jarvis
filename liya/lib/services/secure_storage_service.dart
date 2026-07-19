import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _geminiApiKey = 'gemini_api_key';
  static const String _geminiModel = 'gemini_model';
  static const String _selectedProvider = 'selected_provider';
  static const String _streamingEnabled = 'streaming_enabled';
  static const String _markdownEnabled = 'markdown_enabled';
  static const String _themeMode = 'theme_mode';
  static const String _showTimestamps = 'show_timestamps';
  static const String _customGeminiModels = 'custom_gemini_models';

  static Future<void> saveGeminiApiKey(String apiKey) async {
    await _storage.write(key: _geminiApiKey, value: apiKey);
  }

  static Future<String?> getGeminiApiKey() async {
    return await _storage.read(key: _geminiApiKey);
  }

  static Future<void> deleteGeminiApiKey() async {
    await _storage.delete(key: _geminiApiKey);
  }

  static Future<void> saveGeminiModel(String model) async {
    await _storage.write(key: _geminiModel, value: model);
  }

  static Future<String> getGeminiModel() async {
    return await _storage.read(key: _geminiModel) ?? 'gemini-1.5-flash';
  }

  static Future<void> saveSelectedProvider(String providerId) async {
    await _storage.write(key: _selectedProvider, value: providerId);
  }

  static Future<String> getSelectedProvider() async {
    return await _storage.read(key: _selectedProvider) ?? 'gemini';
  }

  static Future<void> saveStreamingEnabled(bool enabled) async {
    await _storage.write(key: _streamingEnabled, value: enabled.toString());
  }

  static Future<bool> getStreamingEnabled() async {
    final value = await _storage.read(key: _streamingEnabled);
    return value == 'true';
  }

  static Future<void> saveMarkdownEnabled(bool enabled) async {
    await _storage.write(key: _markdownEnabled, value: enabled.toString());
  }

  static Future<bool> getMarkdownEnabled() async {
    final value = await _storage.read(key: _markdownEnabled);
    return value != 'false'; // default true
  }

  static Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: _themeMode, value: mode);
  }

  static Future<String> getThemeMode() async {
    return await _storage.read(key: _themeMode) ?? 'system';
  }

  static Future<void> saveShowTimestamps(bool show) async {
    await _storage.write(key: _showTimestamps, value: show.toString());
  }

  static Future<bool> getShowTimestamps() async {
    final value = await _storage.read(key: _showTimestamps);
    return value == 'true';
  }

  static Future<bool> hasGeminiApiKey() async {
    final key = await _storage.read(key: _geminiApiKey);
    return key != null && key.isNotEmpty;
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<List<String>> getCustomGeminiModels() async {
    final json = await _storage.read(key: _customGeminiModels);
    if (json == null || json.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomGeminiModels(List<String> models) async {
    await _storage.write(key: _customGeminiModels, value: jsonEncode(models));
  }
}