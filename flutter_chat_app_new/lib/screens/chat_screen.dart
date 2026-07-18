import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../providers/chat_providers.dart';
import '../services/ai_provider_service.dart';
import '../services/secure_storage_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messagesController = ChatMessagesController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  late final ChatUser _currentUser;
  late final ChatUser _aiUser;

  bool _isInitialized = false;
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    _currentUser = ChatUser(id: 'user', firstName: 'You');
    _aiUser = ChatUser(id: 'ai', firstName: 'Gemini');
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final settings = ref.read(settingsProvider);
    final provider = AIProviderRegistry.get(settings.selectedProvider);

    if (provider != null) {
      if (provider is GeminiProviderService) {
        final apiKey = await SecureStorageService.getGeminiApiKey();
        if (apiKey != null) {
          await provider.initialize(apiKey, model: settings.selectedModel);
        }
      }
    }

    // Add welcome message
    _addWelcomeMessage();
    setState(() => _isInitialized = true);
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: _uuid.v4(),
      user: _aiUser,
      text: '👋 Hello! I\'m Gemini, your AI assistant. How can I help you today?\n\n'
          '💡 **Tips:**\n'
          '• Type naturally - I understand context\n'
          '• Ask me to write code, explain concepts, or brainstorm\n'
          '• I support streaming responses for a ChatGPT-like experience\n\n'
          'What would you like to talk about?',
      createdAt: DateTime.now(),
      metadata: {'isWelcome': true},
    );
    _messagesController.addMessage(welcomeMessage);
  }

  Future<void> _handleSend(String text) async {
    if (text.trim().isEmpty) return;

    final settings = ref.read(settingsProvider);
    final provider = AIProviderRegistry.get(settings.selectedProvider);

    if (provider == null) {
      _showError('No AI provider selected');
      return;
    }

    // Check if provider is initialized
    if (provider is GeminiProviderService && !provider.isInitialized) {
      final apiKey = await SecureStorageService.getGeminiApiKey();
      if (apiKey == null) {
        _showError('Please configure your Gemini API key in Settings');
        _navigateToSettings();
        return;
      }
      await provider.initialize(apiKey, model: settings.selectedModel);
    }

    // Add user message
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      user: _currentUser,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    _messagesController.addMessage(userMessage);

    // Show typing indicator
    if (settings.streamingEnabled && provider.supportsStreaming) {
      await _handleStreamingResponse(text.trim(), provider, settings);
    } else {
      await _handleSingleResponse(text.trim(), provider);
    }
  }

  Future<void> _handleStreamingResponse(
    String text,
    AIProviderService provider,
    SettingsState settings,
  ) async {
    final aiMessageId = _uuid.v4();
    String accumulatedText = '';

    // Add placeholder message for streaming
    final streamingMessage = ChatMessage(
      id: aiMessageId,
      user: _aiUser,
      text: '',
      createdAt: DateTime.now(),
      status: MessageStatus.inProgress,
    );
    _messagesController.addMessage(streamingMessage);

    try {
      final history = _messagesController.messages
          .where((m) => m.id != aiMessageId)
          .map((m) => AppChatMessage(
                id: m.id,
                text: m.parts.firstOrNull?.text ?? '',
                senderId: m.user.id,
                timestamp: m.createdAt,
                isStreaming: m.status == MessageStatus.inProgress,
              ))
          .toList();

      await for (final chunk in provider.sendMessageStream(text, history)) {
        accumulatedText += chunk;
        _messagesController.updateMessage(
          aiMessageId,
          accumulatedText,
          status: MessageStatus.inProgress,
        );
      }

      // Mark as complete
      _messagesController.updateMessage(
        aiMessageId,
        accumulatedText,
        status: MessageStatus.success,
      );
    } catch (e) {
      _messagesController.updateMessage(
        aiMessageId,
        'Error: $e',
        status: MessageStatus.error,
      );
    }
  }

  Future<void> _handleSingleResponse(String text, AIProviderService provider) async {
    try {
      final history = _messagesController.messages
          .map((m) => AppChatMessage(
                id: m.id,
                text: m.parts.firstOrNull?.text ?? '',
                senderId: m.user.id,
                timestamp: m.createdAt,
              ))
          .toList();

      final response = await provider.sendMessage(text, history);

      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        user: _aiUser,
        text: response,
        createdAt: DateTime.now(),
        status: MessageStatus.success,
      );
      _messagesController.addMessage(aiMessage);
    } catch (e) {
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        user: _aiUser,
        text: 'Error: $e',
        createdAt: DateTime.now(),
        status: MessageStatus.error,
      );
      _messagesController.addMessage(errorMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _messagesController.clear();
              _addWelcomeMessage();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final chatState = ref.watch(chatProvider);
    final theme = Theme.of(context);

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gemini Chat', style: TextStyle(fontSize: 16)),
                Text(
                  settings.selectedModel,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (chatState.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _showClearChatDialog,
              tooltip: 'Clear Chat',
            ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: AIChat(
        currentUser: _currentUser,
        messages: _messagesController.messages,
        controller: _messagesController,
        onSend: (text) => _handleSend(text),
        config: AIChatConfig(
          showAvatar: true,
          showTimestamp: settings.showTimestamps,
          enableMarkdown: settings.markdownEnabled,
          inputConfig: AIChatInputConfig(
            placeholder: 'Message Gemini...',
            maxLines: 5,
            showAttachmentButton: false,
            sendButtonConfig: SendButtonConfig(
              enabled: !chatState.isLoading && !chatState.isStreaming,
              loading: chatState.isLoading || chatState.isStreaming,
            ),
          ),
          typingIndicatorConfig: TypingIndicatorConfig(
            enabled: chatState.isStreaming,
            text: 'Gemini is thinking...',
            style: TypingIndicatorStyle(
              bubbleColor: theme.colorScheme.surfaceContainerHighest,
              dotColor: theme.colorScheme.primary,
            ),
          ),
          messageConfig: MessageConfig(
            userBubbleConfig: BubbleConfig(
              color: theme.colorScheme.primary,
              textStyle: TextStyle(color: theme.colorScheme.onPrimary),
              radius: 18,
            ),
            aiBubbleConfig: BubbleConfig(
              color: theme.colorScheme.surfaceContainerHighest,
              textStyle: TextStyle(color: theme.colorScheme.onSurface),
              radius: 18,
            ),
            errorConfig: ErrorConfig(
              textStyle: TextStyle(color: theme.colorScheme.error),
              retryText: 'Retry',
            ),
          ),
        ),
        theme: AIChatTheme(
          light: AIChatThemeData(
            backgroundColor: theme.colorScheme.surface,
            inputBackgroundColor: theme.colorScheme.surfaceContainer,
            inputBorderColor: theme.colorScheme.outlineVariant,
            primaryColor: theme.colorScheme.primary,
            onPrimaryColor: theme.colorScheme.onPrimary,
          ),
          dark: AIChatThemeData(
            backgroundColor: theme.colorScheme.surface,
            inputBackgroundColor: theme.colorScheme.surfaceContainer,
            inputBorderColor: theme.colorScheme.outlineVariant,
            primaryColor: theme.colorScheme.primary,
            onPrimaryColor: theme.colorScheme.onPrimary,
          ),
        ),
        welcomeMessage: _showWelcome
            ? WelcomeMessage(
                title: 'Welcome to Gemini Chat',
                description: 'Start a conversation with Google\'s Gemini AI. Your API key is stored securely on your device.',
                actionButtons: [],
              )
            : null,
      ),
    );
  }
}