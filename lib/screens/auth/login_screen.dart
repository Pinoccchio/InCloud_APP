import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dialogs/success_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;


  void _handleLogin() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final email = formData['email'] as String;
      final password = formData['password'] as String;

      await ref.read(authProvider.notifier).signIn(
        email: email,
        password: password,
      );
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goToSignup() {
    context.go('/signup');
  }

  void _handleForgotPassword() {
    // TODO: Implement forgot password functionality
    _showErrorSnackbar('Forgot password feature coming soon!');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    // Listen to auth state changes for errors and success messages
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (mounted) {
        // Handle success messages with dialogs for special cases
        if (next.successMessage != null) {
          // Clear the success message first
          ref.read(authProvider.notifier).clearSuccessMessage();

          // Show success dialog for account recovery scenarios
          if (next.successMessage!.contains('recovered') ||
              next.successMessage!.contains('restored')) {
            final userName = next.customerProfile?['full_name'] as String? ?? 'User';
            context.showAccountRecovered(userName);
          } else {
            // For other success messages, use snackbar
            _showSuccessSnackbar(next.successMessage!);
          }
        }

        // Handle error messages
        if (next.error != null) {
          _showErrorSnackbar(next.error!);
          // Clear the error after showing it
          ref.read(authProvider.notifier).clearError();
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset(
                      AppConstants.logoAssetPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title and subtitle
              Text(
                AppConstants.loginTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                AppConstants.loginSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: 40),

              // Login form
              FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    // Email field
                    FormBuilderTextField(
                      name: 'email',
                      decoration: InputDecoration(
                        labelText: AppConstants.emailLabel,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        (value) => Validators.validateEmail(value),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Password field
                    FormBuilderTextField(
                      name: 'password',
                      decoration: InputDecoration(
                        labelText: AppConstants.passwordLabel,
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        (value) => Validators.validatePassword(value),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Remember me and forgot password row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: AppColors.primaryBlue,
                            ),
                            Text(
                              AppConstants.rememberMeLabel,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _handleForgotPassword,
                          child: Text(
                            AppConstants.forgotPasswordButton,
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              )
                            : Text(
                                AppConstants.loginButton,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Signup link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppConstants.dontHaveAccountText,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        TextButton(
                          onPressed: _goToSignup,
                          child: Text(
                            AppConstants.signUpLinkText,
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Company branding
              Center(
                child: Column(
                  children: [
                    Text(
                      AppConstants.companyName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'EST. 2018',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.goldAccent,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}