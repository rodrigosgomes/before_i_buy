import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum CreatorAnalyticsEvent {
  dilemmaCreateStarted('dilemma_create_started'),
  dilemmaDraftSaved('dilemma_draft_saved'),
  offlineDraftRecovered('offline_draft_recovered'),
  offlineDraftPublishReviewed('offline_draft_publish_reviewed'),
  dilemmaShareInvoked('dilemma_share_invoked');

  const CreatorAnalyticsEvent(this.backendName);
  final String backendName;
}

class CreatorAnalyticsEntry {
  const CreatorAnalyticsEntry({
    required this.event,
    required this.clientEventId,
    required this.occurredAt,
    this.draftId,
    this.dilemmaId,
  });

  final CreatorAnalyticsEvent event;
  final String clientEventId;
  final DateTime occurredAt;
  final String? draftId;
  final String? dilemmaId;

  Map<String, Object?> toJson() => {
    'event': event.backendName,
    'clientEventId': clientEventId,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'draftId': draftId,
    'dilemmaId': dilemmaId,
  };

  factory CreatorAnalyticsEntry.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Invalid analytics entry.');
    final values = Map<String, dynamic>.from(json);
    final eventName = values['event'];
    final event = CreatorAnalyticsEvent.values
        .where((candidate) => candidate.backendName == eventName)
        .firstOrNull;
    final clientEventId = values['clientEventId'];
    final occurredAt = DateTime.tryParse(values['occurredAt'] as String? ?? '');
    if (event == null || clientEventId is! String || occurredAt == null) {
      throw const FormatException('Invalid analytics entry.');
    }
    return CreatorAnalyticsEntry(
      event: event,
      clientEventId: clientEventId,
      occurredAt: occurredAt,
      draftId: values['draftId'] as String?,
      dilemmaId: values['dilemmaId'] as String?,
    );
  }
}

abstract interface class CreatorAnalyticsTransport {
  Future<void> send(CreatorAnalyticsEntry entry);
}

abstract interface class CreatorAnalyticsQueue {
  Future<List<CreatorAnalyticsEntry>> load();
  Future<void> save(List<CreatorAnalyticsEntry> entries);
}

abstract interface class CreatorAnalytics {
  Future<void> track(CreatorAnalyticsEntry entry);
  Future<void> flush();
}

typedef CreatorAnalyticsFactory = CreatorAnalytics Function(String userId);

class SecureCreatorAnalyticsQueue implements CreatorAnalyticsQueue {
  SecureCreatorAnalyticsQueue({
    required this.userId,
    FlutterSecureStorage? storage,
    DateTime Function()? now,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _now = now ?? DateTime.now;

  static const storageKey = 'bib.creator_analytics.v1';
  static const retention = Duration(days: 7);
  static const maxEntries = 200;
  final String userId;
  final FlutterSecureStorage _storage;
  final DateTime Function() _now;
  String get _scopedKey => '$storageKey.${sha256.convert(utf8.encode(userId))}';

  @override
  Future<List<CreatorAnalyticsEntry>> load() async {
    final raw = await _storage.read(key: _scopedKey);
    if (raw == null) return const [];
    try {
      final values = jsonDecode(raw);
      if (values is! List) return const [];
      final cutoff = _now().toUtc().subtract(retention);
      final entries = values
          .map(CreatorAnalyticsEntry.fromJson)
          .where((entry) => entry.occurredAt.toUtc().isAfter(cutoff))
          .take(maxEntries)
          .toList(growable: false);
      if (entries.length != values.length) await save(entries);
      return entries;
    } on FormatException {
      await _storage.delete(key: _scopedKey);
      return const [];
    }
  }

  @override
  Future<void> save(List<CreatorAnalyticsEntry> entries) async {
    if (entries.isEmpty) {
      await _storage.delete(key: _scopedKey);
      return;
    }
    await _storage.write(
      key: _scopedKey,
      value: jsonEncode(
        entries.take(maxEntries).map((entry) => entry.toJson()).toList(),
      ),
    );
  }
}

class SupabaseCreatorAnalyticsTransport implements CreatorAnalyticsTransport {
  SupabaseCreatorAnalyticsTransport(this._client);
  final SupabaseClient _client;

  @override
  Future<void> send(CreatorAnalyticsEntry entry) async {
    await _client.rpc(
      'record_creator_analytics_event',
      params: {
        'p_event_name': entry.event.backendName,
        'p_client_event_id': entry.clientEventId,
        'p_draft_id': entry.draftId,
        'p_dilemma_id': entry.dilemmaId,
        'p_occurred_at': entry.occurredAt.toUtc().toIso8601String(),
      },
    );
  }
}

class QueuedCreatorAnalytics implements CreatorAnalytics {
  QueuedCreatorAnalytics({required this.queue, required this.transport});

  final CreatorAnalyticsQueue queue;
  final CreatorAnalyticsTransport transport;
  Future<void> _writes = Future.value();

  @override
  Future<void> track(CreatorAnalyticsEntry entry) {
    _writes = _writes.then((_) async {
      try {
        final entries = await queue.load();
        if (!entries.any(
          (candidate) =>
              candidate.event == entry.event &&
              candidate.clientEventId == entry.clientEventId,
        )) {
          await queue.save([...entries, entry]);
        }
        await _flushNow();
      } catch (_) {
        // Product behavior must remain independent from internal analytics.
      }
    });
    return _writes;
  }

  @override
  Future<void> flush() {
    _writes = _writes.then((_) async {
      try {
        await _flushNow();
      } catch (_) {
        // The persisted queue will retry on the next authenticated session.
      }
    });
    return _writes;
  }

  Future<void> _flushNow() async {
    final entries = await queue.load();
    var sent = 0;
    for (final entry in entries) {
      try {
        await transport.send(entry);
        sent += 1;
      } catch (_) {
        break;
      }
    }
    if (sent > 0) await queue.save(entries.skip(sent).toList());
  }
}

class NoopCreatorAnalytics implements CreatorAnalytics {
  const NoopCreatorAnalytics();
  @override
  Future<void> flush() async {}
  @override
  Future<void> track(CreatorAnalyticsEntry entry) async {}
}

class MemoryCreatorAnalytics implements CreatorAnalytics {
  final entries = <CreatorAnalyticsEntry>[];
  Object? error;

  @override
  Future<void> flush() async {
    if (error != null) throw error!;
  }

  @override
  Future<void> track(CreatorAnalyticsEntry entry) async {
    if (error != null) throw error!;
    entries.add(entry);
  }
}
