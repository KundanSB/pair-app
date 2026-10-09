import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/schedule_service.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Plan any day (including tomorrow, ahead of time). The overlap card
/// converts between each person's own timezone via ScheduleService —
/// see that file for the DST-aware math.
class ScheduleScreen extends StatefulWidget {
  final Pairing pairing;
  const ScheduleScreen({super.key, required this.pairing});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _scheduleService = ScheduleService();
  final _profileService = ProfileService();

  DateTime _selectedDate = DateTime.now();
  Profile? _me;
  Profile? _partner;
  List<ScheduleBlock> _mine = [];
  List<ScheduleBlock> _theirs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final myId = supabase.auth.currentUser!.id;
    final partnerId = widget.pairing.partnerIdFor(myId);

    final me = await _profileService.getMyProfile();
    final partner = partnerId == null ? null : await _profileService.getProfile(partnerId);
    final mine = await _scheduleService.getBlocksForDate(myId, _selectedDate);
    final theirs = partnerId == null ? <ScheduleBlock>[] : await _scheduleService.getBlocksForDate(partnerId, _selectedDate);

    if (!mounted) return;
    setState(() {
      _me = me;
      _partner = partner;
      _mine = mine;
      _theirs = theirs;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _load();
    }
  }

  Future<void> _addBlockDialog() async {
    TimeOfDay start = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 20, minute: 0);
    String type = 'free';
    bool remind = false;
    String? timeError;
    final labelController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add block — ${DateFormat.yMMMd().format(_selectedDate)}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'free', child: Text('Free (countable for overlap)')),
                  DropdownMenuItem(value: 'work', child: Text('Work')),
                  DropdownMenuItem(value: 'sleep', child: Text('Sleep')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom')),
                ],
                onChanged: (v) => setSheetState(() => type = v ?? 'free'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'Label (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: start);
                        if (picked != null) setSheetState(() => start = picked);
                      },
                      child: Text('Start: ${start.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: end);
                        if (picked != null) setSheetState(() => end = picked);
                      },
                      child: Text('End: ${end.format(context)}'),
                    ),
                  ),
                ],
              ),
              if (timeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(timeError!, style: const TextStyle(color: AppTheme.alertText, fontSize: 12)),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Remind me (ring/vibrate at start time)'),
                value: remind,
                onChanged: (v) => setSheetState(() => remind = v),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () async {
                  // Form validation (checklist item) — real check lives
                  // in ScheduleService so it's testable and reused if
                  // another screen ever adds blocks too.
                  final error = ScheduleService.validateTimes(start, end);
                  if (error != null) {
                    setSheetState(() => timeError = error);
                    return;
                  }
                  Navigator.pop(context);
                  await _scheduleService.addBlock(
                    forDate: _selectedDate,
                    startTime: '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00',
                    endTime: '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00',
                    blockType: type,
                    label: labelController.text,
                    remindMe: remind,
                  );
                  if (remind) {
                    await NotificationService().scheduleForBlock(
                      date: _selectedDate,
                      time: start,
                      title: labelController.text.trim().isEmpty ? 'Schedule reminder' : labelController.text.trim(),
                    );
                  }
                  _load();
                },
                child: const Text('Save block'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlaps = (_me == null || _partner == null)
        ? <DateTimeRange>[]
        : ScheduleService.overlapFreeWindows(
            date: _selectedDate, mine: _mine, myTimezone: _me!.timezone, theirs: _theirs, theirTimezone: _partner!.timezone,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), tooltip: 'Choose a date', onPressed: _pickDate),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBlockDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add block'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(DateFormat.yMMMEd().format(_selectedDate), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'You plan in your own timezone (${_me?.timezone ?? '—'}); your partner\'s is '
                      '${_partner?.timezone ?? "not set yet"} — the overlap below already converts between them.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.sage.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Overlapping free time', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (overlaps.isEmpty)
                            const Text('No overlap yet on this day — add some "free" blocks.')
                          else
                            ...overlaps.map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('${DateFormat.jm().format(r.start.toLocal())} – ${DateFormat.jm().format(r.end.toLocal())} (your local time)'),
                                )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Your blocks', style: Theme.of(context).textTheme.titleMedium),
                    if (_mine.isEmpty) const Text('Nothing planned yet for this day.'),
                    ..._mine.map((b) => _BlockTile(
                          block: b,
                          onDelete: () async {
                            await _scheduleService.deleteBlock(b.id);
                            _load();
                          },
                        )),
                    const SizedBox(height: 20),
                    Text("Partner's blocks", style: Theme.of(context).textTheme.titleMedium),
                    if (_theirs.isEmpty) const Text("Nothing planned on their side yet."),
                    ..._theirs.map((b) => _BlockTile(block: b)),
                  ],
                ),
              ),
            ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  final ScheduleBlock block;
  final VoidCallback? onDelete;
  const _BlockTile({required this.block, this.onDelete});

  Color _colorFor(String type) => switch (type) {
        'free' => AppTheme.sage,
        'work' => AppTheme.lavender,
        'sleep' => AppTheme.plum,
        _ => AppTheme.coral,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: _colorFor(block.blockType), radius: 6),
        title: Text(block.label ?? block.blockType),
        subtitle: Text('${block.startTime.substring(0, 5)} – ${block.endTime.substring(0, 5)}${block.remindMe ? '  •  🔔 reminder set' : ''}'),
        trailing: onDelete == null
            ? null
            : IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete this block', onPressed: onDelete),
      ),
    );
  }
}
