import 'package:go_router/go_router.dart';
import 'package:soundshare/features/splash/splash_screen.dart';
import 'package:soundshare/features/permissions/permission_screen.dart';
import 'package:soundshare/features/share/presentation/share_screen.dart';
import 'package:soundshare/features/settings/presentation/settings_screen.dart';
import 'package:soundshare/app/navigation/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Splash
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // Permissions onboarding
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionScreen(),
    ),

    // Main shell with bottom nav
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/share',
              builder: (context, state) => const ShareScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
