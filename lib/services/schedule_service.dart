import 'package:flutter/material.dart' show DateTimeRange, TimeOfDay;
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';
import '../models/models.dart';

class ScheduleService {
  Future<List<ScheduleBlock>> getBlocksForDate(String userId, DateTime date) async {
    final dateStr = _dateOnly(date);
    final res = await supabase
        .from('schedule_blocks')
        .select()
        .eq('user_id', userId)
        .eq('for_date', dateStr)
        .order('start_time');
    return (res as List).map((b) => ScheduleBlock.fromMap(b)).toList();
  }

  /// Rejects a zero-length block (start == end) — an easy accidental tap
  /// to make in the time picker, and a block with no duration is
  /// meaningless for the overlap calculation anyway. Blocks crossing
  /// midnight (e.g. 22:00 sleep to 06:00) are valid and handled correctly
  /// downstream in overlapFreeWindows.
  static String? validateTimes(TimeOfDay start, TimeOfDay end) {
    if (start.hour == end.hour && start.minute == end.minute) {
      return 'Start and end time can\'t be the same.';
    }
    return null;
  }

  Future<void> addBlock({
    required DateTime forDate,
    required String startTime,
    required String endTime,
    required String blockType,
    String? label,
    bool remindMe = false,
  }) async {
    await supabase.from('schedule_blocks').insert({
      'user_id': supabase.auth.currentUser!.id,
      'for_date': _dateOnly(forDate),
      'start_time': startTime,
      'end_time': endTime,
      'block_type': blockType,
      'label': label?.trim().isEmpty == true ? null : label?.trim(),
      'remind_me': remindMe,
    });
  }

  Future<void> deleteBlock(String id) async {
    await supabase.from('schedule_blocks').delete().eq('id', id);
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Computes overlapping "free" windows between two people on the SAME
  /// calendar date, correctly converting each person's local blocks
  /// through their own IANA timezone (DST-aware) before comparing.
  /// Requires `tz.initializeTimeZones()` to have run at app startup.
  static List<DateTimeRange> overlapFreeWindows({
    required DateTime date,
    required List<ScheduleBlock> mine,
    required String myTimezone,
    required List<ScheduleBlock> theirs,
    required String theirTimezone,
  }) {
    final myLocation = _safeLocation(myTimezone);
    final theirLocation = _safeLocation(theirTimezone);

    final myRanges = _toUtcRanges(mine, date, myLocation);
    final theirRanges = _toUtcRanges(theirs, date, theirLocation);

    final overlaps = <DateTimeRange>[];
    for (final a in myRanges) {
      for (final b in theirRanges) {
        final start = a.start.isAfter(b.start) ? a.start : b.start;
        final end = a.end.isBefore(b.end) ? a.end : b.end;
        if (start.isBefore(end)) overlaps.add(DateTimeRange(start: start, end: end));
      }
    }
    return overlaps;
  }

  static tz.Location _safeLocation(String name) {
    try {
      return tz.getLocation(name);
    } catch (_) {
      return tz.getLocation('UTC');
    }
  }

  static List<DateTimeRange> _toUtcRanges(List<ScheduleBlock> blocks, DateTime date, tz.Location location) {
    return blocks.where((b) => b.blockType == 'free').map((b) {
      final start = _parseTime(b.startTime);
      final end = _parseTime(b.endTime);
      final startLocal = tz.TZDateTime(location, date.year, date.month, date.day, start.$1, start.$2);
      var endLocal = tz.TZDateTime(location, date.year, date.month, date.day, end.$1, end.$2);
      if (!endLocal.isAfter(startLocal)) endLocal = endLocal.add(const Duration(days: 1));
      return DateTimeRange(start: startLocal.toUtc(), end: endLocal.toUtc());
    }).toList();
  }

  static (int, int) _parseTime(String hhmmss) {
    final parts = hhmmss.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
}
