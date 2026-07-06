import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/step_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_palette.dart';
import '../services/route_manager.dart';
import 'city_detail_screen.dart';
import 'responsive_main_screen.dart';
import 'package:google_fonts/google_fonts.dart';

Widget roundedButton({
  required String label,
  required VoidCallback onPressed,
  required AppPalette p,
  IconData? icon,
}) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(padding: EdgeInsets.zero),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: p.accent,
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
            Icon(icon, size: 18, color: p.text),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: TextStyle(
              color: p.text,
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
  static const _mapSourceSize = Size(1024, 1536);
  static const _badgeSize = 40.0;

  final TransformationController _mapController = TransformationController();
  List<Map<String, dynamic>> unlockedCities = [];
  Size? _configuredViewport;

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
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _configureInitialView(Size viewportSize, double coverScale) {
    if (_configuredViewport == viewportSize) return;
    _configuredViewport = viewportSize;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _configuredViewport != viewportSize) return;
      final renderedWidth = _mapSourceSize.width * coverScale;
      final renderedHeight = _mapSourceSize.height * coverScale;
      _mapController.value = Matrix4.identity()
        ..translate(
          (viewportSize.width - renderedWidth) / 2,
          (viewportSize.height - renderedHeight) / 2,
        )
        ..scale(coverScale);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final widthScale = viewportSize.width / _mapSourceSize.width;
          final heightScale = viewportSize.height / _mapSourceSize.height;
          final containScale =
              widthScale < heightScale ? widthScale : heightScale;
          final coverScale =
              widthScale > heightScale ? widthScale : heightScale;
          _configureInitialView(viewportSize, coverScale);

          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xFF62C6D2),
                  child: InteractiveViewer(
                    transformationController: _mapController,
                    constrained: false,
                    alignment: Alignment.topLeft,
                    boundaryMargin: const EdgeInsets.all(2000),
                    minScale: containScale,
                    maxScale: coverScale * 4,
                    panEnabled: true,
                    scaleEnabled: true,
                    trackpadScrollCausesScale: true,
                    scaleFactor: 160,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _mapSourceSize.width,
                      height: _mapSourceSize.height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/Italymap.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                          ...unlockedCities.map((city) {
                            final point = Offset(
                              (city['mapX'] as num).toDouble() *
                                  _mapSourceSize.width,
                              (city['mapY'] as num).toDouble() *
                                  _mapSourceSize.height,
                            );
                            return _cityBadge(city, point, p);
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// Bottom action group.
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    roundedButton(
                      p: p,
                      label: 'Home',
                      icon: Icons.home_rounded,
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ResponsiveMainScreen(initialIndex: 0)),
                          (route) => false,
                        );
                      },
                    ),
                    roundedButton(
                      p: p,
                      label: 'Food Journey',
                      icon: Icons.restaurant_rounded,
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ResponsiveMainScreen(
                                        initialIndex: 1)),
                            (route) => false);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cityBadge(Map<String, dynamic> city, Offset point, AppPalette p) {
    return Positioned(
      left: point.dx - _badgeSize / 2,
      top: point.dy - _badgeSize / 2,
      child: GestureDetector(
        onTap: () {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: '',
            barrierColor: Colors.black.withValues(alpha: 0.2), // Translucent scrim
            pageBuilder: (_, __, ___) => const SizedBox(),
            transitionBuilder: (_, anim, __, child) {
              return Transform.scale(
                scale: anim.value,
                child: Opacity(
                  opacity: anim.value,
                  child: Center(
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
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
                              Icon(Icons.celebration_rounded,
                                  size: 18, color: p.primary),
                              const SizedBox(width: 6),
                              Text(
                                "NEW CITY UNLOCKED",
                                style: GoogleFonts.baloo2(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: p.primary,
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
                              color: p.text,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Badge artwork.
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.accent.withValues(alpha: 0.25),
                            ),
                            child: Image.asset(
                              'assets/images/badges/${city['badge']}',
                              width: 170,
                            ),
                          ),

                          const SizedBox(height: 22),

                          roundedButton(
                            p: p,
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
          width: _badgeSize,
          height: _badgeSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
