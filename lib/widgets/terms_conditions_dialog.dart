import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';

class TermsConditionsDialog extends StatelessWidget {
  const TermsConditionsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const TermsConditionsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧾 TERMS AND CONDITIONS',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Effective Date: October 1, 2025',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      title: '1. Introduction',
                      content:
                          'Welcome to ${AppConstants.appName}, the professional inventory management system developed for J.A\'s Food Trading, located in Sampaloc, Manila. By accessing or using our platform, you agree to comply with and be bound by these Terms and Conditions. Please read them carefully before using our services.',
                    ),

                    _buildSection(
                      title: '2. Acceptance of Terms',
                      content:
                          'By creating an account, logging in, or using any part of the system, you acknowledge that you have read, understood, and agreed to these Terms. If you do not agree, please refrain from using the system.',
                    ),

                    _buildSection(
                      title: '3. Description of Service',
                      content:
                          '${AppConstants.appName} is a cloud-based inventory management platform designed to help J.A\'s Food Trading and its partners efficiently manage frozen food distribution through:\n• Real-time inventory tracking\n• Data analytics and reporting\n• Centralized order and delivery management\n• Access-controlled user accounts',
                    ),

                    _buildSection(
                      title: '4. User Responsibilities',
                      content:
                          'Users agree to:\n• Provide accurate and updated information\n• Use the system only for lawful and authorized purposes\n• Maintain the confidentiality of login credentials\n• Immediately report any unauthorized access or system misuse\n\nUnauthorized activities such as system tampering, data breaches, reverse engineering, or sharing confidential company information are strictly prohibited.',
                    ),

                    _buildSection(
                      title: '5. Intellectual Property Rights',
                      content:
                          'All system content, including but not limited to the software, design, logo, interface, analytics tools, and database structure, are the exclusive property of J.A\'s Food Trading. You may not copy, modify, or distribute any part of the system without written consent.',
                    ),

                    _buildSection(
                      title: '6. Data Accuracy and Availability',
                      content:
                          'While ${AppConstants.appName} strives to provide accurate, real-time data, J.A\'s Food Trading does not guarantee uninterrupted access or error-free performance. The company reserves the right to modify, suspend, or discontinue any feature for maintenance or system updates.',
                    ),

                    _buildSection(
                      title: '7. Limitation of Liability',
                      content:
                          'J.A\'s Food Trading shall not be held liable for any:\n• Data loss, delays, or inaccuracies caused by network or third-party service interruptions\n• Damages resulting from misuse or unauthorized access\n• Indirect or incidental damages resulting from system use',
                    ),

                    _buildSection(
                      title: '8. Account Termination',
                      content:
                          'J.A\'s Food Trading reserves the right to suspend or terminate accounts that violate these Terms, compromise system security, or misuse company data.',
                    ),

                    _buildSection(
                      title: '9. Modifications to Terms',
                      content:
                          'We may update these Terms and Conditions at any time. Changes will be effective upon posting on the platform. Continued use of the system after updates means you accept the revised Terms.',
                    ),

                    _buildSection(
                      title: '10. Contact Information',
                      content:
                          'For questions regarding these Terms, please contact:\n\n📍 J.A\'s Food Trading\nSampaloc, Manila\n📧 https://www.facebook.com/JAsFoodTrading\n📞 09663023303',
                    ),

                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'By creating an account, you acknowledge that you have read, understood, and agree to these Terms & Conditions.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'I Understand',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
