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

  final clients = <SupabaseClient>[];
  SupabaseClient client(Future<http.Response> Function(http.Request) handler) {
    final value = SupabaseClient(
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
    clients.add(value);
    return value;
  }

  tearDown(() async {
    for (final client in clients) {
      await client.dispose();
    }
    clients.clear();
  });

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

  test('creator dilemma summary parses row with vote aggregates', () {
    final now = DateTime.now().toUtc();
    final row = {
      'dilemma_id': id,
      'item_name': 'Monitor 4K',
      'price_cents': 350000,
      'currency': 'BRL',
      'category': 'electronics',
      'purpose': 'for_work',
      'reason': 'Mais produtividade no trabalho.',
      'pause_due_at': now.toIso8601String(),
      'state': 'collecting_votes',
      'is_invite_revoked': false,
      'created_at': now.toIso8601String(),
      'buy_count': 3,
      'wait_count': 2,
      'skip_count': 1,
      'total_votes': 6,
    };
    final summary = CreatorDilemmaSummary.fromJson(row);
    expect(summary.id, id);
    expect(summary.itemName, 'Monitor 4K');
    expect(summary.priceCents, 350000);
    expect(summary.totalVotes, 6);
    expect(summary.buyCount, 3);
    expect(summary.waitCount, 2);
    expect(summary.skipCount, 1);
    expect(summary.buyPercentage, closeTo(50.0, 0.01));
    expect(summary.isInviteRevoked, isFalse);
  });

  test(
    'dilemma gateway calls get_creator_dilemmas and parses summaries',
    () async {
      final now = DateTime.now().toUtc();
      final gateway = SupabaseCreatorDilemmaGateway(
        client((request) async {
          expect(request.url.path, '/rest/v1/rpc/get_creator_dilemmas');
          return http.Response(
            jsonEncode([
              {
                'dilemma_id': id,
                'item_name': 'Monitor 4K',
                'price_cents': 350000,
                'currency': 'BRL',
                'category': 'other',
                'purpose': 'for_self',
                'reason': 'Trabalho',
                'pause_due_at': now.toIso8601String(),
                'state': 'collecting_votes',
                'is_invite_revoked': false,
                'created_at': now.toIso8601String(),
                'buy_count': 0,
                'wait_count': 0,
                'skip_count': 0,
                'total_votes': 0,
              },
            ]),
            200,
          );
        }),
      );

      final list = await gateway.fetchDilemmas();
      expect(list, hasLength(1));
      expect(list.single.id, id);
      expect(list.single.itemName, 'Monitor 4K');
    },
  );

  test('dilemma gateway rejects malformed or non-list response', () async {
    final gateway = SupabaseCreatorDilemmaGateway(
      client((_) async => http.Response('{"error": "bad"}', 200)),
    );
    await expectLater(
      gateway.fetchDilemmas(),
      throwsA(isA<CreatorDilemmaResponseException>()),
    );
  });

  test('dilemma gateway calls revoke_dilemma_invite RPC', () async {
    final gateway = SupabaseCreatorDilemmaGateway(
      client((request) async {
        expect(request.url.path, '/rest/v1/rpc/revoke_dilemma_invite');
        expect(jsonDecode(request.body), {'p_dilemma_id': id});
        return http.Response('null', 200);
      }),
    );
    await gateway.revokeInvite(id);
  });

  test('dilemma gateway calls delete_creator_dilemma RPC', () async {
    final gateway = SupabaseCreatorDilemmaGateway(
      client((request) async {
        expect(request.url.path, '/rest/v1/rpc/delete_creator_dilemma');
        expect(jsonDecode(request.body), {'p_dilemma_id': id});
        return http.Response('null', 200);
      }),
    );
    await gateway.deleteDilemma(id);
  });

  test(
    'memory creator dilemma gateway supports list, revoke, and delete',
    () async {
      final initial = CreatorDilemmaSummary(
        id: id,
        itemName: 'Livro',
        priceCents: 5000,
        currency: 'BRL',
        category: ItemCategory.other,
        purpose: DraftPurpose.forSelf,
        reason: 'Estudo',
        pauseDueAt: DateTime.now(),
        state: 'collecting_votes',
        isInviteRevoked: false,
        createdAt: DateTime.now(),
        buyCount: 1,
        waitCount: 0,
        skipCount: 0,
        totalVotes: 1,
      );
      final memoryGateway = MemoryCreatorDilemmaGateway(initial: [initial]);

      expect(
        (await memoryGateway.fetchDilemmas()).single.isInviteRevoked,
        isFalse,
      );

      await memoryGateway.revokeInvite(id);
      expect(
        (await memoryGateway.fetchDilemmas()).single.isInviteRevoked,
        isTrue,
      );

      await memoryGateway.deleteDilemma(id);
      expect(await memoryGateway.fetchDilemmas(), isEmpty);
    },
  );
}
