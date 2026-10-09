class Profile {
  final String id;
  final String displayName;
  final String timezone;
  final bool isOnline;
  final String role; // 'user' | 'premium' | 'admin'

  Profile({
    required this.id,
    required this.displayName,
    required this.timezone,
    required this.isOnline,
    required this.role,
  });

  bool get hasPremiumAccess => role == 'premium' || role == 'admin';

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'],
        displayName: map['display_name'] ?? 'Someone',
        timezone: map['timezone'] ?? 'UTC',
        isOnline: map['is_online'] ?? false,
        role: map['role'] ?? 'user',
      );
}

class Pairing {
  final String id;
  final String? userAId;
  final String? userBId;
  final String status;

  Pairing({required this.id, this.userAId, this.userBId, required this.status});

  factory Pairing.fromMap(Map<String, dynamic> map) => Pairing(
        id: map['id'],
        userAId: map['user_a_id'],
        userBId: map['user_b_id'],
        status: map['status'] ?? 'pending',
      );

  String? partnerIdFor(String myId) =>
      userAId == myId ? userBId : (userBId == myId ? userAId : null);
}

class ChatMessage {
  final String id;
  final String senderId;
  final String kind;
  final String? content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.kind,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'],
        senderId: map['sender_id'],
        kind: map['kind'] ?? 'chat',
        content: map['content'],
        createdAt: DateTime.parse(map['created_at']).toLocal(),
      );
}

class LocationPing {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  LocationPing({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  factory LocationPing.fromMap(Map<String, dynamic> map) => LocationPing(
        id: map['id'],
        userId: map['user_id'],
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        recordedAt: DateTime.parse(map['recorded_at']).toLocal(),
      );
}

class ScheduleBlock {
  final String id;
  final DateTime forDate;
  final String startTime; // "HH:mm:ss", local to the owner's timezone
  final String endTime;
  final String blockType; // sleep | work | free | custom
  final String? label;
  final bool remindMe;

  ScheduleBlock({
    required this.id,
    required this.forDate,
    required this.startTime,
    required this.endTime,
    required this.blockType,
    this.label,
    this.remindMe = false,
  });

  factory ScheduleBlock.fromMap(Map<String, dynamic> map) => ScheduleBlock(
        id: map['id'],
        forDate: DateTime.parse(map['for_date']),
        startTime: map['start_time'],
        endTime: map['end_time'],
        blockType: map['block_type'],
        label: map['label'],
        remindMe: map['remind_me'] ?? false,
      );
}
