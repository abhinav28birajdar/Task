import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../presentation/splash/splash_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/auth/sign_in_screen.dart';
import '../../presentation/auth/sign_up_screen.dart';
import '../../presentation/auth/modern_sign_in_screen.dart';
import '../../presentation/auth/modern_sign_up_screen.dart';
import '../../presentation/auth/forgot_password_screen.dart';
import '../../presentation/main_wrapper/main_wrapper.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/search/search_screen.dart';
import '../../presentation/schedule/schedule_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/task_detail/task_detail_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/settings/account/account_screen.dart';
import '../../presentation/settings/account/edit_profile_screen.dart';
import '../../presentation/settings/account/change_password_screen.dart';
import '../../presentation/settings/privacy/privacy_security_screen.dart';
import '../../presentation/settings/notifications/notification_settings_screen.dart';
import '../../presentation/settings/appearance/appearance_screen.dart';
import '../../presentation/notes/notes_screen.dart';
import '../../presentation/notes/note_editor_screen.dart';
import '../../presentation/analytics/analytics_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final loggingIn = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (isSplash || isOnboarding) return null;
      if (!isLoggedIn && !loggingIn) return '/auth/signin';
      if (isLoggedIn && loggingIn) return '/home';
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Page not found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? 'Unknown error'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
          path: '/auth/signin', builder: (_, __) => const ModernSignInScreen()),
      GoRoute(
          path: '/auth/signup', builder: (_, __) => const ModernSignUpScreen()),
      GoRoute(
          path: '/auth/forgot',
          builder: (_, __) => const ForgotPasswordScreen()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => MainWrapper(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(
              path: '/schedule', builder: (_, __) => const ScheduleScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/notes', builder: (_, __) => const NotesScreen()),
          GoRoute(
              path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
        ],
      ),
      GoRoute(
          path: '/task/:id',
          builder: (_, state) =>
              TaskDetailScreen(taskId: state.pathParameters['id']!)),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/settings/account', builder: (_, __) => const AccountScreen()),
      GoRoute(
          path: '/settings/account/edit',
          builder: (_, __) => const EditProfileScreen()),
      GoRoute(
          path: '/settings/account/password',
          builder: (_, __) => const ChangePasswordScreen()),
      GoRoute(
          path: '/settings/privacy',
          builder: (_, __) => const PrivacySecurityScreen()),
      GoRoute(
          path: '/settings/notifications',
          builder: (_, __) => const NotificationSettingsScreen()),
      GoRoute(
          path: '/settings/appearance',
          builder: (_, __) => const AppearanceScreen()),
      GoRoute(
          path: '/note-editor',
          builder: (_, state) =>
              NoteEditorScreen(note: state.extra as dynamic)),
      GoRoute(
          path: '/note-detail/:id',
          builder: (_, state) =>
              NoteEditorScreen(note: state.extra as dynamic)),
    ],
  );
}
