import 'dart:convert';

import 'package:before_i_buy_mobile/features/analytics/creator_analytics.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingTransport implements CreatorAnalyticsTransport {
  final sent = <CreatorAnalyticsEntry>[];
  Object? error;

  @override
  Future<void> send(CreatorAnalyticsEntry entry) async {
    if (error != null) throw error!;
    sent.add(entry);
  }
}

CreatorAnalyticsEntry _entry({
  String eventId = '00000000-0000-4000-8000-000000000701',
  CreatorAnalyticsEvent event = CreatorAnalyticsEvent.dilemmaDraftSaved,
}) => CreatorAnalyticsEntry(
  event: event,
  clientEventId: eventId,
  occurredAt: DateTime.utc(2026, 9, 5, 12),
  draftId: '00000000-0000-4000-8000-000000000702',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('serialized event contains only the closed client contract', () {
    final encoded = jsonEncode(_entry().toJson());

    expect(encoded, contains('dilemma_draft_saved'));
    expect(encoded, isNot(contains('itemName')));
    expect(encoded, isNot(contains('reason')));
    expect(encoded, isNot(contains('price')));
    expect(encoded, isNot(contains('token')));
    expect(encoded, isNot(contains('url')));
    expect(encoded, isNot(contains('email')));
  });

  test('queue is isolated by authenticated user', () async {
    final first = SecureCreatorAnalyticsQueue(userId: 'owner-a');
    final second = SecureCreatorAnalyticsQueue(userId: 'owner-b');

    await first.save([_entry()]);

    expect(await first.load(), hasLength(1));
    expect(await second.load(), isEmpty);
  });

  test('offline failure preserves the event for a later retry', () async {
    final queue = SecureCreatorAnalyticsQueue(userId: 'owner-a');
    final transport = _RecordingTransport()..error = StateError('offline');
    final analytics = QueuedCreatorAnalytics(
      queue: queue,
      transport: transport,
    );

    await analytics.track(_entry());
    expect(await queue.load(), hasLength(1));

    transport.error = null;
    await analytics.flush();

    expect(transport.sent, hasLength(1));
    expect(await queue.load(), isEmpty);
  });

  test('same event retry is deduplicated while queued', () async {
    final queue = SecureCreatorAnalyticsQueue(userId: 'owner-a');
    final transport = _RecordingTransport()..error = StateError('offline');
    final analytics = QueuedCreatorAnalytics(
      queue: queue,
      transport: transport,
    );

    await analytics.track(_entry());
    await analytics.track(_entry());

    expect(await queue.load(), hasLength(1));
  });

  test('invalid persisted payload is discarded without throwing', () async {
    FlutterSecureStorage.setMockInitialValues({
      '${SecureCreatorAnalyticsQueue.storageKey}.${sha256.convert(utf8.encode('owner-a'))}':
          '[{"event":"not-allowed"}]',
    });
    final queue = SecureCreatorAnalyticsQueue(userId: 'owner-a');

    expect(await queue.load(), isEmpty);
  });

  test(
    'partial send survives restart without blocking later entries',
    () async {
      final queue = SecureCreatorAnalyticsQueue(userId: 'owner-a');
      final firstTransport = _RecordingTransport();
      final partial = _PartialFailureTransport();
      final firstAnalytics = QueuedCreatorAnalytics(
        queue: queue,
        transport: partial,
      );
      await firstAnalytics.track(_entry());
      await firstAnalytics.track(
        _entry(eventId: '00000000-0000-4000-8000-000000000703'),
      );

      final restarted = QueuedCreatorAnalytics(
        queue: SecureCreatorAnalyticsQueue(userId: 'owner-a'),
        transport: firstTransport,
      );
      await restarted.flush();

      expect(firstTransport.sent.map((entry) => entry.clientEventId), [
        '00000000-0000-4000-8000-000000000703',
      ]);
      expect(await queue.load(), isEmpty);
    },
  );
}

class _PartialFailureTransport implements CreatorAnalyticsTransport {
  var calls = 0;

  @override
  Future<void> send(CreatorAnalyticsEntry entry) async {
    calls += 1;
    if (calls > 1) throw StateError('offline');
  }
}
