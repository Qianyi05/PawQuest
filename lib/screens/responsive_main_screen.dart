import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'main_screen.dart';
import 'tablet/tablet_dashboard_screen.dart';

class ResponsiveMainScreen extends StatelessWidget {
  final int initialIndex;

  const ResponsiveMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isTablet(context)) {
      return TabletDashboardScreen(
        initialIndex: _tabletIndexForPhoneIndex(initialIndex),
      );
    }

    return MainScreen(initialIndex: initialIndex);
  }

  int _tabletIndexForPhoneIndex(int phoneIndex) {
    // Tablet index 1 is the extra Badges page. Keep the shared phone indexes
    // stable so Home/Food/Weather/Talk/Profile navigation opens the same
    // feature on every device.
    return switch (phoneIndex) {
      0 => 0, // Overview / Home
      1 => 2, // Food Journey
      2 => 3, // Weather
      3 => 4, // Talk
      4 => 5, // Profile
      _ => 0,
    };
  }
}
