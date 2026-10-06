import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_finance_intelligence/features/accounts/presentation/screens/account_detail_screen.dart';
import 'package:personal_finance_intelligence/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:personal_finance_intelligence/features/ai/presentation/screens/ai_chat_screen.dart';
import 'package:personal_finance_intelligence/features/ai/presentation/screens/ai_screen.dart';
import 'package:personal_finance_intelligence/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:personal_finance_intelligence/features/auth/data/auth_provider.dart';
import 'package:personal_finance_intelligence/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_finance_intelligence/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:personal_finance_intelligence/features/auth/presentation/screens/register_screen.dart';
import 'package:personal_finance_intelligence/features/auth/presentation/screens/splash_screen.dart';
import 'package:personal_finance_intelligence/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:personal_finance_intelligence/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_finance_intelligence/features/imports/presentation/screens/import_screen.dart';
import 'package:personal_finance_intelligence/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:personal_finance_intelligence/features/recurring/presentation/screens/recurring_screen.dart';
import 'package:personal_finance_intelligence/features/reports/presentation/screens/monthly_report_screen.dart';
import 'package:personal_finance_intelligence/features/settings/presentation/screens/settings_screen.dart';
import 'package:personal_finance_intelligence/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:personal_finance_intelligence/features/transactions/presentation/screens/transaction_detail_screen.dart';
import 'package:personal_finance_intelligence/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:personal_finance_intelligence/shared/widgets/shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      final isPublic = loc == '/' ||
          loc.startsWith('/login') ||
          loc.startsWith('/register') ||
          loc.startsWith('/onboarding');

      if (isLoading) return null;
      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && (loc == '/' || loc.startsWith('/login') || loc.startsWith('/register'))) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (_, __) => const TransactionsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, state) => AddTransactionScreen(
                  initialType: state.uri.queryParameters['type'],
                ),
              ),
              GoRoute(
                path: 'transfer',
                builder: (_, __) => const AddTransactionScreen(initialType: 'transfer'),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => TransactionDetailScreen(
                  transactionId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/accounts',
            builder: (_, __) => const AccountsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => AccountDetailScreen(
                  accountId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(path: '/budgets', builder: (_, __) => const BudgetsScreen()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(
            path: '/ai',
            builder: (_, __) => const AIScreen(),
            routes: [
              GoRoute(
                path: ':conversationId',
                builder: (_, state) => AIChatScreen(
                  conversationId: state.pathParameters['conversationId']!,
                ),
              ),
            ],
          ),
          GoRoute(path: '/recurring', builder: (_, __) => const RecurringScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/imports', builder: (_, __) => const ImportScreen()),
          GoRoute(path: '/reports', builder: (_, __) => const MonthlyReportScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}',
            style: const TextStyle(color: Colors.white)),
      ),
    ),
  );
});
