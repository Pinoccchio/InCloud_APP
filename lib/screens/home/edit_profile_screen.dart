import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/error_dialog.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> customerProfile;

  const EditProfileScreen({
    super.key,
    required this.customerProfile,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _barangayController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _deliveryNotesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    _fullNameController.text = widget.customerProfile['full_name'] ?? '';
    _phoneController.text = widget.customerProfile['phone'] ?? '';

    // Handle address (JSONB field) - parse all fields
    final address = widget.customerProfile['address'];
    if (address != null && address is Map) {
      _streetController.text = address['street'] ?? '';
      _barangayController.text = address['barangay'] ?? '';
      _cityController.text = address['city'] ?? 'Manila';
      _provinceController.text = address['province'] ?? 'Metro Manila';
      _postalCodeController.text = address['postal_code'] ?? '';
      _deliveryNotesController.text = address['notes'] ?? '';
    } else {
      // Set defaults for new users without address
      _cityController.text = 'Manila';
      _provinceController.text = 'Metro Manila';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _barangayController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _deliveryNotesController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Build complete address data
      final addressData = {
        'street': _streetController.text.trim(),
        'barangay': _barangayController.text.trim(),
        'city': _cityController.text.trim(),
        'province': _provinceController.text.trim().isEmpty
            ? 'Metro Manila'
            : _provinceController.text.trim(),
        'postal_code': _postalCodeController.text.trim(),
        'notes': _deliveryNotesController.text.trim(),
      };

      final result = await AuthService.updateCustomerProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: addressData,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result.isSuccess) {
          // Show success dialog and return to profile screen
          await SuccessDialog.show(
            context: context,
            title: 'Success',
            message: result.message,
            buttonText: 'Continue',
            onButtonPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to profile with refresh flag
            },
          );
        } else {
          // Show error dialog
          ErrorDialog.show(
            context: context,
            title: 'Update Failed',
            message: result.message,
            buttonText: 'Try Again',
          );
        }
      }
    }
  }

  // Format Philippine phone number to international format
  String _formatPhoneNumber(String input) {
    // Remove all non-digit characters
    String digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');

    // Handle different input formats
    if (digitsOnly.startsWith('639') && digitsOnly.length == 12) {
      // Already in correct format without +, just add +
      return '+$digitsOnly';
    } else if (digitsOnly.startsWith('09') && digitsOnly.length == 11) {
      // Philippine mobile format 09XXXXXXXXX, convert to +639XXXXXXXXX
      return '+63${digitsOnly.substring(1)}';
    } else if (digitsOnly.startsWith('9') && digitsOnly.length == 10) {
      // Missing leading 0, assume Philippine mobile 9XXXXXXXXX
      return '+63$digitsOnly';
    } else if (input.startsWith('+639') && digitsOnly.length == 12) {
      // Already properly formatted
      return input;
    }

    // If none of the above, return the input as-is (for other formats)
    return input;
  }

  // Handle phone number input changes
  void _onPhoneChanged(String value) {
    String formatted = _formatPhoneNumber(value);

    // Only update if the formatted value is different
    if (formatted != value) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().split(' ').length < 2) {
      return 'Please enter your first and last name';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove all non-digit characters for validation
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Check for valid Philippine mobile number formats
    if (value.startsWith('+639') && digitsOnly.length == 12) {
      // International format +639XXXXXXXXX (12 digits total)
      return null;
    } else if (value.startsWith('09') && digitsOnly.length == 11) {
      // Local format 09XXXXXXXXX (11 digits total)
      return null;
    } else if (digitsOnly.startsWith('639') && digitsOnly.length == 12) {
      // International without + sign
      return null;
    } else if (digitsOnly.startsWith('9') && digitsOnly.length == 10) {
      // Missing leading 0
      return null;
    }

    return 'Please enter a valid Philippine mobile number (e.g., 09514575745)';
  }

  String? _validateStreet(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Street address is required';
    }
    if (value.trim().length < 10) {
      return 'Please enter a complete street address (min 10 characters)';
    }
    if (value.trim().length > 255) {
      return 'Street address too long (max 255 characters)';
    }
    return null;
  }

  String? _validateBarangay(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Barangay is required';
    }
    if (value.trim().length > 100) {
      return 'Barangay name too long (max 100 characters)';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (value.trim().length > 100) {
      return 'City name too long (max 100 characters)';
    }
    return null;
  }

  String? _validatePostalCode(String? value) {
    // Optional field, but if provided should be 4 digits
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    if (!RegExp(r'^\d{4}$').hasMatch(value.trim())) {
      return 'Postal code must be 4 digits';
    }
    return null;
  }

  String _formatBranchName(Map<String, dynamic>? branchData) {
    if (branchData == null) {
      return 'No branch assigned';
    }

    final branchName = branchData['name'] as String?;
    if (branchName == null || branchName.isEmpty) {
      return 'No branch assigned';
    }

    return branchName;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Picture Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryRed, AppColors.primaryBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(widget.customerProfile['full_name']),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Edit Your Profile',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Full Name field
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _validateFullName,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(
                      Icons.person_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Phone field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: _validatePhone,
                  onChanged: _onPhoneChanged,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number (e.g., 09514575745)',
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Address Section Header
                Text(
                  'Delivery Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Complete delivery address required',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),

                const SizedBox(height: 16),

                // Street Address field
                TextFormField(
                  controller: _streetController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                  validator: _validateStreet,
                  decoration: InputDecoration(
                    labelText: 'Street Address',
                    hintText: 'e.g., 123 Main Street, Blk 5 Lot 10',
                    prefixIcon: const Icon(
                      Icons.home_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Barangay field
                TextFormField(
                  controller: _barangayController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _validateBarangay,
                  decoration: InputDecoration(
                    labelText: 'Barangay',
                    hintText: 'e.g., Barangay 123',
                    prefixIcon: const Icon(
                      Icons.location_city_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // City and Province Row
                Row(
                  children: [
                    // City field
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: _validateCity,
                        decoration: InputDecoration(
                          labelText: 'City',
                          hintText: 'e.g., Manila',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primaryBlue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Province field
                    Expanded(
                      child: TextFormField(
                        controller: _provinceController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Province (Optional)',
                          hintText: 'Metro Manila',
                          prefixIcon: const Icon(
                            Icons.map_outlined,
                            color: AppColors.primaryBlue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gray300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Postal Code field
                TextFormField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: _validatePostalCode,
                  decoration: InputDecoration(
                    labelText: 'Postal Code (Optional)',
                    hintText: 'e.g., 1008',
                    prefixIcon: const Icon(
                      Icons.markunread_mailbox_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Delivery Notes field
                TextFormField(
                  controller: _deliveryNotesController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Delivery Notes (Optional)',
                    hintText: 'e.g., Near the blue gate, 2nd floor',
                    prefixIcon: const Icon(
                      Icons.notes_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Read-only information section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildReadOnlyField('Email', user?.email ?? 'Not available'),
                      const SizedBox(height: 8),
                      _buildReadOnlyField('Customer Type', (widget.customerProfile['customer_type'] ?? 'regular').toString().toUpperCase()),
                      const SizedBox(height: 8),
                      _buildReadOnlyField('Branch', _formatBranchName(widget.customerProfile['branches'])),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel button
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.gray300),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'U';

    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName[0].toUpperCase();
  }
}