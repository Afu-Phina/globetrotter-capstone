import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/itineraries_service.dart';
import '../models/destination.dart';
import '../widgets/destination_card.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  List<Destination> _recommendations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await recommendationsService.get();
      setState(() => _recommendations = results);
    } catch (e) {
      setState(() => _error = 'Could not load recommendations.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('For You')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          'Based on your itineraries and popular spots in Yaoundé',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      ..._recommendations.map((d) => DestinationCard(destination: d)),
                    ],
                  ),
                ),
    );
  }
}
