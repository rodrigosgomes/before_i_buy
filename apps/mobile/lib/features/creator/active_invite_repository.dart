import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ActiveInviteRepository {
  Future<Uri?> getInviteUri(String dilemmaId);
  Future<void> saveInviteUri(String dilemmaId, Uri inviteUri);
  Future<void> removeInviteUri(String dilemmaId);
}

class SharedPreferencesActiveInviteRepository
    implements ActiveInviteRepository {
  SharedPreferencesActiveInviteRepository({
    required this.userId,
    Future<SharedPreferences>? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance();

  static const storageKey = 'bib.active_invites.v1';
  final Future<SharedPreferences> _preferences;
  final String userId;

  String _scopedKey(String dilemmaId) => '$storageKey.$userId.$dilemmaId';

  @override
  Future<Uri?> getInviteUri(String dilemmaId) async {
    final raw = (await _preferences).getString(_scopedKey(dilemmaId));
    if (raw == null) return null;
    return Uri.tryParse(raw);
  }

  @override
  Future<void> saveInviteUri(String dilemmaId, Uri inviteUri) async {
    final saved = await (await _preferences).setString(
      _scopedKey(dilemmaId),
      inviteUri.toString(),
    );
    if (!saved) throw StateError('Active invite was not saved.');
  }

  @override
  Future<void> removeInviteUri(String dilemmaId) async {
    final prefs = await _preferences;
    final key = _scopedKey(dilemmaId);
    if (!prefs.containsKey(key)) return;
    final removed = await prefs.remove(key);
    if (!removed) throw StateError('Active invite was not removed.');
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
