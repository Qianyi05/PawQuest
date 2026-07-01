import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/daily_quest_provider.dart';
import '../providers/step_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_palette.dart';

class WeatherLocationScreen extends StatefulWidget {
  final Future<void> Function(double latitude, double longitude)?
      onCoordinatesSubmitted;
  final Future<void> Function()? onDeviceLocationRequested;
  final double? initialLatitude;
  final double? initialLongitude;
  final AppPalette? palette;

  const WeatherLocationScreen({
    super.key,
    this.onCoordinatesSubmitted,
    this.onDeviceLocationRequested,
    this.initialLatitude,
    this.initialLongitude,
    this.palette,
  });

  @override
  State<WeatherLocationScreen> createState() => _WeatherLocationScreenState();
}

class _WeatherLocationScreenState extends State<WeatherLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final provider = widget.onCoordinatesSubmitted == null &&
            widget.initialLatitude == null &&
            widget.initialLongitude == null
        ? context.read<DailyQuestProvider>()
        : null;
    _latitudeController = TextEditingController(
      text: (widget.initialLatitude ?? provider?.manualLatitude)?.toString() ??
          '',
    );
    _longitudeController = TextEditingController(
      text:
          (widget.initialLongitude ?? provider?.manualLongitude)?.toString() ??
              '',
    );
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  String? _validateCoordinate(String? value, double min, double max) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null) return 'Enter a valid number';
    if (number < min || number > max) {
      return 'Value must be between $min and $max';
    }
    return null;
  }

  Future<void> _useCoordinates() async {
    if (!_formKey.currentState!.validate()) return;
    final latitude = double.parse(_latitudeController.text.trim());
    final longitude = double.parse(_longitudeController.text.trim());
    await _submit(() {
      if (widget.onCoordinatesSubmitted != null) {
        return widget.onCoordinatesSubmitted!(latitude, longitude);
      }
      return context.read<DailyQuestProvider>().useManualLocation(
            latitude: latitude,
            longitude: longitude,
            currentSteps: context.read<StepProvider>().todaySteps,
          );
    });
  }

  Future<void> _useDeviceLocation() async {
    await _submit(() {
      if (widget.onDeviceLocationRequested != null) {
        return widget.onDeviceLocationRequested!();
      }
      return context.read<DailyQuestProvider>().useDeviceLocation(
            currentSteps: context.read<StepProvider>().todaySteps,
          );
    });
  }

  Future<void> _submit(Future<void> Function() action) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette ?? context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.accent,
        title: const Text('Weather location'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Enter any coordinates to use the current weather at that place.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _latitudeController,
                  enabled: !_isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: 'Example: 41.9028',
                    prefixIcon: Icon(Icons.north_rounded),
                  ),
                  validator: (value) => _validateCoordinate(value, -90, 90),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _longitudeController,
                  enabled: !_isSubmitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: 'Example: 12.4964',
                    prefixIcon: Icon(Icons.east_rounded),
                  ),
                  validator: (value) => _validateCoordinate(value, -180, 180),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _useCoordinates,
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('Use these coordinates'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _useDeviceLocation,
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Use device location'),
          ),
        ],
      ),
    );
  }
}
