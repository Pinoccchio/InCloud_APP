Flutter App Implementation Plan: UI Screens Phase                              │ │
│ │                                                                                │ │
│ │ Overview                                                                       │ │
│ │                                                                                │ │
│ │ Implementing InCloud mobile app UI screens with J.A's Food Trading brand       │ │
│ │ consistency, starting with splash, onboarding, login, and signup screens using │ │
│ │  Flutter with Riverpod state management.                                       │ │
│ │                                                                                │ │
│ │ Phase 1: Project Setup & Configuration                                         │ │
│ │                                                                                │ │
│ │ 1. Dependencies Setup                                                          │ │
│ │                                                                                │ │
│ │ Update pubspec.yaml with required packages:                                    │ │
│ │ - flutter_riverpod: ^2.4.9 - State management                                  │ │
│ │ - supabase_flutter: ^2.0.0 - Backend integration                               │ │
│ │ - go_router: ^12.1.3 - Navigation                                              │ │
│ │ - flutter_form_builder: ^9.2.1 - Form handling                                 │ │
│ │ - form_builder_validators: ^9.1.0 - Validation                                 │ │
│ │ - flutter_svg: ^2.0.9 - Logo rendering                                         │ │
│ │ - lottie: ^2.7.0 - Animations (optional for splash)                            │ │
│ │                                                                                │ │
│ │ 2. Project Structure                                                           │ │
│ │                                                                                │ │
│ │ lib/                                                                           │ │
│ │ ├── core/                                                                      │ │
│ │ │   ├── theme/                                                                 │ │
│ │ │   │   ├── app_theme.dart          # J.A's brand colors & theme               │ │
│ │ │   │   └── app_colors.dart         # Color constants                          │ │
│ │ │   ├── constants/                                                             │ │
│ │ │   │   └── app_constants.dart      # App-wide constants                       │ │
│ │ │   └── utils/                                                                 │ │
│ │ │       └── validators.dart         # Form validation logic                    │ │
│ │ ├── providers/                                                                 │ │
│ │ │   ├── auth_provider.dart          # Authentication state                     │ │
│ │ │   └── app_state_provider.dart     # App-wide state                           │ │
│ │ ├── screens/                                                                   │ │
│ │ │   ├── splash/                                                                │ │
│ │ │   │   └── splash_screen.dart      # Logo animation screen                    │ │
│ │ │   ├── onboarding/                                                            │ │
│ │ │   │   ├── onboarding_screen.dart  # Main onboarding flow                     │ │
│ │ │   │   └── widgets/                # Onboarding components                    │ │
│ │ │   ├── auth/                                                                  │ │
│ │ │   │   ├── login_screen.dart       # Email/password login                     │ │
│ │ │   │   └── signup_screen.dart      # Customer registration                    │ │
│ │ │   └── home/                                                                  │ │
│ │ │       └── main_app_screen.dart    # Future main app (placeholder)            │ │
│ │ ├── widgets/                                                                   │ │
│ │ │   ├── custom_button.dart          # Branded button component                 │ │
│ │ │   ├── custom_text_field.dart      # Branded input field                      │ │
│ │ │   └── loading_indicator.dart      # Loading states                           │ │
│ │ ├── services/                                                                  │ │
│ │ │   └── supabase_service.dart       # Supabase client setup                    │ │
│ │ └── main.dart                       # App entry point                          │ │
│ │                                                                                │ │
│ │ Phase 2: Brand Implementation                                                  │ │
│ │                                                                                │ │
│ │ 3. J.A's Brand Colors & Theme                                                  │ │
│ │                                                                                │ │
│ │ Implement exact color scheme from web app:                                     │ │
│ │ - Primary Red: #C21722 (main brand color)                                      │ │
│ │ - Primary Blue: #1565C0 (text, links, secondary)                               │ │
│ │ - Gold Accent: #D4AF37 (highlights, borders)                                   │ │
│ │ - Supporting grays for backgrounds and neutral elements                        │ │
│ │                                                                                │ │
│ │ Material 3 Theme with custom color scheme matching J.A's identity.             │ │
│ │                                                                                │ │
│ │ 4. Logo Asset Integration                                                      │ │
│ │                                                                                │ │
│ │ - Copy primary-logo.png to assets/images/                                      │ │
│ │ - Configure asset declarations in pubspec.yaml                                 │ │
│ │ - Create responsive logo widget for different screen sizes                     │ │
│ │                                                                                │ │
│ │ Phase 3: UI Screen Implementation                                              │ │
│ │                                                                                │ │
│ │ 5. Splash Screen                                                               │ │
│ │                                                                                │ │
│ │ Features:                                                                      │ │
│ │ - Centered J.A's logo with fade-in animation                                   │ │
│ │ - 2-3 second display duration                                                  │ │
│ │ - Smooth transition to onboarding/main app                                     │ │
│ │ - Brand color background gradient                                              │ │
│ │                                                                                │ │
│ │ Navigation Logic:                                                              │ │
│ │ - First launch → Onboarding                                                    │ │
│ │ - Returning users → Check auth status → Login or Main App                      │ │
│ │                                                                                │ │
│ │ 6. Onboarding Screens (3 Slides)                                               │ │
│ │                                                                                │ │
│ │ Slide 1 - Welcome                                                              │ │
│ │ - J.A's logo and "Welcome to InCloud"                                          │ │
│ │ - "Your trusted frozen food ordering companion"                                │ │
│ │                                                                                │ │
│ │ Slide 2 - Features                                                             │ │
│ │ - "Browse & Order" with product catalog icon                                   │ │
│ │ - "Real-time tracking and updates"                                             │ │
│ │                                                                                │ │
│ │ Slide 3 - Benefits                                                             │ │
│ │ - "Wholesale & retail pricing available"                                       │ │
│ │ - "Direct delivery from J.A's Food Trading"                                    │ │
│ │                                                                                │ │
│ │ UI Elements:                                                                   │ │
│ │ - Page indicators, Skip/Next buttons                                           │ │
│ │ - Consistent brand colors and typography                                       │ │
│ │                                                                                │ │
│ │ 7. Login Screen                                                                │ │
│ │                                                                                │ │
│ │ Form Fields:                                                                   │ │
│ │ - Email input with validation                                                  │ │
│ │ - Password input with show/hide toggle                                         │ │
│ │ - "Remember me" checkbox                                                       │ │
│ │ - "Forgot password?" link                                                      │ │
│ │                                                                                │ │
│ │ Actions:                                                                       │ │
│ │ - Login button with loading states                                             │ │
│ │ - "Don't have an account? Sign up" link                                        │ │
│ │ - Error handling with branded error messages                                   │ │
│ │                                                                                │ │
│ │ 8. Signup Screen                                                               │ │
│ │                                                                                │ │
│ │ Customer Registration Fields:                                                  │ │
│ │ - Full name (required)                                                         │ │
│ │ - Email address (required, unique)                                             │ │
│ │ - Phone number (required)                                                      │ │
│ │ - Password (required, 8+ chars)                                                │ │
│ │ - Confirm password (required, matching)                                        │ │
│ │ - Branch preference (dropdown)                                                 │ │
│ │                                                                                │ │
│ │ Validation:                                                                    │ │
│ │ - Real-time field validation                                                   │ │
│ │ - Password strength indicator                                                  │ │
│ │ - Email format verification                                                    │ │
│ │ - Terms & conditions acceptance                                                │ │
│ │                                                                                │ │
│ │ Phase 4: State Management & Integration                                        │ │
│ │                                                                                │ │
│ │ 9. Riverpod Provider Setup                                                     │ │
│ │                                                                                │ │
│ │ Authentication Provider:                                                       │ │
│ │ - User authentication state                                                    │ │
│ │ - Login/logout methods                                                         │ │
│ │ - Session persistence                                                          │ │
│ │ - Error state management                                                       │ │
│ │                                                                                │ │
│ │ Form Providers:                                                                │ │
│ │ - Login form state                                                             │ │
│ │ - Signup form state                                                            │ │
│ │ - Validation state tracking                                                    │ │
│ │                                                                                │ │
│ │ 10. Supabase Integration                                                       │ │
│ │                                                                                │ │
│ │ Authentication Service:                                                        │ │
│ │ - Email/password authentication                                                │ │
│ │ - User registration flow                                                       │ │
│ │ - Session management                                                           │ │
│ │ - Error handling for auth operations                                           │ │
│ │                                                                                │ │
│ │ Customer Table Integration:                                                    │ │
│ │ - User profile creation on signup                                              │ │
│ │ - Branch assignment logic                                                      │ │
│ │ - Role assignment (customer role)                                              │ │
│ │                                                                                │ │
│ │ 11. Navigation Implementation                                                  │ │
│ │                                                                                │ │
│ │ Route Configuration:                                                           │ │
│ │ - Splash → Onboarding → Auth → Main App flow                                   │ │
│ │ - Deep linking support for auth redirects                                      │ │
│ │ - Proper navigation stack management                                           │ │
│ │                                                                                │ │
│ │ Screen Transitions:                                                            │ │
│ │ - Smooth page transitions                                                      │ │
│ │ - Loading states between screens                                               │ │
│ │ - Back button handling                                                         │ │
│ │                                                                                │ │
│ │ Phase 5: Polish & Validation                                                   │ │
│ │                                                                                │ │
│ │ 12. Form Validation & UX                                                       │ │
│ │                                                                                │ │
│ │ Input Validation:                                                              │ │
│ │ - Real-time validation feedback                                                │ │
│ │ - Clear error messages                                                         │ │
│ │ - Accessibility support                                                        │ │
│ │ - Loading states and feedback                                                  │ │
│ │                                                                                │ │
│ │ User Experience:                                                               │ │
│ │ - Consistent spacing and typography                                            │ │
│ │ - Touch-friendly button sizes                                                  │ │
│ │ - Proper keyboard handling                                                     │ │
│ │ - Focus management                                                             │ │
│ │                                                                                │ │
│ │ Technical Implementation Notes                                                 │ │
│ │                                                                                │ │
│ │ State Management Choice: Riverpod                                              │ │
│ │ - Excellent for real-time data (future inventory sync)                         │ │
│ │ - Type-safe, compile-time dependency injection                                 │ │
│ │ - Great for authentication state management                                    │ │
│ │ - Easy testing and debugging                                                   │ │
│ │                                                                                │ │
│ │ Design System:                                                                 │ │
│ │ - Consistent with web app branding                                             │ │
│ │ - Responsive design for various screen sizes                                   │ │
│ │ - Accessibility compliance (color contrast, touch targets)                     │ │
│ │ - Material 3 design language with J.A's brand overlay                          │ │
│ │                                                                                │ │
│ │ Quality Assurance:                                                             │ │
│ │ - Form validation on all inputs                                                │ │
│ │ - Network error handling                                                       │ │
│ │ - Loading states for all async operations                                      │ │
│ │ - Consistent error messaging                                                   │ │
│ │                                                                                │ │
│ │ This plan delivers a professional, branded mobile app foundation that          │ │
│ │ perfectly matches J.A's Food Trading identity while providing smooth user      │ │
│ │ experience for customer onboarding and authentication.   