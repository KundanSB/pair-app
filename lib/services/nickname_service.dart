import '../main.dart';

class NicknameService {
  /// Kept short deliberately — this is shown in a large headline on the
  /// welcome screen, so an unbounded string could break the layout.
  static const int maxLength = 30;

  /// The nickname your PARTNER chose for you — shown in the welcome loader.
  Future<String?> getMyPetName() async {
    final res = await supabase.from('profiles').select('pet_name').eq('id', supabase.auth.currentUser!.id).single();
    return res['pet_name'] as String?;
  }

  /// Sets the nickname your PARTNER will see. Routed through a
  /// security-definer RPC since normal row-level security only lets you
  /// edit your own row, not theirs.
  Future<void> setPartnerNickname(String nickname) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) throw ArgumentError('Type something first.');
    final safe = trimmed.length > maxLength ? trimmed.substring(0, maxLength) : trimmed;
    await supabase.rpc('set_partner_nickname', params: {'nickname': safe});
  }
}
