import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pawquest/screens/weather_location_screen.dart';
import 'package:pawquest/theme/app_palette.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens location input, applies Rome, and returns',
      (tester) async {
    String selectedLocation = 'Device location';

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Center(child: Text(selectedLocation)),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WeatherLocationScreen(
                    palette: AppPalette.all.first,
                    onCoordinatesSubmitted: (latitude, longitude) async {
                      setState(() {
                        selectedLocation = '$latitude, $longitude';
                      });
                    },
                    onDeviceLocationRequested: () async {},
                  ),
                ),
              ),
              child: const Icon(Icons.edit_location_alt),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.edit_location_alt));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      '41.9028',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '12.4964',
    );
    await tester.tap(find.text('Use these coordinates'));
    await tester.pumpAndSettle();

    expect(find.text('41.9028, 12.4964'), findsOneWidget);
    expect(find.text('Weather location'), findsNothing);
  });
}
