import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:examprep/core/icons.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/app_data.dart';
import '../../data/providers.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _degree = TextEditingController();

  String? _universityId;
  String? _campus;
  int _semester = 1;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _degree.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_universityId == null) {
      AppSnack.show(context, 'Please select your university', success: false);
      return;
    }
    if (_campus == null) {
      AppSnack.show(context, 'Please select your campus', success: false);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(authControllerProvider.notifier).signUp(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          universityId: _universityId!,
          campus: _campus!,
          degreeProgram: _degree.text,
          semester: _semester,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.ok) {
      context.go('/');
    } else {
      AppSnack.show(context, result.error!, success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final universities = ref.watch(appDataProvider).universities;
    final selectedUni = universities.where((u) => u.id == _universityId);
    final campuses = selectedUni.isEmpty ? <String>[] : selectedUni.first.campuses;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(_name, 'Full name', LucideIcons.user,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null),
                    const SizedBox(height: 14),
                    _field(_email, 'Email', LucideIcons.mail,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter a valid email'
                            : null),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(LucideIcons.lock, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                              size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 4) ? 'Min 4 characters' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _universityId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'University',
                        prefixIcon: Icon(LucideIcons.building2, size: 20),
                      ),
                      items: universities
                          .map((u) => DropdownMenuItem(
                                value: u.id,
                                child: Text(u.shortName,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _universityId = v;
                        _campus = null;
                      }),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _campus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: _universityId == null
                            ? 'Select university first'
                            : 'Campus',
                        prefixIcon: const Icon(LucideIcons.mapPin, size: 20),
                      ),
                      items: campuses
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: campuses.isEmpty
                          ? null
                          : (v) => setState(() => _campus = v),
                    ),
                    const SizedBox(height: 14),
                    _field(_degree, 'Degree program (e.g. BS CS)',
                        LucideIcons.bookOpen,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: _semester,
                      decoration: const InputDecoration(
                        hintText: 'Semester',
                        prefixIcon: Icon(LucideIcons.calendar, size: 20),
                      ),
                      items: List.generate(8, (i) => i + 1)
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text('Semester $s')))
                          .toList(),
                      onChanged: (v) => setState(() => _semester = v ?? 1),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Create Account',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: validator,
    );
  }
}
