import 'package:flutter/material.dart';
import 'package:pawquest/screens/home_screen.dart';
import 'package:pawquest/screens/foodsticker_screen.dart';
import 'package:pawquest/screens/community_screen.dart';
import 'package:pawquest/screens/user_screen.dart';
import 'package:pawquest/screens/weather_screen.dart';
import '../widgets/custom_bottom_bar.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  final List<Widget> _pages = [
    const HomeScreen(),
    const FoodStickerScreen(),
    const WeatherScreen(),
    CommunityScreen(), //
    const UserScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Main Screen'),
      // ),
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
