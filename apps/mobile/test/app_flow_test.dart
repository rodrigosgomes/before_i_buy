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
  supabaseAnonKey: 'public-key',
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
}) => BeforeIBuyApp(
  config: config,
  authGateway: auth,
  onboardingRepository: onboarding ?? MemoryOnboardingRepository(),
  draftRepository: drafts ?? MemoryDraftRepository(),
  createId: () => uuid,
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
        config: const AppConfig(supabaseUrl: '', supabaseAnonKey: ''),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configuração interna ausente'), findsOneWidget);
    expect(find.textContaining('Nenhuma conexão foi tentada'), findsOneWidget);
    expect(auth.sendCount, 0);
  });

  testWidgets('magic link validates, handles failure, and waits for callback', (
    tester,
  ) async {
    final auth = FakeAuthGateway();
    await tester.pumpWidget(testApp(auth: auth));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'email-invalido');
    await tester.tap(find.text('Receber link de entrada'));
    await tester.pump();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);

    auth.failure = StateError('offline');
    await tester.enterText(find.byType(TextField), 'lu@example.com');
    await tester.tap(find.text('Receber link de entrada'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Não foi possível enviar'), findsOneWidget);

    auth.failure = null;
    await tester.tap(find.text('Receber link de entrada'));
    await tester.pumpAndSettle();
    expect(find.text('Confira seu e-mail'), findsOneWidget);
    expect(auth.lastEmail, 'lu@example.com');
    expect(auth.lastRedirectTo, 'beforeibuy://auth-callback');

    await tester.tap(find.text('Reenviar link'));
    await tester.pumpAndSettle();
    expect(find.text('Um novo link foi enviado.'), findsOneWidget);
    expect(auth.sendCount, 3);

    await tester.tap(find.text('Usar outro e-mail'));
    await tester.pumpAndSettle();
    expect(find.text('Receber link de entrada'), findsOneWidget);
  });

  testWidgets('fake Auth completes the entire offline 3A flow', (tester) async {
    final auth = FakeAuthGateway();
    final onboarding = MemoryOnboardingRepository();
    final drafts = MemoryDraftRepository();
    await tester.pumpWidget(
      testApp(auth: auth, onboarding: onboarding, drafts: drafts),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'lu@example.com');
    await tester.tap(find.text('Receber link de entrada'));
    await tester.pumpAndSettle();
    auth.completeSignIn();
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
    expect(auth.sendCount, 1);

    await tapVisible(tester, find.text('Editar'));
    expect(find.text('Fone com cancelamento de ruído'), findsOneWidget);
  });

  testWidgets('invalid form announces errors without losing content', (
    tester,
  ) async {
    final auth = FakeAuthGateway(authenticated: true);
    final drafts = MemoryDraftRepository();
    await tester.pumpWidget(
      testApp(
        auth: auth,
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
    await tester.scrollUntilVisible(
      find.text('Quanto espaço você quer antes de decidir?'),
      300,
    );
    expect(tester.takeException(), isNull);
  });
}
