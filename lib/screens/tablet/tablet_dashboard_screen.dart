import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../foodsticker_screen.dart';
import '../user_screen.dart';
import '../weather_screen.dart';
import 'tablet_badge_page.dart';
import 'tablet_community_page.dart';
import 'tablet_overview_page.dart';

class TabletDashboardScreen extends StatefulWidget {
  final int initialIndex;

  const TabletDashboardScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<TabletDashboardScreen> createState() => _TabletDashboardScreenState();
}

class _TabletDashboardScreenState extends State<TabletDashboardScreen> {
  late int _selectedIndex;

  final List<Widget> _pages = [
    const TabletOverviewPage(),
    const TabletBadgePage(),
    const FoodStickerScreen(),
    const WeatherScreen(),
    const TabletCommunityPage(),
    const UserScreen(showBottomNavigation: false),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              minWidth: 86,
              groupAlignment: -0.8,
              backgroundColor: palette.surface,
              selectedIconTheme: IconThemeData(
                color: palette.primary,
                size: 30,
              ),
              unselectedIconTheme: IconThemeData(
                color: palette.textMuted,
                size: 26,
              ),
              selectedLabelTextStyle: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: palette.textMuted,
              ),
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Overview'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  selectedIcon: Icon(Icons.emoji_events),
                  label: Text('Badges'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu),
                  label: Text('Food'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.cloud_outlined),
                  selectedIcon: Icon(Icons.cloud),
                  label: Text('Weather'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum),
                  label: Text('Talk'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _pages[_selectedIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
