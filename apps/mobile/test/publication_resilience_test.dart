import 'dart:async';
import 'dart:convert';

import 'package:before_i_buy_mobile/app.dart';
import 'package:before_i_buy_mobile/features/auth/auth_gateway.dart';
import 'package:before_i_buy_mobile/features/creator/creator_remote_gateway.dart';
import 'package:before_i_buy_mobile/features/creator/draft.dart';
import 'package:before_i_buy_mobile/features/creator/draft_repository.dart';
import 'package:before_i_buy_mobile/features/onboarding/onboarding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_flow_test.dart'
    show configured, completeOnboarding, tapVisible, uuid;

final draft = const DraftDilemma(idempotencyKey: uuid).copyWith(
  itemName: 'Fone privado de A',
  priceCents: 10000,
  reason: 'Quero usar em viagens longas.',
);
const result = PublishedInvite(
  dilemmaId: '00000000-0000-4000-8000-000000000401',
  inviteToken: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
);

Future<void> seed(String userId, {DraftDilemma? value}) async {
  await SharedPreferencesOnboardingRepository(
    userId: userId,
  ).save(completeOnboarding);
  await SharedPreferencesDraftRepository(userId: userId).save(value ?? draft);
}

BeforeIBuyApp app(
  FakeAuthGateway auth, {
  CreatorProfileGateway? profile,
  DilemmaPublicationGateway? publication,
  InviteShareGateway? share,
  DraftRepository? drafts,
}) => BeforeIBuyApp(
  config: configured,
  authGateway: auth,
  creatorProfileGateway: profile,
  publicationGateway: publication,
  shareGateway: share,
  draftRepository: drafts,
);

Future<void> preview(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tapVisible(tester, find.text('Revisar'));
  await tapVisible(tester, find.text('Ver prévia do convite'));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('failed snapshot persistence blocks the publication RPC', (
    tester,
  ) async {
    await seed('test-user');
    final publication = MemoryDilemmaPublicationGateway();
    final repository = SharedPreferencesDraftRepository(
      userId: 'test-user',
      preferences: Future.value(RejectedPreferences()),
    );
    await tester.pumpWidget(
      app(
        FakeAuthGateway(authenticated: true),
        publication: publication,
        drafts: repository,
      ),
    );
    await preview(tester);
    await tapVisible(tester, find.text('Publicar convite privado'));
    expect(publication.published, isEmpty);
    expect(
      find.textContaining('Não foi possível salvar neste aparelho'),
      findsOneWidget,
    );
    expect((await repository.load())?.publicationPending, isFalse);
  });

  test(
    'rejected local removal is reported rather than silently acknowledged',
    () async {
      final repository = SharedPreferencesDraftRepository(
        userId: 'test-user',
        preferences: Future.value(RejectedPreferences()),
      );
      await expectLater(repository.clear(), throwsStateError);
    },
  );

  testWidgets(
    'preview and published screen reflow at 320px with 200 percent text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await seed('test-user', value: draft.copyWith(publicationPending: true));
      await tester.pumpWidget(app(FakeAuthGateway(authenticated: true)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Publicação não confirmada'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Publicar convite privado'));
      expect(find.text('Compartilhar convite'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'offline restart restores scoped draft; reconnect never publishes',
    (tester) async {
      await seed('test-user');
      final auth = FakeAuthGateway(authenticated: true);
      final profile = MemoryCreatorProfileGateway(
        nextStatus: CreatorProfileStatus.unavailable,
      );
      final publication = MemoryDilemmaPublicationGateway();
      await tester.pumpWidget(
        app(auth, profile: profile, publication: publication),
      );
      await preview(tester);
      await tapVisible(tester, find.text('Publicar convite privado'));
      expect(find.textContaining('Sem conexão para publicar'), findsOneWidget);
      expect(publication.published, isEmpty);
      profile.nextStatus = CreatorProfileStatus.ready;
      auth.completeSignIn();
      await tester.pumpAndSettle();
      expect(publication.published, isEmpty);
      await tapVisible(tester, find.text('Publicar convite privado'));
      expect(publication.published, hasLength(1));
    },
  );

  testWidgets('account B cannot inherit onboarding or draft from A', (
    tester,
  ) async {
    await seed('test-user');
    final auth = FakeAuthGateway(authenticated: true);
    await tester.pumpWidget(app(auth));
    await tester.pumpAndSettle();
    expect(find.text(draft.itemName), findsOneWidget);
    auth.signOut();
    await tester.pumpAndSettle();
    auth.completeSignIn(userId: 'account-b');
    await tester.pumpAndSettle();
    expect(
      find.text('Antes de continuar, vamos deixar tudo claro'),
      findsOneWidget,
    );
    expect(find.text(draft.itemName), findsNothing);
    expect(
      await SharedPreferencesOnboardingRepository(userId: 'account-b').load(),
      isNull,
    );
    expect(
      await SharedPreferencesDraftRepository(userId: 'account-b').load(),
      isNull,
    );
    auth.completeSignIn(userId: 'test-user');
    await tester.pumpAndSettle();
    expect(find.text(draft.itemName), findsOneWidget);
  });

  test(
    'legacy records without ownership are never assigned to a user',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesDraftRepository.storageKey: jsonEncode(draft.toJson()),
        SharedPreferencesOnboardingRepository.storageKey: jsonEncode(
          completeOnboarding.toJson(),
        ),
      });
      expect(
        await SharedPreferencesDraftRepository(userId: 'test-user').load(),
        isNull,
      );
      expect(
        await SharedPreferencesOnboardingRepository(userId: 'test-user').load(),
        isNull,
      );
    },
  );

  testWidgets(
    'late publication after logout cannot reopen or clear another account',
    (tester) async {
      await seed('test-user');
      await seed('account-b', value: draft.copyWith(itemName: 'Item de B'));
      final auth = FakeAuthGateway(authenticated: true);
      final publication = DelayedPublication();
      await tester.pumpWidget(app(auth, publication: publication));
      await preview(tester);
      await tester.ensureVisible(find.text('Publicar convite privado'));
      await tester.tap(find.text('Publicar convite privado'));
      await tester.pump();
      await tester.pump();
      auth.signOut();
      await tester.pumpAndSettle();
      auth.completeSignIn(userId: 'account-b');
      await tester.pumpAndSettle();
      publication.completer.complete(result);
      await tester.pumpAndSettle();
      expect(find.text('Item de B'), findsOneWidget);
      expect(find.text('Compartilhar convite'), findsNothing);
      expect(
        (await SharedPreferencesDraftRepository(
          userId: 'test-user',
        ).load())?.publicationPending,
        isTrue,
      );
      expect(
        (await SharedPreferencesDraftRepository(
          userId: 'account-b',
        ).load())?.itemName,
        'Item de B',
      );
    },
  );

  testWidgets('pending publication cannot navigate back or submit twice', (
    tester,
  ) async {
    await seed('test-user');
    final publication = DelayedPublication();
    await tester.pumpWidget(
      app(FakeAuthGateway(authenticated: true), publication: publication),
    );
    await preview(tester);
    await tester.ensureVisible(find.text('Publicar convite privado'));
    await tester.tap(find.text('Publicar convite privado'));
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('Voltar'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.pump();
    expect(publication.calls, 1);
    publication.completer.complete(result);
    await tester.pumpAndSettle();
    expect(find.text('Compartilhar convite'), findsOneWidget);
  });

  testWidgets(
    'lost response survives restart and retries identical payload once explicitly',
    (tester) async {
      await seed('test-user');
      final publication = LostResponsePublication();
      final auth = FakeAuthGateway(authenticated: true);
      await tester.pumpWidget(app(auth, publication: publication));
      await preview(tester);
      await tapVisible(tester, find.text('Publicar convite privado'));
      expect(find.textContaining('Publicação não confirmada'), findsOneWidget);
      expect(find.text('Rascunho — não compartilhado'), findsNothing);
      expect(find.byTooltip('Voltar'), findsNothing);
      final pending = await SharedPreferencesDraftRepository(
        userId: 'test-user',
      ).load();
      expect(pending?.publicationPending, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(auth, publication: publication));
      await tester.pumpAndSettle();
      expect(find.textContaining('Publicação não confirmada'), findsOneWidget);
      expect(publication.payloads, hasLength(1));
      await tapVisible(tester, find.text('Publicar convite privado'));
      expect(publication.payloads, hasLength(2));
      expect(publication.payloads[0], publication.payloads[1]);
      expect(publication.remoteCount, 1);
      expect(find.text('Compartilhar convite'), findsOneWidget);
    },
  );

  testWidgets(
    'same-account refresh and share cancellation retain the published invite',
    (tester) async {
      await seed('test-user');
      final auth = FakeAuthGateway(authenticated: true);
      final publication = MemoryDilemmaPublicationGateway();
      final share = MemoryInviteShareGateway();
      await tester.pumpWidget(
        app(auth, publication: publication, share: share),
      );
      await preview(tester);
      await tapVisible(tester, find.text('Publicar convite privado'));
      auth.completeSignIn();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Compartilhar convite'));
      expect(find.text('Compartilhar convite'), findsOneWidget);
      expect(publication.published, hasLength(1));
      expect(share.shared, hasLength(1));
      expect(find.textContaining(result.inviteToken), findsNothing);
      share.error = StateError('sensitive error');
      await tapVisible(tester, find.text('Compartilhar convite'));
      expect(find.textContaining('Não foi possível abrir'), findsOneWidget);
      expect(find.textContaining('sensitive error'), findsNothing);
    },
  );
}

class DelayedPublication implements DilemmaPublicationGateway {
  final completer = Completer<PublishedInvite>();
  int calls = 0;
  @override
  Future<PublishedInvite> publish(DraftDilemma draft) {
    calls++;
    return completer.future;
  }
}

class LostResponsePublication implements DilemmaPublicationGateway {
  final payloads = <Map<String, Object>>[];
  int remoteCount = 0;
  @override
  Future<PublishedInvite> publish(DraftDilemma draft) async {
    payloads.add(draft.toJson());
    if (remoteCount == 0) {
      remoteCount++;
      throw TimeoutException('response lost after commit');
    }
    return result;
  }
}

class RejectedPreferences implements SharedPreferences {
  @override
  String? getString(String key) => jsonEncode(draft.toJson());
  @override
  Future<bool> setString(String key, String value) async => false;
  @override
  Future<bool> remove(String key) async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
