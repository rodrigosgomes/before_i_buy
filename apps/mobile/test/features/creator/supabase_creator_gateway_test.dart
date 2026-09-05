import 'dart:convert';

import 'package:before_i_buy_mobile/features/creator/creator_remote_gateway.dart';
import 'package:before_i_buy_mobile/features/creator/draft.dart';
import 'package:before_i_buy_mobile/features/onboarding/onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const id = '00000000-0000-4000-8000-000000000401';
  const draft = DraftDilemma(
    idempotencyKey: id,
    itemName: ' Fone ',
    priceCents: 10000,
    reason: ' Para viajar com conforto ',
  );
  const profile = LocalOnboarding(
    displayName: ' Lu ',
    adultConfirmed: true,
    termsAccepted: true,
    privacyAccepted: true,
  );

  SupabaseClient client(Future<http.Response> Function(http.Request) handler) =>
      SupabaseClient(
        'https://example.supabase.co',
        'public-key',
        httpClient: MockClient((request) async {
          final response = await handler(request);
          return http.Response.bytes(
            response.bodyBytes,
            response.statusCode,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

  test(
    'real publication gateway sends the exact RPC payload and parses table result',
    () async {
      final gateway = SupabaseDilemmaPublicationGateway(
        client((request) async {
          expect(request.url.path, '/rest/v1/rpc/publish_dilemma');
          expect(jsonDecode(request.body), {
            'p_item_name': 'Fone',
            'p_price_cents': 10000,
            'p_currency': 'BRL',
            'p_category': 'other',
            'p_purpose': 'for_self',
            'p_reason': 'Para viajar com conforto',
            'p_wanted_since': null,
            'p_pause_hours': 72,
            'p_client_idempotency_key': id,
          });
          return http.Response(
            jsonEncode([
              {'dilemma_id': id, 'invite_token': token},
            ]),
            200,
          );
        }),
      );
      final result = await gateway.publish(draft);
      expect(result.dilemmaId, id);
      expect(result.inviteToken, token);
    },
  );

  test(
    'publication accepts object result and rejects malformed responses without exposing them',
    () async {
      for (final response in [
        null,
        [],
        [{}, {}],
        {},
        {'dilemma_id': 'invalid', 'invite_token': token},
        {'dilemma_id': id, 'invite_token': 'private-malformed-secret'},
      ]) {
        final gateway = SupabaseDilemmaPublicationGateway(
          client((_) async => http.Response(jsonEncode(response), 200)),
        );
        await expectLater(
          gateway.publish(draft),
          throwsA(isA<PublicationResponseException>()),
        );
      }
      final gateway = SupabaseDilemmaPublicationGateway(
        client(
          (_) async => http.Response(
            jsonEncode({'dilemma_id': id, 'invite_token': token}),
            200,
          ),
        ),
      );
      expect((await gateway.publish(draft)).dilemmaId, id);
      expect(
        const PublicationResponseException().toString(),
        isNot(contains(token)),
      );
    },
  );

  test(
    'profile status handles ready, missing, incomplete and unavailable results',
    () async {
      for (final row in [
        null,
        {'is_adult_confirmed': false},
        {'is_adult_confirmed': true, 'terms_accepted_version': 'forged'},
        {
          'is_adult_confirmed': true,
          'terms_accepted_version': 'internal-demo-v1',
          'privacy_accepted_version': 'forged',
        },
        {
          'is_adult_confirmed': true,
          'terms_accepted_version': 'internal-demo-v1',
          'privacy_accepted_version': 'internal-demo-v1',
        },
      ]) {
        final gateway = SupabaseCreatorProfileGateway(
          client((request) async {
            expect(request.url.path, '/rest/v1/profiles');
            return http.Response(jsonEncode(row == null ? [] : [row]), 200);
          }),
        );
        expect(
          await gateway.status(),
          row?['privacy_accepted_version'] == 'internal-demo-v1'
              ? CreatorProfileStatus.ready
              : CreatorProfileStatus.needsSync,
        );
      }
      final offline = SupabaseCreatorProfileGateway(
        client((_) async => throw http.ClientException('offline')),
      );
      expect(await offline.status(), CreatorProfileStatus.unavailable);
    },
  );

  test(
    'profile RPC sends chosen name and independent declarations without client versions',
    () async {
      final gateway = SupabaseCreatorProfileGateway(
        client((request) async {
          expect(request.url.path, '/rest/v1/rpc/upsert_creator_profile');
          expect(jsonDecode(request.body), {
            'p_display_name': 'Lu',
            'p_is_adult_confirmed': true,
            'p_terms_accepted': true,
            'p_privacy_accepted': true,
          });
          return http.Response('{}', 200);
        }),
      );
      await gateway.sync(profile);
    },
  );
}
