import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../../features/auth/controllers/auth_controller.dart';

/// PresenceService — tracks online users and manages real-time presence.
class PresenceService extends GetxService {
  // Map of userId -> presence data
  final onlineUsers = <String, Map<String, dynamic>>{}.obs;
  RealtimeChannel? _presenceChannel;
  
  // Getters for UI
  int get onlineCount => onlineUsers.length;
  Stream<int> get onlineCountStream => onlineUsers.stream.map((users) => users.length);
  bool isUserOnline(String userId) => onlineUsers.containsKey(userId);

  Future<PresenceService> init() async {
    final authController = Get.find<AuthController>();

    // Listen to login status to start/stop presence
    ever(authController.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        _setupPresence();
      } else {
        _cleanupPresence();
      }
    });

    if (authController.isLoggedIn.value) {
      _setupPresence();
    }

    return this;
  }

  void _setupPresence() {
    _cleanupPresence();
    
    final client = SupabaseService.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    debugPrint('[PresenceService] ▶ Setting up presence channel for user: ${user.id}');

    _presenceChannel = client.channel('global-presence', opts: const RealtimeChannelConfig(self: true));

    _presenceChannel!
      .onPresenceSync((payload) {
        final newState = _presenceChannel!.presenceState();
        final users = <String, Map<String, dynamic>>{};
        
        for (final state in newState) {
          final presenceList = state.presences;
          if (presenceList.isNotEmpty) {
            final payloadData = presenceList.first.payload;
            final userId = payloadData['user_id']?.toString();
            if (userId != null) {
              users[userId] = payloadData;
            }
          }
        }
        
        debugPrint('[PresenceService] √ Presence synced. Online users: ${users.length}');
        onlineUsers.assignAll(users);
      })
      .onPresenceJoin((payload) {
        debugPrint('[PresenceService] ℹ User joined: ${payload.newPresences}');
      })
      .onPresenceLeave((payload) {
        debugPrint('[PresenceService] ℹ User left: ${payload.leftPresences}');
      })
      .subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('[PresenceService] √ Subscribed to presence channel.');
          await _presenceChannel!.track({
            'user_id': user.id,
            'online_at': DateTime.now().toIso8601String(),
            'user_type': 'admin',
          });
        } else if (error != null) {
          debugPrint('[PresenceService] ✗ Presence subscription error: $error');
        }
      });
  }

  void _cleanupPresence() {
    _presenceChannel?.unsubscribe();
    _presenceChannel = null;
    onlineUsers.clear();
  }

  @override
  void onClose() {
    _cleanupPresence();
    super.onClose();
  }
}
