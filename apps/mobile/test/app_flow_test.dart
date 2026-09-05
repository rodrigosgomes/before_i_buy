import 'dart:async';

import 'package:before_i_buy_mobile/app.dart';
import 'package:before_i_buy_mobile/core/app_config.dart';
import 'package:before_i_buy_mobile/features/auth/auth_gateway.dart';
import 'package:before_i_buy_mobile/features/creator/active_invite_repository.dart';
import 'package:before_i_buy_mobile/features/creator/draft.dart';
import 'package:before_i_buy_mobile/features/creator/draft_repository.dart';
import 'package:before_i_buy_mobile/features/creator/creator_remote_gateway.dart';
import 'package:before_i_buy_mobile/features/onboarding/onboarding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const configured = AppConfig(
  supabaseUrl: 'https://example.supabase.co',
  supabasePublishableKey: 'public-key',
  googleWebClientId: 'web.apps.googleusercontent.com',
  googleIosClientId: 'ios.apps.googleusercontent.com',
  guestInviteBaseUrl: 'https://guest.example.com',
);
const uuid = '123e4567-e89b-42d3-a456-426614174000';
const completeOnboarding = LocalOnboarding(
  displayName: 'Lu',
  adultConfirmed: true,
  termsAccepted: true,
  privacyAccepted: true,
);

BeforeIBuyApp testApp({
  required FakeAuthGateway auth,
  MemoryOnboardingRepository? onboarding,
  MemoryDraftRepository? drafts,
  ActiveInviteRepository? activeInvites,
  AppConfig config = configured,
  TargetPlatform platform = TargetPlatform.android,
  CreatorProfileGateway? profile,
  DilemmaPublicationGateway? publication,
  CreatorDilemmaGateway? dilemmaGateway,
  InviteShareGateway? share,
  Future<void> Function()? purgeLegacyInvites,
}) => BeforeIBuyApp(
  config: config,
  authGateway: auth,
  onboardingRepository: onboarding ?? MemoryOnboardingRepository(),
  draftRepository: drafts ?? MemoryDraftRepository(),
  activeInviteRepository: activeInvites ?? MemoryActiveInviteRepository(),
  creatorProfileGateway: profile,
  publicationGateway: publication,
  dilemmaGateway: dilemmaGateway,
  shareGateway: share,
  createId: () => uuid,
  platform: platform,
  purgeLegacyInvites: purgeLegacyInvites,
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('missing configuration fails closed without Auth', (
    tester,
  ) async {
    final auth = FakeAuthGateway();
    await tester.pumpWidget(
      testApp(
        auth: auth,
        config: const AppConfig(
          supabaseUrl: '',
          supabasePublishableKey: '',
          googleWebClientId: '',
          googleIosClientId: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configuração interna ausente'), findsOneWidget);
    expect(find.textContaining('Nenhuma conexão foi tentada'), findsOneWidget);
    expect(find.textContaining('GOOGLE_WEB_CLIENT_ID'), findsOneWidget);
    expect(auth.googleSignInCount, 0);
  });

  testWidgets(
    'legacy invite cleanup fails closed before configuration and retries',
    (tester) async {
      var attempts = 0;
      var fail = true;
      Future<void> purge() async {
        attempts++;
        if (fail) throw StateError('simulated cleanup failure');
      }

      await tester.pumpWidget(
        testApp(
          auth: FakeAuthGateway(),
          config: const AppConfig(
            supabaseUrl: '',
            supabasePublishableKey: '',
            googleWebClientId: '',
            googleIosClientId: '',
          ),
          purgeLegacyInvites: purge,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Proteção local pendente'), findsOneWidget);
      expect(find.text('Configuração interna ausente'), findsNothing);
      expect(attempts, 1);

      fail = false;
      await tapVisible(tester, find.text('Tentar novamente'));
      expect(find.text('Configuração interna ausente'), findsOneWidget);
      expect(attempts, 2);
    },
  );

  testWidgets('Google cancellation is neutral and failures are generic', (
    tester,
  ) async {
    final auth = FakeAuthGateway(nextGoogleResult: SocialAuthResult.cancelled);
    await tester.pumpWidget(testApp(auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar com Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Entrada cancelada'), findsOneWidget);
    expect(auth.googleSignInCount, 1);

    auth.nextGoogleResult = SocialAuthResult.failed;
    await tester.tap(find.text('Continuar com Google'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Não foi possível entrar agora'),
      findsOneWidget,
    );
    expect(auth.googleSignInCount, 2);
  });

  testWidgets('fake Google Auth completes the 3B creator publication flow', (
    tester,
  ) async {
    final auth = FakeAuthGateway();
    final onboarding = MemoryOnboardingRepository();
    final drafts = MemoryDraftRepository();
    final profile = MemoryCreatorProfileGateway(
      nextStatus: CreatorProfileStatus.needsSync,
    );
    final publication = MemoryDilemmaPublicationGateway();
    final share = MemoryInviteShareGateway();
    await tester.pumpWidget(
      testApp(
        auth: auth,
        onboarding: onboarding,
        drafts: drafts,
        profile: profile,
        publication: publication,
        share: share,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar com Google'));
    await tester.pumpAndSettle();
    expect(
      find.text('Antes de continuar, vamos deixar tudo claro'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).first, 'Lu');
    await tapVisible(tester, find.text('Confirmo que tenho 18 anos ou mais'));
    await tapVisible(tester, find.text('Aceito os Termos de demonstração'));
    await tapVisible(
      tester,
      find.text('Aceito o Aviso de Privacidade de demonstração'),
    );
    await tapVisible(tester, find.text('Continuar'));

    expect(find.text('Preparar seu perfil de desenvolvimento'), findsOneWidget);
    await tapVisible(tester, find.text('Salvar perfil neste ambiente'));

    expect(find.text('Um pouco de espaço antes de decidir'), findsOneWidget);
    expect(onboarding.value?.isComplete, isTrue);
    expect(profile.synced.single.displayName, 'Lu');
    await tapVisible(tester, find.text('Criar minha primeira tentação'));

    expect(find.text('Rascunho — não compartilhado'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Fone com cancelamento de ruído');
    await tester.enterText(fields.at(1), '240000');
    await tester.enterText(
      fields.at(2),
      'Quero mais foco para trabalhar e viajar com menos ruído.',
    );
    await tester.pump();
    await tapVisible(tester, find.text('É um presente'));
    await tapVisible(tester, find.text('7 dias'));
    await tapVisible(tester, find.text('Revisar'));

    expect(find.text('Tudo certo para pedir uma perspectiva?'), findsOneWidget);
    expect(find.text('Fone com cancelamento de ruído'), findsOneWidget);
    expect(find.text('R\$ 2.400,00'), findsOneWidget);
    expect(find.text('Ver prévia do convite'), findsOneWidget);
    expect(drafts.value?.idempotencyKey, uuid);
    expect(drafts.value?.purpose, DraftPurpose.gift);
    expect(drafts.value?.pauseHours, 168);
    expect(auth.googleSignInCount, 1);

    await tapVisible(tester, find.text('Ver prévia do convite'));
    expect(find.text('Prévia — nenhuma ação será enviada.'), findsOneWidget);
    expect(find.text('Lu pediu sua perspectiva'), findsOneWidget);
    expect(publication.published, isEmpty);
    await tapVisible(tester, find.text('Publicar convite privado'));
    expect(
      find.text('Seu espaço está pronto para receber perspectivas'),
      findsOneWidget,
    );
    expect(publication.published, hasLength(1));
    expect(drafts.value, isNull);

    await tapVisible(tester, find.text('Compartilhar convite'));
    expect(share.shared, hasLength(1));
    expect(share.shared.single.host, 'guest.example.com');
    expect(share.shared.single.pathSegments.take(1), ['invite']);

    await tapVisible(tester, find.text('Ver painel de acompanhamento'));
    expect(find.text('Painel do dilema'), findsOneWidget);
    expect(find.text('Aguardando votos'), findsOneWidget);
  });

  testWidgets('Google entry blocks duplicate taps while authenticating', (
    tester,
  ) async {
    final auth = _DelayedAuthGateway();
    await tester.pumpWidget(testApp(auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuar com Google'));
    await tester.tap(find.text('Continuar com Google'));
    await tester.pump();
    expect(auth.googleSignInCount, 1);

    auth.complete();
    await tester.pumpAndSettle();
    expect(
      find.text('Antes de continuar, vamos deixar tudo claro'),
      findsOneWidget,
    );
  });

  testWidgets('invalid form announces errors without losing content', (
    tester,
  ) async {
    final drafts = MemoryDraftRepository();
    await tester.pumpWidget(
      testApp(
        auth: FakeAuthGateway(authenticated: true),
        onboarding: MemoryOnboardingRepository(completeOnboarding),
        drafts: drafts,
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Criar minha primeira tentação'));

    await tester.enterText(find.byType(TextField).first, 'X');
    await tapVisible(tester, find.text('Revisar'));
    expect(find.text('Use entre 2 e 80 caracteres.'), findsOneWidget);
    expect(find.text('Informe um preço maior que zero.'), findsOneWidget);
    expect(find.text('Use entre 10 e 500 caracteres.'), findsOneWidget);
    expect(find.text('X'), findsOneWidget);
    expect(drafts.value?.itemName, 'X');
  });

  testWidgets('restart recovers the draft and preserves idempotency', (
    tester,
  ) async {
    final recovered = const DraftDilemma(idempotencyKey: uuid).copyWith(
      itemName: 'Fone',
      priceCents: 10000,
      reason: 'Quero usar em viagens longas.',
    );
    final drafts = MemoryDraftRepository(recovered);
    await tester.pumpWidget(
      testApp(
        auth: FakeAuthGateway(authenticated: true),
        onboarding: MemoryOnboardingRepository(completeOnboarding),
        drafts: drafts,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Recuperamos seu rascunho'), findsOneWidget);
    expect(find.text('Fone'), findsOneWidget);
    expect(drafts.value?.idempotencyKey, uuid);
  });

  testWidgets('iOS configuration names its missing public identifier', (
    tester,
  ) async {
    const withoutIosClient = AppConfig(
      supabaseUrl: 'https://example.supabase.co',
      supabasePublishableKey: 'public-key',
      googleWebClientId: 'web.apps.googleusercontent.com',
      googleIosClientId: '',
    );
    await tester.pumpWidget(
      testApp(
        auth: FakeAuthGateway(),
        config: withoutIosClient,
        platform: TargetPlatform.iOS,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('GOOGLE_IOS_CLIENT_ID'), findsOneWidget);
  });

  testWidgets('draft reflows at 320px and 200 percent text', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: testApp(
          auth: FakeAuthGateway(authenticated: true),
          onboarding: MemoryOnboardingRepository(completeOnboarding),
          drafts: MemoryDraftRepository(
            const DraftDilemma(idempotencyKey: uuid),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rascunho — não compartilhado'), findsOneWidget);
    expect(
      find.text('Quanto espaço você quer antes de decidir?'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('publication failure preserves the local draft and UUID', (
    tester,
  ) async {
    final draft = const DraftDilemma(idempotencyKey: uuid).copyWith(
      itemName: 'Fone',
      priceCents: 10000,
      reason: 'Quero usar em viagens longas.',
    );
    final drafts = MemoryDraftRepository(draft);
    final publication = MemoryDilemmaPublicationGateway(
      error: StateError('offline'),
    );
    await tester.pumpWidget(
      testApp(
        auth: FakeAuthGateway(authenticated: true),
        onboarding: MemoryOnboardingRepository(completeOnboarding),
        drafts: drafts,
        publication: publication,
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Revisar'));
    await tapVisible(tester, find.text('Ver prévia do convite'));
    await tapVisible(tester, find.text('Publicar convite privado'));

    expect(
      find.text(
        'Não recebemos a confirmação. Tente novamente para recuperar o mesmo convite.',
      ),
      findsOneWidget,
    );
    expect(drafts.value?.idempotencyKey, uuid);
    expect(publication.published, isEmpty);
  });

  testWidgets(
    'dashboard tracking, revocation and hard deletion flow from home',
    (tester) async {
      final initialDilemma = CreatorDilemmaSummary(
        id: uuid,
        itemName: 'Cadeira Ergonômica',
        priceCents: 180000,
        currency: 'BRL',
        category: ItemCategory.homeLiving,
        purpose: DraftPurpose.forSelf,
        reason: 'Melhorar a postura no trabalho diário.',
        pauseDueAt: DateTime.now().add(const Duration(days: 3)),
        state: 'collecting_votes',
        isInviteRevoked: false,
        createdAt: DateTime.now(),
        buyCount: 2,
        waitCount: 1,
        skipCount: 0,
        totalVotes: 3,
      );
      final dilemmaGateway = MemoryCreatorDilemmaGateway(
        initial: [initialDilemma],
      );
      final activeInvites = MemoryActiveInviteRepository();
      final inviteUri = Uri.parse('https://guest.example.com/invite/tok123');
      await activeInvites.saveInviteUri(uuid, inviteUri);
      final share = MemoryInviteShareGateway();

      await tester.pumpWidget(
        testApp(
          auth: FakeAuthGateway(authenticated: true),
          onboarding: MemoryOnboardingRepository(completeOnboarding),
          dilemmaGateway: dilemmaGateway,
          activeInvites: activeInvites,
          share: share,
        ),
      );
      await tester.pumpAndSettle();

      // Home shows the dilemma card
      expect(find.text('Suas decisões com espaço'), findsOneWidget);
      expect(find.text('Cadeira Ergonômica'), findsOneWidget);
      expect(find.text('R\$ 1.800,00'), findsOneWidget);
      expect(find.text('Coletando votos · 3 votos'), findsOneWidget);

      // Tap to open dashboard
      await tapVisible(tester, find.text('Cadeira Ergonômica'));
      expect(find.text('Painel do dilema'), findsOneWidget);
      expect(find.text('Perspectivas recebidas'), findsOneWidget);
      expect(find.text('Total: 3 votos'), findsOneWidget);
      expect(find.text('Comprar'), findsOneWidget);
      expect(find.text('2 (67%)'), findsOneWidget);

      // Re-share from dashboard
      await tapVisible(tester, find.text('Compartilhar convite'));
      await tapVisible(tester, find.text('Compartilhar'));
      expect(share.shared, [inviteUri]);

      // Revoke invite
      await tapVisible(tester, find.text('Revogar convite'));
      expect(find.text('Revogar convite?'), findsOneWidget);
      await tapVisible(tester, find.text('Revogar'));
      expect(find.text('Convite revogado · votação encerrada'), findsOneWidget);
      expect(find.text('Revogar convite'), findsNothing);
      expect(find.text('Compartilhar convite'), findsNothing);
      expect(await activeInvites.getInviteUri(uuid), isNull);

      // Delete dilemma
      await tapVisible(tester, find.text('Apagar dilema'));
      expect(find.text('Apagar dilema?'), findsOneWidget);
      await tapVisible(tester, find.text('Apagar definitivamente'));

      // Returns to Home, list is empty so onboarding chapters render
      expect(find.text('Um pouco de espaço antes de decidir'), findsOneWidget);
      expect(find.text('Criar minha primeira tentação'), findsOneWidget);
      expect(await dilemmaGateway.fetchDilemmas(), isEmpty);
    },
  );

  testWidgets(
    'logout during async dashboard open does not leak private dashboard to new session',
    (tester) async {
      final initialDilemma = CreatorDilemmaSummary(
        id: uuid,
        itemName: 'Cadeira Ergonômica',
        priceCents: 180000,
        currency: 'BRL',
        category: ItemCategory.homeLiving,
        purpose: DraftPurpose.forSelf,
        reason: 'Melhorar a postura no trabalho diário.',
        pauseDueAt: DateTime.now().add(const Duration(days: 3)),
        state: 'collecting_votes',
        isInviteRevoked: false,
        createdAt: DateTime.now(),
        buyCount: 2,
        waitCount: 1,
        skipCount: 0,
        totalVotes: 3,
      );
      final dilemmaGateway = MemoryCreatorDilemmaGateway(
        initial: [initialDilemma],
      );
      final activeInvites = _DelayedActiveInviteRepository();
      final auth = FakeAuthGateway(authenticated: true);

      await tester.pumpWidget(
        testApp(
          auth: auth,
          onboarding: MemoryOnboardingRepository(completeOnboarding),
          dilemmaGateway: dilemmaGateway,
          activeInvites: activeInvites,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cadeira Ergonômica'), findsOneWidget);

      // Tap card: starts _openDashboard and awaits getInviteUri
      await tester.tap(find.text('Cadeira Ergonômica'));
      await tester.pump();

      // Sign out during await
      auth.signOut();
      await tester.pumpAndSettle();

      // Complete async invite fetch
      activeInvites.completer.complete(Uri.parse('https://example.com/invite'));
      await tester.pumpAndSettle();

      // Ensure dashboard is never displayed
      expect(find.text('Painel do dilema'), findsNothing);
      expect(find.text('Continuar com Google'), findsOneWidget);
    },
  );

  testWidgets(
    'network failure during post-delete refresh still removes dilemma locally from home',
    (tester) async {
      final initialDilemma = CreatorDilemmaSummary(
        id: uuid,
        itemName: 'Cadeira Ergonômica',
        priceCents: 180000,
        currency: 'BRL',
        category: ItemCategory.homeLiving,
        purpose: DraftPurpose.forSelf,
        reason: 'Melhorar a postura no trabalho diário.',
        pauseDueAt: DateTime.now().add(const Duration(days: 3)),
        state: 'collecting_votes',
        isInviteRevoked: false,
        createdAt: DateTime.now(),
        buyCount: 0,
        waitCount: 0,
        skipCount: 0,
        totalVotes: 0,
      );
      final dilemmaGateway = _FailingRefreshDilemmaGateway([initialDilemma]);

      await tester.pumpWidget(
        testApp(
          auth: FakeAuthGateway(authenticated: true),
          onboarding: MemoryOnboardingRepository(completeOnboarding),
          dilemmaGateway: dilemmaGateway,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cadeira Ergonômica'), findsOneWidget);

      // Open dashboard
      await tapVisible(tester, find.text('Cadeira Ergonômica'));
      expect(find.text('Painel do dilema'), findsOneWidget);

      // Make next refresh fail
      dilemmaGateway.failNextFetch = true;

      // Delete dilemma
      await tapVisible(tester, find.text('Apagar dilema'));
      await tapVisible(tester, find.text('Apagar definitivamente'));

      // Locally returns to Home with deleted item removed
      expect(find.text('Cadeira Ergonômica'), findsNothing);
      expect(find.text('Um pouco de espaço antes de decidir'), findsOneWidget);
    },
  );

  testWidgets('initial dilemma load failure shows retry and then recovers', (
    tester,
  ) async {
    final dilemma = CreatorDilemmaSummary(
      id: uuid,
      itemName: 'Cadeira Ergonômica',
      priceCents: 180000,
      currency: 'BRL',
      category: ItemCategory.homeLiving,
      purpose: DraftPurpose.forSelf,
      reason: 'Melhorar a postura no trabalho diário.',
      pauseDueAt: DateTime.now().add(const Duration(days: 3)),
      state: 'collecting_votes',
      isInviteRevoked: false,
      createdAt: DateTime.now(),
      buyCount: 0,
      waitCount: 0,
      skipCount: 0,
      totalVotes: 0,
    );
    final gateway = _FailingRefreshDilemmaGateway([dilemma])
      ..failNextFetch = true;

    await tester.pumpWidget(
      testApp(
        auth: FakeAuthGateway(authenticated: true),
        onboarding: MemoryOnboardingRepository(completeOnboarding),
        dilemmaGateway: gateway,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar seus dilemas agora.'),
      findsOneWidget,
    );
    expect(find.text('Tentar atualizar'), findsOneWidget);
    expect(find.text('Cadeira Ergonômica'), findsNothing);

    gateway.failNextFetch = false;
    await tapVisible(tester, find.text('Tentar atualizar'));
    expect(find.text('Cadeira Ergonômica'), findsOneWidget);
    expect(
      find.text('Não foi possível carregar seus dilemas agora.'),
      findsNothing,
    );
  });

  testWidgets(
    'remote revoke and delete remain successful when local cleanup fails',
    (tester) async {
      final dilemma = CreatorDilemmaSummary(
        id: uuid,
        itemName: 'Cadeira Ergonômica',
        priceCents: 180000,
        currency: 'BRL',
        category: ItemCategory.homeLiving,
        purpose: DraftPurpose.forSelf,
        reason: 'Melhorar a postura no trabalho diário.',
        pauseDueAt: DateTime.now().add(const Duration(days: 3)),
        state: 'collecting_votes',
        isInviteRevoked: false,
        createdAt: DateTime.now(),
        buyCount: 1,
        waitCount: 0,
        skipCount: 0,
        totalVotes: 1,
      );
      final gateway = MemoryCreatorDilemmaGateway(initial: [dilemma]);
      final invites = _FailingRemovalActiveInviteRepository();
      await invites.saveInviteUri(
        uuid,
        Uri.parse('https://guest.example.com/invite/token'),
      );

      await tester.pumpWidget(
        testApp(
          auth: FakeAuthGateway(authenticated: true),
          onboarding: MemoryOnboardingRepository(completeOnboarding),
          dilemmaGateway: gateway,
          activeInvites: invites,
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Cadeira Ergonômica'));

      await tapVisible(tester, find.text('Revogar convite'));
      await tapVisible(tester, find.text('Revogar'));
      expect(find.text('Convite revogado · votação encerrada'), findsOneWidget);
      expect(find.text('Compartilhar convite'), findsNothing);
      expect(
        find.text('Não foi possível revogar o convite agora.'),
        findsNothing,
      );

      await tapVisible(tester, find.text('Apagar dilema'));
      await tapVisible(tester, find.text('Apagar definitivamente'));
      expect(find.text('Cadeira Ergonômica'), findsNothing);
      expect(await gateway.fetchDilemmas(), isEmpty);
      expect(
        find.text('Não foi possível apagar o dilema agora.'),
        findsNothing,
      );
    },
  );

  testWidgets('late refresh from account A cannot replace account B data', (
    tester,
  ) async {
    final gateway = _SessionSwitchDilemmaGateway();
    final auth = FakeAuthGateway(authenticated: true)..accountId = 'account-a';

    await tester.pumpWidget(
      testApp(
        auth: auth,
        onboarding: MemoryOnboardingRepository(completeOnboarding),
        dilemmaGateway: gateway,
      ),
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Dilema da conta A'));

    await tester.tap(find.byTooltip('Atualizar perspectivas'));
    await tester.pump();
    gateway.serveAccountB = true;
    auth.completeSignIn(userId: 'account-b');
    await tester.pumpAndSettle();

    expect(find.text('Dilema da conta B'), findsOneWidget);
    gateway.refreshCompleter.complete([gateway.accountA]);
    await tester.pumpAndSettle();
    expect(find.text('Dilema da conta B'), findsOneWidget);
    expect(find.text('Dilema da conta A'), findsNothing);
  });

  testWidgets(
    'late revocation from account A cannot alter account B or its invite',
    (tester) async {
      final gateway = _SessionSwitchDilemmaGateway(delayRevoke: true);
      final auth = FakeAuthGateway(authenticated: true)
        ..accountId = 'account-a';
      final invites = _TrackingActiveInviteRepository();
      await invites.saveInviteUri(
        gateway.accountB.id,
        Uri.parse('https://guest.example.com/invite/account-b'),
      );

      await tester.pumpWidget(
        testApp(
          auth: auth,
          onboarding: MemoryOnboardingRepository(completeOnboarding),
          dilemmaGateway: gateway,
          activeInvites: invites,
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Dilema da conta A'));
      await tapVisible(tester, find.text('Revogar convite'));
      await tester.tap(find.text('Revogar'));
      await tester.pump();

      gateway.serveAccountB = true;
      auth.completeSignIn(userId: 'account-b');
      await tester.pumpAndSettle();
      gateway.revokeCompleter.complete();
      await tester.pumpAndSettle();

      expect(find.text('Dilema da conta B'), findsOneWidget);
      expect(gateway.accountB.isInviteRevoked, isFalse);
      expect(invites.removedIds, isEmpty);
      expect(await invites.getInviteUri(gateway.accountB.id), isNotNull);
    },
  );

  testWidgets(
    'late deletion from account A cannot alter account B or its invite',
    (tester) async {
      final gateway = _SessionSwitchDilemmaGateway(delayDelete: true);
      final auth = FakeAuthGateway(authenticated: true)
        ..accountId = 'account-a';
      final invites = _TrackingActiveInviteRepository();
      await invites.saveInviteUri(
        gateway.accountB.id,
        Uri.parse('https://guest.example.com/invite/account-b'),
      );

      await tester.pumpWidget(
        testApp(
          auth: auth,
          onboarding: MemoryOnboardingRepository(completeOnboarding),
          dilemmaGateway: gateway,
          activeInvites: invites,
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Dilema da conta A'));
      await tapVisible(tester, find.text('Apagar dilema'));
      await tester.tap(find.text('Apagar definitivamente'));
      await tester.pump();

      gateway.serveAccountB = true;
      auth.completeSignIn(userId: 'account-b');
      await tester.pumpAndSettle();
      gateway.deleteCompleter.complete();
      await tester.pumpAndSettle();

      expect(find.text('Dilema da conta B'), findsOneWidget);
      expect(invites.removedIds, isEmpty);
      expect(await invites.getInviteUri(gateway.accountB.id), isNotNull);
    },
  );

  testWidgets('tapping sign out on Home returns to Google sign-in screen', (
    tester,
  ) async {
    final auth = FakeAuthGateway(authenticated: true);
    await tester.pumpWidget(
      testApp(
        auth: auth,
        onboarding: MemoryOnboardingRepository(completeOnboarding),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Before I Buy'), findsOneWidget);
    final signOutButton = find.byTooltip('Sair da conta');
    expect(signOutButton, findsOneWidget);

    await tester.tap(signOutButton);
    await tester.pumpAndSettle();

    expect(find.text('Continuar com Google'), findsOneWidget);
    expect(auth.isAuthenticated, isFalse);
  });

  testWidgets(
    'tapping sign out on Draft screen returns to Google sign-in screen',
    (tester) async {
      final auth = FakeAuthGateway(authenticated: true);
      final draft = DraftDilemma(
        idempotencyKey: uuid,
        itemName: 'Fone de Ouvido',
        priceCents: 15000,
        category: ItemCategory.techElectronics,
        reason: 'Trabalhar com mais foco sem barulho.',
        purpose: DraftPurpose.forSelf,
        pauseHours: 72,
      );
      await tester.pumpWidget(
        testApp(
          auth: auth,
          onboarding: MemoryOnboardingRepository(completeOnboarding),
          drafts: MemoryDraftRepository(draft),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nova tentação'), findsOneWidget);
      final signOutButton = find.byTooltip('Sair da conta');
      expect(signOutButton, findsOneWidget);

      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      expect(find.text('Continuar com Google'), findsOneWidget);
      expect(auth.isAuthenticated, isFalse);
    },
  );
}

class _DelayedActiveInviteRepository implements ActiveInviteRepository {
  final completer = Completer<Uri?>();

  @override
  Future<Uri?> getInviteUri(String dilemmaId) => completer.future;

  @override
  Future<void> saveInviteUri(String dilemmaId, Uri inviteUri) async {}

  @override
  Future<void> removeInviteUri(String dilemmaId) async {}
}

class _FailingRemovalActiveInviteRepository implements ActiveInviteRepository {
  Uri? value;

  @override
  Future<Uri?> getInviteUri(String dilemmaId) async => value;

  @override
  Future<void> saveInviteUri(String dilemmaId, Uri inviteUri) async {
    value = inviteUri;
  }

  @override
  Future<void> removeInviteUri(String dilemmaId) async {
    throw StateError('simulated local cleanup failure');
  }
}

class _TrackingActiveInviteRepository extends MemoryActiveInviteRepository {
  final removedIds = <String>[];

  @override
  Future<void> removeInviteUri(String dilemmaId) async {
    removedIds.add(dilemmaId);
    await super.removeInviteUri(dilemmaId);
  }
}

class _SessionSwitchDilemmaGateway implements CreatorDilemmaGateway {
  _SessionSwitchDilemmaGateway({
    this.delayRevoke = false,
    this.delayDelete = false,
  });

  final bool delayRevoke;
  final bool delayDelete;
  final refreshCompleter = Completer<List<CreatorDilemmaSummary>>();
  final revokeCompleter = Completer<void>();
  final deleteCompleter = Completer<void>();
  bool serveAccountB = false;
  var fetchCount = 0;

  late final accountA = _dilemma('account-a-dilemma', 'Dilema da conta A');
  late final accountB = _dilemma('account-b-dilemma', 'Dilema da conta B');

  @override
  Future<List<CreatorDilemmaSummary>> fetchDilemmas() {
    fetchCount++;
    if (!serveAccountB && fetchCount > 1) return refreshCompleter.future;
    return Future.value([serveAccountB ? accountB : accountA]);
  }

  @override
  Future<void> revokeInvite(String dilemmaId) async {
    if (delayRevoke) await revokeCompleter.future;
  }

  @override
  Future<void> deleteDilemma(String dilemmaId) async {
    if (delayDelete) await deleteCompleter.future;
  }

  static CreatorDilemmaSummary _dilemma(String id, String name) =>
      CreatorDilemmaSummary(
        id: id,
        itemName: name,
        priceCents: 10000,
        currency: 'BRL',
        category: ItemCategory.other,
        purpose: DraftPurpose.forSelf,
        reason: 'Contexto suficiente para o teste de sessão.',
        pauseDueAt: DateTime.now().add(const Duration(days: 3)),
        state: 'collecting_votes',
        isInviteRevoked: false,
        createdAt: DateTime.now(),
        buyCount: 0,
        waitCount: 0,
        skipCount: 0,
        totalVotes: 0,
      );
}

class _FailingRefreshDilemmaGateway implements CreatorDilemmaGateway {
  _FailingRefreshDilemmaGateway(this.dilemmas);
  List<CreatorDilemmaSummary> dilemmas;
  bool failNextFetch = false;

  @override
  Future<List<CreatorDilemmaSummary>> fetchDilemmas() async {
    if (failNextFetch) throw StateError('simulated network failure');
    return dilemmas;
  }

  @override
  Future<void> revokeInvite(String dilemmaId) async {
    dilemmas = [
      for (final d in dilemmas)
        if (d.id == dilemmaId) d.copyWith(isInviteRevoked: true) else d,
    ];
  }

  @override
  Future<void> deleteDilemma(String dilemmaId) async {
    dilemmas = dilemmas.where((d) => d.id != dilemmaId).toList();
  }
}

class _DelayedAuthGateway extends FakeAuthGateway {
  final _completer = Completer<SocialAuthResult>();

  @override
  Future<SocialAuthResult> signInWithGoogle() {
    googleSignInCount += 1;
    return _completer.future;
  }

  void complete() {
    completeSignIn();
    _completer.complete(SocialAuthResult.authenticated);
  }
}
