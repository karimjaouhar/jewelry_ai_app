import 'package:flutter_test/flutter_test.dart';
import 'package:jewelry_ai_app/features/generate/domain/composition_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/generation_request.dart';
import 'package:jewelry_ai_app/features/generate/domain/jewelry_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_age.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_gender.dart';
import 'package:jewelry_ai_app/features/generate/domain/prompt_builder.dart';
import 'package:jewelry_ai_app/features/generate/domain/setting_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/skin_tone.dart';

void main() {
  const builder = PromptBuilder();

  test('Necklace prompt includes fidelity and placement rules', () {
    const request = GenerationRequest(
      imageFilePath: 'path/to/image.jpg',
      jewelryType: JewelryType.necklace,
      modelGender: ModelGender.woman,
      modelAge: ModelAge.twenties,
      skinTone: SkinTone.medium,
      settingType: SettingType.studio,
      compositionType: CompositionType.closeUp,
      variations: 2,
    );

    final parts = builder.build(request);

    expect(parts.system, contains('Preserve the jewelry exactly'));
    expect(parts.system, contains('No redesigns'));
    expect(parts.system, contains('Necklace must drape naturally'));
    expect(parts.user, contains('close-up framing'));
    expect(parts.negative, contains('No text, watermarks, or logos'));
  });

  test('Ring prompt includes fidelity and placement rules', () {
    const request = GenerationRequest(
      imageFilePath: 'path/to/image.jpg',
      jewelryType: JewelryType.ring,
      modelGender: ModelGender.neutral,
      modelAge: ModelAge.forties,
      skinTone: SkinTone.light,
      settingType: SettingType.lifestyle,
      lifestylePreset: LifestylePreset.street,
      compositionType: CompositionType.midShot,
      variations: 3,
    );

    final parts = builder.build(request);

    expect(parts.system, contains('Preserve the jewelry exactly'));
    expect(parts.system, contains('Ring must be centered on the finger'));
    expect(parts.user, contains('lifestyle scene'));
    expect(parts.user, contains('mid shot'));
  });
}
