import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/step_provider.dart';
import '../services/route_manager.dart';
import 'city_detail_screen.dart';
import 'main_screen.dart';
import 'package:google_fonts/google_fonts.dart';

Widget roundedButton({
  required String label,
  required VoidCallback onPressed,
  IconData? icon,
}) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(padding: EdgeInsets.zero),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8D66D),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xFF6C4A2F)),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6C4A2F),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

/// WorldMapScreen Stateful Widget
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({Key? key}) : super(key: key);

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  List<Map<String, dynamic>> unlockedCities = [];

  @override
  void initState() {
    super.initState();
    _loadUnlockedCities();
  }

  Future<void> _loadUnlockedCities() async {
    final stepProvider = Provider.of<StepProvider>(context, listen: false);
    final cities = await RouteManager().loadUnlockedCities(stepProvider.steps);
    setState(() {
      unlockedCities = cities;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          /// 背景地图
          Positioned.fill(
            child: Image.asset(
              'assets/images/Italymap.png',
              fit: BoxFit.cover,
            ),
          ),

          /// 城市徽章标记
          ...unlockedCities.map((city) {
            debugPrint('$city');
            double x = city['x'] / 1000 * screenWidth;
            double y = city['y'] / 1000 * screenHeight;

            return Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                onTap: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: '',
                    barrierColor: Colors.black.withValues(alpha: 0.2), // 半透明背景
                    pageBuilder: (_, __, ___) => const SizedBox(),
                    transitionBuilder: (_, anim, __, child) {
                      return Transform.scale(
                        scale: anim.value,
                        child: Opacity(
                          opacity: anim.value,
                          child: Center(
                            child: Container(
                              width: 320,
                              padding:
                                  const EdgeInsets.fromLTRB(28, 26, 28, 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 24,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.celebration_rounded,
                                          size: 18, color: Color(0xFFF77F42)),
                                      const SizedBox(width: 6),
                                      Text(
                                        "NEW CITY UNLOCKED",
                                        style: GoogleFonts.baloo2(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFF77F42),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    city['name'],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.baloo2(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF6C4A2F),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // 🔥 勋章图案
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFF8D66D)
                                          .withValues(alpha: 0.25),
                                    ),
                                    child: Image.asset(
                                      'assets/images/badges/${city['badge']}',
                                      width: 170,
                                    ),
                                  ),

                                  const SizedBox(height: 22),

                                  roundedButton(
                                    label: 'View details',
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CityDetailScreen(
                                            cityName: city['name'],
                                            badgeImagePath:
                                                'assets/images/badges/${city['badge']}',
                                            stepRequired: city['stepRequired'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Image.asset(
                  'assets/images/badges/${city['badge']}',
                  width: 40,
                ),
              ),
            );
          }).toList(),

          /// 底部按钮组
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                roundedButton(
                  label: 'Home',
                  icon: Icons.home_rounded,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MainScreen(initialIndex: 0)),
                      (route) => false,
                    );
                  },
                ),
                roundedButton(
                  label: 'Food Journey',
                  icon: Icons.restaurant_rounded,
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const MainScreen(initialIndex: 1)),
                        (route) => false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
