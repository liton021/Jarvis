import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/chat_providers.dart';
import '../services/ai_provider_service.dart';
import '../services/secure_storage_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureApiKey = true;
  bool _isTestingKey = false;
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadApiKey();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    }
  }

  Future<void> _loadApiKey() async {
    final key = await SecureStorageService.getGeminiApiKey();
    if (mounted) {
      _apiKeyController.text = key ?? '';
    }
  }

  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;

    final key = _apiKeyController.text.trim();
    await SecureStorageService.saveGeminiApiKey(key);

    // Reinitialize the provider
    final provider = AIProviderRegistry.get('gemini');
    if (provider is GeminiProviderService) {
      final model = await SecureStorageService.getGeminiModel();
      await provider.initialize(key, model: model);
    }

    ref.read(settingsProvider.notifier).state = ref.read(settingsProvider).copyWith(
      geminiApiKey: key,
      hasGeminiKey: true,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved successfully')),
      );
    }
  }

  Future<void> _deleteApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API Key'),
        content: const Text('Are you sure you want to delete your Gemini API key?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SecureStorageService.deleteGeminiApiKey();
      _apiKeyController.clear();

      // Dispose the provider
      final provider = AIProviderRegistry.get('gemini');
      if (provider is GeminiProviderService) {
        await provider.dispose();
      }

      ref.read(settingsProvider.notifier).state = ref.read(settingsProvider).copyWith(
        geminiApiKey: null,
        hasGeminiKey: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key deleted')),
        );
      }
    }
  }

  Future<void> _testApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _isTestingKey = true);

    try {
      final provider = GeminiProviderService();
      await provider.initialize(key);
      await provider.sendMessage('Hello', []);
      await provider.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key is valid!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid API key: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTestingKey = false);
    }
  }

  Future<void> _changeModel(String model) async {
    await SecureStorageService.saveGeminiModel(model);

    final provider = AIProviderRegistry.get('gemini');
    if (provider is GeminiProviderService) {
      final key = await SecureStorageService.getGeminiApiKey();
      if (key != null) {
        await provider.initialize(key, model: model);
      }
    }

    ref.read(settingsProvider.notifier).state = ref.read(settingsProvider).copyWith(
      selectedModel: model,
    );
  }

  Future<void> _openAiStudio() async {
    const url = 'https://aistudio.google.com/apikey';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final provider = AIProviderRegistry.get('gemini')!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'AI Provider',
            [
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(provider.providerName),
                  subtitle: Text('Google Gemini AI'),
                  trailing: Chip(
                    label: const Text('Active'),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openAiStudio,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Get API Key from Google AI Studio'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Model',
            [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Model', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.availableModels.map((model) {
                          final isSelected = settings.selectedModel == model;
                          return ChoiceChip(
                            label: Text(model),
                            selected: isSelected,
                            onSelected: (_) => _changeModel(model),
                            selectedColor: Theme.of(context).colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'API Key',
            [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.vpn_key, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Text('Gemini API Key', style: Theme.of(context).textTheme.titleMedium),
                            const Spacer(),
                            if (settings.hasGeminiKey)
                              Chip(
                                label: const Text('Configured'),
                                backgroundColor: Colors.green.withAlpha(26), // 0.1 opacity
                                labelStyle: const TextStyle(color: Colors.green),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your API key is stored securely on your device using platform keystore (Keychain/Keystore).',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _apiKeyController,
                          obscureText: _obscureApiKey,
                          decoration: InputDecoration(
                            labelText: 'API Key',
                            hintText: 'Enter your API key (starts with AIza...)',
                            prefixIcon: const Icon(Icons.key),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(_obscureApiKey ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                                ),
                                if (_apiKeyController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => _apiKeyController.clear(),
                                  ),
                              ],
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an API key';
                            }
                            if (!value.trim().startsWith('AIza')) {
                              return 'Gemini API keys typically start with "AIza"';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _saveApiKey,
                                icon: const Icon(Icons.save),
                                label: const Text('Save Key'),
                              ),
                            ),
                            if (settings.hasGeminiKey) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _deleteApiKey,
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _isTestingKey ? null : _testApiKey,
                          icon: _isTestingKey
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.science),
                          label: Text(_isTestingKey ? 'Testing...' : 'Test API Key'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Chat Features',
            [
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Streaming Responses'),
                      subtitle: const Text('Show responses word-by-word as they arrive (ChatGPT style)'),
                      value: settings.streamingEnabled,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).state = settings.copyWith(
                          streamingEnabled: value,
                        );
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Markdown Rendering'),
                      subtitle: const Text('Render code blocks, tables, and formatting'),
                      value: settings.markdownEnabled,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).state = settings.copyWith(
                          markdownEnabled: value,
                        );
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Show Timestamps'),
                      subtitle: const Text('Display time for each message'),
                      value: settings.showTimestamps,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).state = settings.copyWith(
                          showTimestamps: value,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Appearance',
            [
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Theme'),
                      subtitle: Text(settings.themeMode),
                      trailing: DropdownButton<String>(
                        value: settings.themeMode,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'system', child: Text('System')),
                          DropdownMenuItem(value: 'light', child: Text('Light')),
                          DropdownMenuItem(value: 'dark', child: Text('Dark')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(settingsProvider.notifier).state = settings.copyWith(
                              themeMode: value,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'About',
            [
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Privacy'),
                      subtitle: const Text('Your API keys never leave your device'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Security'),
                      subtitle: const Text('Keys stored in platform secure storage (Keychain/Keystore)'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Open Source'),
                      subtitle: const Text('Built with Flutter, Riverpod, and Google Generative AI'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Version'),
                      subtitle: Text('$_appVersion ($_buildNumber)'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}