import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../models/app_user.dart';
import 'app_data.dart';
import 'supabase_repo.dart';

/// Result of an auth attempt — ok, or a human-readable error.
class AuthResult {
  final bool ok;
  final String? error;
  const AuthResult.ok() : ok = true, error = null;
  const AuthResult.fail(this.error) : ok = false;
}

/// Auth backed by Supabase. The profile is cached in Hive so the router can
/// resolve login state synchronously on startup.
class AuthController extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    if (!supabaseRepo.hasSession) return null;
    final cached = ref.read(localStorageProvider).currentUser;
    if (cached != null) return cached;
    final u = Supabase.instance.client.auth.currentUser;
    return AppUser(
      id: u?.id ?? '',
      name: '',
      email: u?.email ?? '',
      universityId: '',
      campus: '',
      degreeProgram: '',
      semester: 1,
    );
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final user = await supabaseRepo.signIn(email.trim(), password);
      await ref.read(localStorageProvider).setCurrentUser(user);
      state = user;
      await ref.read(appDataProvider.notifier).sync();
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(e.message);
    } catch (_) {
      return const AuthResult.fail('Login failed. Check your connection.');
    }
  }

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
    required String universityId,
    required String campus,
    required String degreeProgram,
    required int semester,
  }) async {
    try {
      final user = await supabaseRepo.signUp(
        name: name.trim(),
        email: email.trim(),
        password: password,
        universityId: universityId,
        campus: campus,
        degree: degreeProgram.trim(),
        semester: semester,
      );
      await ref.read(localStorageProvider).setCurrentUser(user);
      state = user;
      await ref.read(appDataProvider.notifier).sync();
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.fail(e.message);
    } catch (_) {
      return const AuthResult.fail('Sign up failed. Check your connection.');
    }
  }

  /// Refreshes the profile from the server (e.g. on app start).
  Future<void> refreshProfile() async {
    if (!supabaseRepo.hasSession) return;
    try {
      final user = await supabaseRepo.currentProfile();
      if (user != null) {
        await ref.read(localStorageProvider).setCurrentUser(user);
        state = user;
      }
    } catch (_) {/* keep cached */}
  }

  Future<void> updateProfile(AppUser updated) async {
    await supabaseRepo.updateProfile(updated);
    await ref.read(localStorageProvider).setCurrentUser(updated);
    state = updated;
  }

  Future<void> logout() async {
    await supabaseRepo.signOut();
    await ref.read(localStorageProvider).setCurrentUser(null);
    state = null;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AppUser?>(AuthController.new);

/// Whether onboarding has been completed.
class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(localStorageProvider).onboardingSeen;

  Future<void> complete() async {
    await ref.read(localStorageProvider).setOnboardingSeen(true);
    state = true;
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);

/// App theme mode, persisted.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final raw = ref.watch(localStorageProvider).themeMode;
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    await ref.read(localStorageProvider).setThemeMode(mode.name);
    state = mode;
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
