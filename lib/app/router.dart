import 'package:flutter/material.dart';
import 'package:jewelry_ai_app/features/generate/ui/generate_flow_screen.dart';
import 'package:jewelry_ai_app/features/history/ui/history_screen.dart';
import 'package:jewelry_ai_app/features/settings/ui/api_key_screen.dart';

class AppRouter {
  static const String root = '/';
  static const String settings = '/settings';
  static const String history = '/history';

  static Map<String, WidgetBuilder> get routes {
    return {
      root: (_) => const GenerateFlowScreen(),
      settings: (_) => const ApiKeyScreen(),
      history: (_) => const HistoryScreen(),
    };
  }
}
