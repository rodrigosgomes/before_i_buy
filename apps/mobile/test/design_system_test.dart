import 'package:before_i_buy_mobile/design_system/bib_components.dart';
import 'package:before_i_buy_mobile/design_system/bib_theme.dart';
import 'package:before_i_buy_mobile/features/creator/draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theme uses the approved semantic colors and minimum button height', () {
    final theme = buildBibTheme();
    expect(theme.scaffoldBackgroundColor, BibColors.canvas);
    expect(theme.colorScheme.primary, BibColors.actionPrimary);
    expect(theme.colorScheme.onPrimary, BibColors.onActionPrimary);
    expect(
      theme.filledButtonTheme.style?.minimumSize?.resolve({}),
      const Size(48, 52),
    );
  });

  test('currency formatter keeps digits as a localized BRL value', () {
    final value = BrCurrencyInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '240000'),
    );
    expect(value.text, '2.400,00');
    expect(value.selection.baseOffset, value.text.length);
    expect(
      BrCurrencyInputFormatter()
          .formatEditUpdate(value, TextEditingValue.empty)
          .text,
      isEmpty,
    );
  });

  testWidgets('consent checklist keeps acceptances independent', (
    tester,
  ) async {
    var terms = false;
    var privacy = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBibTheme(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: BibConsentChecklist(
              termsAccepted: terms,
              privacyAccepted: privacy,
              onTermsChanged: (value) => setState(() => terms = value),
              onPrivacyChanged: (value) => setState(() => privacy = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aceito os Termos de demonstração'));
    await tester.pump();
    expect(terms, isTrue);
    expect(privacy, isFalse);
    expect(find.textContaining('sem validade jurídica'), findsOneWidget);
  });

  testWidgets('segmented choice and select expose every label', (tester) async {
    var purpose = DraftPurpose.forSelf;
    var category = ItemCategory.other;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBibTheme(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ListView(
              children: [
                BibSegmentedChoice<DraftPurpose>(
                  label: 'É para quem?',
                  options: {
                    for (final value in DraftPurpose.values) value: value.label,
                  },
                  selected: purpose,
                  onChanged: (value) => setState(() => purpose = value),
                ),
                BibSelectField<ItemCategory>(
                  label: 'Categoria',
                  value: category,
                  items: {
                    for (final value in ItemCategory.values) value: value.label,
                  },
                  onChanged: (value) {
                    if (value != null) setState(() => category = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('É um presente'));
    await tester.pump();
    expect(purpose, DraftPurpose.gift);
    expect(find.text('Categoria'), findsOneWidget);
  });
}
