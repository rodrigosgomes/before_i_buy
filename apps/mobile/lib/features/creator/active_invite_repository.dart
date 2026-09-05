import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ActiveInviteRepository {
  Future<Uri?> getInviteUri(String dilemmaId);
  Future<void> saveInviteUri(String dilemmaId, Uri inviteUri);
  Future<void> removeInviteUri(String dilemmaId);
}

abstract final class LegacyActiveInviteStorage {
  static const storageKey = 'bib.active_invites.v1';

  static Future<void> purgeAll({
    Future<SharedPreferences>? preferences,
    Future<bool> Function(SharedPreferences preferences, String key)? removeKey,
  }) async {
    final prefs = await (preferences ?? SharedPreferences.getInstance());
    final remove = removeKey ?? (preferences, key) => preferences.remove(key);
    final legacyKeys = prefs
        .getKeys()
        .where((key) => key.startsWith('$storageKey.'))
        .toList(growable: false);
    for (final key in legacyKeys) {
      final removed = await remove(prefs, key);
      if (!removed || prefs.containsKey(key)) {
        throw StateError('Could not purge legacy invite storage.');
      }
    }
  }
}

class MemoryActiveInviteRepository implements ActiveInviteRepository {
  final Map<String, Uri> _invites = {};

  @override
  Future<Uri?> getInviteUri(String dilemmaId) async => _invites[dilemmaId];

  @override
  Future<void> saveInviteUri(String dilemmaId, Uri inviteUri) async {
    _invites[dilemmaId] = inviteUri;
  }

  @override
  Future<void> removeInviteUri(String dilemmaId) async {
    _invites.remove(dilemmaId);
  }
}
