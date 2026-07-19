import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
          text: '👋 Hello! I\'m **Liya**, your cooperative digital assistant. How can I help you today?\n\n'
              '💡 **Tips:**\n'
              '• Type naturally - I understand context\n'
              '• Ask me to write code, explain concepts, or brainstorm\n'
              '• Streaming responses work like ChatGPT\n\n'
              'What would you like to talk about?',
          senderId: 'ai',
          timestamp: DateTime.now(),
          isUser: false,
        ));

    setState(() => _isInitialized = true);
  }

  Future<void> _changeModelQuick(String model) async {
    final settings = ref.read(settingsProvider);
    if (settings.selectedModel == model) return;

    final provider = AIProviderRegistry.get(settings.selectedProvider);
    if (provider is GeminiProviderService) {
      final key = await SecureStorageService.getGeminiApiKey();
      if (key != null) {
        await provider.initialize(key, model: model);
      }
    }

    ref.read(settingsProvider.notifier).state = settings.copyWith(
      selectedModel: model,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to $model'), duration: const Duration(seconds: 2)),
      );
    }
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

    final newAiMessageId = _uuid.v4();

    ref.read(chatProvider.notifier).updateMessage(
      messages[aiMessageIndex].id,
      '',
      isStreaming: true,
    );

    try {
      final history = messages
          .where((m) => m.id != messages[aiMessageIndex].id && m.id != newAiMessageId)
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
        const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)),
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
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                const Text('Liya', style: TextStyle(fontSize: 16)),
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
          // Quick Model Picker
          PopupMenuButton<String>(
            tooltip: 'Switch Model',
            icon: const Icon(Icons.swap_horiz_rounded),
            onSelected: (model) => _changeModelQuick(model),
            itemBuilder: (context) {
              final provider = AIProviderRegistry.get('gemini');
              if (provider == null) return [];
              final models = provider.availableModels;
              return models.map((model) {
                final isSelected = settings.selectedModel == model;
                return PopupMenuItem<String>(
                  value: model,
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(Icons.check, size: 18, color: theme.colorScheme.primary)
                      else
                        const SizedBox(width: 24),
                      const SizedBox(width: 8),
                      Text(model),
                    ],
                  ),
                );
              }).toList();
            },
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final message = chatState.messages[index];
                final isUser = message.isUser;
                final isRegenerating = _regeneratingMessageIndex == index;

                if (isUser) {
                  return _buildUserMessage(message, theme, settings);
                } else {
                  return _buildAiMessage(message, index, theme, isRegenerating, settings);
                }
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

  Widget _buildUserMessage(AppChatMessage message, ThemeData theme, SettingsState settings) {
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: const Radius.circular(4),
                  bottomLeft: const Radius.circular(18),
                ),
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            if (settings.showTimestamps)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 8),
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

  Widget _buildAiMessage(
    AppChatMessage message,
    int index,
    ThemeData theme,
    bool isRegenerating,
    SettingsState settings,
  ) {
    final timeStr = DateFormat('HH:mm').format(message.timestamp);
    final isError = message.metadata?['isError'] == true;
    final isStreaming = message.isStreaming || isRegenerating;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Liya',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (isStreaming) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const Spacer(),
              if (!isStreaming) ...[
                _buildActionButton(
                  icon: Icons.content_copy,
                  tooltip: 'Copy',
                  onPressed: () => _copyToClipboard(message.text),
                ),
                _buildActionButton(
                  icon: Icons.refresh,
                  tooltip: 'Regenerate',
                  onPressed: () => _regenerateResponse(index),
                ),
                _buildActionButton(
                  icon: Icons.share,
                  tooltip: 'Share',
                  onPressed: () => _shareResponse(message.text),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isError
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isError
                    ? theme.colorScheme.error
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: MarkdownBody(
              data: message.text,
              selectable: true,
              styleSheet: _buildMarkdownStyleSheet(theme, isError),
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href));
                }
              },
              extensionSet: md.ExtensionSet.gitHubFlavored,
            ),
          ),
          if (settings.showTimestamps)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _regeneratingMessageIndex != -1 ? 'Regenerating...' : 'Liya is thinking...',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, ChatState chatState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
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
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: 'Message Liya...',
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
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(ThemeData theme, bool isError) {
    final baseColor = isError
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurface;

    return MarkdownStyleSheet(
      p: TextStyle(fontSize: 15, color: baseColor, height: 1.6),
      h1: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: baseColor),
      h2: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: baseColor),
      h3: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: baseColor),
      code: TextStyle(
        fontSize: 14,
        fontFamily: 'monospace',
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainer,
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      blockquote: TextStyle(
        fontSize: 15,
        color: baseColor.withAlpha(180),
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),
      blockquotePadding: const EdgeInsets.all(12),
      a: TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      listBullet: TextStyle(fontSize: 15, color: baseColor),
      listIndent: 24,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
    );
  }
}