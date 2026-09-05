import 'package:supabase_flutter/supabase_flutter.dart';

import '../onboarding/onboarding_repository.dart';
import 'draft.dart';

enum CreatorProfileStatus { ready, needsSync, unavailable }

abstract interface class CreatorProfileGateway {
  Future<CreatorProfileStatus> status();
  Future<void> sync(LocalOnboarding onboarding);
}

abstract interface class DilemmaPublicationGateway {
  Future<PublishedInvite> publish(DraftDilemma draft);
}

abstract interface class CreatorDilemmaGateway {
  Future<List<CreatorDilemmaSummary>> fetchDilemmas();
  Future<void> revokeInvite(String dilemmaId);
  Future<void> deleteDilemma(String dilemmaId);
}

abstract interface class InviteShareGateway {
  Future<void> share(Uri inviteUri);
}

class CreatorDilemmaSummary {
  const CreatorDilemmaSummary({
    required this.id,
    required this.itemName,
    required this.priceCents,
    required this.currency,
    required this.category,
    required this.purpose,
    required this.reason,
    required this.pauseDueAt,
    required this.state,
    required this.isInviteRevoked,
    required this.createdAt,
    required this.buyCount,
    required this.waitCount,
    required this.skipCount,
    required this.totalVotes,
  });

  final String id;
  final String itemName;
  final int priceCents;
  final String currency;
  final ItemCategory category;
  final DraftPurpose purpose;
  final String reason;
  final DateTime pauseDueAt;
  final String state;
  final bool isInviteRevoked;
  final DateTime createdAt;
  final int buyCount;
  final int waitCount;
  final int skipCount;
  final int totalVotes;

  bool get isVotingOpen =>
      !isInviteRevoked &&
      state == 'collecting_votes' &&
      pauseDueAt.isAfter(DateTime.now());

  double get buyPercentage =>
      totalVotes == 0 ? 0.0 : (buyCount / totalVotes) * 100;
  double get waitPercentage =>
      totalVotes == 0 ? 0.0 : (waitCount / totalVotes) * 100;
  double get skipPercentage =>
      totalVotes == 0 ? 0.0 : (skipCount / totalVotes) * 100;

  CreatorDilemmaSummary copyWith({
    String? id,
    String? itemName,
    int? priceCents,
    String? currency,
    ItemCategory? category,
    DraftPurpose? purpose,
    String? reason,
    DateTime? pauseDueAt,
    String? state,
    bool? isInviteRevoked,
    DateTime? createdAt,
    int? buyCount,
    int? waitCount,
    int? skipCount,
    int? totalVotes,
  }) => CreatorDilemmaSummary(
    id: id ?? this.id,
    itemName: itemName ?? this.itemName,
    priceCents: priceCents ?? this.priceCents,
    currency: currency ?? this.currency,
    category: category ?? this.category,
    purpose: purpose ?? this.purpose,
    reason: reason ?? this.reason,
    pauseDueAt: pauseDueAt ?? this.pauseDueAt,
    state: state ?? this.state,
    isInviteRevoked: isInviteRevoked ?? this.isInviteRevoked,
    createdAt: createdAt ?? this.createdAt,
    buyCount: buyCount ?? this.buyCount,
    waitCount: waitCount ?? this.waitCount,
    skipCount: skipCount ?? this.skipCount,
    totalVotes: totalVotes ?? this.totalVotes,
  );

  factory CreatorDilemmaSummary.fromJson(Map<String, dynamic> json) =>
      CreatorDilemmaSummary(
        id: json['dilemma_id'] as String,
        itemName: json['item_name'] as String,
        priceCents: (json['price_cents'] as num).toInt(),
        currency: json['currency'] as String? ?? 'BRL',
        category:
            ItemCategory.fromBackendValue(json['category'] as String) ??
            ItemCategory.other,
        purpose:
            DraftPurpose.fromBackendValue(json['purpose'] as String) ??
            DraftPurpose.forSelf,
        reason: json['reason'] as String,
        pauseDueAt: DateTime.parse(json['pause_due_at'] as String),
        state: json['state'] as String,
        isInviteRevoked: json['is_invite_revoked'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        buyCount: (json['buy_count'] as num?)?.toInt() ?? 0,
        waitCount: (json['wait_count'] as num?)?.toInt() ?? 0,
        skipCount: (json['skip_count'] as num?)?.toInt() ?? 0,
        totalVotes: (json['total_votes'] as num?)?.toInt() ?? 0,
      );
}

class PublishedInvite {
  const PublishedInvite({required this.dilemmaId, required this.inviteToken});

  final String dilemmaId;
  final String inviteToken;
}

class GuestInviteLinkBuilder {
  const GuestInviteLinkBuilder(this.baseUri);

  final Uri? baseUri;

  Uri build(String inviteToken) {
    if (baseUri == null ||
        inviteToken.isEmpty ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(inviteToken)) {
      throw const InviteLinkConfigurationException();
    }
    final pathSegments = [
      ...baseUri!.pathSegments.where((segment) => segment.isNotEmpty),
      'invite',
      inviteToken,
    ];
    return baseUri!.replace(pathSegments: pathSegments);
  }
}

class InviteLinkConfigurationException implements Exception {
  const InviteLinkConfigurationException();
}

class SupabaseCreatorProfileGateway implements CreatorProfileGateway {
  SupabaseCreatorProfileGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<CreatorProfileStatus> status() async {
    try {
      final row = await _client
          .from('profiles')
          .select(
            'id, is_adult_confirmed, terms_accepted_version, privacy_accepted_version',
          )
          .maybeSingle();
      if (row == null ||
          row['is_adult_confirmed'] != true ||
          row['terms_accepted_version'] != 'internal-demo-v1' ||
          row['privacy_accepted_version'] != 'internal-demo-v1') {
        return CreatorProfileStatus.needsSync;
      }
      return CreatorProfileStatus.ready;
    } catch (_) {
      return CreatorProfileStatus.unavailable;
    }
  }

  @override
  Future<void> sync(LocalOnboarding onboarding) async {
    await _client.rpc(
      'upsert_creator_profile',
      params: {
        'p_display_name': onboarding.displayName.trim(),
        'p_is_adult_confirmed': onboarding.adultConfirmed,
        'p_terms_accepted': onboarding.termsAccepted,
        'p_privacy_accepted': onboarding.privacyAccepted,
      },
    );
  }
}

class SupabaseDilemmaPublicationGateway implements DilemmaPublicationGateway {
  SupabaseDilemmaPublicationGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<PublishedInvite> publish(DraftDilemma draft) async {
    final response = await _client.rpc(
      'publish_dilemma',
      params: {
        'p_item_name': draft.itemName.trim(),
        'p_price_cents': draft.priceCents,
        'p_currency': 'BRL',
        'p_category': draft.category.backendValue,
        'p_purpose': draft.purpose.backendValue,
        'p_reason': draft.reason.trim(),
        'p_wanted_since': null,
        'p_pause_hours': draft.pauseHours,
        'p_client_idempotency_key': draft.idempotencyKey,
      },
    );
    final values = response is List && response.length == 1
        ? response.single
        : response;
    if (values is! Map) throw const PublicationResponseException();
    final dilemmaId = values['dilemma_id'];
    final inviteToken = values['invite_token'];
    if (dilemmaId is! String ||
        !RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        ).hasMatch(dilemmaId) ||
        inviteToken is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(inviteToken)) {
      throw const PublicationResponseException();
    }
    return PublishedInvite(dilemmaId: dilemmaId, inviteToken: inviteToken);
  }
}

class PublicationResponseException implements Exception {
  const PublicationResponseException();
}

class SupabaseCreatorDilemmaGateway implements CreatorDilemmaGateway {
  SupabaseCreatorDilemmaGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CreatorDilemmaSummary>> fetchDilemmas() async {
    final response = await _client.rpc('get_creator_dilemmas');
    if (response is! List) return [];
    return response
        .whereType<Map>()
        .map(
          (row) =>
              CreatorDilemmaSummary.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  @override
  Future<void> revokeInvite(String dilemmaId) async {
    await _client.rpc(
      'revoke_dilemma_invite',
      params: {'p_dilemma_id': dilemmaId},
    );
  }

  @override
  Future<void> deleteDilemma(String dilemmaId) async {
    await _client.rpc(
      'delete_creator_dilemma',
      params: {'p_dilemma_id': dilemmaId},
    );
  }
}

class MemoryCreatorProfileGateway implements CreatorProfileGateway {
  MemoryCreatorProfileGateway({
    this.nextStatus = CreatorProfileStatus.ready,
    this.syncError,
  });

  CreatorProfileStatus nextStatus;
  Object? syncError;
  final synced = <LocalOnboarding>[];

  @override
  Future<CreatorProfileStatus> status() async => nextStatus;

  @override
  Future<void> sync(LocalOnboarding onboarding) async {
    if (syncError != null) throw syncError!;
    synced.add(onboarding);
    nextStatus = CreatorProfileStatus.ready;
  }
}

class MemoryDilemmaPublicationGateway implements DilemmaPublicationGateway {
  MemoryDilemmaPublicationGateway({this.result, this.error});

  PublishedInvite? result;
  Object? error;
  final published = <DraftDilemma>[];

  @override
  Future<PublishedInvite> publish(DraftDilemma draft) async {
    if (error != null) throw error!;
    published.add(draft);
    return result ??
        const PublishedInvite(
          dilemmaId: '00000000-0000-4000-8000-000000000401',
          inviteToken: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        );
  }
}

class MemoryInviteShareGateway implements InviteShareGateway {
  Object? error;
  final shared = <Uri>[];

  @override
  Future<void> share(Uri inviteUri) async {
    if (error != null) throw error!;
    shared.add(inviteUri);
  }
}

class MemoryCreatorDilemmaGateway implements CreatorDilemmaGateway {
  MemoryCreatorDilemmaGateway({List<CreatorDilemmaSummary>? initial})
    : dilemmas = initial != null ? List.of(initial) : [];

  final List<CreatorDilemmaSummary> dilemmas;
  Object? error;

  @override
  Future<List<CreatorDilemmaSummary>> fetchDilemmas() async {
    if (error != null) throw error!;
    return List.unmodifiable(dilemmas);
  }

  @override
  Future<void> revokeInvite(String dilemmaId) async {
    if (error != null) throw error!;
    final index = dilemmas.indexWhere((d) => d.id == dilemmaId);
    if (index != -1) {
      final current = dilemmas[index];
      dilemmas[index] = CreatorDilemmaSummary(
        id: current.id,
        itemName: current.itemName,
        priceCents: current.priceCents,
        currency: current.currency,
        category: current.category,
        purpose: current.purpose,
        reason: current.reason,
        pauseDueAt: current.pauseDueAt,
        state: current.state,
        isInviteRevoked: true,
        createdAt: current.createdAt,
        buyCount: current.buyCount,
        waitCount: current.waitCount,
        skipCount: current.skipCount,
        totalVotes: current.totalVotes,
      );
    }
  }

  @override
  Future<void> deleteDilemma(String dilemmaId) async {
    if (error != null) throw error!;
    dilemmas.removeWhere((d) => d.id == dilemmaId);
  }
}
