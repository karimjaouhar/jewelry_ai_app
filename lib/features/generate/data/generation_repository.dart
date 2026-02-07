import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'package:jewelry_ai_app/core/services/generation_api_client.dart';
import 'package:jewelry_ai_app/features/generate/domain/generation_request.dart';
import 'package:jewelry_ai_app/features/generate/domain/prompt_builder.dart';

class GenerationRepository {
  GenerationRepository({GenerationApiClient? apiClient})
      : _apiClient = apiClient ?? DioGenerationApiClient();

  final GenerationApiClient _apiClient;

  Future<List<String>> generateAndSave({
    required String apiKey,
    required GenerationRequest request,
    required PromptParts prompt,
  }) async {
    final images = await _apiClient.generateImages(
      apiKey: apiKey,
      request: request,
      prompt: prompt,
    );

    if (images.isEmpty) {
      throw GenerationApiException(
        GenerationErrorType.emptyResult,
        'No images were returned. Please try again.',
      );
    }

    return _saveImages(images);
  }

  Future<List<String>> _saveImages(List<Uint8List> images) async {
    final baseDir = await _resolveBaseDirectory();
    final outputDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}JewelryAI',
    );
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final timestampMs = DateTime.now().millisecondsSinceEpoch;
    final savedPaths = <String>[];

    for (var i = 0; i < images.length; i++) {
      final file = File(
        '${outputDir.path}${Platform.pathSeparator}generation_${timestampMs}_${i + 1}.png',
      );
      await file.writeAsBytes(images[i], flush: true);
      savedPaths.add(file.path);
    }

    return savedPaths;
  }

  Future<Directory> _resolveBaseDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir;
      }
    }
    return getApplicationDocumentsDirectory();
  }
}
