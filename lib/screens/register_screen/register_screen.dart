import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  String _selectedLocale = 'en';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "register.title".tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "register.name".tr(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'register.enter_name'.tr() : null,
                ),
                const SizedBox(height: 20),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "register.email".tr(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? 'register.enter_email'.tr() : null,
                ),
                const SizedBox(height: 20),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "register.password".tr(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.length < 6 ? 'register.min_6_chars'.tr() : null,
                ),
                const SizedBox(height: 20),

                // Zone (optional)
                TextFormField(
                  controller: _zoneController,
                  decoration: InputDecoration(
                    labelText: "register.zone_optional".tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Register button
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
                            if (!_formKey.currentState!.validate()) return;
                            await authNotifier.register({
                              'name': _nameController.text,
                              'email': _emailController.text,
                              'password': _passwordController.text,
                              'zone': _zoneController.text,
                            });
                            if (!mounted) return;
                            if (authState.user != null) {
                              context.go('/login');
                            } else if (authState.error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(authState.error!)),
                              );
                            }
                          },
                    child: authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "register.title".tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 15),

                // Language + Back to Login row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Language dropdown with icon
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

                    // Back to login
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        "register.back_to_login".tr(),
                        style: const TextStyle(
                          color: Color(0xFF295D6B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
