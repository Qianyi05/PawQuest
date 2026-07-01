import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/utils/map_coordinates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 16 cities have normalized map coordinates', () async {
    final json = await rootBundle.loadString('assets/config/cities.json');
    final cities = (jsonDecode(json) as List).cast<Map<String, dynamic>>();

    expect(cities, hasLength(16));
    for (final city in cities) {
      expect(city['mapX'], isA<num>(), reason: '${city['name']} mapX');
      expect(city['mapY'], isA<num>(), reason: '${city['name']} mapY');
      expect((city['mapX'] as num).toDouble(), inInclusiveRange(0, 1));
      expect((city['mapY'] as num).toDouble(), inInclusiveRange(0, 1));
    }
  });

  test('cover mapping includes centered crop on a landscape viewport', () {
    final point = normalizedMapPointInCover(
      normalizedPoint: const Offset(0.5, 0.5),
      sourceSize: const Size(1024, 1536),
      viewportSize: const Size(1200, 900),
    );

    expect(point.dx, closeTo(600, 0.001));
    expect(point.dy, closeTo(450, 0.001));
  });

  test('cover mapping preserves points on a matching portrait ratio', () {
    final point = normalizedMapPointInCover(
      normalizedPoint: const Offset(0.25, 0.75),
      sourceSize: const Size(1024, 1536),
      viewportSize: const Size(400, 600),
    );

    expect(point.dx, closeTo(100, 0.001));
    expect(point.dy, closeTo(450, 0.001));
  });
}
