import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'draft.dart';

abstract interface class DraftRepository {
  Future<DraftDilemma?> load();
  Future<void> save(DraftDilemma draft);
  Future<void> clear();
}

class SharedPreferencesDraftRepository implements DraftRepository {
  SharedPreferencesDraftRepository({
    required this.userId,
    Future<SharedPreferences>? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance();

  static const storageKey = 'bib.draft.v1';
  final Future<SharedPreferences> _preferences;
  final String userId;
  String get scopedStorageKey => '$storageKey.$userId';

  @override
  Future<DraftDilemma?> load() async {
    final raw = (await _preferences).getString(scopedStorageKey);
    if (raw == null) return null;
    try {
      return DraftDilemma.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(DraftDilemma draft) async {
    final saved = await (await _preferences).setString(
      scopedStorageKey,
      jsonEncode(draft.toJson()),
    );
    if (!saved) throw StateError('Local draft was not saved.');
  }

  @override
  Future<void> clear() async {
    final removed = await (await _preferences).remove(scopedStorageKey);
    if (!removed) throw StateError('Local draft was not cleared.');
  }
}

class MemoryDraftRepository implements DraftRepository {
  MemoryDraftRepository([this.value]);

  DraftDilemma? value;
  int saveCount = 0;

  @override
  Future<DraftDilemma?> load() async => value;

  @override
  Future<void> save(DraftDilemma draft) async {
    value = draft;
    saveCount += 1;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}
