import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/destinations_service.dart';
import '../services/itineraries_service.dart';
import '../services/auth_service.dart';
import '../models/destination.dart';
import '../widgets/destination_card.dart';
import '../widgets/hill_clipper.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/staggered_list_item.dart';

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
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToItinerarySheet(destination: destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = authService.currentUser?.name.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                HillHero(
                  height: 180,
                  gradientColors: const [AppColors.forestDeep, AppColors.forestMid],
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Karibu, $userName 👋',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.cream),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Where to in Yaoundé today?',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.marigoldLight),
                        ),
                      ],
                    ),
                  ),
                ),
                // Search card floats over the hill edge, Airbnb-style.
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: -26,
                  child: Material(
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Search destinations, tags...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 26 + AppSpacing.lg)),
          SliverToBoxAdapter(
            child: SizedBox(
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
                    selectedColor: AppColors.marigold.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.forest : AppColors.inkMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    ),
                    side: BorderSide(color: selected ? AppColors.marigold : AppColors.border),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        ],
        body: _loading
            ? ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: 4,
                itemBuilder: (_, __) => const DestinationCardShimmer(),
              )
            : _error != null
                ? Center(child: Text(_error!))
                : _destinations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.travel_explore, size: 48, color: AppColors.inkMuted),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'No spots match that search.\nTry a different word or category.',
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
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: _destinations.length,
                          itemBuilder: (context, index) {
                            final destination = _destinations[index];
                            return StaggeredListItem(
                              index: index,
                              child: DestinationCard(
                                destination: destination,
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: AppColors.forest,
                                  onPressed: () => _showAddToItinerarySheet(destination),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Add to itinerary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (!_loading)
                ..._itineraries.map(
                  (itinerary) => ListTile(
                    leading: const Icon(Icons.map_outlined, color: AppColors.forest),
                    title: Text(itinerary.title),
                    onTap: () => _addTo(itinerary),
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle, color: AppColors.marigold),
                title: const Text('Create new itinerary', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: _createNew,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
