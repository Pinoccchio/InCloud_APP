import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return AppConstants.emailRequiredError;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return AppConstants.emailInvalidError;
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return AppConstants.passwordRequiredError;
    }

    if (password.length < AppConstants.minPasswordLength) {
      return AppConstants.passwordMinLengthError;
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? confirmPassword, String? password) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return AppConstants.passwordRequiredError;
    }

    if (confirmPassword != password) {
      return AppConstants.passwordMismatchError;
    }

    return null;
  }

  // Full name validation
  static String? validateFullName(String? fullName) {
    if (fullName == null || fullName.isEmpty) {
      return AppConstants.fullNameRequiredError;
    }

    if (fullName.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }

    if (fullName.length > AppConstants.maxNameLength) {
      return 'Full name must be less than ${AppConstants.maxNameLength} characters';
    }

    // Check if name contains only letters, spaces, and common punctuation
    final nameRegex = RegExp(r"^[a-zA-Z\s\.\-']+$");
    if (!nameRegex.hasMatch(fullName)) {
      return 'Full name can only contain letters, spaces, and common punctuation';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return AppConstants.phoneRequiredError;
    }

    // Remove any non-digit characters for validation
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Philippine mobile numbers: 09xxxxxxxxx or +639xxxxxxxxx
    // Landline: 02xxxxxxxx or +632xxxxxxxx
    if (digitsOnly.length < 10 || digitsOnly.length > 13) {
      return AppConstants.phoneInvalidError;
    }

    // Check for Philippine mobile format
    final mobileRegex = RegExp(r'^(\+639|09)\d{9}$');
    // Check for Philippine landline format
    final landlineRegex = RegExp(r'^(\+632|02)\d{8}$');
    // Check for international format
    final internationalRegex = RegExp(r'^\+\d{10,13}$');

    if (!mobileRegex.hasMatch(phoneNumber) &&
        !landlineRegex.hasMatch(phoneNumber) &&
        !internationalRegex.hasMatch(phoneNumber)) {
      return AppConstants.phoneInvalidError;
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Generic text length validation
  static String? validateTextLength(String? value, String fieldName,
      {int? minLength, int? maxLength}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (minLength != null && value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (maxLength != null && value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }

    return null;
  }

  // Utility method to check if form is valid
  static bool isFormValid(List<String?> validationResults) {
    return validationResults.every((result) => result == null);
  }

  // Utility method to format phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.startsWith('639') && digitsOnly.length == 12) {
      // Convert +639xxxxxxxxx to 09xxxxxxxxx format
      return '0${digitsOnly.substring(2)}';
    }

    if (digitsOnly.startsWith('9') && digitsOnly.length == 10) {
      // Add 0 prefix for mobile numbers
      return '0$digitsOnly';
    }

    return phoneNumber;
  }

  // Utility method to normalize phone number for storage
  static String normalizePhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.startsWith('09') && digitsOnly.length == 11) {
      // Convert 09xxxxxxxxx to +639xxxxxxxxx
      return '+63${digitsOnly.substring(1)}';
    }

    if (digitsOnly.startsWith('02') && digitsOnly.length == 10) {
      // Convert 02xxxxxxxx to +632xxxxxxxx
      return '+632${digitsOnly.substring(2)}';
    }

    if (digitsOnly.startsWith('639') && digitsOnly.length == 12) {
      // Already in +639 format
      return '+$digitsOnly';
    }

    if (digitsOnly.startsWith('632') && digitsOnly.length == 11) {
      // Already in +632 format
      return '+$digitsOnly';
    }

    // If already in international format or unknown format, return as is
    return phoneNumber.startsWith('+') ? phoneNumber : '+$digitsOnly';
  }
}

/// Input formatter for Philippine phone numbers
/// Automatically formats input to +63 format as user types
class PhilippinePhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String newText = newValue.text;

    // If user is deleting, allow it
    if (newText.length < oldValue.text.length) {
      return newValue;
    }

    // Remove all non-digit characters
    String digitsOnly = newText.replaceAll(RegExp(r'\D'), '');

    // If user starts typing 0, convert to +63
    if (digitsOnly.startsWith('0')) {
      if (digitsOnly.length >= 2 && digitsOnly.substring(0, 2) == '09') {
        // Mobile number: 09 -> +639
        digitsOnly = '63${digitsOnly.substring(1)}';
      } else if (digitsOnly.length >= 2 && digitsOnly.substring(0, 2) == '02') {
        // Landline: 02 -> +632
        digitsOnly = '632${digitsOnly.substring(2)}';
      }
    }

    // If user types digits directly without 0, assume mobile
    if (!digitsOnly.startsWith('63') && digitsOnly.isNotEmpty && !digitsOnly.startsWith('0')) {
      digitsOnly = '639$digitsOnly';
    }

    // Add + prefix if not present
    String formattedText = digitsOnly.isEmpty ? '' : '+$digitsOnly';

    // Limit length to reasonable phone number length
    if (formattedText.length > 14) {
      formattedText = formattedText.substring(0, 14);
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}