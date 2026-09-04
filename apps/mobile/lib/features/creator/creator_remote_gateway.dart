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

abstract interface class InviteShareGateway {
  Future<void> share(Uri inviteUri);
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
