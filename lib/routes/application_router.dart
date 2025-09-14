import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen/login_screen.dart';
import '../screens/home_screen/home_screen.dart';
import '../../screens/collector_screen/collector_screen.dart';
import '../../screens/admin_screen/admin_screen.dart';
import '../../screens/reports_screen/reports_screen.dart';
import '../../screens/register_screen/register_screen.dart';
import '../screens/dashboard_screen/dashboard_screen.dart';

class ApplicationRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login', // start from login
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/collector',
        builder: (context, state) => const CollectorScreen(),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Route not found'))),
  );
}
