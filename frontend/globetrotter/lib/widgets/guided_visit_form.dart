import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/visits_service.dart';

class GuidedVisitForm extends StatefulWidget {
  final String destinationId;
  final String destinationName;

  const GuidedVisitForm({
    super.key,
    required this.destinationId,
    required this.destinationName,
  });

  @override
  State<GuidedVisitForm> createState() => _GuidedVisitFormState();
}

class _GuidedVisitFormState extends State<GuidedVisitForm> with SingleTickerProviderStateMixin {
  DateTime? _date;
  TimeOfDay? _time;
  int _numPeople = 2;
  final _requestsController = TextEditingController();
  bool _booking = false;
  bool _booked = false;
  String? _error;

  late final AnimationController _confirmController;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _confirmController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _checkScale = CurvedAnimation(parent: _confirmController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _confirmController.dispose();
    _requestsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
    if (picked != null) setState(() => _time = picked);
  }

  String get _dateLabel => _date == null
      ? 'Date'
      : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';

  Future<void> _book() async {
    if (_date == null || _time == null) {
      setState(() => _error = 'Choose a date and time first.');
      return;
    }
    setState(() {
      _booking = true;
      _error = null;
    });
    try {
      final dateStr =
          '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';
      final timeStr = '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';
      await visitsService.book(
        destinationId: widget.destinationId,
        date: dateStr,
        time: timeStr,
        numPeople: _numPeople,
        specialRequests: _requestsController.text.trim(),
      );
      setState(() => _booked = true);
      _confirmController.forward();
    } catch (e) {
      setState(() => _error = 'Could not book this visit. Please try again.');
    } finally {
      setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booked) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: AppColors.forest, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: AppColors.cream, size: 32),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Visit booked!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              widget.destinationName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _confirmRow(Icons.calendar_today, _dateLabel),
                  _confirmRow(Icons.access_time, _time?.format(context) ?? ''),
                  _confirmRow(Icons.people_outline, '$_numPeople visitor${_numPeople > 1 ? 's' : ''}'),
                  if (_requestsController.text.trim().isNotEmpty)
                    _confirmRow(Icons.notes, _requestsController.text.trim()),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'You can view or cancel this booking anytime from My Bookings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_available_outlined, size: 18, color: AppColors.forest),
            const SizedBox(width: AppSpacing.xs),
            Text('Order a guided visit', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_dateLabel),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time, size: 16),
                label: Text(_time == null ? 'Time' : _time!.format(context)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Text('People:', style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            IconButton(
              onPressed: _numPeople > 1 ? () => setState(() => _numPeople--) : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.forest,
            ),
            Text('$_numPeople', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              onPressed: () => setState(() => _numPeople++),
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.forest,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _requestsController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Special requests (optional)',
            hintText: 'e.g. wheelchair access, a French-speaking guide...',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _booking ? null : _book,
            child: _booking
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestDeep),
                  )
                : const Text('Book Visit'),
          ),
        ),
      ],
    );
  }

  Widget _confirmRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.inkMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
