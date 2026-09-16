import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/core/constants/app_constants.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:topar_115/features/auth/presentation/controllers/auth_controller.dart';
import 'package:topar_115/shared/widgets/fifteen_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    HapticUtils.light();
    FocusScope.of(context).unfocus();

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              Gap(10),
              Expanded(
                child: Text('Haýyş, adyňyzy, familiýaňyzy we telefon belgiňizi giriziň!'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final fullPhone = phone.startsWith('+993') || phone.startsWith('993') ? phone : '+993 $phone';

    await ref.read(authProvider.notifier).loginByFields(
          firstName: firstName,
          lastName: lastName,
          phone: fullPhone,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Header Icon Badge ──────────────────────────────────────────
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🎓',
                      style: TextStyle(fontSize: 44),
                    ),
                  ),
                ),
                const Gap(20),

                // ── App Title & Subtitle ─────────────────────────────────────
                Text(
                  'Kursdaşlar',
                  style: tt.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const Gap(6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${AppConstants.className} • Ulanyjy Giriş',
                    style: tt.labelMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Gap(28),

                // ── Card Container with Form ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoş geldiňiz! 👋',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        'Topara girmek üçin maglumatlaryňyzy giriziň:',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const Gap(20),

                      // First Name Field
                      FifteenTextField(
                        controller: _firstNameCtrl,
                        focusNode: _firstNameFocus,
                        label: 'Adyňyz',
                        hintText: 'Adyňyzy giriziň',
                        icon: Icons.person_outline_rounded,
                        onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                      ),
                      const Gap(14),

                      // Last Name Field
                      FifteenTextField(
                        controller: _lastNameCtrl,
                        focusNode: _lastNameFocus,
                        label: 'Familiýaňyz',
                        hintText: 'Familiýaňyzy giriziň',
                        icon: Icons.badge_outlined,
                        onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                      ),
                      const Gap(14),

                      // Phone Field
                      FifteenTextField(
                        controller: _phoneCtrl,
                        focusNode: _phoneFocus,
                        label: 'Telefon belgisi',
                        hintText: '61 76 28 19',
                        prefixText: '+993 ',
                        keyboardType: TextInputType.phone,
                        icon: Icons.phone_android_rounded,
                        onChanged: (_) => ref.read(authProvider.notifier).clearError(),
                      ),
                      const Gap(20),

                      // Error message alert if any
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withAlpha(180),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cs.error.withAlpha(100)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
                              const Gap(10),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(20),
                      ],

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _submitLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: cs.primary.withAlpha(100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Ulgama gir',
                                      style: tt.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Gap(8),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
