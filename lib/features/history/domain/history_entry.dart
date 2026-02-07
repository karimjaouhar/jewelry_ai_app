import 'package:jewelry_ai_app/features/generate/domain/generation_request.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.createdAt,
    required this.requestSnapshot,
    required this.outputPaths,
  });

  final String id;
  final DateTime createdAt;
  final GenerationRequest requestSnapshot;
  final List<String> outputPaths;

  String? get thumbnailPath =>
      outputPaths.isNotEmpty ? outputPaths.first : null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'requestSnapshot': requestSnapshot.toMap(),
      'outputPaths': outputPaths,
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? 0,
      ),
      requestSnapshot: GenerationRequest.fromMap(
        Map<String, dynamic>.from(
          map['requestSnapshot'] as Map? ?? <String, dynamic>{},
        ),
      ),
      outputPaths: (map['outputPaths'] as List?)
              ?.map((value) => value.toString())
              .toList() ??
          <String>[],
    );
  }
}
