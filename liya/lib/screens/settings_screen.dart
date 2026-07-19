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
  final _customModelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureApiKey = true;
  bool _isTestingKey = false;
  bool _isAddingModel = false;
  bool _isFetchingModels = false;
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
        const SnackBar(content: Text('API key saved')),
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
          SnackBar(
            content: const Text('API key is valid'),
            backgroundColor: Colors.green,
          ),
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

  Future<void> _fetchModels() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      _showError('Please enter an API key first');
      return;
    }

    setState(() => _isFetchingModels = true);

    try {
      final provider = GeminiProviderService();
      await provider.initialize(key);
      final models = await provider.fetchAvailableModels(key);
      await provider.dispose();

      if (mounted) {
        final geminiProvider = AIProviderRegistry.get('gemini');
        if (geminiProvider is GeminiProviderService) {
          for (final model in models) {
            await geminiProvider.addCustomModel(model);
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetched ${models.length} models')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to fetch models: $e');
      }
    } finally {
      if (mounted) setState(() => _isFetchingModels = false);
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

  Future<void> _addCustomModel() async {
    final model = _customModelController.text.trim();
    if (model.isEmpty) return;

    setState(() => _isAddingModel = true);

    try {
      final geminiProvider = AIProviderRegistry.get('gemini');
      if (geminiProvider is GeminiProviderService) {
        await geminiProvider.addCustomModel(model);
        _customModelController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added model: $model')),
          );
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add model: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingModel = false);
    }
  }

  Future<void> _removeModel(String model) async {
    final geminiProvider = AIProviderRegistry.get('gemini');
    if (geminiProvider is GeminiProviderService) {
      await geminiProvider.removeCustomModel(model);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed model: $model')),
        );
      }
    }
  }

  Future<void> _openAiStudio() async {
    const url = 'https://aistudio.google.com/apikey';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final provider = AIProviderRegistry.get('gemini')!;
    final theme = Theme.of(context);

    final defaultModels = [
      'gemini-3.1-flash-lite',
      'gemini-2.5-flash-lite',
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-2.0-flash-exp',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ];
    final customModels = provider.availableModels.where((m) => !defaultModels.contains(m)).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                color: theme.colorScheme.surface,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.smart_toy_outlined, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  title: Text(provider.providerName, style: theme.textTheme.titleMedium),
                  subtitle: const Text('Liya — Cooperative Digital Assistant'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openAiStudio,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Get API Key from Google AI Studio'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Models',
            [
              Card(
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Select Model', style: theme.textTheme.titleMedium),
                          const Spacer(),
                          if (settings.hasGeminiKey)
                            FilledButton.tonalIcon(
                              onPressed: _isFetchingModels ? null : _fetchModels,
                              icon: _isFetchingModels
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.download_outlined, size: 18),
                              label: Text(_isFetchingModels ? 'Fetching...' : 'Fetch from API'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text('Default Models', style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: defaultModels.map((model) {
                          final isSelected = settings.selectedModel == model;
                          return ChoiceChip(
                            label: Text(model),
                            selected: isSelected,
                            onSelected: (_) => _changeModel(model),
                            selectedColor: theme.colorScheme.surfaceContainerHighest,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            backgroundColor: theme.colorScheme.surface,
                            side: BorderSide(color: theme.colorScheme.outline),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          );
                        }).toList(),
                      ),

                      if (customModels.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text('Custom / Fetched Models', style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                            const Spacer(),
                            Text('(${customModels.length})', style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: customModels.map((model) {
                            final isSelected = settings.selectedModel == model;
                            return InputChip(
                              label: Text(model),
                              selected: isSelected,
                              onSelected: (_) => _changeModel(model),
                              onDeleted: () => _removeModel(model),
                              selectedColor: theme.colorScheme.surfaceContainerHighest,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              backgroundColor: theme.colorScheme.surface,
                              side: BorderSide(color: theme.colorScheme.outline),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text('Add Custom Model', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Enter a custom model ID (e.g., gemini-2.5-flash-preview-05-20)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customModelController,
                      decoration: InputDecoration(
                        labelText: 'Model ID',
                        hintText: 'gemini-2.5-flash-preview-05-20',
                        prefixIcon: const Icon(Icons.add_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: _customModelController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => _customModelController.clear(),
                              )
                            : null,
                      ),
                      onFieldSubmitted: (_) => _addCustomModel(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isAddingModel ? null : _addCustomModel,
                    icon: _isAddingModel
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add, size: 18),
                    label: Text(_isAddingModel ? 'Adding...' : 'Add'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'API Key',
            [
              Card(
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.vpn_key_outlined, color: theme.colorScheme.onSurfaceVariant, size: 20),
                            const SizedBox(width: 12),
                            Text('Gemini API Key', style: theme.textTheme.titleMedium),
                            const Spacer(),
                            if (settings.hasGeminiKey)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Configured',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your API key is stored securely on your device using platform keystore (Keychain/Keystore).',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _apiKeyController,
                          obscureText: _obscureApiKey,
                          decoration: InputDecoration(
                            labelText: 'API Key',
                            hintText: 'Enter your API key (starts with AIza...)',
                            prefixIcon: const Icon(Icons.key_outlined, size: 20),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(_obscureApiKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                  onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                                ),
                                if (_apiKeyController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () => _apiKeyController.clear(),
                                  ),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                icon: const Icon(Icons.save_outlined, size: 18),
                                label: const Text('Save Key'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            if (settings.hasGeminiKey) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _deleteApiKey,
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                    side: BorderSide(color: theme.colorScheme.error),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.science_outlined, size: 18),
                          label: Text(_isTestingKey ? 'Testing...' : 'Test API Key'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
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
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Streaming Responses'),
                      subtitle: const Text('Show responses word-by-word as they arrive'),
                      value: settings.streamingEnabled,
                      onChanged: (value) {
                        ref.read(settingsProvider.notifier).state = settings.copyWith(
                          streamingEnabled: value,
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                color: theme.colorScheme.surface,
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.description_outlined, color: theme.colorScheme.onSurfaceVariant),
                      title: const Text('Privacy'),
                      subtitle: const Text('Your API keys never leave your device'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    ListTile(
                      leading: Icon(Icons.security_outlined, color: theme.colorScheme.onSurfaceVariant),
                      title: const Text('Security'),
                      subtitle: const Text('Keys stored in platform secure storage'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    ListTile(
                      leading: Icon(Icons.code_outlined, color: theme.colorScheme.onSurfaceVariant),
                      title: const Text('Version'),
                      subtitle: Text('$_appVersion ($_buildNumber)'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}