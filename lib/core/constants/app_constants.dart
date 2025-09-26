class AppConstants {
  // App Information
  static const String appName = 'InCloud';
  static const String companyName = "J.A's Food Trading";
  static const String appVersion = '1.0.0';

  // App Description
  static const String appTagline = 'Your trusted frozen food ordering companion';
  static const String companyDescription = 'Established 2018 - Premium frozen food distributor in Sampaloc, Manila';

  // Onboarding Content
  static const String onboardingWelcomeTitle = 'Welcome to InCloud';
  static const String onboardingWelcomeSubtitle = 'Your trusted frozen food ordering companion from J.A\'s Food Trading';

  static const String onboardingFeaturesTitle = 'Browse & Order';
  static const String onboardingFeaturesSubtitle = 'Explore our premium frozen food catalog with real-time inventory and easy ordering';

  static const String onboardingBenefitsTitle = 'Flexible Pricing';
  static const String onboardingBenefitsSubtitle = 'Choose from wholesale, retail, or box pricing options. Direct delivery from our Manila location';

  // Authentication Messages
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to your InCloud account';
  static const String signupTitle = 'Create Account';
  static const String signupSubtitle = 'Join InCloud for seamless frozen food ordering';

  // Form Labels
  static const String emailLabel = 'Email Address';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String fullNameLabel = 'Full Name';
  static const String phoneLabel = 'Phone Number';
  static const String branchPreferenceLabel = 'Preferred Branch';

  // Button Labels
  static const String loginButton = 'Sign In';
  static const String signupButton = 'Create Account';
  static const String continueButton = 'Continue';
  static const String skipButton = 'Skip';
  static const String nextButton = 'Next';
  static const String getStartedButton = 'Get Started';
  static const String forgotPasswordButton = 'Forgot Password?';
  static const String rememberMeLabel = 'Remember me';

  // Navigation Labels
  static const String dontHaveAccountText = "Don't have an account?";
  static const String signUpLinkText = 'Sign up';
  static const String alreadyHaveAccountText = 'Already have an account?';
  static const String signInLinkText = 'Sign in';

  // Validation Messages
  static const String emailRequiredError = 'Email address is required';
  static const String emailInvalidError = 'Please enter a valid email address';
  static const String passwordRequiredError = 'Password is required';
  static const String passwordMinLengthError = 'Password must be at least 8 characters';
  static const String passwordMismatchError = 'Passwords do not match';
  static const String fullNameRequiredError = 'Full name is required';
  static const String phoneRequiredError = 'Phone number is required';
  static const String phoneInvalidError = 'Please enter a valid phone number';

  // Loading Messages
  static const String signingInMessage = 'Signing in...';
  static const String creatingAccountMessage = 'Creating account...';
  static const String loadingMessage = 'Loading...';

  // Error Messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String authErrorMessage = 'Invalid email or password.';

  // Success Messages
  static const String accountCreatedMessage = 'Account created successfully!';
  static const String loginSuccessMessage = 'Welcome back!';

  // Asset Paths
  static const String logoAssetPath = 'assets/images/primary-logo.png';
  static const String splashBackgroundPath = 'assets/images/splash_background.png';

  // Animation Durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration fadeAnimationDuration = Duration(milliseconds: 500);
  static const Duration slideAnimationDuration = Duration(milliseconds: 300);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardElevation = 2.0;

  // Branch Locations (from the business model)
  static const List<String> branchLocations = [
    'Main Branch - Sampaloc, Manila',
    'Branch 2 - Sampaloc, Manila',
    'Branch 3 - Sampaloc, Manila',
  ];

  // Minimum Requirements
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxPhoneLength = 15;

  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
}