import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/destination.dart';
import '../models/review.dart';
import '../services/itineraries_service.dart';
import '../services/destinations_service.dart';
import 'rating_stars.dart';
import 'ask_question_widget.dart';
import 'guided_visit_form.dart';
import 'destination_image.dart';

/// Full "place details" sheet -- description, tags, rating/reviews, an
/// ask-a-question FAQ, a guided-visit booking form, an "open in maps"
/// shortcut, and adding the place to an itinerary. No photo gallery or
/// embedded map: Phase 1 has no image hosting or maps API key, so this
/// covers everything that's realistically buildable on this stack.
class DestinationDetailSheet extends StatefulWidget {
  final Destination destination;
  const DestinationDetailSheet({super.key, required this.destination});

  @override
  State<DestinationDetailSheet> createState() => _DestinationDetailSheetState();
}

class _DestinationDetailSheetState extends State<DestinationDetailSheet> {
  bool _loadingItineraries = true;
  List _itineraries = [];
  bool _added = false;

  List<Review> _reviews = [];
  bool _loadingReviews = true;

  List<Destination> _nearby = [];
  bool _loadingNearby = true;

  @override
  void initState() {
    super.initState();
    _fetchItineraries();
    _fetchReviews();
    _fetchNearby();
  }

  Future<void> _fetchNearby() async {
    try {
      final results = await destinationsService.getNearby(widget.destination.id);
      if (mounted) {
        setState(() {
          _nearby = results;
          _loadingNearby = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  Future<void> _fetchItineraries() async {
    final results = await itinerariesService.list();
    if (mounted) {
      setState(() {
        _itineraries = results;
        _loadingItineraries = false;
      });
    }
  }

  Future<void> _fetchReviews() async {
    final results = await destinationsService.getReviews(widget.destination.id);
    if (mounted) {
      setState(() {
        _reviews = results;
        _loadingReviews = false;
      });
    }
  }

  Future<void> _addTo(dynamic itinerary) async {
    final updatedIds = [...itinerary.destinationIds, widget.destination.id];
    await itinerariesService.update(itinerary.id, {'destination_ids': updatedIds});
    if (mounted) {
      setState(() => _added = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to ${itinerary.title}')),
      );
    }
  }

  Future<void> _createNewItinerary() async {
    await itinerariesService.create(
      title: '${widget.destination.name} trip',
      destinationIds: [widget.destination.id],
    );
    if (mounted) {
      setState(() => _added = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New itinerary created')),
      );
    }
  }

  Future<void> _openInMaps() async {
    final query = Uri.encodeComponent('${widget.destination.name}, Yaoundé, Cameroon');
    // "dir" (directions) mode instead of "search": leaving origin blank tells
    // Maps to use the device's current location automatically, so it opens
    // showing the route and estimated travel time to get there -- not just
    // a pin on the map.
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps.')),
      );
    }
  }

  Future<void> _showWriteReviewSheet() async {
    final result = await showModalBottomSheet<Review>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(destinationId: widget.destination.id),
    );
    if (result != null) {
      setState(() => _reviews = [result, ..._reviews]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (d.imageUrl != null) ...[
                Hero(
                  tag: 'destination-image-${d.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: DestinationImage(
                            source: d.imageUrl!,
                            debugLabel: d.name,
                            fallback: Container(
                              color: AppColors.surface,
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined, color: AppColors.inkMuted),
                              ),
                            ),
                          ),
                        ),
                        if (d.imageAttribution != null)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                d.imageAttribution!,
                                style: const TextStyle(fontSize: 9, color: Colors.white70),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.forest.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  d.category,
                  style: const TextStyle(fontSize: 12, color: AppColors.forest, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(d.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Row(
                children: [
                  RatingStars(averageRating: d.averageRating, reviewCount: d.reviewCount),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.place, size: 14, color: AppColors.inkMuted),
                  const SizedBox(width: 3),
                  Text(d.neighborhood, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(d.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...d.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.papaya.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(fontSize: 12, color: AppColors.papaya, fontWeight: FontWeight.w600),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (d.history != null) ...[
                Row(
                  children: [
                    const Icon(Icons.history_edu_outlined, size: 16, color: AppColors.forest),
                    const SizedBox(width: AppSpacing.xs),
                    Text('History', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(d.history!, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
              ],
              if (d.funFact != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.marigold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.marigold),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(d.funFact!, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (d.travelTips.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, size: 16, color: AppColors.forest),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Travel Tips', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ...d.travelTips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(tip, style: Theme.of(context).textTheme.bodyMedium)),
                        ],
                      ),
                    )),
                const SizedBox(height: AppSpacing.sm),
              ],
              OutlinedButton.icon(
                onPressed: _openInMaps,
                icon: const Icon(Icons.directions, size: 16),
                label: const Text('Get Directions'),
              ),

              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              AskQuestionWidget(destinationId: d.id),

              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              GuidedVisitForm(destinationId: d.id, destinationName: d.name),

              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton(onPressed: _showWriteReviewSheet, child: const Text('Write a review')),
                ],
              ),
              if (_loadingReviews) const Center(child: CircularProgressIndicator()),
              if (!_loadingReviews && _reviews.isEmpty)
                Text('No reviews yet -- be the first.', style: Theme.of(context).textTheme.bodyMedium),
              ..._reviews.map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(r.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(width: AppSpacing.sm),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 14,
                                color: AppColors.marigold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r.comment, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              if (!_loadingNearby && _nearby.isNotEmpty) ...[
                Text('Nearby in our guide', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Other places we know about nearby -- not a full map search.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _nearby.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final place = _nearby[index];
                      return ActionChip(
                        avatar: const Icon(Icons.place_outlined, size: 14, color: AppColors.forest),
                        label: Text(place.name),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DestinationDetailSheet(destination: place),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text('Add to itinerary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (_loadingItineraries) const Center(child: CircularProgressIndicator()),
              if (!_loadingItineraries)
                ..._itineraries.map(
                  (itinerary) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: const Icon(Icons.map_outlined, color: AppColors.forest),
                      title: Text(itinerary.title),
                      trailing: _added ? const Icon(Icons.check_circle, color: AppColors.forest) : null,
                      onTap: () => _addTo(itinerary),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _createNewItinerary,
                  icon: const Icon(Icons.add),
                  label: const Text('Create new itinerary'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Small bottom sheet for submitting a new review.
class _WriteReviewSheet extends StatefulWidget {
  final String destinationId;
  const _WriteReviewSheet({required this.destinationId});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_commentController.text.trim().isEmpty) {
      setState(() => _error = 'Write a short comment first.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final review = await destinationsService.addReview(
        widget.destinationId,
        _rating,
        _commentController.text.trim(),
      );
      if (mounted) Navigator.pop(context, review);
    } catch (e) {
      setState(() => _error = 'Could not submit your review. Are you logged in?');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Write a review', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              RatingPicker(value: _rating, onChanged: (v) => setState(() => _rating = v)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'What stood out to you?'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestDeep),
                        )
                      : const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
