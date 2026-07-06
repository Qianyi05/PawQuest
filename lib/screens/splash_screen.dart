import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/providers/theme_provider.dart';
import 'package:pawquest/theme/app_palette.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme; // 可选：从上层传入主题切换

  const SplashScreen({super.key, this.onToggleTheme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  AppPalette p = AppPalette.all.first;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    p = context.watch<ThemeProvider>().palette;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.shortestSide >= 600;
    final useLandscapeTabletLayout = isTablet && size.width > size.height;

    return Scaffold(
      // 给深色背景，避免看起来像“白屏”
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeIn,
        child: useLandscapeTabletLayout
            ? _landscapeTabletWelcome()
            : Stack(
                children: [
                  // 背景图
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 底部按钮：按屏幕宽度比例定位，紧贴背景里鱼/饼干图标的右侧
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _welcomeButton(
                            'Login',
                            () => _goTo(const LoginScreen()),
                            width: isTablet ? 420 : null,
                          ),
                          const SizedBox(height: 14),
                          _welcomeButton(
                            'Register',
                            () => _goTo(const RegisterScreen()),
                            width: isTablet ? 420 : null,
                            primary: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _landscapeTabletWelcome() {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 0.62,
                heightFactor: 0.78,
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 54),
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _welcomeButton(
                        'Login',
                        () => _goTo(const LoginScreen()),
                        width: double.infinity,
                      ),
                      const SizedBox(height: 14),
                      _welcomeButton(
                        'Register',
                        () => _goTo(const RegisterScreen()),
                        width: double.infinity,
                        primary: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeButton(
    String label,
    VoidCallback onTap, {
    double? width,
    bool primary = true,
  }) {
    const textStyle = TextStyle(
        fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.5);
    return SizedBox(
      width: width ?? MediaQuery.of(context).size.width * 0.72,
      height: 54,
      child: primary
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: p.primary.withValues(alpha: 0.45),
                shape: const StadiumBorder(),
                textStyle: textStyle,
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: p.primary,
                backgroundColor: Colors.white,
                side: BorderSide(color: p.primary, width: 1.8),
                shape: const StadiumBorder(),
                textStyle: textStyle,
              ),
              child: Text(label),
            ),
    );
  }
}
