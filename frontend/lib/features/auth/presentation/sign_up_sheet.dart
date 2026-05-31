import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/haul_button.dart';
import '../../../shared/providers/auth_provider.dart';

class SignUpSheet extends ConsumerStatefulWidget {
  const SignUpSheet({super.key});

  @override
  ConsumerState<SignUpSheet> createState() => _SignUpSheetState();
}

class _SignUpSheetState extends ConsumerState<SignUpSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Fields cannot be empty.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() => _errorMessage = null);

    await ref.read(authNotifierProvider.notifier).signUp(email, password);

    if (mounted) {
      final authState = ref.read(authNotifierProvider).valueOrNull;
      if (authState?.status == AuthState.authenticated) {
        context.go('/preferences');
      } else if (ref.read(authNotifierProvider).hasError) {
        setState(() => _errorMessage = ref.read(authNotifierProvider).error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: const BoxDecoration(
            color: AppColors.warmWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXL)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.pebble,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Create your account', style: AppTypography.displayMD.copyWith(color: AppColors.ink)),
              const SizedBox(height: AppSpacing.xl),
              _buildField('Email', _emailController, obscureText: false),
              const SizedBox(height: AppSpacing.md),
              _buildField('Password', _passwordController, obscureText: true),
              const SizedBox(height: AppSpacing.md),
              _buildField('Confirm Password', _confirmPasswordController, obscureText: true),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_errorMessage!, style: AppTypography.bodySM.copyWith(color: AppColors.errorCrimson)),
              ],
              const SizedBox(height: AppSpacing.xxl),
              HaulButton(
                label: 'CREATE ACCOUNT',
                trailingArrow: true,
                isFullWidth: true,
                isLoading: isLoading,
                onPressed: _signUp,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodyMD.copyWith(color: AppColors.stone),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.pebble),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.signal, width: 2),
        ),
      ),
    );
  }
}
