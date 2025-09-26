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

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;


  void _handleSignup() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      if (!_acceptTerms) {
        _showErrorSnackbar('Please accept the terms and conditions');
        return;
      }

      final formData = _formKey.currentState!.value;
      final fullName = formData['fullName'] as String;
      final email = formData['email'] as String;
      final phone = formData['phone'] as String;
      final password = formData['password'] as String;

      // Auto-assign the main branch ID
      const mainBranchId = AppConstants.mainBranchId;

      await ref.read(authProvider.notifier).signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        preferredBranchId: mainBranchId,
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

  void _goToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    // Listen to auth state changes for errors and success messages
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (mounted) {
        // Handle success messages with dialogs
        if (next.successMessage != null) {
          final email = _formKey.currentState?.value['email'] as String? ?? '';
          final fullName = _formKey.currentState?.value['fullName'] as String? ?? 'User';

          // Clear the success message first
          ref.read(authProvider.notifier).clearSuccessMessage();

          // Show appropriate success dialog based on message content
          if (next.successMessage!.contains('check your email')) {
            // Email confirmation required
            context.showSignupSuccess(email);
          } else if (next.successMessage!.contains('sign in with your new credentials')) {
            // Direct signup success (no email confirmation needed)
            context.showSignupComplete(fullName);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      AppConstants.logoAssetPath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title and subtitle
              Text(
                AppConstants.signupTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                AppConstants.signupSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: 32),

              // Signup form
              FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    // Full name field
                    FormBuilderTextField(
                      name: 'fullName',
                      decoration: InputDecoration(
                        labelText: AppConstants.fullNameLabel,
                        prefixIcon: const Icon(
                          Icons.person_outlined,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        (value) => Validators.validateFullName(value),
                      ]),
                    ),

                    const SizedBox(height: 16),

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

                    // Phone number field
                    FormBuilderTextField(
                      name: 'phone',
                      decoration: InputDecoration(
                        labelText: AppConstants.phoneLabel,
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        hintText: '09xxxxxxxxx',
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        PhilippinePhoneInputFormatter(),
                      ],
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        (value) => Validators.validatePhoneNumber(value),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Branch location (read-only, auto-assigned)
                    FormBuilderTextField(
                      name: 'branchPreference',
                      decoration: InputDecoration(
                        labelText: 'Branch Location',
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: AppColors.primaryBlue,
                        ),
                        suffixIcon: const Icon(
                          Icons.lock_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      initialValue: AppConstants.fullBranchDisplay,
                      readOnly: true,
                      enabled: false,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
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
                      textInputAction: TextInputAction.next,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        (value) => Validators.validatePassword(value),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Confirm password field
                    FormBuilderTextField(
                      name: 'confirmPassword',
                      decoration: InputDecoration(
                        labelText: AppConstants.confirmPasswordLabel,
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSignup(),
                      validator: (value) {
                        final password = _formKey.currentState?.value['password'];
                        return Validators.validateConfirmPassword(value, password);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Terms and conditions checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                          activeColor: AppColors.primaryBlue,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _acceptTerms = !_acceptTerms;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms and Conditions',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Signup button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleSignup,
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
                                AppConstants.signupButton,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppConstants.alreadyHaveAccountText,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        TextButton(
                          onPressed: _goToLogin,
                          child: Text(
                            AppConstants.signInLinkText,
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
            ],
          ),
        ),
      ),
    );
  }
}