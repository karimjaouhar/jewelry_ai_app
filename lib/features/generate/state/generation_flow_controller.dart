import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:jewelry_ai_app/features/generate/domain/composition_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/generation_request.dart';
import 'package:jewelry_ai_app/features/generate/domain/hair_preset.dart';
import 'package:jewelry_ai_app/features/generate/domain/jewelry_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_age.dart';
import 'package:jewelry_ai_app/features/generate/domain/model_gender.dart';
import 'package:jewelry_ai_app/features/generate/domain/prompt_builder.dart';
import 'package:jewelry_ai_app/features/generate/domain/setting_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/skin_tone.dart';
import 'package:jewelry_ai_app/features/generate/data/generation_repository.dart';
import 'package:jewelry_ai_app/core/services/generation_api_client.dart';
import 'package:jewelry_ai_app/core/services/secure_storage_service.dart';
import 'package:jewelry_ai_app/features/history/data/history_store.dart';
import 'package:jewelry_ai_app/features/history/domain/history_entry.dart';

enum GenerationStatus {
  idle,
  loading,
  success,
  error,
}

class GenerationFlowController extends ChangeNotifier {
  GenerationFlowController({
    SecureStorageService? storageService,
    PromptBuilder? promptBuilder,
    GenerationRepository? repository,
    HistoryStore? historyStore,
  })  : _storageService = storageService ?? SecureStorageService(),
        _promptBuilder = promptBuilder ?? const PromptBuilder(),
        _repository = repository ?? GenerationRepository(),
        _historyStore = historyStore ?? HistoryStore();

  final SecureStorageService _storageService;
  final PromptBuilder _promptBuilder;
  final GenerationRepository _repository;
  final HistoryStore _historyStore;

  int _currentStepIndex = 0;
  String? _selectedImagePath;
  JewelryType _jewelryType = JewelryType.necklace;
  ModelGender _modelGender = ModelGender.woman;
  ModelAge _modelAge = ModelAge.twenties;
  SkinTone _skinTone = SkinTone.medium;
  HairPreset? _hairPreset;
  SettingType _settingType = SettingType.studio;
  LifestylePreset _lifestylePreset = LifestylePreset.beach;
  CompositionType _compositionType = CompositionType.closeUp;
  int _variations = 2;
  GenerationStatus _status = GenerationStatus.idle;
  String? _errorMessage;
  List<String> _generatedImagePaths = [];
  String? _generatedOutputDirectory;
  GenerationRequest? _lastRequest;
  PromptParts? _lastPrompt;

  int get currentStepIndex => _currentStepIndex;
  String? get selectedImagePath => _selectedImagePath;
  bool get hasSelectedImage => _selectedImagePath != null;
  JewelryType get jewelryType => _jewelryType;
  ModelGender get modelGender => _modelGender;
  ModelAge get modelAge => _modelAge;
  SkinTone get skinTone => _skinTone;
  HairPreset? get hairPreset => _hairPreset;
  SettingType get settingType => _settingType;
  LifestylePreset get lifestylePreset => _lifestylePreset;
  CompositionType get compositionType => _compositionType;
  int get variations => _variations;
  GenerationStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<String> get generatedImagePaths => List.unmodifiable(_generatedImagePaths);
  String? get generatedOutputDirectory => _generatedOutputDirectory;
  GenerationRequest? get lastRequest => _lastRequest;
  PromptParts? get lastPrompt => _lastPrompt;
  bool get isLoading => _status == GenerationStatus.loading;

  int _clampInt(int value, int min, int max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  void setSelectedImagePath(String path) {
    if (path == _selectedImagePath) {
      return;
    }
    _selectedImagePath = path;
    _generatedImagePaths = [];
    _generatedOutputDirectory = null;
    _status = GenerationStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedImage() {
    if (_selectedImagePath == null) {
      return;
    }
    _selectedImagePath = null;
    _generatedImagePaths = [];
    _generatedOutputDirectory = null;
    _status = GenerationStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void setJewelryType(JewelryType value) {
    if (value == _jewelryType) {
      return;
    }
    _jewelryType = value;
    notifyListeners();
  }

  void setModelGender(ModelGender value) {
    if (value == _modelGender) {
      return;
    }
    _modelGender = value;
    notifyListeners();
  }

  void setModelAge(ModelAge value) {
    if (value == _modelAge) {
      return;
    }
    _modelAge = value;
    notifyListeners();
  }

  void setSkinTone(SkinTone value) {
    if (value == _skinTone) {
      return;
    }
    _skinTone = value;
    notifyListeners();
  }

  void setHairPreset(HairPreset? value) {
    if (value == _hairPreset) {
      return;
    }
    _hairPreset = value;
    notifyListeners();
  }

  void setSettingType(SettingType value) {
    if (value == _settingType) {
      return;
    }
    _settingType = value;
    notifyListeners();
  }

  void setLifestylePreset(LifestylePreset value) {
    if (value == _lifestylePreset) {
      return;
    }
    _lifestylePreset = value;
    notifyListeners();
  }

  void setCompositionType(CompositionType value) {
    if (value == _compositionType) {
      return;
    }
    _compositionType = value;
    notifyListeners();
  }

  void setVariations(int value) {
    if (value == _variations) {
      return;
    }
    _variations = _clampInt(value, 2, 4);
    notifyListeners();
  }

  void setStepIndex(int index) {
    if (index == _currentStepIndex) {
      return;
    }
    _currentStepIndex = index;
    notifyListeners();
  }

  void advanceStep() {
    setStepIndex(_currentStepIndex + 1);
  }

  Future<void> generate() async {
    if (_selectedImagePath == null) {
      _setError('Please upload a jewelry photo first.');
      return;
    }
    if (isLoading) {
      return;
    }

    _status = GenerationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final apiKey = await _storageService.readApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      _setError('Add your API key in Settings to generate images.');
      return;
    }

    final request = GenerationRequest(
      imageFilePath: _selectedImagePath!,
      jewelryType: _jewelryType,
      modelGender: _modelGender,
      modelAge: _modelAge,
      skinTone: _skinTone,
      settingType: _settingType,
      lifestylePreset:
          _settingType == SettingType.lifestyle ? _lifestylePreset : null,
      compositionType: _compositionType,
      variations: _variations,
    );

    final prompt = _promptBuilder.build(request);
    _lastRequest = request;
    _lastPrompt = prompt;

    try {
      final paths = await _repository.generateAndSave(
        apiKey: apiKey,
        request: request,
        prompt: prompt,
      );

      _generatedImagePaths = paths;
      _generatedOutputDirectory =
          paths.isNotEmpty ? File(paths.first).parent.path : null;
      _status = GenerationStatus.success;
      _errorMessage = null;
      await _historyStore.addEntry(
        HistoryEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          requestSnapshot: request,
          outputPaths: paths,
        ),
      );
      notifyListeners();
    } on GenerationApiException catch (error) {
      _setError(_friendlyErrorMessage(error));
    } catch (_) {
      _setError('Something went wrong. Please try again.');
    }
  }

  void _setError(String message) {
    _status = GenerationStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  String _friendlyErrorMessage(GenerationApiException error) {
    switch (error.type) {
      case GenerationErrorType.network:
        return 'Network error. Check your connection and retry.';
      case GenerationErrorType.invalidKey:
        return 'Invalid API key. Please update it in Settings.';
      case GenerationErrorType.rateLimit:
        return 'Rate limit reached. Please wait and try again.';
      case GenerationErrorType.emptyResult:
        return error.message;
      case GenerationErrorType.unknown:
        return error.message.isNotEmpty
            ? error.message
            : 'Generation failed. Please try again.';
    }
  }

  void applyRequestSnapshot(GenerationRequest request) {
    _jewelryType = request.jewelryType;
    _modelGender = request.modelGender;
    _modelAge = request.modelAge;
    _skinTone = request.skinTone;
    _settingType = request.settingType;
    _lifestylePreset = request.lifestylePreset ?? LifestylePreset.beach;
    _compositionType = request.compositionType;
    _variations = _clampInt(request.variations, 2, 4);
    if (request.imageFilePath.isNotEmpty) {
      final file = File(request.imageFilePath);
      if (file.existsSync()) {
        _selectedImagePath = request.imageFilePath;
      }
    }
    _status = GenerationStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> regenerateLast() async {
    if (_lastRequest == null || _lastPrompt == null) {
      _setError('No previous request to regenerate yet.');
      return;
    }
    if (isLoading) {
      return;
    }
    _status = GenerationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final apiKey = await _storageService.readApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      _setError('Add your API key in Settings to generate images.');
      return;
    }

    try {
      final paths = await _repository.generateAndSave(
        apiKey: apiKey,
        request: _lastRequest!,
        prompt: _lastPrompt!,
      );

      _generatedImagePaths = paths;
      _generatedOutputDirectory =
          paths.isNotEmpty ? File(paths.first).parent.path : null;
      _status = GenerationStatus.success;
      _errorMessage = null;
      notifyListeners();
    } on GenerationApiException catch (error) {
      _setError(_friendlyErrorMessage(error));
    } catch (_) {
      _setError('Something went wrong. Please try again.');
    }
  }
}
