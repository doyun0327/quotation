import 'package:flutter/foundation.dart';
import 'package:quotation/data/dday_cloud_sync.dart';
import 'package:quotation/data/dday_invite_repository.dart';
import 'package:quotation/data/ios_fake_wallpaper.dart';

/// What a left room still keeps on this phone besides the room itself
/// (DdayController.remove drops that and its saved look): the invite code
/// shown on the invite screen, the "look already taken" marker and the
/// room's own iPhone transparent photo. Each step stands alone.
abstract final class RoomLocalCleanup {
  static Future<void> run(String roomId) async {
    final steps = <Future<void> Function()>[
      () => DdayCloudSync.forgetLayoutSeen(roomId),
      () => DdayInviteRepository.forgetCachedCode(roomId),
      () => IosFakeWallpaper.forgetRoom(roomId),
    ];
    for (final step in steps) {
      try {
        await step();
      } catch (e) {
        debugPrint('room cleanup $roomId: $e');
      }
    }
  }
}
