import 'dart:convert';

import 'package:before_i_buy/features/analytics/creator_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  setUp(() => SharedPreferences.setMockInitialValues({}));

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
    final preferences = SharedPreferences.getInstance();
    final first = SharedPreferencesCreatorAnalyticsQueue(
      userId: 'owner-a',
      preferences: preferences,
    );
    final second = SharedPreferencesCreatorAnalyticsQueue(
      userId: 'owner-b',
      preferences: preferences,
    );

    await first.save([_entry()]);

    expect(await first.load(), hasLength(1));
    expect(await second.load(), isEmpty);
  });

  test('offline failure preserves the event for a later retry', () async {
    final queue = SharedPreferencesCreatorAnalyticsQueue(
      userId: 'owner-a',
      preferences: SharedPreferences.getInstance(),
    );
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
    final queue = SharedPreferencesCreatorAnalyticsQueue(
      userId: 'owner-a',
      preferences: SharedPreferences.getInstance(),
    );
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
    SharedPreferences.setMockInitialValues({
      '${SharedPreferencesCreatorAnalyticsQueue.storageKey}.owner-a':
          '[{"event":"not-allowed"}]',
    });
    final queue = SharedPreferencesCreatorAnalyticsQueue(
      userId: 'owner-a',
      preferences: SharedPreferences.getInstance(),
    );

    expect(await queue.load(), isEmpty);
  });
}
