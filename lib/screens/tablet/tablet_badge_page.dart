import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/step_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/route_manager.dart';
import '../../services/wiki_city_service.dart';

class TabletBadgePage extends StatefulWidget {
  const TabletBadgePage({super.key});

  @override
  State<TabletBadgePage> createState() => _TabletBadgePageState();
}

class _TabletBadgePageState extends State<TabletBadgePage> {
  static const _mapSourceSize = Size(1024, 1536);

  final TransformationController _mapController = TransformationController();
  List<Map<String, dynamic>> _unlockedCities = [];
  Map<String, dynamic>? _selectedCity;
  Future<WikiCityInfo>? _selectedCityInfo;
  Size? _configuredViewport;
  int? _loadedForSteps;
  double _minScale = 0.1;
  double _maxScale = 4;
  double _fitScale = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final steps = context.watch<StepProvider>().steps;
    if (_loadedForSteps != steps) {
      _loadedForSteps = steps;
      _loadUnlockedCities(steps);
    }
  }

  Future<void> _loadUnlockedCities(int steps) async {
    final cities = await RouteManager().loadUnlockedCities(steps);
    if (!mounted || _loadedForSteps != steps) return;
    setState(() => _unlockedCities = cities);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _selectCity(Map<String, dynamic> city) {
    setState(() {
      _selectedCity = city;
      _selectedCityInfo = WikiCityService().fetchCityInfo(
        city['name']?.toString() ?? '',
      );
    });
  }

  void _configureMap(Size viewport) {
    final containScale = (viewport.width / _mapSourceSize.width) <
            (viewport.height / _mapSourceSize.height)
        ? viewport.width / _mapSourceSize.width
        : viewport.height / _mapSourceSize.height;
    _fitScale = containScale;
    _minScale = containScale * 0.72;
    _maxScale = containScale * 6;

    if (_configuredViewport == viewport) return;
    _configuredViewport = viewport;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _configuredViewport != viewport) return;
      _setScale(containScale, viewport);
    });
  }

  void _setScale(double scale, Size viewport) {
    final clamped = scale.clamp(_minScale, _maxScale).toDouble();
    _mapController.value = Matrix4.identity()
      ..translate(
        (viewport.width - _mapSourceSize.width * clamped) / 2,
        (viewport.height - _mapSourceSize.height * clamped) / 2,
      )
      ..scale(clamped);
  }

  void _zoom(double factor, Size viewport) {
    final current = _mapController.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(_minScale, _maxScale).toDouble();
    if ((target - current).abs() < 0.0001) return;

    final focalPoint = Offset(viewport.width / 2, viewport.height / 2);
    final scenePoint = _mapController.toScene(focalPoint);
    final next = Matrix4.copy(_mapController.value);
    next.translate(scenePoint.dx, scenePoint.dy);
    next.scale(target / current);
    next.translate(-scenePoint.dx, -scenePoint.dy);
    _mapController.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeProvider>().palette;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Badges', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.zero,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final viewport = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        _configureMap(viewport);

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: ColoredBox(
                                color: const Color(0xFF62C6D2),
                                child: InteractiveViewer(
                                  transformationController: _mapController,
                                  constrained: false,
                                  alignment: Alignment.topLeft,
                                  boundaryMargin: const EdgeInsets.all(1600),
                                  minScale: _minScale,
                                  maxScale: _maxScale,
                                  panEnabled: true,
                                  scaleEnabled: true,
                                  trackpadScrollCausesScale: true,
                                  scaleFactor: 160,
                                  child: SizedBox(
                                    width: _mapSourceSize.width,
                                    height: _mapSourceSize.height,
                                    child: AnimatedBuilder(
                                      animation: _mapController,
                                      child: Positioned.fill(
                                        child: Image.asset(
                                          'assets/images/Italymap.png',
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      builder: (context, mapImage) {
                                        final currentScale = _mapController
                                            .value
                                            .getMaxScaleOnAxis();
                                        final zoomRatio =
                                            currentScale / _fitScale;

                                        // Rendered size follows the zoom level,
                                        // while limits keep badges usable and
                                        // prevent nearby cities overlapping.
                                        final renderedBadgeSize =
                                            (38 + 18 * zoomRatio)
                                                .clamp(52.0, 86.0)
                                                .toDouble();
                                        final badgeSize =
                                            renderedBadgeSize / currentScale;

                                        return Stack(
                                          children: [
                                            mapImage!,
                                            ..._unlockedCities.map((city) {
                                              final point = Offset(
                                                (city['mapX'] as num)
                                                        .toDouble() *
                                                    _mapSourceSize.width,
                                                (city['mapY'] as num)
                                                        .toDouble() *
                                                    _mapSourceSize.height,
                                              );
                                              final selected = identical(
                                                    city,
                                                    _selectedCity,
                                                  ) ||
                                                  city['name'] ==
                                                      _selectedCity?['name'];
                                              return Positioned(
                                                left: point.dx - badgeSize / 2,
                                                top: point.dy - badgeSize / 2,
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _selectCity(city),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 160,
                                                    ),
                                                    width: badgeSize,
                                                    height: badgeSize,
                                                    padding: EdgeInsets.all(
                                                      badgeSize *
                                                          (selected
                                                              ? 0.1
                                                              : 0.04),
                                                    ),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: selected
                                                          ? palette.accent
                                                          : Colors.white
                                                              .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Colors.black26,
                                                          blurRadius: 5,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Image.asset(
                                                      'assets/images/badges/${city['badge']}',
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 14,
                              right: 14,
                              child: _MapControls(
                                onZoomIn: () => _zoom(1.25, viewport),
                                onZoomOut: () => _zoom(0.8, viewport),
                                onReset: () {
                                  _configuredViewport = null;
                                  _configureMap(viewport);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 9,
                  child: _CityInfoPanel(
                    city: _selectedCity,
                    cityInfo: _selectedCityInfo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom in',
            onPressed: onZoomIn,
            icon: const Icon(Icons.add),
          ),
          const Divider(height: 1),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove),
          ),
          const Divider(height: 1),
          IconButton(
            tooltip: 'Show full map',
            onPressed: onReset,
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }
}

class _CityInfoPanel extends StatelessWidget {
  final Map<String, dynamic>? city;
  final Future<WikiCityInfo>? cityInfo;

  const _CityInfoPanel({required this.city, required this.cityInfo});

  @override
  Widget build(BuildContext context) {
    if (city == null || cityInfo == null) {
      return const Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        child: SizedBox.expand(),
      );
    }

    final name = city!['name']?.toString() ?? 'Unknown';
    final badge = city!['badge']?.toString() ?? '';
    final steps = (city!['stepRequired'] as num?)?.toInt() ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<WikiCityInfo>(
        future: cityInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/badges/$badge',
                    width: 82,
                    height: 82,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name Explorer',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text('Unlocked at $steps steps'),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              if (snapshot.hasError)
                Text(
                  'Wikipedia content is temporarily unavailable for $name.',
                )
              else ...[
                if (snapshot.data!.city.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      snapshot.data!.city.imageUrl!,
                      height: 190,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(height: 18),
                _InfoSection(
                  title: 'City Description',
                  body: snapshot.data!.city.extract,
                ),
                if (snapshot.data!.landmark != null)
                  _InfoSection(
                    title: 'Landmark: ${snapshot.data!.landmark!.title}',
                    body: snapshot.data!.landmark!.extract,
                  ),
                if (snapshot.data!.history != null)
                  _InfoSection(
                    title: 'History',
                    body: snapshot.data!.history!.extract,
                  ),
                const SizedBox(height: 4),
                Text(
                  'Content retrieved from Wikipedia / Wikimedia REST API.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String body;

  const _InfoSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}
