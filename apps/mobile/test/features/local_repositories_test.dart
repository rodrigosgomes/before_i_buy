import 'dart:convert';

import 'package:before_i_buy_mobile/features/creator/active_invite_repository.dart';
import 'package:before_i_buy_mobile/features/creator/draft.dart';
import 'package:before_i_buy_mobile/features/creator/draft_repository.dart';
import 'package:before_i_buy_mobile/features/onboarding/onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const uuid = '123e4567-e89b-42d3-a456-426614174000';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('draft repository saves and restores the complete draft', () async {
    final repository = SharedPreferencesDraftRepository(userId: 'test-user');
    final draft = const DraftDilemma(idempotencyKey: uuid).copyWith(
      itemName: 'Fone',
      priceCents: 240000,
      reason: 'Quero mais foco para trabalhar.',
    );
    await repository.save(draft);

    final restored = await SharedPreferencesDraftRepository(
      userId: 'test-user',
    ).load();
    expect(restored?.toJson(), draft.toJson());
    expect(restored?.idempotencyKey, uuid);
    await repository.clear();
    expect(
      await SharedPreferencesDraftRepository(userId: 'test-user').load(),
      isNull,
    );
  });

  test('draft repository fails closed for corrupt local data', () async {
    SharedPreferences.setMockInitialValues({
      '${SharedPreferencesDraftRepository.storageKey}.test-user': '{broken',
    });
    expect(
      await SharedPreferencesDraftRepository(userId: 'test-user').load(),
      isNull,
    );

    SharedPreferences.setMockInitialValues({
      '${SharedPreferencesDraftRepository.storageKey}.test-user': jsonEncode({
        'schema_version': 99,
      }),
    });
    expect(
      await SharedPreferencesDraftRepository(userId: 'test-user').load(),
      isNull,
    );
  });

  test('onboarding repository saves only its internal local fixture', () async {
    const onboarding = LocalOnboarding(
      displayName: 'Lu',
      adultConfirmed: true,
      termsAccepted: true,
      privacyAccepted: true,
    );
    final repository = SharedPreferencesOnboardingRepository(
      userId: 'test-user',
    );
    await repository.save(onboarding);

    final restored = await SharedPreferencesOnboardingRepository(
      userId: 'test-user',
    ).load();
    expect(restored?.displayName, 'Lu');
    expect(restored?.isComplete, isTrue);
  });

  test('onboarding completion requires every independent acceptance', () {
    expect(
      const LocalOnboarding(
        displayName: 'Lu',
        adultConfirmed: true,
        termsAccepted: true,
        privacyAccepted: false,
      ).isComplete,
      isFalse,
    );
    expect(
      LocalOnboarding(
        displayName: 'a' * 51,
        adultConfirmed: true,
        termsAccepted: true,
        privacyAccepted: true,
      ).isComplete,
      isFalse,
    );
    expect(LocalOnboarding.fromJson(null), isNull);
    expect(LocalOnboarding.fromJson({'schema_version': 1}), isNull);
    expect(
      const LocalOnboarding(
        displayName: 'X',
        adultConfirmed: true,
        termsAccepted: true,
        privacyAccepted: true,
      ).isComplete,
      isFalse,
    );
  });

  test('memory repositories expose saves for integration assertions', () async {
    final drafts = MemoryDraftRepository();
    final onboarding = MemoryOnboardingRepository();
    const draft = DraftDilemma(idempotencyKey: uuid);
    const profile = LocalOnboarding(
      displayName: 'Lu',
      adultConfirmed: true,
      termsAccepted: true,
      privacyAccepted: true,
    );
    await drafts.save(draft);
    await onboarding.save(profile);
    expect(await drafts.load(), same(draft));
    expect(await onboarding.load(), same(profile));
    expect(drafts.saveCount, 1);
    expect(onboarding.saveCount, 1);
  });

  test('active invite repository keeps invite URIs only in memory', () async {
    final repository = MemoryActiveInviteRepository();
    final uri = Uri.parse('https://guest.example.com/invite/tok123');
    await repository.saveInviteUri('dilemma-1', uri);

    expect(await repository.getInviteUri('dilemma-1'), uri);
    expect(
      await MemoryActiveInviteRepository().getInviteUri('dilemma-1'),
      isNull,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getKeys().any(
        (key) => key.startsWith(LegacyActiveInviteStorage.storageKey),
      ),
      isFalse,
    );
    await repository.removeInviteUri('dilemma-1');
    expect(await repository.getInviteUri('dilemma-1'), isNull);
  });

  test(
    'legacy persisted invite URLs are purged without touching other data',
    () async {
      SharedPreferences.setMockInitialValues({
        '${LegacyActiveInviteStorage.storageKey}.user.dilemma':
            'https://guest.example.com/invite/sensitive-token',
        'unrelated': 'keep-me',
      });

      await LegacyActiveInviteStorage.purgeAll();

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getKeys().any(
          (key) => key.startsWith(LegacyActiveInviteStorage.storageKey),
        ),
        isFalse,
      );
      expect(preferences.getString('unrelated'), 'keep-me');
    },
  );

  test('legacy invite purge rejects an unsuccessful removal', () async {
    const key = '${LegacyActiveInviteStorage.storageKey}.user.dilemma';
    SharedPreferences.setMockInitialValues({
      key: 'https://guest.example.com/invite/sensitive-token',
    });

    await expectLater(
      LegacyActiveInviteStorage.purgeAll(
        removeKey: (preferences, key) async => false,
      ),
      throwsStateError,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(key), isTrue);
  });

  test('legacy invite purge propagates storage exceptions', () async {
    const key = '${LegacyActiveInviteStorage.storageKey}.user.dilemma';
    SharedPreferences.setMockInitialValues({
      key: 'https://guest.example.com/invite/sensitive-token',
    });

    await expectLater(
      LegacyActiveInviteStorage.purgeAll(
        removeKey: (preferences, key) async {
          throw StateError('simulated storage failure');
        },
      ),
      throwsStateError,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(key), isTrue);
  });
}
