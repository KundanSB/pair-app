import '../main.dart';
import '../models/models.dart';

class ChatService {
  /// Keeps a single message from growing unreasonably large — mostly a
  /// sanity limit (checklist item: form validation), not a security
  /// control (RLS already prevents writing to anyone else's pairing).
  static const int maxMessageLength = 2000;

  Future<List<ChatMessage>> loadHistory(String pairingId) async {
    final res = await supabase
        .from('messages')
        .select()
        .eq('pairing_id', pairingId)
        .order('created_at', ascending: true)
        .limit(200);
    return (res as List).map((m) => ChatMessage.fromMap(m)).toList();
  }

  Future<void> send(String pairingId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final safe = trimmed.length > maxMessageLength ? trimmed.substring(0, maxMessageLength) : trimmed;
    await supabase.from('messages').insert({
      'pairing_id': pairingId,
      'sender_id': supabase.auth.currentUser!.id,
      'kind': 'chat',
      'content': safe,
    });
  }

  void watchMessages(String pairingId, void Function(ChatMessage) onInsert) {
    supabase
        .channel('messages:$pairingId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'pairing_id', value: pairingId),
          callback: (payload) => onInsert(ChatMessage.fromMap(payload.newRecord)),
        )
        .subscribe();
  }
}
