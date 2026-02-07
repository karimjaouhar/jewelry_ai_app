import 'package:jewelry_ai_app/features/generate/domain/composition_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/generation_request.dart';
import 'package:jewelry_ai_app/features/generate/domain/jewelry_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_age.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_gender.dart';
import 'package:jewelry_ai_app/features/generate/domain/setting_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/skin_tone.dart';

class PromptParts {
  const PromptParts({
    required this.system,
    required this.user,
    this.negative,
  });

  final String system;
  final String user;
  final String? negative;
}

class PromptBuilder {
  const PromptBuilder();

  PromptParts build(GenerationRequest request) {
    final system = _buildSystem(request);
    final user = _buildUser(request);
    final negative = _buildNegative(request);

    return PromptParts(
      system: system,
      user: user,
      negative: negative,
    );
  }

  String _buildSystem(GenerationRequest request) {
    final buffer = StringBuffer()
      ..writeln('You are a product photography assistant.')
      ..writeln('Preserve the jewelry exactly as in the reference image.')
      ..writeln(
        'No redesigns: keep shape, stones, metal tone, proportions, and details identical.',
      )
      ..writeln('Do not add or remove jewelry pieces.')
      ..writeln(
        _placementRule(
          request.jewelryType,
          request.settingType,
        ),
      );

    return buffer.toString().trim();
  }

  String _buildUser(GenerationRequest request) {
    final buffer = StringBuffer()
      ..writeln(
        'Model: ${request.modelGender.label}, ${request.modelAge.label}, ${request.skinTone.label} skin tone.',
      )
      ..writeln(_settingRule(request.settingType, request.lifestylePreset))
      ..writeln(_compositionRule(request.compositionType))
      ..writeln(_poseRule(request.settingType, request.jewelryType))
      ..writeln(_cameraStyleRule(request));

    if (request.seed != null) {
      buffer.writeln('Seed: ${request.seed}.');
    }

    return buffer.toString().trim();
  }

  String? _buildNegative(GenerationRequest request) {
    final buffer = StringBuffer()
      ..write('No text, watermarks, or logos. ')
      ..write('No collages, overlays, insets, or split frames. ')
      ..write('Avoid extra fingers, distorted anatomy, or asymmetry errors. ')
      ..write('No melted metal, warped stones, or deformed prongs.');

    if (request.compositionType == CompositionType.lifestyleWide ||
        request.settingType == SettingType.lifestyle) {
      buffer.write(' Avoid studio lighting, heavy bokeh, or stock-photo styling.');
    }

    return buffer.toString();
  }

  String _placementRule(
    JewelryType type,
    SettingType settingType,
  ) {
    switch (type) {
      case JewelryType.necklace:
        if (settingType == SettingType.studio) {
          return 'Necklace must drape naturally on the collarbone and be fully visible.';
        }
        return 'Necklace must be naturally worn on the collarbone and visible without forced framing.';
      case JewelryType.earrings:
        return 'Earrings must be clearly visible on both ears with matching size and angle.';
      case JewelryType.ring:
        return 'Ring must be centered on the finger with a natural hand pose.';
      case JewelryType.bracelet:
        return 'Bracelet should sit naturally on the wrist; if multiple are present, stack evenly.';
      case JewelryType.anklet:
        return 'Anklet must wrap naturally around the ankle and be fully visible.';
      case JewelryType.other:
        return 'Keep the jewelry placement faithful to the reference image.';
    }
  }

  String _settingRule(
    SettingType settingType,
    LifestylePreset? lifestylePreset,
  ) {
    switch (settingType) {
      case SettingType.studio:
        return 'Setting: clean studio background, soft diffused lighting.';
      case SettingType.studioNatural:
        return 'Setting: studio with natural daylight, soft shadows, clean background.';
      case SettingType.lifestyle:
        final preset = lifestylePreset?.label ?? 'Lifestyle';
        return 'Setting: lifestyle scene (${preset.toLowerCase()}).';
    }
  }

  String _compositionRule(CompositionType compositionType) {
    switch (compositionType) {
      case CompositionType.closeUp:
        return 'Composition: close-up framing that emphasizes the jewelry.';
      case CompositionType.midShot:
        return 'Composition: mid shot with jewelry clearly prominent.';
      case CompositionType.lifestyleWide:
        return 'Composition: lifestyle wide shot, natural candid framing (iPhone/digital camera feel). '
            'Jewelry is part of the outfit but remains clearly visible.';
    }
  }

  String _cameraStyleRule(GenerationRequest request) {
    if (request.compositionType == CompositionType.lifestyleWide) {
      return 'Single photograph. Natural light, minimal bokeh, everyday smartphone/digital camera look; '
          'keep the jewelry clear without forced blur.';
    }
    if (request.settingType == SettingType.studioNatural) {
      return 'Single photograph. Soft natural light, gentle depth of field; jewelry remains crisp. '
          'Natural skin texture with subtle pores and light freckles; avoid heavy airbrushing.';
    }
    return 'Single photograph. Shallow depth of field; sharp focus on the jewelry.';
  }

  String _poseRule(SettingType settingType, JewelryType jewelryType) {
    if (settingType != SettingType.studioNatural) {
      return 'Natural, relaxed pose showcasing the jewelry.';
    }

    switch (jewelryType) {
      case JewelryType.ring:
        return 'Natural studio pose showcasing rings (e.g., hand near face or chin-on-hand).';
      case JewelryType.necklace:
        return 'Natural studio pose showcasing the necklace and collarbone.';
      case JewelryType.earrings:
        return 'Natural studio pose with earrings visible and head slightly turned.';
      case JewelryType.bracelet:
        return 'Natural studio pose with wrist gently angled to show the bracelet.';
      case JewelryType.anklet:
        return 'Natural studio pose with ankle visible and relaxed stance.';
      case JewelryType.other:
        return 'Natural studio pose showcasing the jewelry.';
    }
  }
}
