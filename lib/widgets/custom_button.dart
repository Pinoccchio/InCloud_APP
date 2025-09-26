import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? 48,
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: AppColors.white,
            elevation: 2,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBackgroundColor: AppColors.gray300,
            disabledForegroundColor: AppColors.gray500,
          ),
          child: _buildButtonContent(),
        );

      case ButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.white,
            elevation: 2,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBackgroundColor: AppColors.gray300,
            disabledForegroundColor: AppColors.gray500,
          ),
          child: _buildButtonContent(),
        );

      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryRed,
            side: const BorderSide(color: AppColors.primaryRed),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledForegroundColor: AppColors.gray500,
            disabledBackgroundColor: Colors.transparent,
          ),
          child: _buildButtonContent(),
        );

      case ButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledForegroundColor: AppColors.gray500,
          ),
          child: _buildButtonContent(),
        );
    }
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.outline || variant == ButtonVariant.text
                ? AppColors.primaryRed
                : AppColors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// Convenience constructors
class PrimaryButton extends CustomButton {
  const PrimaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.isFullWidth = false,
    super.icon,
    super.width,
    super.height,
    super.padding,
  }) : super(variant: ButtonVariant.primary);
}

class SecondaryButton extends CustomButton {
  const SecondaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.isFullWidth = false,
    super.icon,
    super.width,
    super.height,
    super.padding,
  }) : super(variant: ButtonVariant.secondary);
}

class OutlineButton extends CustomButton {
  const OutlineButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.isFullWidth = false,
    super.icon,
    super.width,
    super.height,
    super.padding,
  }) : super(variant: ButtonVariant.outline);
}

class TextOnlyButton extends CustomButton {
  const TextOnlyButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isLoading = false,
    super.isFullWidth = false,
    super.icon,
    super.width,
    super.height,
    super.padding,
  }) : super(variant: ButtonVariant.text);
}