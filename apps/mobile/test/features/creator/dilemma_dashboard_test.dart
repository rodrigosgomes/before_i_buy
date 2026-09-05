import 'package:before_i_buy_mobile/design_system/bib_theme.dart';
import 'package:before_i_buy_mobile/features/creator/creator_flow.dart';
import 'package:before_i_buy_mobile/features/creator/creator_remote_gateway.dart';
import 'package:before_i_buy_mobile/features/creator/draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: buildBibTheme(),
  home: Scaffold(body: child),
);

CreatorDilemmaSummary _dummyDilemma({
  String id = 'dilemma-1',
  String itemName = 'Fone Noise Cancelling',
  int priceCents = 240000,
  int buyCount = 0,
  int waitCount = 0,
  int skipCount = 0,
  int totalVotes = 0,
  bool isInviteRevoked = false,
  DateTime? pauseDueAt,
  String state = 'collecting_votes',
}) => CreatorDilemmaSummary(
  id: id,
  itemName: itemName,
  priceCents: priceCents,
  currency: 'BRL',
  category: ItemCategory.techElectronics,
  purpose: DraftPurpose.forSelf,
  reason: 'Mais concentração.',
  pauseDueAt: pauseDueAt ?? DateTime.now().add(const Duration(days: 7)),
  state: state,
  isInviteRevoked: isInviteRevoked,
  createdAt: DateTime.now(),
  buyCount: buyCount,
  waitCount: waitCount,
  skipCount: skipCount,
  totalVotes: totalVotes,
);

void main() {
  group('CreatorHomeScreen', () {
    testWidgets('empty dilemmas list renders onboarding chapters', (
      tester,
    ) async {
      var createCalled = false;
      await tester.pumpWidget(
        _wrap(
          CreatorHomeScreen(
            dilemmas: const [],
            onCreate: () => createCalled = true,
            onSelectDilemma: (_) {},
          ),
        ),
      );

      expect(find.text('Um pouco de espaço antes de decidir'), findsOneWidget);
      expect(find.text('Criar minha primeira tentação'), findsOneWidget);

      await tester.tap(find.text('Criar minha primeira tentação'));
      expect(createCalled, isTrue);
    });

    testWidgets('populated dilemmas renders dilemma cards and handles tap', (
      tester,
    ) async {
      final dilemma = _dummyDilemma(
        itemName: 'Fone Premium',
        priceCents: 150000,
        totalVotes: 3,
        buyCount: 2,
        waitCount: 1,
      );
      CreatorDilemmaSummary? selected;
      var createCalled = false;

      await tester.pumpWidget(
        _wrap(
          CreatorHomeScreen(
            dilemmas: [dilemma],
            onCreate: () => createCalled = true,
            onSelectDilemma: (d) => selected = d,
          ),
        ),
      );

      expect(find.text('Suas decisões com espaço'), findsOneWidget);
      expect(find.text('Fone Premium'), findsOneWidget);
      expect(find.text('R\$ 1.500,00'), findsOneWidget);
      expect(find.text('Coletando votos · 3 votos'), findsOneWidget);

      await tester.tap(find.text('Fone Premium'));
      expect(selected?.id, dilemma.id);

      await tester.ensureVisible(find.text('Criar nova tentação'));
      await tester.tap(find.text('Criar nova tentação'));
      expect(createCalled, isTrue);
    });

    testWidgets('shows revoked badge when invite is revoked on card', (
      tester,
    ) async {
      final dilemma = _dummyDilemma(isInviteRevoked: true);
      await tester.pumpWidget(
        _wrap(
          CreatorHomeScreen(
            dilemmas: [dilemma],
            onCreate: () {},
            onSelectDilemma: (_) {},
          ),
        ),
      );

      expect(find.text('Convite revogado'), findsOneWidget);
    });
  });

  group('PublishedDilemmaScreen', () {
    testWidgets('renders go to dashboard button and calls handler', (
      tester,
    ) async {
      var goToDashboardCalled = false;
      const draft = DraftDilemma(
        idempotencyKey: 'key',
        itemName: 'Kindle',
        priceCents: 50000,
        reason: 'Para ler mais livros.',
      );

      await tester.pumpWidget(
        _wrap(
          PublishedDilemmaScreen(
            draft: draft,
            onShare: () async => null,
            onGoToDashboard: () => goToDashboardCalled = true,
          ),
        ),
      );

      expect(find.text('Ver painel de acompanhamento'), findsOneWidget);
      await tester.ensureVisible(find.text('Ver painel de acompanhamento'));
      await tester.tap(find.text('Ver painel de acompanhamento'));
      expect(goToDashboardCalled, isTrue);
    });
  });

  group('DilemmaDashboardScreen', () {
    testWidgets('0 votes state displays waiting card and active share', (
      tester,
    ) async {
      final dilemma = _dummyDilemma(totalVotes: 0);
      var shareCalled = false;

      await tester.pumpWidget(
        _wrap(
          DilemmaDashboardScreen(
            dilemma: dilemma,
            onBack: () {},
            onShare: () async {
              shareCalled = true;
              return null;
            },
            onRevoke: () async => null,
            onDelete: () async => null,
          ),
        ),
      );

      expect(find.text('Aguardando votos'), findsOneWidget);
      expect(
        find.textContaining('Compartilhe o convite com pessoas próximas'),
        findsOneWidget,
      );
      expect(find.text('Compartilhar convite'), findsOneWidget);

      await tester.ensureVisible(find.text('Compartilhar convite'));
      await tester.tap(find.text('Compartilhar convite'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compartilhar'));
      await tester.pumpAndSettle();
      expect(shareCalled, isTrue);
    });

    testWidgets('1+ votes state displays vote distribution breakdown', (
      tester,
    ) async {
      final dilemma = _dummyDilemma(
        totalVotes: 4,
        buyCount: 2,
        waitCount: 1,
        skipCount: 1,
      );

      await tester.pumpWidget(
        _wrap(
          DilemmaDashboardScreen(
            dilemma: dilemma,
            onBack: () {},
            onShare: () async => null,
            onRevoke: () async => null,
            onDelete: () async => null,
          ),
        ),
      );

      expect(find.text('Perspectivas recebidas'), findsOneWidget);
      expect(find.text('Total: 4 votos'), findsOneWidget);
      expect(find.text('Comprar'), findsOneWidget);
      expect(find.text('2 (50%)'), findsOneWidget);
      expect(find.text('Esperar'), findsOneWidget);
      expect(find.text('1 (25%)'), findsNWidgets(2));
      expect(find.text('Deixar pra lá'), findsOneWidget);
    });

    testWidgets('revocation confirmation dialog works (cancel and confirm)', (
      tester,
    ) async {
      final dilemma = _dummyDilemma();
      var revokeCalled = false;

      await tester.pumpWidget(
        _wrap(
          DilemmaDashboardScreen(
            dilemma: dilemma,
            onBack: () {},
            onShare: () async => null,
            onRevoke: () async {
              revokeCalled = true;
              return null;
            },
            onDelete: () async => null,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Revogar convite'));
      await tester.tap(find.text('Revogar convite'));
      await tester.pumpAndSettle();

      // Dialog is displayed
      expect(find.text('Revogar convite?'), findsOneWidget);
      expect(
        find.textContaining('O link deixará de funcionar imediatamente'),
        findsOneWidget,
      );

      // Cancel dialog
      await tester.tap(find.text('Manter convite'));
      await tester.pumpAndSettle();
      expect(find.text('Revogar convite?'), findsNothing);
      expect(revokeCalled, isFalse);

      // Re-open and confirm
      await tester.tap(find.text('Revogar convite'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revogar'));
      await tester.pumpAndSettle();
      expect(revokeCalled, isTrue);
    });

    testWidgets('deletion confirmation dialog works (cancel and confirm)', (
      tester,
    ) async {
      final dilemma = _dummyDilemma();
      var deleteCalled = false;

      await tester.pumpWidget(
        _wrap(
          DilemmaDashboardScreen(
            dilemma: dilemma,
            onBack: () {},
            onShare: () async => null,
            onRevoke: () async => null,
            onDelete: () async {
              deleteCalled = true;
              return null;
            },
          ),
        ),
      );

      await tester.ensureVisible(find.text('Apagar dilema'));
      await tester.tap(find.text('Apagar dilema'));
      await tester.pumpAndSettle();

      // Dialog is displayed
      expect(find.text('Apagar dilema?'), findsOneWidget);
      expect(
        find.textContaining('Esta ação é definitiva e removerá este dilema'),
        findsOneWidget,
      );

      // Cancel dialog
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Apagar dilema?'), findsNothing);
      expect(deleteCalled, isFalse);

      // Re-open and confirm
      await tester.tap(find.text('Apagar dilema'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar definitivamente'));
      await tester.pumpAndSettle();
      expect(deleteCalled, isTrue);
    });

    testWidgets('revoked dilemma hides revoke action and disables share', (
      tester,
    ) async {
      final dilemma = _dummyDilemma(isInviteRevoked: true);

      await tester.pumpWidget(
        _wrap(
          DilemmaDashboardScreen(
            dilemma: dilemma,
            onBack: () {},
            onShare: null,
            onRevoke: () async => null,
            onDelete: () async => null,
          ),
        ),
      );

      expect(find.text('Convite revogado · votação encerrada'), findsOneWidget);
      expect(find.text('Revogar convite'), findsNothing);
      expect(find.text('Compartilhar convite'), findsNothing);
    });

    testWidgets('refresh reports failure and allows a successful retry', (
      tester,
    ) async {
      final dilemma = _dummyDilemma();
      var refreshCount = 0;

      await tester.pumpWidget(
        _wrap(
          DilemmaDashboardScreen(
            dilemma: dilemma,
            onBack: () {},
            onShare: () async => null,
            onRevoke: () async => null,
            onDelete: () async => null,
            onRefresh: () async {
              refreshCount += 1;
              return refreshCount == 1
                  ? 'Não foi possível atualizar as perspectivas agora.'
                  : null;
            },
          ),
        ),
      );

      final refreshBtn = find.byTooltip('Atualizar perspectivas');
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();
      expect(refreshCount, 1);
      expect(
        find.text('Não foi possível atualizar as perspectivas agora.'),
        findsOneWidget,
      );

      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();
      expect(refreshCount, 2);
      expect(
        find.text('Não foi possível atualizar as perspectivas agora.'),
        findsNothing,
      );
    });

    testWidgets('re-share warns that the private link may be forwarded', (
      tester,
    ) async {
      final dilemma = _dummyDilemma();
      var shareCalled = false;
      await tester.pumpWidget(
        _wrap(
          DilemmaDashboardScreen(
            dilemma: dilemma,
            onBack: () {},
            onShare: () async {
              shareCalled = true;
              return null;
            },
            onRevoke: () async => null,
            onDelete: () async => null,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Compartilhar convite'));
      await tester.tap(find.text('Compartilhar convite'));
      await tester.pumpAndSettle();
      expect(find.text('Compartilhar este convite?'), findsOneWidget);
      expect(find.textContaining('pode ser encaminhado'), findsOneWidget);
      expect(shareCalled, isFalse);

      await tester.tap(find.text('Compartilhar'));
      await tester.pumpAndSettle();
      expect(shareCalled, isTrue);
    });

    testWidgets(
      'expired pause displays closed status and hides share and revoke',
      (tester) async {
        final expired = _dummyDilemma(
          pauseDueAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        await tester.pumpWidget(
          _wrap(
            DilemmaDashboardScreen(
              dilemma: expired,
              onBack: () {},
              onShare: () async => null,
              onRevoke: () async => null,
              onDelete: () async => null,
            ),
          ),
        );

        expect(
          find.text('Pausa concluída · votação encerrada'),
          findsOneWidget,
        );
        expect(find.text('Compartilhar convite'), findsNothing);
        expect(find.text('Revogar convite'), findsNothing);
        expect(find.text('Apagar dilema'), findsOneWidget);
      },
    );

    testWidgets(
      'revocation error displays inline error message and re-enables buttons',
      (tester) async {
        final dilemma = _dummyDilemma();

        await tester.pumpWidget(
          _wrap(
            DilemmaDashboardScreen(
              dilemma: dilemma,
              onBack: () {},
              onShare: () async => null,
              onRevoke: () async => 'Erro ao revogar convite',
              onDelete: () async => null,
            ),
          ),
        );

        await tester.ensureVisible(find.text('Revogar convite'));
        await tester.tap(find.text('Revogar convite'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Revogar'));
        await tester.pumpAndSettle();

        expect(find.text('Erro ao revogar convite'), findsOneWidget);
        expect(find.text('Revogar convite'), findsOneWidget);
      },
    );

    testWidgets(
      'deletion error displays inline error message and re-enables buttons',
      (tester) async {
        final dilemma = _dummyDilemma();

        await tester.pumpWidget(
          _wrap(
            DilemmaDashboardScreen(
              dilemma: dilemma,
              onBack: () {},
              onShare: () async => null,
              onRevoke: () async => null,
              onDelete: () async => 'Erro ao apagar dilema',
            ),
          ),
        );

        await tester.ensureVisible(find.text('Apagar dilema'));
        await tester.tap(find.text('Apagar dilema'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apagar definitivamente'));
        await tester.pumpAndSettle();

        expect(find.text('Erro ao apagar dilema'), findsOneWidget);
        expect(find.text('Apagar dilema'), findsOneWidget);
      },
    );

    testWidgets(
      'dashboard reflows at 320px with 200 percent text without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final dilemma = _dummyDilemma(
          buyCount: 12,
          waitCount: 8,
          skipCount: 5,
          totalVotes: 25,
        );

        await tester.pumpWidget(
          _wrap(
            DilemmaDashboardScreen(
              dilemma: dilemma,
              onBack: () {},
              onShare: () async => null,
              onRevoke: () async => null,
              onDelete: () async => null,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Perspectivas recebidas'), findsOneWidget);
        expect(find.text('Comprar'), findsOneWidget);
        expect(find.text('Esperar'), findsOneWidget);
        expect(find.text('Deixar pra lá'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
