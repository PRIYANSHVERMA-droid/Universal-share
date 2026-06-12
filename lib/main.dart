import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/network/cert_manager.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/history_repository.dart';

void main() async {
  // Ensure native bindings are initialized for SharedPreferences & PathProvider
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load SharedPreferences settings instance
  final prefs = await SharedPreferences.getInstance();

  // 2. Pre-generate / load self-signed TLS certificates for local encryption
  final certManager = CertManager();
  await certManager.init();

  // 3. Load Transfer History logs database from JSON
  final historyRepository = HistoryRepository();
  await historyRepository.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        certManagerProvider.overrideWithValue(certManager),
        historyRepositoryProvider.overrideWithValue(historyRepository),
      ],
      child: const MyApp(),
    ),
  );
}
