import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/itineraries_service.dart';
import '../services/auth_service.dart';
import '../models/itinerary.dart';
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
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ItineraryFormScreen()),
          );
          if (created == true) _load();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _itineraries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_outlined, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No itineraries yet.\nAdd destinations from Explore to start one.',
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(AppSpacing.md),
                              leading: Icon(
                                isShared ? Icons.people_alt : Icons.map,
                                color: AppColors.primary,
                              ),
                              title: Text(itinerary.title),
                              subtitle: Text(
                                '${itinerary.destinationIds.length} stop(s)'
                                '${isShared ? ' · Shared with you' : ''}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ItineraryDetailScreen(itinerary: itinerary),
                                  ),
                                );
                                _load();
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
