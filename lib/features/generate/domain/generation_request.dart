import 'package:jewelry_ai_app/features/generate/domain/composition_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/jewelry_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_gender.dart';
import 'package:jewelry_ai_app/features/generate/domain/setting_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/skin_tone.dart';

class GenerationRequest {
  const GenerationRequest({
    required this.imageFilePath,
    required this.jewelryType,
    required this.modelGender,
    required this.skinTone,
    required this.settingType,
    this.lifestylePreset,
    required this.compositionType,
    required this.variations,
    this.seed,
  });

  final String imageFilePath;
  final JewelryType jewelryType;
  final ModelGender modelGender;
  final SkinTone skinTone;
  final SettingType settingType;
  final LifestylePreset? lifestylePreset;
  final CompositionType compositionType;
  final int variations;
  final int? seed;

  Map<String, dynamic> toMap() {
    return {
      'imageFilePath': imageFilePath,
      'jewelryType': jewelryType.name,
      'modelGender': modelGender.name,
      'skinTone': skinTone.name,
      'settingType': settingType.name,
      'lifestylePreset': lifestylePreset?.name,
      'compositionType': compositionType.name,
      'variations': variations,
      'seed': seed,
    };
  }

  factory GenerationRequest.fromMap(Map<String, dynamic> map) {
    return GenerationRequest(
      imageFilePath: map['imageFilePath'] as String? ?? '',
      jewelryType: JewelryType.values.byName(
        (map['jewelryType'] as String?) ?? JewelryType.necklace.name,
      ),
      modelGender: ModelGender.values.byName(
        (map['modelGender'] as String?) ?? ModelGender.woman.name,
      ),
      skinTone: SkinTone.values.byName(
        (map['skinTone'] as String?) ?? SkinTone.medium.name,
      ),
      settingType: SettingType.values.byName(
        (map['settingType'] as String?) ?? SettingType.studio.name,
      ),
      lifestylePreset: _parseLifestylePreset(map['lifestylePreset']),
      compositionType: CompositionType.values.byName(
        (map['compositionType'] as String?) ?? CompositionType.closeUp.name,
      ),
      variations: map['variations'] as int? ?? 2,
      seed: map['seed'] as int?,
    );
  }

  static LifestylePreset? _parseLifestylePreset(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return LifestylePreset.values.byName(value);
  }
}
