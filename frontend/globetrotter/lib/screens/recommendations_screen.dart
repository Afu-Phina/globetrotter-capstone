import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/itineraries_service.dart';
import '../models/destination.dart';
import '../widgets/destination_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/staggered_list_item.dart';

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
          ? ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: 4,
              itemBuilder: (_, __) => const DestinationCardShimmer(),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.forestDeep, AppColors.forestMid],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.marigoldLight),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Picked from your itineraries and what\'s popular in Yaoundé',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.cream),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._recommendations.asMap().entries.map(
                            (entry) => StaggeredListItem(
                              index: entry.key,
                              child: DestinationCard(destination: entry.value),
                            ),
                          ),
                    ],
                  ),
                ),
    );
  }
}
