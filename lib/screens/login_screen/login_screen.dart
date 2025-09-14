import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/api_service.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _checkingToken = true;
  String _selectedLocale = 'en';

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = await ApiService.getToken();
    if (token != null) {
      ApiService.dio.options.headers['Authorization'] = 'Bearer $token';
      if (mounted) context.go('/');
    } else {
      setState(() => _checkingToken = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingToken) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tr("login.title"),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: tr("login.email"),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF295D6B)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF295D6B), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr("login.password"),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF295D6B)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF295D6B), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF295D6B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          ref.read(adminProvider.notifier).reset();
                          await authNotifier.login(
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                          );
                          final user = ref.read(authProvider).user;
                          if (user != null) {
                            await ref.read(adminProvider.notifier).init();
                            context.go('/');
                          }
                        },
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          tr("login.login"),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 15),
              // Row with language dropdown and register
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: Color(0xFF295D6B)),
                      const SizedBox(width: 4),
                      DropdownButton<String>(
                        value: _selectedLocale,
                        items: [
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('register.english'.tr()),
                          ),
                          DropdownMenuItem(
                            value: 'km',
                            child: Text('register.khmer'.tr()),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLocale = val);
                            context.setLocale(Locale(val));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 40),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text(
                      tr("login.register"),
                      style: const TextStyle(
                        color: Color(0xFF295D6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Error message
              if (authState.error != null) ...[
                const SizedBox(height: 20),
                Text(
                  authState.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
