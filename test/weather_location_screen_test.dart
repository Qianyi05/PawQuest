import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/screens/weather_location_screen.dart';
import 'package:pawquest/theme/app_palette.dart';

void main() {
  testWidgets('validates coordinates and submits a valid location',
      (tester) async {
    double? submittedLatitude;
    double? submittedLongitude;

    await tester.pumpWidget(
      MaterialApp(
        home: WeatherLocationScreen(
          palette: AppPalette.all.first,
          onCoordinatesSubmitted: (latitude, longitude) async {
            submittedLatitude = latitude;
            submittedLongitude = longitude;
          },
          onDeviceLocationRequested: () async {},
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '100',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '12.4964',
    );
    await tester.tap(find.text('Use these coordinates'));
    await tester.pump();

    expect(find.text('Value must be between -90.0 and 90.0'), findsOneWidget);
    expect(submittedLatitude, isNull);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '41.9028',
    );
    await tester.tap(find.text('Use these coordinates'));
    await tester.pumpAndSettle();

    expect(submittedLatitude, 41.9028);
    expect(submittedLongitude, 12.4964);
  });
}
