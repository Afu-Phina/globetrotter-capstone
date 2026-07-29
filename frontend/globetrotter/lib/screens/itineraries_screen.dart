import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/itineraries_service.dart';
import '../services/auth_service.dart';
import '../models/itinerary.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/staggered_list_item.dart';
import '../utils/page_transitions.dart';
import 'itinerary_detail_screen.dart';
import 'itinerary_form_screen.dart';

class ItinerariesScreen extends StatefulWidget {
  const ItinerariesScreen({super.key});

  @override
  State<ItinerariesScreen> createState() => _ItinerariesScreenState();
}

class _ItinerariesScreenState extends State<ItinerariesScreen> {
  List<Itinerary> _itineraries = [];
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
      final results = await itinerariesService.list();
      setState(() => _itineraries = results);
    } catch (e) {
      setState(() => _error = 'Could not load itineraries.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = authService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('My Itineraries')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.marigold,
        elevation: 2,
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            fadeSlideRoute<bool>(const ItineraryFormScreen()),
          );
          if (created == true) _load();
        },
        child: const Icon(Icons.add, color: AppColors.forestDeep),
      ),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: 3,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ShimmerBox(height: 76, borderRadius: BorderRadius.circular(AppRadius.card)),
              ),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : _itineraries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.marigold.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.map_outlined, size: 40, color: AppColors.marigold),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text('No itineraries yet', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Add a destination from Explore to start planning your trip.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _itineraries.length,
                        itemBuilder: (context, index) {
                          final itinerary = _itineraries[index];
                          final isShared = itinerary.ownerId != myId;
                          return StaggeredListItem(
                            index: index,
                            child: Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(AppSpacing.md),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: (isShared ? AppColors.papaya : AppColors.forest).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isShared ? Icons.people_alt : Icons.map,
                                    color: isShared ? AppColors.papaya : AppColors.forest,
                                  ),
                                ),
                                title: Text(itinerary.title, style: Theme.of(context).textTheme.titleMedium),
                                subtitle: Text(
                                  '${itinerary.destinationIds.length} stop(s)'
                                  '${isShared ? ' · Shared with you' : ''}',
                                ),
                                trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    fadeSlideRoute(ItineraryDetailScreen(itinerary: itinerary)),
                                  );
                                  _load();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
