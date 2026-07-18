// lib/app/routes.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/injection/dependency_injection.dart';
import 'package:ai_insurance_advisor/presentation/bloc/auth/auth_bloc.dart';
import 'package:ai_insurance_advisor/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/splash_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/auth/login_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/auth/register_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/home/home_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/home/dashboard_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/chat/chat_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/profile/profile_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/products/products_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/products/product_detail_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/declaration/declaration_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/conseil/conseil_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/prevention/prevention_screen.dart';

/// Convertit un Stream (ici le stream de AuthBloc) en Listenable pour que
/// GoRouter réévalue `redirect` à chaque changement d'état d'authentification,
/// et pas seulement lors d'une navigation explicite.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: GoRouterRefreshStream(getIt<AuthBloc>().stream),
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isLoggedIn = authState is AuthAuthenticated;
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final isAuthRoute = state.matchedLocation.contains('/auth');
      final isHomeRoute = state.matchedLocation == '/' || state.matchedLocation == '/home';
      final isSplashRoute = state.matchedLocation == '/splash';

      if (isOnboardingRoute || isSplashRoute) {
        return null;
      }

      if (!isLoggedIn && !isAuthRoute && !isHomeRoute) {
        return '/';
      }

      if (isLoggedIn && (isAuthRoute || isHomeRoute || state.matchedLocation == '/')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // ─── Onboarding ──────────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ─── Splash Screen ────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ─── Page d'accueil publique ──────────────────────────────────────────
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ─── Authentification ────────────────────────────────────────────────
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ─── Dashboard ──────────────────────────────────────────────────────
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // ─── Sous-routes ──────────────────────────────────────────────────────
      GoRoute(
        path: '/dashboard/declaration',
        name: 'declaration',
        builder: (context, state) => const DeclarationScreen(),
      ),
      GoRoute(
        path: '/dashboard/conseil',
        name: 'conseil',
        builder: (context, state) => const ConseilScreen(),
      ),
      GoRoute(
        path: '/dashboard/prevention',
        name: 'prevention',
        builder: (context, state) => const PreventionScreen(),
      ),
      GoRoute(
        path: '/dashboard/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/dashboard/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/dashboard/products',
        name: 'products',
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/dashboard/product/:id',
        name: 'product_detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
    ],
  );
}