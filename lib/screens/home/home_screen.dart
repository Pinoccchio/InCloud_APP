import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/exit_confirmation_dialog.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize screens with navigation callback
    _screens = [
      DashboardScreen(onNavigateToTab: _navigateToTab),
      const SearchScreen(),
      CartScreen(onNavigateToTab: _navigateToTab),
      OrdersScreen(onNavigateToTab: _navigateToTab),
      const ProfileScreen(),
    ];
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Handles the system back button press
  /// Returns true to allow exit, false to prevent it
  Future<bool> _onWillPop() async {
    // If not on the first tab (Dashboard), navigate back to Dashboard
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false; // Prevent app exit
    }

    // If on Dashboard, show exit confirmation dialog
    final shouldExit = await ExitConfirmationDialog.show(context);
    return shouldExit;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent automatic pop
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // If already popped, return
        if (didPop) return;

        // Handle the back button press
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          // Exit the app properly
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfacePrimary,
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: AppColors.primaryRed,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: AppColors.white,
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}


