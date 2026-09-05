import 'dart:io';

import 'package:before_i_buy_mobile/features/creator/creator_remote_gateway.dart';
import 'package:before_i_buy_mobile/features/creator/draft.dart';
import 'package:before_i_buy_mobile/features/creator/draft_repository.dart';
import 'package:before_i_buy_mobile/features/onboarding/onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

void main() {
  // Construct real HTTP transports before installing the widget test binding.
  final adminTransport = IOClient(HttpClient());
  final creatorTransport = IOClient(HttpClient());
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test(
    'local creator profile, persisted retry, invite and guest vote use real RPCs',
    () async {
      const url = 'http://127.0.0.1:56321';
      final anonKey = Platform.environment['LOCAL_SUPABASE_ANON_KEY'];
      final serviceKey =
          Platform.environment['LOCAL_SUPABASE_SERVICE_ROLE_KEY'];
      if (anonKey == null || serviceKey == null) {
        fail(
          'Run node scripts/ci/test-mobile-supabase.mjs from the repository root.',
        );
      }
      final admin = SupabaseClient(url, serviceKey, httpClient: adminTransport);
      final creator = SupabaseClient(
        url,
        anonKey,
        httpClient: creatorTransport,
      );
      final runId = const Uuid().v4();
      final email = 'creator-$runId@example.test';
      final password = '${const Uuid().v4()}-Local!';
      String? userId;
      try {
        final user = await admin.auth.admin.createUser(
          AdminUserAttributes(
            email: email,
            password: password,
            emailConfirm: true,
          ),
        );
        userId = user.user!.id;
        await creator.auth.signInWithPassword(email: email, password: password);
        final profiles = SupabaseCreatorProfileGateway(creator);
        expect(await profiles.status(), CreatorProfileStatus.needsSync);
        await profiles.sync(
          const LocalOnboarding(
            displayName: 'Creator Local',
            adultConfirmed: true,
            termsAccepted: true,
            privacyAccepted: true,
          ),
        );
        expect(await profiles.status(), CreatorProfileStatus.ready);

        final repository = SharedPreferencesDraftRepository(userId: userId);
        final draft = DraftDilemma(
          idempotencyKey: runId,
          itemName: 'Fone de teste',
          priceCents: 10000,
          reason: 'Para validar o fluxo local.',
          publicationPending: true,
        );
        await repository.save(draft);
        final publication = SupabaseDilemmaPublicationGateway(creator);
        final first = await publication.publish(draft);
        // Simulate losing the response: recreate storage/gateway and replay only
        // the persisted snapshot, without persisting the returned invite secret.
        final restored = await SharedPreferencesDraftRepository(
          userId: userId,
        ).load();
        final retry = await SupabaseDilemmaPublicationGateway(
          creator,
        ).publish(restored!);
        expect(retry.dilemmaId == first.dilemmaId, isTrue);
        expect(retry.inviteToken == first.inviteToken, isTrue);
        final rows = await creator.from('dilemmas').select('id');
        expect(rows.length, 1);
        final link = GuestInviteLinkBuilder(
          Uri.parse('https://guest.example.test'),
        ).build(retry.inviteToken);
        expect(link.pathSegments.first, 'invite');
        final secret = '${const Uuid().v4()}${const Uuid().v4()}'
            .replaceAll('-', '')
            .substring(0, 43);
        final rateKey = '${const Uuid().v4()}${const Uuid().v4()}'.replaceAll(
          '-',
          '',
        );
        final opened = await admin.rpc(
          'open_guest_invite_session',
          params: {
            'p_invite_token_plain': retry.inviteToken,
            'p_session_secret_plain': secret,
            'p_rate_limit_key_hash': rateKey,
          },
        );
        expect((opened as List).single['owner_display_name'], 'Creator Local');
        expect(opened.single.containsKey('total_votes'), isFalse);
        final voted = await admin.rpc(
          'submit_guest_vote',
          params: {
            'p_dilemma_id': retry.dilemmaId,
            'p_session_secret_plain': secret,
            'p_prediction': 'wait',
            'p_rate_limit_key_hash': rateKey,
          },
        );
        expect((voted as List).single['total_votes'], 1);
        await repository.clear();
        expect(await repository.load(), isNull);

        // Exercise SupabaseCreatorDilemmaGateway against real RPCs
        final dilemmaGateway = SupabaseCreatorDilemmaGateway(creator);
        final dilemmas = await dilemmaGateway.fetchDilemmas();
        expect(dilemmas, hasLength(1));
        final created = dilemmas.single;
        expect(created.id, retry.dilemmaId);
        expect(created.itemName, 'Fone de teste');
        expect(created.waitCount, 1);
        expect(created.totalVotes, 1);
        expect(created.isInviteRevoked, isFalse);

        // Revoke invite
        await dilemmaGateway.revokeInvite(retry.dilemmaId);
        final afterRevoke = await dilemmaGateway.fetchDilemmas();
        expect(afterRevoke.single.isInviteRevoked, isTrue);

        // Hard delete dilemma (LGPD)
        await dilemmaGateway.deleteDilemma(retry.dilemmaId);
        final afterDelete = await dilemmaGateway.fetchDilemmas();
        expect(afterDelete, isEmpty);
      } finally {
        if (userId != null) await admin.auth.admin.deleteUser(userId);
        await creator.dispose();
        await admin.dispose();
        adminTransport.close();
        creatorTransport.close();
      }
    },
    skip: Platform.environment['LOCAL_SUPABASE_ANON_KEY'] == null
        ? 'Executed separately by the required local Supabase integration gate.'
        : false,
  );
}
