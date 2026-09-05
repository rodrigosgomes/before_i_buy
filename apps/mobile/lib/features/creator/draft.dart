enum ItemCategory {
  techElectronics('tech_electronics', 'Tecnologia e eletrônicos'),
  fashionApparel('fashion_apparel', 'Moda e vestuário'),
  beautyPersonalCare('beauty_personal_care', 'Beleza e cuidados pessoais'),
  homeLiving('home_living', 'Casa'),
  hobbiesCrafts('hobbies_crafts', 'Hobbies e artesanato'),
  gamingEntertainment('gaming_entertainment', 'Jogos e entretenimento'),
  foodExperiences('food_experiences', 'Comida e experiências'),
  toolsHardware('tools_hardware', 'Ferramentas'),
  other('other', 'Outro');

  const ItemCategory(this.backendValue, this.label);
  final String backendValue;
  final String label;

  static ItemCategory? fromBackendValue(String value) {
    for (final category in values) {
      if (category.backendValue == value) return category;
    }
    return null;
  }
}

enum DraftPurpose {
  forSelf('for_self', 'Para mim'),
  gift('gift', 'É um presente');

  const DraftPurpose(this.backendValue, this.label);
  final String backendValue;
  final String label;

  static DraftPurpose? fromBackendValue(String value) {
    for (final purpose in values) {
      if (purpose.backendValue == value) return purpose;
    }
    return null;
  }
}

enum DraftField { itemName, price, reason }

class DraftDilemma {
  const DraftDilemma({
    required this.idempotencyKey,
    this.itemName = '',
    this.priceCents = 0,
    this.category = ItemCategory.other,
    this.reason = '',
    this.purpose = DraftPurpose.forSelf,
    this.pauseHours = 72,
    this.publicationPending = false,
  });

  static const schemaVersion = 1;
  static const validPauseHours = {24, 72, 168};

  final String idempotencyKey;
  final String itemName;
  final int priceCents;
  final ItemCategory category;
  final String reason;
  final DraftPurpose purpose;
  final int pauseHours;
  final bool publicationPending;

  Map<DraftField, String> get validationErrors {
    final errors = <DraftField, String>{};
    final normalizedName = itemName.trim();
    final normalizedReason = reason.trim();
    if (normalizedName.length < 2 || normalizedName.length > 80) {
      errors[DraftField.itemName] = 'Use entre 2 e 80 caracteres.';
    }
    if (priceCents <= 0) {
      errors[DraftField.price] = 'Informe um preço maior que zero.';
    }
    if (normalizedReason.length < 10 || normalizedReason.length > 500) {
      errors[DraftField.reason] = 'Use entre 10 e 500 caracteres.';
    }
    return errors;
  }

  bool get isValid => validationErrors.isEmpty;

  String get pauseLabel => switch (pauseHours) {
    24 => '24 horas',
    72 => '3 dias',
    168 => '7 dias',
    _ => '$pauseHours horas',
  };

  DraftDilemma copyWith({
    String? itemName,
    int? priceCents,
    ItemCategory? category,
    String? reason,
    DraftPurpose? purpose,
    int? pauseHours,
    bool? publicationPending,
  }) => DraftDilemma(
    idempotencyKey: idempotencyKey,
    itemName: itemName ?? this.itemName,
    priceCents: priceCents ?? this.priceCents,
    category: category ?? this.category,
    reason: reason ?? this.reason,
    purpose: purpose ?? this.purpose,
    pauseHours: pauseHours ?? this.pauseHours,
    publicationPending: publicationPending ?? this.publicationPending,
  );

  Map<String, Object> toJson() => {
    'schema_version': schemaVersion,
    'idempotency_key': idempotencyKey,
    'item_name': itemName,
    'price_cents': priceCents,
    'category': category.backendValue,
    'reason': reason,
    'purpose': purpose.backendValue,
    'pause_hours': pauseHours,
    'publication_pending': publicationPending,
  };

  static DraftDilemma? fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['schema_version'] != schemaVersion) {
      return null;
    }
    final key = value['idempotency_key'];
    final itemName = value['item_name'];
    final priceCents = value['price_cents'];
    final categoryValue = value['category'];
    final reason = value['reason'];
    final purposeValue = value['purpose'];
    final pauseHours = value['pause_hours'];
    if (key is! String || !_isUuid(key)) return null;
    if (itemName is! String ||
        priceCents is! int ||
        categoryValue is! String ||
        reason is! String ||
        purposeValue is! String ||
        pauseHours is! int) {
      return null;
    }
    final category = ItemCategory.fromBackendValue(categoryValue);
    final purpose = DraftPurpose.fromBackendValue(purposeValue);
    if (category == null ||
        purpose == null ||
        !validPauseHours.contains(pauseHours)) {
      return null;
    }
    return DraftDilemma(
      idempotencyKey: key,
      itemName: itemName,
      priceCents: priceCents,
      category: category,
      reason: reason,
      purpose: purpose,
      pauseHours: pauseHours,
      publicationPending: value['publication_pending'] == true,
    );
  }

  static bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}

int brlToCents(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(digits) ?? 0;
}

String centsToBrl(int cents, {bool includeSymbol = true}) {
  final safeCents = cents < 0 ? 0 : cents;
  final whole = (safeCents ~/ 100).toString();
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final decimal = (safeCents % 100).toString().padLeft(2, '0');
  return '${includeSymbol ? 'R\$ ' : ''}$grouped,$decimal';
}
