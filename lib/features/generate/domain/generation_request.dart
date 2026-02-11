import 'package:jewelry_ai_app/features/generate/domain/composition_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/jewelry_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_age.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_gender.dart';
import 'package:jewelry_ai_app/features/generate/domain/setting_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/skin_tone.dart';

class GenerationRequest {
  const GenerationRequest({
    required this.imageFilePaths,
    required this.jewelryType,
    required this.modelGender,
    required this.modelAge,
    required this.skinTone,
    required this.settingType,
    this.lifestylePreset,
    required this.compositionType,
    required this.variations,
    this.seed,
  });

  final List<String> imageFilePaths;
  final JewelryType jewelryType;
  final ModelGender modelGender;
  final ModelAge modelAge;
  final SkinTone skinTone;
  final SettingType settingType;
  final LifestylePreset? lifestylePreset;
  final CompositionType compositionType;
  final int variations;
  final int? seed;

  Map<String, dynamic> toMap() {
    return {
      'imageFilePaths': imageFilePaths,
      'jewelryType': jewelryType.name,
      'modelGender': modelGender.name,
      'modelAge': modelAge.name,
      'skinTone': skinTone.name,
      'settingType': settingType.name,
      'lifestylePreset': lifestylePreset?.name,
      'compositionType': compositionType.name,
      'variations': variations,
      'seed': seed,
    };
  }

  factory GenerationRequest.fromMap(Map<String, dynamic> map) {
    final imageFilePaths = _parseImageFilePaths(map);
    return GenerationRequest(
      imageFilePaths: imageFilePaths,
      jewelryType: JewelryType.values.byName(
        (map['jewelryType'] as String?) ?? JewelryType.necklace.name,
      ),
      modelGender: ModelGender.values.byName(
        (map['modelGender'] as String?) ?? ModelGender.woman.name,
      ),
      modelAge: _parseModelAge(map['modelAge']),
      skinTone: _parseSkinTone(map['skinTone']),
      settingType: SettingType.values.byName(
        (map['settingType'] as String?) ?? SettingType.studio.name,
      ),
      lifestylePreset: _parseLifestylePreset(map['lifestylePreset']),
      compositionType: CompositionType.values.byName(
        (map['compositionType'] as String?) ?? CompositionType.closeUp.name,
      ),
      variations: map['variations'] as int? ?? 1,
      seed: map['seed'] as int?,
    );
  }

  static List<String> _parseImageFilePaths(Map<String, dynamic> map) {
    final rawList = map['imageFilePaths'];
    if (rawList is List) {
      return rawList.map((value) => value.toString()).toList();
    }
    final legacyPath = map['imageFilePath'];
    if (legacyPath is String && legacyPath.isNotEmpty) {
      return [legacyPath];
    }
    return <String>[];
  }

  static LifestylePreset? _parseLifestylePreset(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return LifestylePreset.values.byName(value);
  }

  static SkinTone _parseSkinTone(Object? value) {
    final raw = value is String ? value : '';
    switch (raw) {
      case 'light':
        return SkinTone.light;
      case 'medium':
        return SkinTone.tanned;
      case 'tanned':
        return SkinTone.tanned;
      case 'brown':
        return SkinTone.brown;
      case 'deep':
        return SkinTone.dark;
      case 'dark':
        return SkinTone.dark;
      default:
        return SkinTone.tanned;
    }
  }

  static ModelAge _parseModelAge(Object? value) {
    final raw = value is String ? value : '';
    switch (raw) {
      case 'kids':
        return ModelAge.teen;
      case 'forties':
        return ModelAge.adult;
      case 'teen':
        return ModelAge.teen;
      case 'twenties':
        return ModelAge.twenties;
      case 'adult':
        return ModelAge.adult;
      case 'senior':
        return ModelAge.senior;
      default:
        return ModelAge.twenties;
    }
  }
}
