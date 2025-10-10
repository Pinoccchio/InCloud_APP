import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const PrivacyPolicyDialog(),
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
                      'Privacy Policy',
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
                      '🔒 PRIVACY POLICY',
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
                      title: '1. Overview',
                      content:
                          'J.A\'s Food Trading ("we," "our," "us") respects your privacy. This Privacy Policy explains how we collect, use, store, and protect personal information when you use the ${AppConstants.appName} Inventory Management System.',
                    ),

                    _buildSection(
                      title: '2. Information We Collect',
                      content:
                          'We may collect the following types of information:\n\nPersonal Information: name, email address, delivery address, phone number.\n\nSystem Data: login credentials, account activity logs, and usage analytics.\n\nOperational Data: inventory records, order details, and distribution data uploaded by authorized users.',
                    ),

                    _buildSection(
                      title: '3. How We Use Your Information',
                      content:
                          'The collected information is used to:\n\n• Manage user accounts and permissions\n• Improve system functionality and performance\n• Generate analytics for business operations\n• Maintain system security and detect unauthorized activity\n• Provide technical support and service updates\n\nWe do not sell, rent, or share your data with third parties for marketing purposes.',
                    ),

                    _buildSection(
                      title: '4. Data Security',
                      content:
                          'We implement strict measures to protect your data, including encryption, role-based access control, and regular security audits. However, no digital platform is completely secure. Users are encouraged to safeguard their login credentials at all times.',
                    ),

                    _buildSection(
                      title: '5. Data Retention',
                      content:
                          'Data will be retained only as long as necessary for operational or legal purposes. Once no longer required, it will be securely deleted or anonymized.',
                    ),

                    _buildSection(
                      title: '6. User Rights',
                      content:
                          'You have the right to:\n\n• Access and review your personal information\n• Request correction of inaccurate data\n• Request deletion of your account or data, subject to business or legal retention requirements',
                    ),

                    _buildSection(
                      title: '7. Cookies and Tracking Technologies',
                      content:
                          'The system may use cookies or tracking tools to enhance user experience and collect operational metrics. You may disable cookies in your browser settings, but some features may not function properly.',
                    ),

                    _buildSection(
                      title: '8. Third-Party Services',
                      content:
                          'Our system may integrate with third-party services (e.g., cloud hosting, analytics tools). These providers are contractually bound to maintain confidentiality and comply with data protection standards.',
                    ),

                    _buildSection(
                      title: '9. Policy Updates',
                      content:
                          'We may update this Privacy Policy from time to time. The latest version will always be available on the platform, with the effective date clearly indicated.',
                    ),

                    _buildSection(
                      title: '10. Contact Us',
                      content:
                          'For privacy-related inquiries or data requests, please contact:\n\n📍 J.A\'s Food Trading\nSampaloc, Manila\n📧 https://www.facebook.com/JAsFoodTrading\n📞 09663023303',
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
                            Icons.shield_outlined,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'J.A\'s Food Trading respects your privacy and is committed to protecting your personal information in accordance with data protection standards.',
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
