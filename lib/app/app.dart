import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'theme.dart';
import 'theme_controller.dart';
import 'package:jewelry_ai_app/features/generate/state/generation_flow_controller.dart';

class JewelryApp extends StatelessWidget {
  const JewelryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GenerationFlowController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, controller, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: controller.themeMode,
            initialRoute: AppRouter.root,
            routes: AppRouter.routes,
          );
        },
      ),
    );
  }
}
