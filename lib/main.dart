import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'app/router.dart';
import 'app/theme.dart';
import 'data/app_data.dart';
import 'data/local_storage.dart';
import 'data/providers.dart';
import 'data/seed_data.dart';
import 'data/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to the cloud backend (multi-user sync).
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use — using the legacy JWT anon key.
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // Load persistence + the shipped catalog before the first frame so the
  // rest of the app can stay synchronous.
  final storage = await LocalStorage.open();
  final seed = await AppSeed.load();

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        appSeedProvider.overrideWithValue(seed),
      ],
      child: const ExamPrepApp(),
    ),
  );
}

class ExamPrepApp extends ConsumerWidget {
  const ExamPrepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ExamPrep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
