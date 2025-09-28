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
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    _fullNameController.text = widget.customerProfile['full_name'] ?? '';
    _phoneController.text = widget.customerProfile['phone'] ?? '';

    // Handle address (JSONB field)
    final address = widget.customerProfile['address'];
    if (address != null && address is Map) {
      _addressController.text = address['street'] ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Prepare address data
      Map<String, dynamic>? addressData;
      if (_addressController.text.trim().isNotEmpty) {
        addressData = {
          'street': _addressController.text.trim(),
        };
      }

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

                const SizedBox(height: 16),

                // Address field (optional)
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Address (Optional)',
                    hintText: 'Enter your address',
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