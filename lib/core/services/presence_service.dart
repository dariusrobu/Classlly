import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages real-time presence and collaboration status using Supabase.
class PresenceService {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _channel;
  
  final _presenceController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get presenceStream => _presenceController.stream;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Joins a collaboration room for a specific note.
  void joinNote(String noteId, String userName) {
    leave(); // Ensure clean state

    _channel = _client.channel('note:$noteId', opts: const RealtimeChannelConfig(self: true));
    
    _channel!.onPresenceSync((_) {
      final states = _channel!.presenceState();
      
      // Flatten the presences
      final users = <Map<String, dynamic>>[];
      for (final state in states) {
        if (state.presences.isNotEmpty) {
          final payload = Map<String, dynamic>.from(state.presences.first.payload);
          // Only add others to the list for remote indicators
          if (payload['user_id'] != currentUserId) {
            users.add({
              'user_id': payload['user_id'],
              'name': payload['name'] ?? 'Other Student',
              'cursor_x': payload['cursor_x'],
              'cursor_y': payload['cursor_y'],
              'is_typing': payload['is_typing'] ?? false,
              'updated_at': payload['updated_at'],
            });
          }
        }
      }
      
      _presenceController.add(users);
    }).subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _channel!.track({
          'user_id': currentUserId,
          'name': userName,
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Updates the local user's metadata (e.g., cursor position).
  /// Should be throttled at the caller level.
  Future<void> updateLocalPresence({
    String? name,
    Offset? cursor,
    bool? isTyping,
  }) async {
    if (_channel == null) return;

    final payload = {
      'user_id': currentUserId,
      if (name != null) 'name': name,
      if (cursor != null) 'cursor_x': cursor.dx,
      if (cursor != null) 'cursor_y': cursor.dy,
      if (isTyping != null) 'is_typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _channel!.track(payload);
  }

  /// Leaves the current collaboration room.
  void leave() {
    _channel?.unsubscribe();
    _channel = null;
  }

  void dispose() {
    leave();
    _presenceController.close();
  }
}
