import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../providers/chat_providers.dart';
import '../services/ai_provider_service.dart';
import '../services/secure_storage_service.dart';
import '../models/chat_message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

    // Add welcome message if empty
    ref.read(chatProvider.notifier).addMessage(AppChatMessage(
          id: _uuid.v4(),
          text: '👋 Hello! I\'m Gemini, your AI assistant. How can I help you today?\n\n'
              '💡 **Tips:**\n'
              '• Type naturally - I understand context\n'
              '• Ask me to write code, explain concepts, or brainstorm\n'
              '• Streaming responses work like ChatGPT\n\n'
              'What would you like to talk about?',
          senderId: 'ai',
          timestamp: DateTime.now(),
        ));

    setState(() => _isInitialized = true);
  }

  Future<void> _handleSend() async {
    final settings = ref.read(settingsProvider);
    final provider = AIProviderRegistry.get(settings.selectedProvider);

    if (provider == null) {
      _showError('No AI provider selected');
      return;
    }

    if (provider is GeminiProviderService && !provider.isInitialized) {
      final apiKey = await SecureStorageService.getGeminiApiKey();
      if (apiKey == null) {
        _showError('Please configure your Gemini API key in Settings');
        _navigateToSettings();
        return;
      }
      await provider.initialize(apiKey, model: settings.selectedModel);
    }

    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();

    // Add user message
    final userMessage = AppChatMessage(
      id: _uuid.v4(),
      text: text,
      senderId: 'user',
      timestamp: DateTime.now(),
    );
    ref.read(chatProvider.notifier).addMessage(userMessage);

    // Add AI placeholder
    final aiMessageId = _uuid.v4();
    final aiMessage = AppChatMessage(
      id: aiMessageId,
      text: '',
      senderId: 'ai',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    ref.read(chatProvider.notifier).addMessage(aiMessage);

    setState(() => _isLoading = true);
    _scrollToBottom();

    try {
      final history = ref.read(chatProvider).messages
          .where((m) => m.id != aiMessageId)
          .toList();

      if (settings.streamingEnabled) {
        String accumulatedText = '';
        await for (final chunk in provider.sendMessageStream(text, history)) {
          accumulatedText += chunk;
          ref.read(chatProvider.notifier).updateMessage(
            aiMessageId,
            accumulatedText,
            isStreaming: true,
          );
          _scrollToBottom();
        }

        // Mark as complete
        ref.read(chatProvider.notifier).updateMessage(
          aiMessageId,
          accumulatedText,
          isStreaming: false,
        );
      } else {
        final response = await provider.sendMessage(text, history);
        ref.read(chatProvider.notifier).updateMessage(
          aiMessageId,
          response,
          isStreaming: false,
        );
      }
    } catch (e) {
      ref.read(chatProvider.notifier).updateMessage(
        aiMessageId,
        'Error: $e',
        isStreaming: false,
      );
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
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
              ref.read(chatProvider.notifier).clearMessages();
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
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final settings = ref.watch(settingsProvider);
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
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                final isUser = message.senderId == 'user';
                return _buildMessageBubble(message, isUser, settings);
              },
            ),
          ),
          if (chatState.isStreaming || _isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gemini is thinking...',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          _buildInputArea(theme, chatState),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AppChatMessage message, bool isUser, SettingsState settings) {
    final theme = Theme.of(context);
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Gemini',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (message.isStreaming) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                ),
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (settings.showTimestamps)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                child: Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, ChatState chatState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: 'Message Gemini...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: (_isLoading || chatState.isLoading) ? null : _handleSend,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}