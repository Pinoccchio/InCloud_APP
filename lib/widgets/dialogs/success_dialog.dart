import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Success dialog widget for showing positive feedback to users
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final IconData? icon;
  final Color? iconColor;
  final bool dismissible;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.icon,
    this.iconColor,
    this.dismissible = true,
  });

  /// Factory constructor for signup success with email confirmation
  factory SuccessDialog.signupSuccess({
    required BuildContext context,
    required String email,
  }) {
    return SuccessDialog(
      title: 'Account Created Successfully!',
      message: 'We\'ve sent a confirmation email to $email.\n\n'
          'Please check your email and click the confirmation link to activate your account. '
          'Once confirmed, you can sign in and start using InCloud.',
      icon: Icons.check_circle,
      iconColor: AppColors.success,
      primaryButtonText: 'Go to Sign In',
      secondaryButtonText: 'I\'ll check later',
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        context.go('/login');
      },
      onSecondaryPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  /// Factory constructor for successful direct signup (no email confirmation needed)
  factory SuccessDialog.signupComplete({
    required BuildContext context,
    required String userName,
  }) {
    return SuccessDialog(
      title: 'Account Created Successfully!',
      message: 'Hi $userName!\n\n'
          'Your account has been created successfully. '
          'Please sign in with your new credentials to start browsing our premium frozen food catalog.',
      icon: Icons.check_circle,
      iconColor: AppColors.success,
      primaryButtonText: 'Go to Sign In',
      secondaryButtonText: 'I\'ll sign in later',
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        context.go('/login');
      },
      onSecondaryPressed: () {
        Navigator.of(context).pop();
      },
    );
  }

  /// Factory constructor for password reset success
  factory SuccessDialog.passwordResetSent({
    required BuildContext context,
    required String email,
  }) {
    return SuccessDialog(
      title: 'Password Reset Sent',
      message: 'We\'ve sent password reset instructions to $email.\n\n'
          'Please check your email and follow the link to reset your password.',
      icon: Icons.email,
      iconColor: AppColors.primaryBlue,
      primaryButtonText: 'Back to Sign In',
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        context.go('/login');
      },
    );
  }

  /// Factory constructor for orphaned user recovery
  factory SuccessDialog.accountRecovered({
    required BuildContext context,
    required String userName,
  }) {
    return SuccessDialog(
      title: 'Account Recovered!',
      message: 'Hi $userName!\n\n'
          'We\'ve successfully recovered your account. Your profile has been restored '
          'and you can now access all InCloud features.',
      icon: Icons.restore,
      iconColor: AppColors.success,
      primaryButtonText: 'Continue',
      onPrimaryPressed: () {
        Navigator.of(context).pop();
        // Will navigate to home via auth state change
      },
    );
  }

  /// Show the dialog
  static Future<void> show(BuildContext context, SuccessDialog dialog) {
    return showDialog<void>(
      context: context,
      barrierDismissible: dialog.dismissible,
      builder: (BuildContext context) => dialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surfacePrimary,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            if (icon != null) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (iconColor ?? AppColors.success).withValues(alpha: 0.1),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor ?? AppColors.success,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Secondary button (if provided)
                if (secondaryButtonText != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        secondaryButtonText!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Primary button
                Expanded(
                  flex: secondaryButtonText != null ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      primaryButtonText ?? 'OK',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to easily show success dialogs from context
extension SuccessDialogExtension on BuildContext {
  Future<void> showSuccessDialog(SuccessDialog dialog) {
    return SuccessDialog.show(this, dialog);
  }

  Future<void> showSignupSuccess(String email) {
    return showSuccessDialog(SuccessDialog.signupSuccess(
      context: this,
      email: email,
    ));
  }

  Future<void> showSignupComplete(String userName) {
    return showSuccessDialog(SuccessDialog.signupComplete(
      context: this,
      userName: userName,
    ));
  }

  Future<void> showPasswordResetSent(String email) {
    return showSuccessDialog(SuccessDialog.passwordResetSent(
      context: this,
      email: email,
    ));
  }

  Future<void> showAccountRecovered(String userName) {
    return showSuccessDialog(SuccessDialog.accountRecovered(
      context: this,
      userName: userName,
    ));
  }
}