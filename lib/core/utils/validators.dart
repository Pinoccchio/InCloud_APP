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

    // If already in international format or unknown format, return as is
    return phoneNumber.startsWith('+') ? phoneNumber : '+$digitsOnly';
  }
}