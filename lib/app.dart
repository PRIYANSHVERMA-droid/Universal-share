import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/discovery/presentation/discovery_screen.dart';
import 'features/settings/application/settings_providers.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch user's theme selection (defaults to dark theme)
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Universal Share',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const DiscoveryScreen(),
    );
  }
}
