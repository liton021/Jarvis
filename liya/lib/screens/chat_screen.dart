import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
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
  int _regeneratingMessageIndex = -1;

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

    ref.read(chatProvider.notifier).addMessage(AppChatMessage(
          id: _uuid.v4(),
          text: 'How can I help you today?',
          senderId: 'ai',
          timestamp: DateTime.now(),
          isUser: false,
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
        _showError('Please configure your API key in Settings');
        _navigateToSettings();
        return;
      }
      await provider.initialize(apiKey, model: settings.selectedModel);
    }

    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();

    final userMessage = AppChatMessage(
      id: _uuid.v4(),
      text: text,
      senderId: 'user',
      timestamp: DateTime.now(),
      isUser: true,
    );
    ref.read(chatProvider.notifier).addMessage(userMessage);

    final aiMessageId = _uuid.v4();
    final aiMessage = AppChatMessage(
      id: aiMessageId,
      text: '',
      senderId: 'ai',
      timestamp: DateTime.now(),
      isStreaming: true,
      isUser: false,
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
        metadata: {'isError': true},
      );
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _regenerateResponse(int messageIndex) async {
    final settings = ref.read(settingsProvider);
    final messages = ref.read(chatProvider).messages;
    if (messageIndex >= messages.length) return;

    final message = messages[messageIndex];
    if (message.senderId != 'user') return;

    final userMessageIndex = messageIndex;
    final aiMessageIndex = messageIndex + 1;

    if (aiMessageIndex >= messages.length || messages[aiMessageIndex].senderId != 'ai') return;

    final provider = AIProviderRegistry.get(settings.selectedProvider);
    if (provider == null) return;

    setState(() => _regeneratingMessageIndex = aiMessageIndex);

    ref.read(chatProvider.notifier).updateMessage(
      messages[aiMessageIndex].id,
      '',
      isStreaming: true,
    );

    try {
      final history = messages
          .where((m) => m.id != messages[aiMessageIndex].id)
          .take(userMessageIndex + 1)
          .toList();

      String accumulatedText = '';
      await for (final chunk in provider.sendMessageStream(message.text, history)) {
        accumulatedText += chunk;
        ref.read(chatProvider.notifier).updateMessage(
          messages[aiMessageIndex].id,
          accumulatedText,
          isStreaming: true,
        );
        _scrollToBottom();
      }

      ref.read(chatProvider.notifier).updateMessage(
        messages[aiMessageIndex].id,
        accumulatedText,
        isStreaming: false,
      );
    } catch (e) {
      ref.read(chatProvider.notifier).updateMessage(
        messages[aiMessageIndex].id,
        'Error: $e',
        isStreaming: false,
        metadata: {'isError': true},
      );
    } finally {
      setState(() => _regeneratingMessageIndex = -1);
      _scrollToBottom();
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _shareResponse(String text) async {
    await Share.share(text, subject: 'Liya Response');
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Liya'),
        actions: [
          if (chatState.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _showClearChatDialog,
              tooltip: 'Clear Chat',
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                final isUser = message.isUser;
                final isRegenerating = _regeneratingMessageIndex == index;

                return _buildMessage(message, index, theme, isRegenerating);
              },
            ),
          ),
          if (chatState.isStreaming || _isLoading || _regeneratingMessageIndex != -1)
            _buildThinkingIndicator(theme),
          _buildInputArea(theme, chatState),
        ],
      ),
    );
  }

  Widget _buildMessage(AppChatMessage message, int index, ThemeData theme, bool isRegenerating) {
    final isUser = message.isUser;
    final isError = message.metadata?['isError'] == true;
    final isStreaming = message.isStreaming || isRegenerating;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(theme, isStreaming),
          if (!isUser) const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Liya',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (isStreaming) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: theme.colorScheme.outline),
                  ),
                  child: SelectableText(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                if (!isStreaming && !isUser) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.content_copy_outlined,
                        tooltip: 'Copy',
                        onPressed: () => _copyToClipboard(message.text),
                        theme: theme,
                      ),
                      _buildActionButton(
                        icon: Icons.refresh_outlined,
                        tooltip: 'Regenerate',
                        onPressed: () => _regenerateResponse(index),
                        theme: theme,
                      ),
                      _buildActionButton(
                        icon: Icons.share_outlined,
                        tooltip: 'Share',
                        onPressed: () => _shareResponse(message.text),
                        theme: theme,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(left: isUser ? 0 : 4, right: isUser ? 4 : 0),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser) _buildUserAvatar(theme),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, bool isStreaming) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.smart_toy_outlined,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildUserAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person_outline,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.smart_toy_outlined,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _regeneratingMessageIndex != -1 ? 'Regenerating...' : 'Thinking...',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, ChatState chatState) {
    final isLoading = _isLoading || chatState.isLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                minLines: 1,
                maxLength: 4000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Message Liya...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton.filled(
                onPressed: isLoading ? null : _handleSend,
                icon: const Icon(Icons.send_rounded, size: 20),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  foregroundColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                  disabledForegroundColor: theme.colorScheme.onPrimary.withAlpha(100),
                  disabledBackgroundColor: theme.colorScheme.primary.withAlpha(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}