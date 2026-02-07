import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:jewelry_ai_app/features/history/domain/history_entry.dart';

class HistoryStore {
  static const String _key = 'generation_history';
  static const int _maxEntries = 25;

  Future<List<HistoryEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    final entries = raw
        .map((value) => HistoryEntry.fromMap(
              jsonDecode(value) as Map<String, dynamic>,
            ))
        .toList();
    return entries;
  }

  Future<void> addEntry(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];
    raw.insert(0, jsonEncode(entry.toMap()));
    if (raw.length > _maxEntries) {
      raw.removeRange(_maxEntries, raw.length);
    }
    await prefs.setStringList(_key, raw);
  }
}
