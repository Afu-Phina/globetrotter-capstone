import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/destinations_service.dart';
import '../services/itineraries_service.dart';
import '../models/destination.dart';
import '../widgets/destination_card.dart';

class DestinationsScreen extends StatefulWidget {
  const DestinationsScreen({super.key});

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  final _searchController = TextEditingController();
  List<Destination> _destinations = [];
  bool _loading = true;
  String? _error;
  Timer? _debounce;

  static const _categories = [
    'All',
    'Nature & Wildlife',
    'History & Culture',
    'Markets & Shopping',
    'Nature & Views',
    'Nightlife & Dining',
    'Local Life',
  ];
  String _selectedCategory = 'All';

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
      final results = await destinationsService.list(
        query: _searchController.text.trim(),
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      setState(() => _destinations = results);
    } catch (e) {
      setState(() => _error = 'Could not load destinations. Check your connection.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddToItinerarySheet(Destination destination) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _AddToItinerarySheet(destination: destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Yaoundé')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search destinations, tags...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                    _load();
                  },
                  selectedColor: AppColors.forest.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.forest : AppColors.inkMuted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _destinations.isEmpty
                        ? const Center(child: Text('No destinations found.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              itemCount: _destinations.length,
                              itemBuilder: (context, index) {
                                final destination = _destinations[index];
                                return DestinationCard(
                                  destination: destination,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: AppColors.forest,
                                    onPressed: () => _showAddToItinerarySheet(destination),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet: add this destination to an existing itinerary, or create
/// a brand new one with it as the first stop.
class _AddToItinerarySheet extends StatefulWidget {
  final Destination destination;
  const _AddToItinerarySheet({required this.destination});

  @override
  State<_AddToItinerarySheet> createState() => _AddToItinerarySheetState();
}

class _AddToItinerarySheetState extends State<_AddToItinerarySheet> {
  bool _loading = true;
  List _itineraries = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final results = await itinerariesService.list();
    setState(() {
      _itineraries = results;
      _loading = false;
    });
  }

  Future<void> _addTo(dynamic itinerary) async {
    final updatedIds = [...itinerary.destinationIds, widget.destination.id];
    await itinerariesService.update(itinerary.id, {'destination_ids': updatedIds});
    if (mounted) Navigator.pop(context);
  }

  Future<void> _createNew() async {
    await itinerariesService.create(
      title: '${widget.destination.name} trip',
      destinationIds: [widget.destination.id],
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add to itinerary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading)
              ..._itineraries.map(
                (itinerary) => ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(itinerary.title),
                  onTap: () => _addTo(itinerary),
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.forest),
              title: const Text('Create new itinerary'),
              onTap: _createNew,
            ),
          ],
        ),
      ),
    );
  }
}
