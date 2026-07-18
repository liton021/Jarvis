import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_providers.freezed.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    @Default([]) List<AppChatMessage> messages,
    @Default(false) bool isLoading,
    @Default(false) bool isStreaming,
    String? error,
    String? currentSessionId,
    @Default('gemini') String currentProvider,
    @Default('gemini-1.5-flash') String currentModel,
  }) = _ChatState;
}

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default('gemini') String selectedProvider,
    @Default('gemini-1.5-flash') String selectedModel,
    @Default(true) bool streamingEnabled,
    @Default(true) bool markdownEnabled,
    @Default('system') String themeMode,
    @Default(false) bool showTimestamps,
    String? geminiApiKey,
    @Default(false) bool hasGeminiKey,
  }) = _SettingsState;
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState());

  void addMessage(AppChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void updateMessage(String messageId, String text, {bool? isStreaming, Map<String, dynamic>? metadata}) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(
            text: text,
            isStreaming: isStreaming ?? m.isStreaming,
            metadata: metadata ?? m.metadata,
          );
        }
        return m;
      }).toList(),
    );
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setStreaming(bool streaming) {
    state = state.copyWith(isStreaming: streaming);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void updateStreamingEnabled(bool enabled) {
    state = state.copyWith(streamingEnabled: enabled);
  }

  void updateMarkdownEnabled(bool enabled) {
    state = state.copyWith(markdownEnabled: enabled);
  }

  void updateThemeMode(String mode) {
    state = state.copyWith(themeMode: mode);
  }

  void updateShowTimestamps(bool show) {
    state = state.copyWith(showTimestamps: show);
  }

  void updateSelectedModel(String model) {
    state = state.copyWith(selectedModel: model);
  }

  void updateGeminiApiKey(String? key) {
    state = state.copyWith(
      geminiApiKey: key,
      hasGeminiKey: key != null && key.isNotEmpty,
    );
  }
}