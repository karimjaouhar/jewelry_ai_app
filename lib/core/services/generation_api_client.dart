import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'package:jewelry_ai_app/features/generate/domain/generation_request.dart';
import 'package:jewelry_ai_app/features/generate/domain/prompt_builder.dart';

enum GenerationErrorType {
  network,
  invalidKey,
  rateLimit,
  emptyResult,
  unknown,
}

class GenerationApiException implements Exception {
  GenerationApiException(this.type, this.message);

  final GenerationErrorType type;
  final String message;

  @override
  String toString() => message;
}

abstract class GenerationApiClient {
  Future<List<Uint8List>> generateImages({
    required String apiKey,
    required GenerationRequest request,
    required PromptParts prompt,
  });
}

class DioGenerationApiClient implements GenerationApiClient {
  DioGenerationApiClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-3-pro-image-preview:generateContent';

  @override
  Future<List<Uint8List>> generateImages({
    required String apiKey,
    required GenerationRequest request,
    required PromptParts prompt,
  }) async {
    final imageBytes = await File(request.imageFilePath).readAsBytes();
    final imageData = base64Encode(imageBytes);
    final mimeType = _detectMimeType(request.imageFilePath);
    final promptText = _buildPromptText(prompt);

    final images = <Uint8List>[];
    for (var i = 0; i < request.variations; i++) {
      final result = await _generateOnce(
        apiKey: apiKey,
        imageData: imageData,
        mimeType: mimeType,
        promptText: promptText,
      );
      images.addAll(result);
    }

    return images;
  }

  Future<List<Uint8List>> _generateOnce({
    required String apiKey,
    required String imageData,
    required String mimeType,
    required String promptText,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': imageData,
                  }
                },
                {'text': promptText},
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['IMAGE'],
          },
        },
        options: Options(
          headers: {
            'x-goog-api-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data == null) {
        throw GenerationApiException(
          GenerationErrorType.emptyResult,
          'No response data received.',
        );
      }

      final images = _extractImages(data);
      if (images.isEmpty) {
        throw GenerationApiException(
          GenerationErrorType.emptyResult,
          'No images were returned. Please try again.',
        );
      }
      return images;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final message = _extractErrorMessage(error.response?.data) ??
          'Generation failed. Please try again.';
      if (statusCode == 401 || statusCode == 403) {
        throw GenerationApiException(GenerationErrorType.invalidKey, message);
      }
      if (statusCode == 429) {
        throw GenerationApiException(GenerationErrorType.rateLimit, message);
      }
      if (statusCode != null && statusCode >= 500) {
        throw GenerationApiException(GenerationErrorType.network, message);
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        throw GenerationApiException(GenerationErrorType.network, message);
      }
      throw GenerationApiException(GenerationErrorType.unknown, message);
    }
  }

  List<Uint8List> _extractImages(Map<String, dynamic> data) {
    final candidates = data['candidates'];
    if (candidates is! List) {
      return const [];
    }

    final images = <Uint8List>[];
    for (final candidate in candidates) {
      if (candidate is! Map<String, dynamic>) {
        continue;
      }
      final content = candidate['content'];
      if (content is! Map<String, dynamic>) {
        continue;
      }
      final parts = content['parts'];
      if (parts is! List) {
        continue;
      }
      for (final part in parts) {
        if (part is! Map<String, dynamic>) {
          continue;
        }
        final inlineData = part['inlineData'] ?? part['inline_data'];
        if (inlineData is! Map<String, dynamic>) {
          continue;
        }
        final dataValue = inlineData['data'];
        if (dataValue is String && dataValue.isNotEmpty) {
          images.add(base64Decode(dataValue));
        }
      }
    }

    return images;
  }

  String? _extractErrorMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    }
    return null;
  }

  String _buildPromptText(PromptParts parts) {
    final buffer = StringBuffer()..writeln(parts.system);
    buffer.writeln(parts.user);
    if (parts.negative != null && parts.negative!.trim().isNotEmpty) {
      buffer.writeln('Negative constraints: ${parts.negative}');
    }
    return buffer.toString().trim();
  }

  String _detectMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}

class FakeGenerationApiClient implements GenerationApiClient {
  const FakeGenerationApiClient({
    this.assetPath = 'assets/placeholder.png',
  });

  final String assetPath;

  @override
  Future<List<Uint8List>> generateImages({
    required String apiKey,
    required GenerationRequest request,
    required PromptParts prompt,
  }) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    return List<Uint8List>.generate(
      request.variations,
      (_) => bytes,
    );
  }
}
