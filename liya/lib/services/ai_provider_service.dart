import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import '../services/secure_storage_service.dart';

abstract class AIProviderService {
  String get providerId;
  String get providerName;
  List<String> get availableModels;
  String get defaultModel;
  bool get supportsStreaming;
  bool get supportsMultimodal;
  bool get isInitialized;

  Future<void> initialize(String apiKey, {String? model});
  Stream<String> sendMessageStream(String message, List<AppChatMessage> history);
  Future<String> sendMessage(String message, List<AppChatMessage> history);
  Future<void> dispose();
  Future<void> updateModel(String model);
  Future<List<String>> fetchAvailableModels(String apiKey);
}

class GeminiProviderService implements AIProviderService {
  @override
  final String providerId = 'gemini';

  @override
  final String providerName = 'Google Gemini';

  List<String> _availableModels = [
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.0-flash-exp',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
  ];

  @override
  List<String> get availableModels => _availableModels;

  @override
  final String defaultModel = 'gemini-3.1-flash-lite';

  @override
  final bool supportsStreaming = true;

  @override
  final bool supportsMultimodal = true;

  GenerativeModel? _model;
  String? _currentModel;
  String? _apiKey;
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize(String apiKey, {String? model}) async {
    // Load custom models on first initialization
    if (_availableModels.length <= 5) { // Only defaults
      final customModels = await SecureStorageService.getCustomGeminiModels();
      _availableModels = customModels;
    }
    
    _apiKey = apiKey;
    _currentModel = model ?? defaultModel;

    _model = GenerativeModel(
      model: _currentModel!,
      apiKey: _apiKey!,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
    _initialized = true;
  }

  @override
  Stream<String> sendMessageStream(String message, List<AppChatMessage> history) async* {
    if (!_initialized || _model == null) {
      throw StateError('Gemini provider not initialized. Call initialize() first.');
    }

    try {
      final chat = _model!.startChat(
        history: _buildHistory(history),
      );

      final responseStream = chat.sendMessageStream(Content.text(message));

      await for (final chunk in responseStream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<String> sendMessage(String message, List<AppChatMessage> history) async {
    if (!_initialized || _model == null) {
      throw StateError('Gemini provider not initialized. Call initialize() first.');
    }

    try {
      final chat = _model!.startChat(
        history: _buildHistory(history),
      );

      final response = await chat.sendMessage(Content.text(message));
      return response.text ?? '';
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  List<Content> _buildHistory(List<AppChatMessage> history) {
    return history
        .where((msg) => msg.senderId != 'system')
        .map((msg) => Content(
              msg.senderId == 'user' ? 'user' : 'model',
              [TextPart(msg.text)],
            ))
        .toList();
  }

  @override
  Future<void> dispose() async {
    _model = null;
    _initialized = false;
  }

  @override
  Future<void> updateModel(String model) async {
    if (_availableModels.contains(model)) {
      _currentModel = model;
      if (_initialized && _apiKey != null) {
        await initialize(_apiKey!, model: model);
      }
      await SecureStorageService.saveGeminiModel(model);
    }
  }

  Future<void> addCustomModel(String model) async {
    final trimmed = model.trim();
    if (trimmed.isNotEmpty && !_availableModels.contains(trimmed)) {
      _availableModels.add(trimmed);
      await SecureStorageService.saveCustomGeminiModels(_availableModels);
    }
  }

  Future<void> removeCustomModel(String model) async {
    _availableModels.remove(model);
    await SecureStorageService.saveCustomGeminiModels(_availableModels);
  }

  String? get currentModel => _currentModel;
  
  Future<List<String>> fetchAvailableModels(String apiKey) async {
    try {
      // Use the REST API to list models
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey')
      );
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);
      
      final models = <String>[];
      if (data['models'] != null) {
        for (final model in data['models']) {
          final name = model['name'] as String?;
          if (name != null && (name.contains('gemini') || name.contains('embedding'))) {
            // Extract model ID from full name (e.g., "models/gemini-1.5-flash" -> "gemini-1.5-flash")
            final modelId = name.split('/').last;
            if (!modelId.contains('embedding')) { // Skip embedding models
              models.add(modelId);
            }
          }
        }
      }
      
      // Sort: flash-lite first, then flash, then pro, then experimental, then older
      models.sort((a, b) {
        int priority(String m) {
          if (m.contains('flash-lite')) return 0;
          if (m.contains('flash')) return 1;
          if (m.contains('pro')) return 2;
          if (m.contains('exp')) return 3;
          return 4;
        }
        return priority(a).compareTo(priority(b));
      });
      
      return models;
    } catch (e) {
      // Return defaults on error
      return [
        'gemini-2.5-flash-lite',
        'gemini-2.5-flash',
        'gemini-2.5-pro',
        'gemini-2.0-flash-exp',
        'gemini-1.5-flash',
        'gemini-1.5-pro',
      ];
    }
  }
}

class AIProviderRegistry {
  static final Map<String, AIProviderService> _providers = {};

  static void register(AIProviderService provider) {
    _providers[provider.providerId] = provider;
  }

  static AIProviderService? get(String providerId) {
    return _providers[providerId];
  }

  static List<AIProviderService> get all => _providers.values.toList();

  static AIProviderService? get defaultProvider => _providers['gemini'];

  static void initializeDefaults() {
    register(GeminiProviderService());
  }
}