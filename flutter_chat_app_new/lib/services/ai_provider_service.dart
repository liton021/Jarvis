import 'dart:async';
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
}

class GeminiProviderService implements AIProviderService {
  @override
  final String providerId = 'gemini';

  @override
  final String providerName = 'Google Gemini';

  @override
  final List<String> availableModels = const [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash-exp',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
  ];

  @override
  final String defaultModel = 'gemini-1.5-flash';

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
              msg.senderId == 'user' ? Role.user : Role.model,
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
    if (availableModels.contains(model)) {
      _currentModel = model;
      if (_initialized && _apiKey != null) {
        await initialize(_apiKey!, model: model);
      }
      await SecureStorageService.saveGeminiModel(model);
    }
  }

  String? get currentModel => _currentModel;
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