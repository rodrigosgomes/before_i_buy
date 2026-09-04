import 'package:share_plus/share_plus.dart';

import 'creator_remote_gateway.dart';

class SharePlusInviteShareGateway implements InviteShareGateway {
  @override
  Future<void> share(Uri inviteUri) =>
      SharePlus.instance.share(ShareParams(uri: inviteUri));
}
