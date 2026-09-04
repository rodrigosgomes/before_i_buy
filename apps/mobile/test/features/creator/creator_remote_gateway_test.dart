import 'package:before_i_buy_mobile/features/creator/creator_remote_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('builds an HTTPS invite link without altering the configured path', () {
    final link = GuestInviteLinkBuilder(
      Uri.parse('https://guest.example.com/before-i-buy'),
    ).build(token);

    expect(link.scheme, 'https');
    expect(link.host, 'guest.example.com');
    expect(link.pathSegments, ['before-i-buy', 'invite', token]);
  });

  test('fails closed for a missing base URL or malformed token', () {
    expect(
      () => const GuestInviteLinkBuilder(null).build(token),
      throwsA(isA<InviteLinkConfigurationException>()),
    );
    expect(
      () => GuestInviteLinkBuilder(
        Uri.parse('https://guest.example.com'),
      ).build('not-a-token'),
      throwsA(isA<InviteLinkConfigurationException>()),
    );
  });

  test(
    'memory share gateway keeps the invite only at the share boundary',
    () async {
      final share = MemoryInviteShareGateway();
      final link = GuestInviteLinkBuilder(
        Uri.parse('https://guest.example.com'),
      ).build(token);

      await share.share(link);

      expect(share.shared, [link]);
    },
  );
}
