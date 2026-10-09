import '../main.dart';
import '../models/models.dart';
import 'analytics_service.dart';

class PairingService {
  /// A code must be exactly 6 digits — checked client-side so the user
  /// gets instant feedback, AND server-side (the join_pairing SQL
  /// function only matches real, unexpired codes regardless of what the
  /// client sends). Never trust client-side validation alone for
  /// anything security-relevant; this is a UX nicety layered on top of
  /// the real enforcement in the database.
  static bool isValidCodeFormat(String code) => RegExp(r'^\d{6}$').hasMatch(code);

  Future<String> generateCode() async {
    final res = await supabase.rpc('create_pairing');
    Analytics.track('pairing_code_generated');
    return res as String;
  }

  Future<String> joinWithCode(String code) async {
    if (!isValidCodeFormat(code)) {
      throw ArgumentError('Enter the 6-digit code exactly as your partner sent it.');
    }
    final res = await supabase.rpc('join_pairing', params: {'code': code});
    Analytics.track('pairing_joined');
    return res as String;
  }

  Future<Pairing?> getMyPairing() async {
    final uid = supabase.auth.currentUser!.id;
    final res = await supabase
        .from('pairings')
        .select()
        .or('user_a_id.eq.$uid,user_b_id.eq.$uid')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return res == null ? null : Pairing.fromMap(res);
  }

  void watchPairing(String pairingId, void Function(Pairing) onChange) {
    supabase
        .channel('pairing:$pairingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'pairings',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: pairingId),
          callback: (payload) => onChange(Pairing.fromMap(payload.newRecord)),
        )
        .subscribe();
  }
}
