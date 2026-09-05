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

  test(
    'active invite repository saves, restores and removes invite URIs',
    () async {
      final repository = SharedPreferencesActiveInviteRepository(
        userId: 'test-user',
      );
      final uri = Uri.parse('https://guest.example.com/invite/tok123');
      await repository.saveInviteUri('dilemma-1', uri);

      final restored = await repository.getInviteUri('dilemma-1');
      expect(restored, uri);

      // Other user cannot see this invite
      final otherRepo = SharedPreferencesActiveInviteRepository(
        userId: 'other-user',
      );
      expect(await otherRepo.getInviteUri('dilemma-1'), isNull);

      // Remove
      await repository.removeInviteUri('dilemma-1');
      expect(await repository.getInviteUri('dilemma-1'), isNull);
    },
  );

  test(
    'active invite repository reports save and removal failures with StateError',
    () async {
      final repository = SharedPreferencesActiveInviteRepository(
        userId: 'test-user',
        preferences: Future.value(_RejectedPreferences()),
      );
      final uri = Uri.parse('https://guest.example.com/invite/tok123');

      await expectLater(
        repository.saveInviteUri('dilemma-1', uri),
        throwsStateError,
      );
      await expectLater(
        repository.removeInviteUri('dilemma-1'),
        throwsStateError,
      );
    },
  );

  test('memory active invite repository works in-memory', () async {
    final repo = MemoryActiveInviteRepository();
    final uri = Uri.parse('https://guest.example.com/invite/tok456');
    await repo.saveInviteUri('dilemma-2', uri);
    expect(await repo.getInviteUri('dilemma-2'), uri);
    await repo.removeInviteUri('dilemma-2');
    expect(await repo.getInviteUri('dilemma-2'), isNull);
  });
}

class _RejectedPreferences implements SharedPreferences {
  @override
  bool containsKey(String key) => true;

  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) async => false;

  @override
  Future<bool> remove(String key) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
