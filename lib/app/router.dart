import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/browser/courses_screen.dart';
import '../features/browser/departments_screen.dart';
import '../features/browser/semesters_screen.dart';
import '../features/course/course_detail_screen.dart';
import '../features/notes/note_detail_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/study_plan/study_plan_screen.dart';

/// A [Listenable] that pokes GoRouter whenever auth/onboarding state changes,
/// so the redirect guard re-runs.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(onboardingSeenProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/splash') return null; // splash routes onward itself

      final seenOnboarding = ref.read(onboardingSeenProvider);
      final loggedIn = ref.read(authControllerProvider) != null;

      final onOnboarding = loc == '/onboarding';
      final onAuth = loc == '/login' || loc == '/signup';

      if (!seenOnboarding) {
        return onOnboarding ? null : '/onboarding';
      }
      if (!loggedIn) {
        return onAuth ? null : '/login';
      }
      if (onAuth || onOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeShell()),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: '/university/:id',
        builder: (_, s) =>
            DepartmentsScreen(universityId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/department/:id',
        builder: (_, s) =>
            SemestersScreen(departmentId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/semester/:deptId/:sem',
        builder: (_, s) => CoursesScreen(
          departmentId: s.pathParameters['deptId']!,
          semester: int.tryParse(s.pathParameters['sem'] ?? '1') ?? 1,
        ),
      ),
      GoRoute(
        path: '/course/:id',
        builder: (_, s) =>
            CourseDetailScreen(courseId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/note/:id',
        builder: (_, s) => NoteDetailScreen(noteId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/study-plan/:courseId',
        builder: (_, s) =>
            StudyPlanScreen(courseId: s.pathParameters['courseId']!),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text(
          kDebugMode ? 'Route error: ${state.error}' : 'Something went wrong',
        ),
      ),
    ),
  );
});
