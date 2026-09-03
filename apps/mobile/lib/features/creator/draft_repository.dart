import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'draft.dart';

abstract interface class DraftRepository {
  Future<DraftDilemma?> load();
  Future<void> save(DraftDilemma draft);
}

class SharedPreferencesDraftRepository implements DraftRepository {
  SharedPreferencesDraftRepository({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  static const storageKey = 'bib.draft.v1';
  final Future<SharedPreferences> _preferences;

  @override
  Future<DraftDilemma?> load() async {
    final raw = (await _preferences).getString(storageKey);
    if (raw == null) return null;
    try {
      return DraftDilemma.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(DraftDilemma draft) async {
    await (await _preferences).setString(
      storageKey,
      jsonEncode(draft.toJson()),
    );
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
}
