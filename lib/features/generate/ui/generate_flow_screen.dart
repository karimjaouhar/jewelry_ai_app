import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:jewelry_ai_app/app/router.dart';
import 'package:jewelry_ai_app/core/services/secure_storage_service.dart';
import 'package:jewelry_ai_app/features/generate/domain/composition_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/generation_request.dart';
import 'package:jewelry_ai_app/features/generate/domain/jewelry_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_age.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_gender.dart';
import 'package:jewelry_ai_app/features/generate/domain/setting_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/skin_tone.dart';
import 'package:jewelry_ai_app/features/generate/state/generation_flow_controller.dart';
import 'package:jewelry_ai_app/features/generate/ui/results_screen.dart';
import 'package:jewelry_ai_app/features/history/data/history_store.dart';
import 'package:jewelry_ai_app/features/history/domain/history_entry.dart';

class GenerateFlowScreen extends StatelessWidget {
  const GenerateFlowScreen({super.key});

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

    context.read<GenerationFlowController>().addSelectedImagePath(file.path);
  }

  Future<void> _pickMultiple(BuildContext context) async {
    final files = await _picker.pickMultiImage(
      imageQuality: 92,
    );

    if (files.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    context
        .read<GenerationFlowController>()
        .addSelectedImagePaths(files.map((file) => file.path).toList());
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GenerationFlowController>();
    final hasImages = controller.hasSelectedImages;
    final imagePaths = controller.selectedImagePaths;
    final textTheme = Theme.of(context).textTheme;
    final apiKeyFuture = SecureStorageService().readApiKey();
    final isLoading = controller.isLoading;
    final stepIndex = controller.currentStepIndex.clamp(0, 4);
    final hasJewelryType = controller.jewelryType != null;

    final canMoveFromUpload = hasImages && !isLoading;
    final canMoveFromJewelryType = hasJewelryType && !isLoading;
    final canMoveFromModelProfile = !isLoading;
    final canGenerate = hasImages && hasJewelryType && !isLoading;

    final isPrimaryEnabled = switch (stepIndex) {
      0 => canMoveFromUpload,
      1 => canMoveFromJewelryType,
      2 => canMoveFromModelProfile,
      3 => canGenerate,
      _ => false,
    };

    final primaryLabel = stepIndex == 3 ? 'Generate' : 'Next';

    final statusText = switch (stepIndex) {
      0 when !hasImages => 'Upload photos to continue.',
      0 => 'Ready to continue.',
      1 when !hasJewelryType => 'Select a jewelry type to continue.',
      1 => 'Choose the jewelry type and continue.',
      2 => 'Set model profile preferences and continue.',
      3 when isLoading => 'Generating image... this can take a moment.',
      3 => 'Set look and style, then generate.',
      _ => '',
    };

    Future<void> handlePrimaryAction() async {
      if (!isPrimaryEnabled) {
        return;
      }

      if (stepIndex == 0) {
        controller.setStepIndex(1);
        return;
      }

      if (stepIndex == 1) {
        controller.setStepIndex(2);
        return;
      }

      if (stepIndex == 2) {
        controller.setStepIndex(3);
        return;
      }

      if (stepIndex == 3) {
        controller.setStepIndex(4);
        await controller.generate();
        return;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: stepIndex > 0 && stepIndex < 4
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => controller.setStepIndex(stepIndex - 1),
              )
            : null,
        title: const Text('Jewelry Studio AI'),
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
      bottomNavigationBar: stepIndex == 4
          ? _ResultsBottomBar(
              isLoading: controller.isLoading,
              onNewUpload: () {
                controller.clearSelectedImages();
                controller.setStepIndex(0);
              },
            )
          : _FlowBottomBar(
              statusText: statusText,
              primaryLabel: primaryLabel,
              isPrimaryEnabled: isPrimaryEnabled,
              isLoading: isLoading && stepIndex == 3,
              onPrimaryPressed: handlePrimaryAction,
              onBackPressed: stepIndex > 0 && stepIndex < 4
                  ? () => controller.setStepIndex(stepIndex - 1)
                  : null,
            ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
          children: [
            if (stepIndex < 4) ...[
              _FlowStepIndicator(stepIndex: stepIndex),
              const SizedBox(height: 12),
            ],
            if (stepIndex != 4)
              FutureBuilder<String?>(
                future: apiKeyFuture,
                builder: (context, snapshot) {
                  final hasKey =
                      snapshot.data != null && snapshot.data!.trim().isNotEmpty;
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      hasKey) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add your API key to enable generation.',
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                          ),
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildStepContent(
                context: context,
                controller: controller,
                isLoading: isLoading,
                imagePaths: imagePaths,
                stepIndex: stepIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent({
    required BuildContext context,
    required GenerationFlowController controller,
    required bool isLoading,
    required List<String> imagePaths,
    required int stepIndex,
  }) {
    switch (stepIndex) {
      case 0:
        return _UploadSectionCard(
          key: const ValueKey('step-upload'),
          hasImages: controller.hasSelectedImages,
          isLoading: isLoading,
          imagePaths: imagePaths,
          onPickMultiple: () => _pickMultiple(context),
          onPickCamera: () => _pickImage(context, ImageSource.camera),
          onRemoveImage: controller.removeSelectedImageAt,
        );
      case 1:
        return _JewelryTypeSelectionCard(
          key: const ValueKey('step-jewelry-type'),
          selected: controller.jewelryType,
          onSelected: controller.setJewelryType,
          isEnabled: !isLoading,
        );
      case 2:
        return _SectionCard(
          key: const ValueKey('step-model-profile'),
          title: 'Model Profile',
          helperText: 'Select model profile details.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Gender'),
              const SizedBox(height: 8),
              _ModelProfileSelector(
                selected: controller.modelGender,
                onSelected: controller.setModelGender,
                isEnabled: !isLoading,
              ),
              const SizedBox(height: 16),
              _SectionHeader(title: 'Age'),
              const SizedBox(height: 8),
              _AgeGridSelector(
                values: ModelAge.values,
                selected: controller.modelAge,
                onSelected: controller.setModelAge,
                isEnabled: !isLoading,
              ),
              const SizedBox(height: 16),
              _SectionHeader(title: 'Skin Tone'),
              _HelperText(text: 'Defaults: Woman = Light, Man = Tanned'),
              _SkinToneGridSelector(
                values: SkinTone.values,
                selected: controller.skinTone,
                onSelected: controller.setSkinTone,
                isEnabled: !isLoading,
              ),
            ],
          ),
        );
      case 3:
        return _SectionCard(
          key: const ValueKey('step-look-style'),
          title: 'Look & Style',
          helperText: 'Define setting and composition.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Setting'),
              _HelperText(text: 'Recommended: Studio natural'),
              _ImageChoiceGrid<SettingType>(
                options: _settingOptions(),
                selected: controller.settingType,
                onSelected: controller.setSettingType,
                isEnabled: !isLoading,
                columns: 3,
              ),
              if (controller.settingType == SettingType.lifestyle) ...[
                const SizedBox(height: 12),
                _SectionHeader(title: 'Lifestyle preset'),
                const SizedBox(height: 8),
                DropdownButtonFormField<LifestylePreset>(
                  key: ValueKey(controller.lifestylePreset),
                  initialValue: controller.lifestylePreset,
                  decoration: const InputDecoration(
                    labelText: 'Lifestyle preset',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                  isDense: true,
                  iconSize: 18,
                  style: Theme.of(context).textTheme.bodySmall,
                  items: LifestylePreset.values
                      .map(
                        (preset) => DropdownMenuItem<LifestylePreset>(
                          value: preset,
                          child: Text(preset.label),
                        ),
                      )
                      .toList(),
                  onChanged: !isLoading
                      ? (value) {
                          if (value == null) {
                            return;
                          }
                          controller.setLifestylePreset(value);
                        }
                      : null,
                ),
              ],
              const SizedBox(height: 16),
              _SectionHeader(title: 'Composition'),
              _HelperText(text: 'Recommended: Close-up'),
              _ImageChoiceGrid<CompositionType>(
                options: _compositionOptions(),
                selected: controller.compositionType,
                onSelected: controller.setCompositionType,
                isEnabled: !isLoading,
                columns: 3,
              ),
              if (controller.status == GenerationStatus.error &&
                  controller.errorMessage != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(
                  message: controller.errorMessage!,
                  onRetry: controller.generate,
                ),
              ],
            ],
          ),
        );
      default:
        return _SectionCard(
          key: const ValueKey('step-results'),
          title: 'Results',
          helperText: 'Generated images and recent history.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: controller.isLoading
                        ? null
                        : controller.regenerateLast,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Regenerate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (controller.isLoading)
                const _ResultsLoadingSection()
              else if (controller.generatedImagePaths.isEmpty)
                Text(
                  'No generated images yet. Generate from the Look & Style step.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              else
                _ResultsInlineSection(
                  imagePaths: controller.generatedImagePaths,
                  request: controller.lastRequest,
                ),
              const SizedBox(height: 16),
              _HistoryInlineSection(
                onViewAll: () {
                  Navigator.of(context).pushNamed(AppRouter.history);
                },
                onViewEntry: (entry) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ResultsScreen(
                        imagePaths: entry.outputPaths,
                      ),
                    ),
                  );
                },
                onReuseEntry: (entry) {
                  controller.applyRequestSnapshot(entry.requestSnapshot);
                  controller.setStepIndex(3);
                },
              ),
            ],
          ),
        );
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.helperText,
  });

  final String title;
  final String? helperText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Text(
              helperText!,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FlowStepIndicator extends StatelessWidget {
  const _FlowStepIndicator({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    const steps = ['Upload', 'Type', 'Profile', 'Style'];
    final colorScheme = Theme.of(context).colorScheme;
    final transparent = colorScheme.primary.withValues(alpha: 0);

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = stepIndex > index;
        final isCurrent = stepIndex == index;
        final leftActive = stepIndex >= index;
        final rightActive = stepIndex > index;
        final lineColor = leftActive ? colorScheme.primary : colorScheme.outlineVariant;
        final rightLineColor =
            rightActive ? colorScheme.primary : colorScheme.outlineVariant;
        final labelColor =
            (isCompleted || isCurrent) ? colorScheme.primary : colorScheme.onSurfaceVariant;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0 ? transparent : lineColor,
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted ? colorScheme.primary : colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCompleted || isCurrent
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: colorScheme.onPrimary,
                            )
                          : Text(
                              '${index + 1}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isCurrent
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == steps.length - 1
                          ? transparent
                          : rightLineColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[index],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _FlowBottomBar extends StatelessWidget {
  const _FlowBottomBar({
    required this.statusText,
    required this.primaryLabel,
    required this.isPrimaryEnabled,
    required this.isLoading,
    required this.onPrimaryPressed,
    this.onBackPressed,
  });

  final String statusText;
  final String primaryLabel;
  final bool isPrimaryEnabled;
  final bool isLoading;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .colorScheme
                .shadow
                .withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              statusText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (onBackPressed != null) ...[
                  OutlinedButton(
                    onPressed: isLoading ? null : onBackPressed,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(96, 52),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: isPrimaryEnabled ? onPrimaryPressed : null,
                    style: ButtonStyle(
                      minimumSize: const WidgetStatePropertyAll(
                        Size.fromHeight(52),
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) {
                          final colorScheme = Theme.of(context).colorScheme;
                          if (states.contains(WidgetState.disabled)) {
                            return colorScheme.onSurface
                                .withValues(alpha: 0.12);
                          }
                          return colorScheme.primary;
                        },
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) {
                          final colorScheme = Theme.of(context).colorScheme;
                          if (states.contains(WidgetState.disabled)) {
                            return colorScheme.onSurface
                                .withValues(alpha: 0.38);
                          }
                          return colorScheme.onPrimary;
                        },
                      ),
                    ),
                    child: isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text('Generating...'),
                            ],
                          )
                        : Text(primaryLabel),
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

class _ResultsBottomBar extends StatelessWidget {
  const _ResultsBottomBar({
    required this.isLoading,
    required this.onNewUpload,
  });

  final bool isLoading;
  final VoidCallback onNewUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .colorScheme
                .shadow
                .withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onNewUpload,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('New upload'),
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(
              Size.fromHeight(52),
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) {
                final colorScheme = Theme.of(context).colorScheme;
                if (states.contains(WidgetState.disabled)) {
                  return colorScheme.onSurface.withValues(alpha: 0.12);
                }
                return colorScheme.primary;
              },
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) {
                final colorScheme = Theme.of(context).colorScheme;
                if (states.contains(WidgetState.disabled)) {
                  return colorScheme.onSurface.withValues(alpha: 0.38);
                }
                return colorScheme.onPrimary;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsLoadingSection extends StatelessWidget {
  const _ResultsLoadingSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerPlaceholder(
          height: 280,
          borderRadius: 16,
        ),
        const SizedBox(height: 16),
        _LoadingStatusTicker(
          messages: const [
            'Preparing model features...',
            'Adjusting lighting...',
            'Placing your jewelry...',
            'Refining textures...',
            'Polishing the final look...',
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'AI is working in the background',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadingStatusTicker extends StatefulWidget {
  const _LoadingStatusTicker({required this.messages});

  final List<String> messages;

  @override
  State<_LoadingStatusTicker> createState() => _LoadingStatusTickerState();
}

class _LoadingStatusTickerState extends State<_LoadingStatusTicker> {
  static const _tickDuration = Duration(milliseconds: 40);
  static const _pauseDuration = Duration(milliseconds: 900);

  late int _index;
  int _charCount = 0;
  int _pauseTicks = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _index = 0;
    _timer = Timer.periodic(_tickDuration, (_) => _onTick());
  }

  void _onTick() {
    if (!mounted || widget.messages.isEmpty) {
      return;
    }

    final message = widget.messages[_index];
    if (_charCount < message.length) {
      setState(() => _charCount += 1);
      return;
    }

    final pauseLimit = _pauseDuration.inMilliseconds ~/
        _tickDuration.inMilliseconds;
    if (_pauseTicks < pauseLimit) {
      _pauseTicks += 1;
      return;
    }

    setState(() {
      _pauseTicks = 0;
      _charCount = 0;
      _index = (_index + 1) % widget.messages.length;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const SizedBox.shrink();
    }
    final message = widget.messages[_index];
    final visibleText =
        message.substring(0, _charCount.clamp(0, message.length));
    final cursor = _charCount < message.length ? '|' : '';

    return Text(
      '$visibleText$cursor',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder({
    required this.height,
    required this.borderRadius,
  });

  final double height;
  final double borderRadius;

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmerPosition = _controller.value * 2 - 1;
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            children: [
              Container(
                height: widget.height,
                width: double.infinity,
                color: colorScheme.surfaceContainerHighest,
              ),
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(shimmerPosition * 200, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surfaceContainerHighest.withValues(alpha: 0),
                          colorScheme.primary.withValues(alpha: 0.12),
                          colorScheme.surfaceContainerHighest.withValues(alpha: 0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UploadSectionCard extends StatelessWidget {
  const _UploadSectionCard({
    super.key,
    required this.hasImages,
    required this.isLoading,
    required this.imagePaths,
    required this.onPickMultiple,
    required this.onPickCamera,
    required this.onRemoveImage,
  });

  final bool hasImages;
  final bool isLoading;
  final List<String> imagePaths;
  final VoidCallback onPickMultiple;
  final VoidCallback onPickCamera;
  final ValueChanged<int> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload 1-3 photos of your jewelry.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasImages) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Upload photos'),
              onPressed: isLoading ? null : onPickMultiple,
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(
                  Size.fromHeight(52),
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) {
                    final colorScheme = Theme.of(context).colorScheme;
                    if (states.contains(WidgetState.disabled)) {
                      return colorScheme.onSurface
                          .withValues(alpha: 0.12);
                    }
                    return colorScheme.primary;
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) {
                    final colorScheme = Theme.of(context).colorScheme;
                    if (states.contains(WidgetState.disabled)) {
                      return colorScheme.onSurface
                          .withValues(alpha: 0.38);
                    }
                    return colorScheme.onPrimary;
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    onPressed: isLoading ? null : onPickCamera,
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    onPressed: isLoading ? null : onPickMultiple,
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _UploadEmptyState(),
          ] else ...[
            Row(
              children: [
                Text(
                  'Selected photos',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add more'),
                  onPressed: isLoading ? null : onPickMultiple,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(
                      color:
                          Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SelectedImagesRow(
              paths: imagePaths,
              onRemove: isLoading ? null : onRemoveImage,
            ),
          ],
        ],
      ),
    );
  }
}

class _JewelryTypeSelectionCard extends StatelessWidget {
  const _JewelryTypeSelectionCard({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.isEnabled,
  });

  final JewelryType? selected;
  final ValueChanged<JewelryType> onSelected;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Jewelry Type',
      helperText: 'Required: choose what you uploaded.',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: JewelryType.values.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (context, index) {
          final type = JewelryType.values[index];
          final isSelected = selected == type;
          return _JewelryTypeTile(
            type: type,
            isSelected: isSelected,
            isEnabled: isEnabled,
            onTap: () => onSelected(type),
          );
        },
      ),
    );
  }
}

class _JewelryTypeTile extends StatelessWidget {
  const _JewelryTypeTile({
    required this.type,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  final JewelryType type;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transparent = colorScheme.primary.withValues(alpha: 0);
    final imagePath = _imageForJewelryType(type);
    final foregroundColor =
        isSelected ? colorScheme.primary : colorScheme.onSurface;
    final selectedFill = _selectionFillColor(context);

    return Material(
      color: transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? selectedFill : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            _iconForJewelryType(type),
                            size: 28,
                            color: foregroundColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  type.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _imageForJewelryType(JewelryType type) {
  switch (type) {
    case JewelryType.necklace:
      return 'assets/jewelry_types/necklace.jpg';
    case JewelryType.earrings:
      return 'assets/jewelry_types/earing.jpg';
    case JewelryType.ring:
      return 'assets/jewelry_types/ring.jpg';
    case JewelryType.bracelet:
      return 'assets/jewelry_types/bracelet.jpg';
    case JewelryType.anklet:
      return 'assets/jewelry_types/anklet.jpg';
    case JewelryType.other:
      return 'assets/jewelry_types/other.jpg';
  }
}

Color _selectionFillColor(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  if (theme.brightness == Brightness.dark) {
    return colorScheme.surface;
  }
  return colorScheme.primaryContainer;
}

class _ModelProfileSelector extends StatelessWidget {
  const _ModelProfileSelector({
    required this.selected,
    required this.onSelected,
    required this.isEnabled,
  });

  final ModelGender selected;
  final ValueChanged<ModelGender> onSelected;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProfileOptionButton(
            label: ModelGender.woman.label,
            icon: Icons.female_outlined,
            isSelected: selected == ModelGender.woman,
            isEnabled: isEnabled,
            onTap: () => onSelected(ModelGender.woman),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProfileOptionButton(
            label: ModelGender.man.label,
            icon: Icons.male_outlined,
            isSelected: selected == ModelGender.man,
            isEnabled: isEnabled,
            onTap: () => onSelected(ModelGender.man),
          ),
        ),
      ],
    );
  }
}

class _AgeGridSelector extends StatelessWidget {
  const _AgeGridSelector({
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.isEnabled,
  });

  final List<ModelAge> values;
  final ModelAge selected;
  final ValueChanged<ModelAge> onSelected;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) {
        final age = values[index];
        final isSelected = age == selected;
        return _AgeOptionTile(
          age: age,
          isSelected: isSelected,
          isEnabled: isEnabled,
          onTap: () => onSelected(age),
        );
      },
    );
  }
}

class _AgeOptionTile extends StatelessWidget {
  const _AgeOptionTile({
    required this.age,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  final ModelAge age;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor =
        isSelected ? colorScheme.primary : colorScheme.onSurface;
    final selectedFill = _selectionFillColor(context);

    return Material(
      color: colorScheme.primary.withValues(alpha: 0),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? selectedFill : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconForModelAge(age),
                size: 16,
                color: foregroundColor,
              ),
              const SizedBox(width: 6),
              Text(
                age.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinToneGridSelector extends StatelessWidget {
  const _SkinToneGridSelector({
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.isEnabled,
  });

  final List<SkinTone> values;
  final SkinTone selected;
  final ValueChanged<SkinTone> onSelected;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) {
        final tone = values[index];
        final isSelected = tone == selected;
        return _SkinToneOptionTile(
          tone: tone,
          isSelected: isSelected,
          isEnabled: isEnabled,
          onTap: () => onSelected(tone),
        );
      },
    );
  }
}

class _SkinToneOptionTile extends StatelessWidget {
  const _SkinToneOptionTile({
    required this.tone,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  final SkinTone tone;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor =
        isSelected ? colorScheme.primary : colorScheme.onSurface;
    final selectedFill = _selectionFillColor(context);

    return Material(
      color: colorScheme.primary.withValues(alpha: 0),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? selectedFill : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _skinToneThumbnail(context, tone, isSelected),
              const SizedBox(width: 8),
              Text(
                tone.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileOptionButton extends StatelessWidget {
  const _ProfileOptionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor =
        isSelected ? colorScheme.primary : colorScheme.onSurface;
    final selectedFill = _selectionFillColor(context);

    return Material(
      color: colorScheme.primary.withValues(alpha: 0),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? selectedFill : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageChoiceOption<T> {
  const _ImageChoiceOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.imageAssetPath,
  });

  final T value;
  final String label;
  final IconData icon;
  final String imageAssetPath;
}

class _ImageChoiceGrid<T> extends StatelessWidget {
  const _ImageChoiceGrid({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.isEnabled,
    this.columns = 3,
  });

  final List<_ImageChoiceOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool isEnabled;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.64,
      ),
      itemBuilder: (context, index) {
        final option = options[index];
        return _ImageChoiceTile<T>(
          option: option,
          isSelected: option.value == selected,
          isEnabled: isEnabled,
          onTap: () => onSelected(option.value),
        );
      },
    );
  }
}

class _ImageChoiceTile<T> extends StatelessWidget {
  const _ImageChoiceTile({
    required this.option,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  final _ImageChoiceOption<T> option;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = isSelected ? colorScheme.primary : colorScheme.outlineVariant;
    final previewColor = colorScheme.surfaceContainerHighest;
    final iconColor = isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final labelColor = isSelected ? colorScheme.primary : colorScheme.onSurface;

    return Material(
      color: colorScheme.primary.withValues(alpha: 0),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Ink(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: previewColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.asset(
                    option.imageAssetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: previewColor,
                        alignment: Alignment.center,
                        child: Icon(
                          option.icon,
                          size: 26,
                          color: iconColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

List<_ImageChoiceOption<SettingType>> _settingOptions() {
  return const [
    _ImageChoiceOption(
      value: SettingType.studio,
      label: 'Studio',
      icon: Icons.photo_camera_back_outlined,
      imageAssetPath: 'assets/placeholder.png',
    ),
    _ImageChoiceOption(
      value: SettingType.studioNatural,
      label: 'Studio natural',
      icon: Icons.wb_sunny_outlined,
      imageAssetPath: 'assets/placeholder.png',
    ),
    _ImageChoiceOption(
      value: SettingType.lifestyle,
      label: 'Lifestyle',
      icon: Icons.park_outlined,
      imageAssetPath: 'assets/placeholder.png',
    ),
  ];
}

List<_ImageChoiceOption<CompositionType>> _compositionOptions() {
  return const [
    _ImageChoiceOption(
      value: CompositionType.closeUp,
      label: 'Close-up',
      icon: Icons.zoom_in_outlined,
      imageAssetPath: 'assets/placeholder.png',
    ),
    _ImageChoiceOption(
      value: CompositionType.midShot,
      label: 'Mid shot',
      icon: Icons.crop_7_5_outlined,
      imageAssetPath: 'assets/placeholder.png',
    ),
    _ImageChoiceOption(
      value: CompositionType.lifestyleWide,
      label: 'Lifestyle wide',
      icon: Icons.panorama_outlined,
      imageAssetPath: 'assets/placeholder.png',
    ),
  ];
}

IconData _iconForModelAge(ModelAge age) {
  switch (age) {
    case ModelAge.teen:
      return Icons.school_outlined;
    case ModelAge.twenties:
      return Icons.person_outline;
    case ModelAge.adult:
      return Icons.work_outline;
    case ModelAge.senior:
      return Icons.accessibility_new_outlined;
  }
}

Widget _skinToneThumbnail(
  BuildContext context,
  SkinTone tone,
  bool isSelected,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final borderColor =
      isSelected ? colorScheme.primary : colorScheme.outlineVariant;

  return Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: borderColor),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset(
        _skinToneAsset(tone),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          );
        },
      ),
    ),
  );
}

String _skinToneAsset(SkinTone tone) {
  switch (tone) {
    case SkinTone.light:
      return 'assets/skin_tones/light.jpg';
    case SkinTone.tanned:
      return 'assets/skin_tones/tanned.jpg';
    case SkinTone.brown:
      return 'assets/skin_tones/brown.jpg';
    case SkinTone.dark:
      return 'assets/skin_tones/dark.jpg';
  }
}

IconData _iconForJewelryType(JewelryType type) {
  switch (type) {
    case JewelryType.necklace:
      return Icons.workspace_premium_outlined;
    case JewelryType.earrings:
      return Icons.radio_button_checked_outlined;
    case JewelryType.ring:
      return Icons.circle_outlined;
    case JewelryType.bracelet:
      return Icons.watch_outlined;
    case JewelryType.anklet:
      return Icons.directions_walk_outlined;
    case JewelryType.other:
      return Icons.category_outlined;
  }
}

class _UploadEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Icon(
            Icons.photo_outlined,
            size: 28,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
            const SizedBox(height: 8),
            Text(
              'Drag in or pick photos to get started.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
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
    final textTheme = Theme.of(context).textTheme;
    return Text(
      title,
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _HelperText extends StatelessWidget {
  const _HelperText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SelectedImagesRow extends StatelessWidget {
  const _SelectedImagesRow({
    required this.paths,
    required this.onRemove,
  });

  final List<String> paths;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final path = paths[index];
          return SizedBox(
            width: 110,
            child: _SelectedImageTile(
              path: path,
              onRemove: onRemove == null ? null : () => onRemove!(index),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedImageTile extends StatelessWidget {
  const _SelectedImageTile({
    required this.path,
    required this.onRemove,
  });

  final String path;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(path, fit: BoxFit.cover)
                : Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .scrim
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultsInlineSection extends StatelessWidget {
  const _ResultsInlineSection({
    required this.imagePaths,
    this.request,
  });

  final List<String> imagePaths;
  final GenerationRequest? request;

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    final contextLine = _buildContextLine();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Results',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          contextLine,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: imagePaths.length,
          itemBuilder: (context, index) {
            final path = imagePaths[index];
            return _ResultTile(
              path: path,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FullScreenViewer(path: path),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _buildContextLine() {
    final count = imagePaths.length;
    final label = count == 1 ? 'image' : 'images';
    if (request == null) {
      return '$count $label';
    }
    return '$count $label - ${request!.settingType.label} - '
        '${request!.compositionType.label}';
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.path,
    required this.onTap,
  });

  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb
            ? Image.network(path, fit: BoxFit.cover)
            : Image.file(File(path), fit: BoxFit.cover),
      ),
    );
  }
}

class _HistoryInlineSection extends StatelessWidget {
  const _HistoryInlineSection({
    required this.onViewAll,
    required this.onViewEntry,
    required this.onReuseEntry,
  });

  final VoidCallback onViewAll;
  final ValueChanged<HistoryEntry> onViewEntry;
  final ValueChanged<HistoryEntry> onReuseEntry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HistoryEntry>>(
      future: HistoryStore().loadEntries(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? <HistoryEntry>[];
        final visibleEntries = entries.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SectionHeader(title: 'History'),
                const Spacer(),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.onSurface,
                  ),
                  child: const Text('View all'),
                ),
              ],
            ),
            if (visibleEntries.isEmpty)
              Text(
                'No history yet.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              ...visibleEntries.map(
                (entry) => _HistoryInlineTile(
                  entry: entry,
                  onView: () => onViewEntry(entry),
                  onReuse: () => onReuseEntry(entry),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HistoryInlineTile extends StatelessWidget {
  const _HistoryInlineTile({
    required this.entry,
    required this.onView,
    required this.onReuse,
  });

  final HistoryEntry entry;
  final VoidCallback onView;
  final VoidCallback onReuse;

  @override
  Widget build(BuildContext context) {
    final request = entry.requestSnapshot;
    final subtitle =
        '${request.settingType.label} - ${request.compositionType.label}';
    final thumbnailPath = entry.thumbnailPath;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _HistoryThumbnail(path: thumbnailPath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.jewelryType.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onView,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text('View'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onReuse,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: const Text('Reuse'),
          ),
        ],
      ),
    );
  }
}

class _HistoryThumbnail extends StatelessWidget {
  const _HistoryThumbnail({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final size = 48.0;
    if (path == null || path!.isEmpty) {
      return _placeholder(context, size);
    }

    final image = kIsWeb
        ? Image.network(path!, fit: BoxFit.cover)
        : Image.file(File(path!), fit: BoxFit.cover);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: size,
        width: size,
        child: image,
      ),
    );
  }

  Widget _placeholder(BuildContext context, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined),
    );
  }
}
