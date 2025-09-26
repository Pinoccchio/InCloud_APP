import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.contentPadding,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          style: TextStyle(
            fontSize: 16,
            color: widget.enabled ? AppColors.textPrimary : AppColors.textTertiary,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: AppColors.primaryBlue,
                    size: 20,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(),
            filled: true,
            fillColor: widget.enabled ? AppColors.gray50 : AppColors.gray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            labelStyle: TextStyle(
              color: widget.enabled ? AppColors.textSecondary : AppColors.textTertiary,
              fontSize: 14,
            ),
            hintStyle: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
            helperStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
            ),
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            counterStyle: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: widget.enabled
            ? () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              }
            : null,
      );
    }

    return widget.suffixIcon;
  }
}

// Convenience constructors
class EmailTextField extends CustomTextField {
  const EmailTextField({
    super.key,
    super.label = 'Email Address',
    super.hint = 'Enter your email address',
    super.controller,
    super.onChanged,
    super.validator,
    super.enabled = true,
  }) : super(
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        );
}

class PasswordTextField extends CustomTextField {
  const PasswordTextField({
    super.key,
    super.label = 'Password',
    super.hint = 'Enter your password',
    super.controller,
    super.onChanged,
    super.onSubmitted,
    super.validator,
    super.enabled = true,
    super.textInputAction = TextInputAction.done,
  }) : super(
          prefixIcon: Icons.lock_outlined,
          obscureText: true,
        );
}

class PhoneTextField extends CustomTextField {
  const PhoneTextField({
    super.key,
    super.label = 'Phone Number',
    super.hint = '+63 or 09xxxxxxxxx',
    super.controller,
    super.onChanged,
    super.validator,
    super.enabled = true,
  }) : super(
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        );
}

class NameTextField extends CustomTextField {
  const NameTextField({
    super.key,
    super.label = 'Full Name',
    super.hint = 'Enter your full name',
    super.controller,
    super.onChanged,
    super.validator,
    super.enabled = true,
  }) : super(
          prefixIcon: Icons.person_outlined,
          textCapitalization: TextCapitalization.words,
        );
}

class SearchTextField extends CustomTextField {
  const SearchTextField({
    super.key,
    super.label,
    super.hint = 'Search...',
    super.controller,
    super.onChanged,
    super.onSubmitted,
    super.enabled = true,
  }) : super(
          prefixIcon: Icons.search_outlined,
          textInputAction: TextInputAction.search,
        );
}