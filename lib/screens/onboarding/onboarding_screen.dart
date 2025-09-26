import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: AppConstants.onboardingWelcomeTitle,
      subtitle: AppConstants.onboardingWelcomeSubtitle,
      icon: Icons.store_rounded,
      color: AppColors.primaryRed,
    ),
    OnboardingSlide(
      title: AppConstants.onboardingFeaturesTitle,
      subtitle: AppConstants.onboardingFeaturesSubtitle,
      icon: Icons.shopping_cart_rounded,
      color: AppColors.primaryBlue,
    ),
    OnboardingSlide(
      title: AppConstants.onboardingBenefitsTitle,
      subtitle: AppConstants.onboardingBenefitsSubtitle,
      icon: Icons.local_offer_rounded,
      color: AppColors.goldAccent,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.slideAnimationDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _skipToLogin() {
    _goToLogin();
  }

  void _goToLogin() {
    context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipToLogin,
                    child: Text(
                      AppConstants.skipButton,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),

            // Bottom section with indicators and button
            Padding(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _slides[_currentPage].color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? AppConstants.getStartedButton
                            : AppConstants.nextButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.largePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: slide.color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              slide.icon,
              size: 60,
              color: slide.color,
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),

          const SizedBox(height: 32),

          // Company info for first slide
          if (_currentPage == 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                AppConstants.companyDescription,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.goldAccent700,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: AppConstants.fadeAnimationDuration,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? _slides[_currentPage].color
            : AppColors.gray300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}