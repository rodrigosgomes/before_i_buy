import 'dart:convert';

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
    final repository = SharedPreferencesDraftRepository();
    final draft = const DraftDilemma(idempotencyKey: uuid).copyWith(
      itemName: 'Fone',
      priceCents: 240000,
      reason: 'Quero mais foco para trabalhar.',
    );
    await repository.save(draft);

    final restored = await SharedPreferencesDraftRepository().load();
    expect(restored?.toJson(), draft.toJson());
    expect(restored?.idempotencyKey, uuid);
    await repository.clear();
    expect(await SharedPreferencesDraftRepository().load(), isNull);
  });

  test('draft repository fails closed for corrupt local data', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesDraftRepository.storageKey: '{broken',
    });
    expect(await SharedPreferencesDraftRepository().load(), isNull);

    SharedPreferences.setMockInitialValues({
      SharedPreferencesDraftRepository.storageKey: jsonEncode({
        'schema_version': 99,
      }),
    });
    expect(await SharedPreferencesDraftRepository().load(), isNull);
  });

  test('onboarding repository saves only its internal local fixture', () async {
    const onboarding = LocalOnboarding(
      displayName: 'Lu',
      adultConfirmed: true,
      termsAccepted: true,
      privacyAccepted: true,
    );
    final repository = SharedPreferencesOnboardingRepository();
    await repository.save(onboarding);

    final restored = await SharedPreferencesOnboardingRepository().load();
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
}
