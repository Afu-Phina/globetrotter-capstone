import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/visits_service.dart';
import '../models/visit.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/staggered_list_item.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Visit> _visits = [];
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
      final results = await visitsService.listMine();
      setState(() => _visits = results);
    } catch (e) {
      setState(() => _error = 'Could not load your bookings.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancel(Visit visit) async {
    await visitsService.cancel(visit.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: 3,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ShimmerBox(height: 90, borderRadius: BorderRadius.circular(AppRadius.card)),
              ),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : _visits.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_busy_outlined, size: 44, color: AppColors.inkMuted),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No guided visits booked yet.\nBook one from a destination\'s page.',
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
                        itemCount: _visits.length,
                        itemBuilder: (context, index) {
                          final visit = _visits[index];
                          final cancelled = visit.status == 'cancelled';
                          return StaggeredListItem(
                            index: index,
                            child: Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: (cancelled ? AppColors.inkMuted : AppColors.marigold).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        cancelled ? Icons.event_busy : Icons.event_available,
                                        color: cancelled ? AppColors.inkMuted : AppColors.marigold,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(visit.destinationName, style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${visit.date} · ${visit.time} · ${visit.numPeople} people',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          if (visit.specialRequests.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                'Note: ${visit.specialRequests}',
                                                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted, fontStyle: FontStyle.italic),
                                              ),
                                            ),
                                          if (cancelled)
                                            const Padding(
                                              padding: EdgeInsets.only(top: 2),
                                              child: Text(
                                                'Cancelled',
                                                style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (!cancelled)
                                      IconButton(
                                        icon: const Icon(Icons.close, color: AppColors.error),
                                        onPressed: () => _cancel(visit),
                                        tooltip: 'Cancel',
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
