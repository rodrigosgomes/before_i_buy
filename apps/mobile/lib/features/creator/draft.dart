enum DraftPurpose { forSelf, gift }

class DraftDilemma {
  const DraftDilemma({
    this.itemName = '',
    this.priceCents = 0,
    this.category = 'other',
    this.reason = '',
    this.purpose = DraftPurpose.forSelf,
    this.pauseHours = 72,
  });
  final String itemName, category, reason;
  final int priceCents, pauseHours;
  final DraftPurpose purpose;
  bool get valid =>
      itemName.trim().length >= 2 &&
      itemName.trim().length <= 80 &&
      priceCents > 0 &&
      reason.trim().length >= 10 &&
      reason.trim().length <= 500;
  DraftDilemma copyWith({
    String? itemName,
    int? priceCents,
    String? category,
    String? reason,
  }) => DraftDilemma(
    itemName: itemName ?? this.itemName,
    priceCents: priceCents ?? this.priceCents,
    category: category ?? this.category,
    reason: reason ?? this.reason,
    purpose: purpose,
    pauseHours: pauseHours,
  );
}

int brlToCents(String value) =>
    int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
String centsToBrl(int cents) =>
    'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
