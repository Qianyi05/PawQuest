import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/daily_quest_provider.dart';
import '../providers/step_provider.dart';
import '../providers/theme_provider.dart';
import 'weather_location_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final steps = context.read<StepProvider>().todaySteps;
      context.read<DailyQuestProvider>().loadTodayQuest(steps);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final steps = context.watch<StepProvider>().todaySteps;
    final provider = context.watch<DailyQuestProvider>();
    final weather = provider.weather;
    final quest = provider.quest;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.accent,
        leading: IconButton(
          tooltip: 'Change weather location',
          icon: const Icon(Icons.edit_location_alt_rounded),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const WeatherLocationScreen(),
            ),
          ),
        ),
        title: const Text('Weather Quest'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: provider.isLoading
                ? null
                : () => context.read<DailyQuestProvider>().refresh(steps),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DailyQuestProvider>().refresh(steps),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(),
              ),
            if (provider.errorMessage != null)
              _MessageCard(message: provider.errorMessage!),
            _WeatherCard(
              cityName: weather?.locationName ?? quest?.locationName,
              temperature: weather?.temperature ?? quest?.temperature,
              weatherMain: weather?.weatherMain ?? quest?.weatherMain,
              description: weather?.description,
              advice: weather?.walkingAdvice,
            ),
            const SizedBox(height: 16),
            if (quest == null && provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (quest != null)
              _QuestCard(
                title: quest.questTitle,
                description: quest.questDescription,
                currentSteps: quest.currentSteps,
                goalSteps: quest.goalSteps,
                completed: quest.completed,
              )
            else
              const _MessageCard(
                message: 'Daily Quest is not ready yet. Tap refresh to retry.',
              ),
          ],
        ),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final String? cityName;
  final double? temperature;
  final String? weatherMain;
  final String? description;
  final String? advice;

  const _WeatherCard({
    this.cityName,
    this.temperature,
    this.weatherMain,
    this.description,
    this.advice,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cityName ?? 'Current location',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              temperature == null
                  ? '-- °C'
                  : '${temperature!.toStringAsFixed(1)} °C',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: p.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              [
                weatherMain ?? 'Weather unavailable',
                if (description != null) description!,
              ].join(' · '),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              advice ?? 'Refresh to get walking advice for your location.',
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final String title;
  final String description;
  final int currentSteps;
  final int goalSteps;
  final bool completed;

  const _QuestCard({
    required this.title,
    required this.description,
    required this.currentSteps,
    required this.goalSteps,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final progress =
        goalSteps == 0 ? 0.0 : (currentSteps / goalSteps).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  completed ? Icons.verified : Icons.flag,
                  color: completed ? Colors.green : p.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(height: 1.35)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                backgroundColor: p.accent.withValues(alpha: 0.35),
                color: completed ? Colors.green : p.accent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$currentSteps / $goalSteps steps',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              completed ? 'Completed' : 'In progress',
              style: TextStyle(
                color: completed ? Colors.green : Colors.brown,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Card(
      color: p.accent.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
