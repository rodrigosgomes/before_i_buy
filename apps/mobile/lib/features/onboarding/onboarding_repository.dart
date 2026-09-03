import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalOnboarding {
  const LocalOnboarding({
    required this.displayName,
    required this.adultConfirmed,
    required this.termsAccepted,
    required this.privacyAccepted,
  });

  static const schemaVersion = 1;

  final String displayName;
  final bool adultConfirmed;
  final bool termsAccepted;
  final bool privacyAccepted;

  bool get isComplete =>
      displayName.trim().isNotEmpty &&
      adultConfirmed &&
      termsAccepted &&
      privacyAccepted;

  Map<String, Object> toJson() => {
    'schema_version': schemaVersion,
    'display_name': displayName,
    'adult_confirmed': adultConfirmed,
    'terms_accepted': termsAccepted,
    'privacy_accepted': privacyAccepted,
  };

  static LocalOnboarding? fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['schema_version'] != schemaVersion ||
        value['display_name'] is! String ||
        value['adult_confirmed'] is! bool ||
        value['terms_accepted'] is! bool ||
        value['privacy_accepted'] is! bool) {
      return null;
    }
    return LocalOnboarding(
      displayName: value['display_name'] as String,
      adultConfirmed: value['adult_confirmed'] as bool,
      termsAccepted: value['terms_accepted'] as bool,
      privacyAccepted: value['privacy_accepted'] as bool,
    );
  }
}

abstract interface class OnboardingRepository {
  Future<LocalOnboarding?> load();
  Future<void> save(LocalOnboarding onboarding);
}

class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  SharedPreferencesOnboardingRepository({
    Future<SharedPreferences>? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance();

  static const storageKey = 'bib.onboarding.internal.v1';
  final Future<SharedPreferences> _preferences;

  @override
  Future<LocalOnboarding?> load() async {
    final raw = (await _preferences).getString(storageKey);
    if (raw == null) return null;
    try {
      return LocalOnboarding.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(LocalOnboarding onboarding) async {
    await (await _preferences).setString(
      storageKey,
      jsonEncode(onboarding.toJson()),
    );
  }
}

class MemoryOnboardingRepository implements OnboardingRepository {
  MemoryOnboardingRepository([this.value]);

  LocalOnboarding? value;
  int saveCount = 0;

  @override
  Future<LocalOnboarding?> load() async => value;

  @override
  Future<void> save(LocalOnboarding onboarding) async {
    value = onboarding;
    saveCount += 1;
  }
}
