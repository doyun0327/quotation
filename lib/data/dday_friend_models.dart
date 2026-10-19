/// A friend who accepted an invite for a specific D-Day (max 5 per D-Day).
class DdayFriendMember {
  const DdayFriendMember({
    required this.uid,
    required this.characterId,
    this.displayName,
  });

  final String uid;
  final String characterId;
  final String? displayName;

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'characterId': characterId,
        if (displayName != null) 'displayName': displayName,
      };

  factory DdayFriendMember.fromJson(Map<String, dynamic> json) {
    return DdayFriendMember(
      uid: json['uid'] as String? ?? '',
      characterId: json['characterId'] as String? ?? 'basic',
      displayName: json['displayName'] as String?,
    );
  }
}

abstract final class DdayInviteLimits {
  static const maxFriends = 5;
  static const codeLength = 6;
  static const inviteTtl = Duration(days: 7);

  static const httpsInviteBase = 'https://dearly-cf730.web.app/invite';
  static const appSchemeInviteBase = 'dearly://invite';

  static String shareUrl(String code) => '$httpsInviteBase/$code';
  static String appLink(String code) => '$appSchemeInviteBase/$code';
}
