import 'package:before_i_buy_mobile/features/creator/draft.dart';
import 'package:flutter_test/flutter_test.dart';

const uuid = '123e4567-e89b-42d3-a456-426614174000';

void main() {
  group('BRL conversion', () {
    test('parses typed BRL into cents', () {
      expect(brlToCents('R\$ 2.400,00'), 240000);
      expect(brlToCents('0,01'), 1);
      expect(brlToCents(''), 0);
      expect(brlToCents('abc'), 0);
    });

    test('formats cents with Brazilian grouping', () {
      expect(centsToBrl(240000), 'R\$ 2.400,00');
      expect(centsToBrl(1, includeSymbol: false), '0,01');
      expect(centsToBrl(-1), 'R\$ 0,00');
    });
  });

  group('DraftDilemma', () {
    test('validates item, positive price, and reason limits', () {
      const invalid = DraftDilemma(idempotencyKey: uuid);
      expect(invalid.isValid, isFalse);
      expect(invalid.validationErrors.keys, {
        DraftField.itemName,
        DraftField.price,
        DraftField.reason,
      });

      final valid = invalid.copyWith(
        itemName: 'Fone',
        priceCents: 240000,
        reason: 'Quero mais foco para trabalhar.',
      );
      expect(valid.isValid, isTrue);
      expect(valid.pauseLabel, '3 dias');
      expect(valid.copyWith(pauseHours: 24).pauseLabel, '24 horas');
      expect(valid.copyWith(pauseHours: 168).pauseLabel, '7 dias');
    });

    test('copy keeps the idempotency key and updates all choices', () {
      const draft = DraftDilemma(idempotencyKey: uuid);
      final changed = draft.copyWith(
        category: ItemCategory.techElectronics,
        purpose: DraftPurpose.gift,
        pauseHours: 168,
      );
      expect(changed.idempotencyKey, uuid);
      expect(changed.category.backendValue, 'tech_electronics');
      expect(changed.purpose.backendValue, 'gift');
      expect(changed.pauseHours, 168);
    });

    test('round-trips versioned JSON preserving UUID', () {
      final original = const DraftDilemma(idempotencyKey: uuid).copyWith(
        itemName: 'Fone',
        priceCents: 240000,
        category: ItemCategory.techElectronics,
        reason: 'Quero mais foco para trabalhar.',
        purpose: DraftPurpose.gift,
        pauseHours: 168,
      );
      final restored = DraftDilemma.fromJson(original.toJson());
      expect(restored?.toJson(), original.toJson());
      expect(restored?.idempotencyKey, uuid);
    });

    test('rejects corrupt, unknown, or incompatible JSON', () {
      expect(DraftDilemma.fromJson(null), isNull);
      expect(DraftDilemma.fromJson({'schema_version': 2}), isNull);
      expect(
        DraftDilemma.fromJson({
          ...const DraftDilemma(idempotencyKey: uuid).toJson(),
          'idempotency_key': 'not-a-uuid',
        }),
        isNull,
      );
      expect(
        DraftDilemma.fromJson({
          ...const DraftDilemma(idempotencyKey: uuid).toJson(),
          'category': 'unknown',
        }),
        isNull,
      );
      expect(
        DraftDilemma.fromJson({
          ...const DraftDilemma(idempotencyKey: uuid).toJson(),
          'pause_hours': 12,
        }),
        isNull,
      );
    });

    test('maps backend enum values defensively', () {
      expect(
        ItemCategory.fromBackendValue('food_experiences'),
        ItemCategory.foodExperiences,
      );
      expect(ItemCategory.fromBackendValue('missing'), isNull);
      expect(DraftPurpose.fromBackendValue('for_self'), DraftPurpose.forSelf);
      expect(DraftPurpose.fromBackendValue('missing'), isNull);
    });
  });
}
