import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:jewelry_ai_app/features/generate/domain/composition_type.dart';
import 'package:jewelry_ai_app/features/generate/domain/generation_request.dart';
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
  final List<String> _selectedImagePaths = [];
  JewelryType? _jewelryType;
  ModelGender _modelGender = ModelGender.woman;
  ModelAge _modelAge = ModelAge.twenties;
  SkinTone _skinTone = SkinTone.light;
  SettingType _settingType = SettingType.studioNatural;
  LifestylePreset _lifestylePreset = LifestylePreset.beach;
  CompositionType _compositionType = CompositionType.closeUp;
  int _variations = 1;
  GenerationStatus _status = GenerationStatus.idle;
  String? _errorMessage;
  List<String> _generatedImagePaths = [];
  String? _generatedOutputDirectory;
  GenerationRequest? _lastRequest;
  PromptParts? _lastPrompt;

  int get currentStepIndex => _currentStepIndex;
  List<String> get selectedImagePaths =>
      List.unmodifiable(_selectedImagePaths);
  bool get hasSelectedImages => _selectedImagePaths.isNotEmpty;
  JewelryType? get jewelryType => _jewelryType;
  ModelGender get modelGender => _modelGender;
  ModelAge get modelAge => _modelAge;
  SkinTone get skinTone => _skinTone;
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
    _selectedImagePaths
      ..clear()
      ..add(path);
    _generatedImagePaths = [];
    _generatedOutputDirectory = null;
    _status = GenerationStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void addSelectedImagePath(String path) {
    if (_selectedImagePaths.contains(path)) {
      return;
    }
    _selectedImagePaths.add(path);
    _generatedImagePaths = [];
    _generatedOutputDirectory = null;
    _status = GenerationStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void addSelectedImagePaths(List<String> paths) {
    final filtered = paths.where((path) => path.isNotEmpty).toList();
    if (filtered.isEmpty) {
      return;
    }
    final added = filtered.where((path) => !_selectedImagePaths.contains(path));
    _selectedImagePaths.addAll(added);
    _generatedImagePaths = [];
    _generatedOutputDirectory = null;
    _status = GenerationStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void removeSelectedImageAt(int index) {
    if (index < 0 || index >= _selectedImagePaths.length) {
      return;
    }
    _selectedImagePaths.removeAt(index);
    _generatedImagePaths = [];
    _generatedOutputDirectory = null;
    _status = GenerationStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedImages() {
    if (_selectedImagePaths.isEmpty) {
      return;
    }
    _selectedImagePaths.clear();
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
    _skinTone = _defaultSkinToneFor(value);
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
    final normalized = _clampInt(value, 1, 1);
    if (normalized == _variations) {
      return;
    }
    _variations = normalized;
    notifyListeners();
  }

  void setStepIndex(int index) {
    final normalized = _clampInt(index, 0, 4);
    if (normalized == _currentStepIndex) {
      return;
    }
    _currentStepIndex = normalized;
    notifyListeners();
  }

  void advanceStep() {
    setStepIndex(_currentStepIndex + 1);
  }

  Future<void> generate() async {
    if (_selectedImagePaths.isEmpty) {
      _setError('Please upload at least one jewelry photo first.');
      return;
    }
    if (_jewelryType == null) {
      _setError('Select a jewelry type to continue.');
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
      imageFilePaths: List.unmodifiable(_selectedImagePaths),
      jewelryType: _jewelryType!,
      modelGender: _modelGender,
      modelAge: _modelAge,
      skinTone: _skinTone,
      settingType: _settingType,
      lifestylePreset:
          _settingType == SettingType.lifestyle ? _lifestylePreset : null,
      compositionType: _compositionType,
      variations: 1,
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
    _modelGender = request.modelGender == ModelGender.neutral
        ? ModelGender.woman
        : request.modelGender;
    _modelAge = request.modelAge;
    _skinTone = request.skinTone;
    _settingType = request.settingType;
    _lifestylePreset = request.lifestylePreset ?? LifestylePreset.beach;
    _compositionType = request.compositionType;
    _variations = 1;
    _selectedImagePaths.clear();
    for (final path in request.imageFilePaths) {
      if (path.isEmpty) {
        continue;
      }
      final file = File(path);
      if (file.existsSync()) {
        _selectedImagePaths.add(path);
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

  SkinTone _defaultSkinToneFor(ModelGender gender) {
    switch (gender) {
      case ModelGender.woman:
        return SkinTone.light;
      case ModelGender.man:
        return SkinTone.tanned;
      case ModelGender.neutral:
        return SkinTone.tanned;
    }
  }
}
