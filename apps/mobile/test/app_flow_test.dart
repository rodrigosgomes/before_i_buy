import 'dart:async';

import 'package:before_i_buy_mobile/app.dart';
import 'package:before_i_buy_mobile/core/app_config.dart';
import 'package:before_i_buy_mobile/features/auth/auth_gateway.dart';
import 'package:before_i_buy_mobile/features/creator/draft.dart';
import 'package:before_i_buy_mobile/features/creator/draft_repository.dart';
import 'package:before_i_buy_mobile/features/onboarding/onboarding_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const configured = AppConfig(
  supabaseUrl: 'https://example.supabase.co',
  supabasePublishableKey: 'public-key',
  googleWebClientId: 'web.apps.googleusercontent.com',
  googleIosClientId: 'ios.apps.googleusercontent.com',
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
  AppConfig config = configured,
  TargetPlatform platform = TargetPlatform.android,
}) => BeforeIBuyApp(
  config: config,
  authGateway: auth,
  onboardingRepository: onboarding ?? MemoryOnboardingRepository(),
  draftRepository: drafts ?? MemoryDraftRepository(),
  createId: () => uuid,
  platform: platform,
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
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

  testWidgets('fake Google Auth completes the entire offline 3A flow', (
    tester,
  ) async {
    final auth = FakeAuthGateway();
    final onboarding = MemoryOnboardingRepository();
    final drafts = MemoryDraftRepository();
    await tester.pumpWidget(
      testApp(auth: auth, onboarding: onboarding, drafts: drafts),
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

    expect(find.text('Um pouco de espaço antes de decidir'), findsOneWidget);
    expect(onboarding.value?.isComplete, isTrue);
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
    expect(find.text('Publicação disponível na próxima etapa'), findsOneWidget);
    expect(drafts.value?.idempotencyKey, uuid);
    expect(drafts.value?.purpose, DraftPurpose.gift);
    expect(drafts.value?.pauseHours, 168);
    expect(auth.googleSignInCount, 1);

    await tapVisible(tester, find.text('Editar'));
    expect(find.text('Fone com cancelamento de ruído'), findsOneWidget);
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
