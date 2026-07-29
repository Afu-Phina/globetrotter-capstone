import 'package:flutter/material.dart';
import 'package:globetrotter/screens/itineraries_screen.dart';
import '../theme/app_theme.dart';
import '../services/itineraries_service.dart';
import '../services/destinations_service.dart';
import '../services/auth_service.dart';
// ignore: unused_import
import '../models/itinerary.dart';
// ignore: unused_import
import '../models/destination.dart';
import 'itinerary_form_screen.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final Itinerary itinerary;
  const ItineraryDetailScreen({super.key, required this.itinerary});

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  late Itinerary _itinerary;
  List<Destination> _stops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _itinerary = widget.itinerary;
    _loadStops();
  }

  Future<void> _loadStops() async {
    setState(() => _loading = true);
    final stops = await Future.wait(
      _itinerary.destinationIds.map((id) => destinationsService.getById(id)),
    );
    setState(() {
      _stops = stops;
      _loading = false;
    });
  }

  bool get _isOwner => _itinerary.ownerId == authService.currentUser?.id;

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete itinerary?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await itinerariesService.delete(_itinerary.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _share() async {
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Share itinerary'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: "Friend's email"),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, emailController.text.trim()),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    if (email != null && email.isNotEmpty) {
      try {
        final updated = await itinerariesService.share(_itinerary.id, email);
        setState(() => _itinerary = updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Shared with $email')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not share: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_itinerary.title),
        actions: _isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.person_add_alt),
                  onPressed: _share,
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ItineraryFormScreen(existing: _itinerary),
                      ),
                    );
                    if (updated == true) Navigator.of(context).pop();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: _delete,
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (_itinerary.notes.isNotEmpty) ...[
                  Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_itinerary.notes, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text('Stops (${_stops.length})', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                if (_stops.isEmpty)
                  const Text('No destinations added yet. Add some from Explore.'),
                ..._stops.map(
                  (d) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: const Icon(Icons.place, color: AppColors.forest),
                      title: Text(d.name),
                      subtitle: Text(d.neighborhood),
                    ),
                  ),
                ),
                if (_itinerary.sharedWith.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Shared with ${_itinerary.sharedWith.length} other user(s)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
    );
  }
}
