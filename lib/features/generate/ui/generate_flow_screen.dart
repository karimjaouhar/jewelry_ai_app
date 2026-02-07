import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:jewelry_ai_app/app/router.dart';
import 'package:jewelry_ai_app/core/services/secure_storage_service.dart';
import 'package:jewelry_ai_app/features/generate/domain/composition_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/hair_preset.dart';
import 'package:jewelry_ai_app/features/generate/domain/jewelry_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_gender.dart';
import 'package:jewelry_ai_app/features/generate/domain/setting_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/skin_tone.dart';
import 'package:jewelry_ai_app/features/generate/state/generation_flow_controller.dart';
import 'package:jewelry_ai_app/features/generate/ui/results_screen.dart';

class GenerateFlowScreen extends StatelessWidget {
  const GenerateFlowScreen({super.key});

  static const double _previewAspectRatio = 4 / 3;
  static final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 92,
    );

    if (file == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    context.read<GenerationFlowController>().setSelectedImagePath(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GenerationFlowController>();
    final hasImage = controller.hasSelectedImage;
    final imagePath = controller.selectedImagePath;
    final textTheme = Theme.of(context).textTheme;
    final apiKeyFuture = SecureStorageService().readApiKey();
    final isLoading = controller.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.history);
            },
          ),
          IconButton(
            tooltip: 'API Key',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.settings);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FutureBuilder<String?>(
              future: apiKeyFuture,
              builder: (context, snapshot) {
                final hasKey = snapshot.data != null &&
                    snapshot.data!.trim().isNotEmpty;
                if (snapshot.connectionState == ConnectionState.waiting ||
                    hasKey) {
                  return const SizedBox.shrink();
                }
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add your API key to enable generation.',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRouter.settings);
                        },
                        child: const Text('Go to Settings'),
                      ),
                    ],
                  ),
                );
              },
            ),
            Text(
              'Step 1: Upload jewelry photo',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Upload photo'),
              onPressed: isLoading
                  ? null
                  : () => _pickImage(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    onPressed: isLoading
                        ? null
                        : () => _pickImage(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    onPressed: isLoading
                        ? null
                        : () => _pickImage(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (hasImage && imagePath != null)
              AspectRatio(
                aspectRatio: _previewAspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: kIsWeb
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                        ),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                  child: const Center(
                    child: Text(
                      'No photo selected yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            const SizedBox(height: 32),
            Text(
              'Step 2: Configure',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Jewelry Type'),
            _ChoiceChips<JewelryType>(
              values: JewelryType.values,
              selected: controller.jewelryType,
              labelBuilder: (value) => value.label,
              onSelected: controller.setJewelryType,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Model Profile'),
            _ChoiceChips<ModelGender>(
              values: ModelGender.values,
              selected: controller.modelGender,
              labelBuilder: (value) => value.label,
              onSelected: controller.setModelGender,
              enabled: !isLoading,
            ),
            const SizedBox(height: 8),
            _ChoiceChips<SkinTone>(
              values: SkinTone.values,
              selected: controller.skinTone,
              labelBuilder: (value) => value.label,
              onSelected: controller.setSkinTone,
              enabled: !isLoading,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HairPreset?>(
              key: ValueKey(controller.hairPreset),
              initialValue: controller.hairPreset,
              decoration: const InputDecoration(
                labelText: 'Hair preset (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<HairPreset?>(
                  value: null,
                  child: Text('No preference'),
                ),
                ...HairPreset.values.map(
                  (preset) => DropdownMenuItem<HairPreset?>(
                    value: preset,
                    child: Text(preset.label),
                  ),
                ),
              ],
              onChanged: isLoading ? null : controller.setHairPreset,
            ),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Setting'),
            _ChoiceChips<SettingType>(
              values: SettingType.values,
              selected: controller.settingType,
              labelBuilder: (value) => value.label,
              onSelected: controller.setSettingType,
              enabled: !isLoading,
            ),
            if (controller.settingType == SettingType.lifestyle) ...[
              const SizedBox(height: 8),
              _ChoiceChips<LifestylePreset>(
                values: LifestylePreset.values,
                selected: controller.lifestylePreset,
                labelBuilder: (value) => value.label,
                onSelected: controller.setLifestylePreset,
                enabled: !isLoading,
              ),
            ],
            const SizedBox(height: 16),
            _SectionHeader(title: 'Composition'),
            _ChoiceChips<CompositionType>(
              values: CompositionType.values,
              selected: controller.compositionType,
              labelBuilder: (value) => value.label,
              onSelected: controller.setCompositionType,
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Variations'),
            _ChoiceChips<int>(
              values: const [2, 3, 4],
              selected: controller.variations,
              labelBuilder: (value) => value.toString(),
              onSelected: controller.setVariations,
              enabled: !isLoading,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: hasImage && !isLoading
                        ? () => controller.generate()
                        : null,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: !isLoading &&
                            controller.lastRequest != null &&
                            controller.lastPrompt != null
                        ? () => controller.regenerateLast()
                        : null,
                    child: const Text('Regenerate'),
                  ),
                ),
              ],
            ),
            if (controller.status == GenerationStatus.error &&
                controller.errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(
                message: controller.errorMessage!,
                onRetry: controller.generate,
              ),
            ],
            if (controller.status == GenerationStatus.success &&
                controller.generatedImagePaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Saved ${controller.generatedImagePaths.length} image(s) to device.',
                style: textTheme.bodyMedium,
              ),
              if (controller.generatedOutputDirectory != null) ...[
                const SizedBox(height: 8),
                SelectableText(
                  controller.generatedOutputDirectory!,
                  style: textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ResultsScreen(
                          imagePaths: controller.generatedImagePaths,
                        ),
                      ),
                    );
                  },
                  child: const Text('View results'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class _ChoiceChips<T> extends StatelessWidget {
  const _ChoiceChips({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    this.enabled = true,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => ChoiceChip(
              label: Text(labelBuilder(value)),
              selected: value == selected,
              onSelected: enabled
                  ? (isSelected) {
                      if (isSelected) {
                        onSelected(value);
                      }
                    }
                  : null,
            ),
          )
          .toList(),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
