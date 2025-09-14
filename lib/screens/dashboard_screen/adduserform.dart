import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/register_provider.dart';
// import '../../providers/user_register_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class AddEditUserForm extends ConsumerStatefulWidget {
  final bool useUserRegister; // true → user, false → admin
  const AddEditUserForm({super.key, this.useUserRegister = false});

  @override
  ConsumerState<AddEditUserForm> createState() => _AddEditUserFormState();
}

class _AddEditUserFormState extends ConsumerState<AddEditUserForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = widget.useUserRegister
        ? ref.watch(userRegisterProvider)
        : ref.watch(registerProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr("register.title"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: tr("register.name")),
                    validator: (v) =>
                        v!.isEmpty ? tr("register.enter_name") : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: tr("register.email"),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? tr("register.enter_email") : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: tr("register.password"),
                    ),
                    validator: (v) =>
                        v!.length < 6 ? tr("register.min_6_chars") : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _zoneController,
                    decoration: InputDecoration(
                      labelText: tr("register.zone_optional"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF295D6B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: state.loading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;

                              if (widget.useUserRegister) {
                                final userNotifier =
                                    ref.read(userRegisterProvider.notifier)
                                        as UserRegisterNotifier;
                                await userNotifier.registerUser(
                                  name: _nameController.text,
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                  zone: _zoneController.text.isEmpty
                                      ? null
                                      : _zoneController.text,
                                );
                              } else {
                                final adminNotifier =
                                    ref.read(registerProvider.notifier)
                                        as RegisterNotifier;
                                await adminNotifier.registerUser(
                                  name: _nameController.text,
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                  zone: _zoneController.text.isEmpty
                                      ? null
                                      : _zoneController.text,
                                );
                              }

                              if (state.message != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(state.message!)),
                                );
                              }
                              Navigator.pop(context);
                            },
                      child: state.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.useUserRegister
                                  ? tr("register.add_user")
                                  : tr("register.add_admin"),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
