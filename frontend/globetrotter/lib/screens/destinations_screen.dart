import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/destinations_service.dart';
import '../services/auth_service.dart';
import '../models/destination.dart';
import '../widgets/destination_grid_card.dart';
import '../widgets/destination_detail_sheet.dart';
import '../widgets/quick_place_sheet.dart';
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
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  Timer? _debounce;

  static const _pageSize = 8;

  static const _categories = [
    'All',
    'Nature & Wildlife',
    'History & Culture',
    'Markets & Shopping',
    'Nature & Views',
    'Nightlife & Dining',
    'Sports & Recreation',
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
      final page = await destinationsService.list(
        query: _searchController.text.trim(),
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        limit: _pageSize,
      );
      setState(() {
        _destinations = page.items;
        _total = page.total;
      });
    } catch (e) {
      setState(() => _error = 'Could not load destinations. Check your connection.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _destinations.length >= _total) return;
    setState(() => _loadingMore = true);
    try {
      final page = await destinationsService.list(
        query: _searchController.text.trim(),
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        limit: _pageSize,
        offset: _destinations.length,
      );
      setState(() {
        _destinations = [..._destinations, ...page.items];
        _total = page.total;
      });
    } catch (e) {
      // Silent -- the user can just tap "Load More Places" again.
    } finally {
      setState(() => _loadingMore = false);
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

  void _openDetail(Destination destination) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DestinationDetailSheet(destination: destination),
    );
  }

  /// Opens a popup for a place typed in search that isn't in our curated
  /// destinations.json -- styled consistently with a real destination's
  /// popup, but honest that there's no real data behind it (see
  /// QuickPlaceSheet).
  void _openQuickPlace(String query) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickPlaceSheet(query: query),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = authService.currentUser?.name.split(' ').first ?? 'there';
    final hasMore = _destinations.length < _total;

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
                          'Welcome, $userName 👋',
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
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        ],
        body: _loading
            ? GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.78,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => ShimmerBox(
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
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
                              if (_searchController.text.trim().isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  "Not in our curated list yet? Tap below to look it up.",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Material(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.card),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(AppRadius.card),
                                    onTap: () => _openQuickPlace(_searchController.text.trim()),
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.place_outlined, color: AppColors.marigold),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            '"${_searchController.text.trim()}"',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          const Icon(Icons.chevron_right, color: AppColors.inkMuted),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                0,
                                AppSpacing.md,
                                AppSpacing.md,
                              ),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: AppSpacing.md,
                                  crossAxisSpacing: AppSpacing.md,
                                  childAspectRatio: 0.78,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final destination = _destinations[index];
                                    return StaggeredListItem(
                                      index: index % _pageSize,
                                      child: DestinationGridCard(
                                        destination: destination,
                                        onTap: () => _openDetail(destination),
                                      ),
                                    );
                                  },
                                  childCount: _destinations.length,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  0,
                                  AppSpacing.lg,
                                  AppSpacing.xl,
                                ),
                                child: Center(
                                  child: hasMore
                                      ? OutlinedButton(
                                          onPressed: _loadingMore ? null : _loadMore,
                                          child: _loadingMore
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Text('Load More Places'),
                                        )
                                      : Text(
                                          'That\'s every spot in Yaoundé we know about so far.',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
