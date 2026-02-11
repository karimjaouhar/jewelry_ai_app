import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:jewelry_ai_app/app/theme_controller.dart';
import 'package:jewelry_ai_app/core/services/secure_storage_service.dart';

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final SecureStorageService _storageService = SecureStorageService();
  final TextEditingController _controller = TextEditingController();
  bool _obscureText = true;
  bool _hasSavedKey = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await _storageService.readApiKey();
    if (!mounted) {
      return;
    }
    setState(() {
      _hasSavedKey = key != null && key.isNotEmpty;
      _controller.text = key ?? '';
    });
  }

  Future<void> _saveKey() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      _showSnackBar('API key cannot be empty.');
      return;
    }
    setState(() {
      _isBusy = true;
    });
    await _storageService.writeApiKey(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _hasSavedKey = true;
      _isBusy = false;
    });
    _showSnackBar('API key saved.');
  }

  Future<void> _clearKey() async {
    setState(() {
      _isBusy = true;
    });
    await _storageService.clearApiKey();
    if (!mounted) {
      return;
    }
    setState(() {
      _hasSavedKey = false;
      _controller.clear();
      _isBusy = false;
    });
    _showSnackBar('API key cleared.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _hasSavedKey ? 'Saved' : 'Not saved';
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor =
        _hasSavedKey ? colorScheme.onSurface : colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Key'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _ThemeModeTile(),
            const SizedBox(height: 24),
            Text(
              'Status: $statusText',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: statusColor,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'API key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscureText ? 'Show' : 'Hide',
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _saveKey,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isBusy ? null : _clearKey,
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final isDark = controller.themeMode == ThemeMode.dark;
    return SwitchListTile(
      value: isDark,
      onChanged: controller.setDarkMode,
      title: const Text('Dark theme'),
      subtitle: const Text('Studio-lit, calm, and high-contrast.'),
      contentPadding: EdgeInsets.zero,
    );
  }
}
