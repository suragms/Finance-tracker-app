import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api_config.dart';
import 'core/theme/app_theme.dart';
import 'features/accounts/application/account_providers.dart';
import 'features/accounts/presentation/account_setup_screen.dart';
import 'features/auth/application/session_notifier.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/shell/presentation/app_shell.dart';
import 'features/sms/sms_service.dart';

class MoneyflowApp extends ConsumerStatefulWidget {
  const MoneyflowApp({super.key});

  @override
  ConsumerState<MoneyflowApp> createState() => _MoneyflowAppState();
}

class _MoneyflowAppState extends ConsumerState<MoneyflowApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionProvider.notifier).hydrate();
      SmsService.initialize(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(sessionProvider);
    final showShell = kNoApiMode || loggedIn;
    return MaterialApp(
      title: 'MoneyFlow AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppDarkTheme(),
      themeMode: ThemeMode.dark,
      home: showShell ? const AuthGuard() : const LoginScreen(),
    );
  }
}

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kNoApiMode) return const AppShell();

    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
      data: (ledger) {
        if (ledger.accounts.isEmpty) {
          return const AccountSetupScreen();
        }
        return const AppShell();
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0B0F1A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      ),
      error: (e, __) => Scaffold(
        backgroundColor: const Color(0xFF0B0F1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load accounts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(accountsProvider),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
