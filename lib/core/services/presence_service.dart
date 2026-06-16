import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_logger_service.dart';
import 'supabase_service.dart';

/// PresenceService — tracks online users and manages real-time presence.
class PresenceService extends GetxService {
  // Map of userId -> presence data
  final onlineUsers = <String, Map<String, dynamic>>{}.obs;
  RealtimeChannel? _presenceChannel;
  StreamSubscription<AuthState>? _authSubscription;
  String? _trackedUserId;
  bool _isSettingUp = false;
  
  // Getters for UI
  int get onlineCount => onlineUsers.length;
  Stream<int> get onlineCountStream => onlineUsers.stream.map((users) => users.length);
  bool isUserOnline(String userId) => onlineUsers.containsKey(userId);

  Future<PresenceService> init() async {
    AppLoggerService.debugTrace(
      className: 'PresenceService',
      method: 'init',
      feature: 'Core',
      status: 'INFO',
    );
    // Single auth listener — avoids duplicate channels from ever() + initial call
    _authSubscription = SupabaseService.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _setupPresence();
      } else {
        _cleanupPresence();
      }
    });

    if (SupabaseService.isLoggedIn) {
      _setupPresence();
      _updateLastSeen();
    }

    return this;
  }

  Future<void> _setupPresence() async {
    if (_isSettingUp) return;

    final client = SupabaseService.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    // Already connected for this user — do not recreate channel
    if (_presenceChannel != null && _trackedUserId == user.id) return;

    _isSettingUp = true;
    _cleanupPresence();
    
    AppLoggerService.debugTrace(
      className: 'PresenceService',
      method: '_setupPresence',
      feature: 'Core',
      status: 'INFO',
      params: {'userId': user.id},
    );

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
        
        AppLoggerService.debugTrace(
          className: 'PresenceService',
          method: 'onPresenceSync',
          feature: 'Core',
          status: 'SUCCESS',
          params: {'onlineUsers': users.length},
        );
        onlineUsers.assignAll(users);
      })
      .onPresenceJoin((payload) {
        AppLoggerService.debugTrace(
          className: 'PresenceService',
          method: 'onPresenceJoin',
          feature: 'Core',
          status: 'INFO',
          params: {'count': payload.newPresences.length},
        );
      })
      .onPresenceLeave((payload) {
        AppLoggerService.debugTrace(
          className: 'PresenceService',
          method: 'onPresenceLeave',
          feature: 'Core',
          status: 'INFO',
          params: {'count': payload.leftPresences.length},
        );
      })
      .subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          AppLoggerService.debugTrace(
            className: 'PresenceService',
            method: 'subscribe',
            feature: 'Core',
            status: 'SUCCESS',
            message: 'Subscribed to presence channel',
          );
          _trackedUserId = user.id;
          await _presenceChannel!.track({
            'user_id': user.id,
            'online_at': DateTime.now().toIso8601String(),
            'user_type': 'admin',
          });
        } else if (error != null) {
          AppLoggerService.debugTrace(
            className: 'PresenceService',
            method: 'subscribe',
            feature: 'Core',
            status: 'FAILED',
            error: error,
          );
        }
        _isSettingUp = false;
      });
  }

  Future<void> _updateLastSeen() async {
    if (!SupabaseService.isLoggedIn) return;
    try {
      await SupabaseService.client.rpc('fn_update_last_seen');
      AppLoggerService.debugTrace(
        className: 'PresenceService',
        method: '_updateLastSeen',
        feature: 'Core',
        status: 'SUCCESS',
      );
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'PresenceService',
        method: '_updateLastSeen',
        feature: 'Core',
        status: 'FAILED',
        error: e,
      );
    }
  }

  void _cleanupPresence() {
    AppLoggerService.debugTrace(
      className: 'PresenceService',
      method: '_cleanupPresence',
      feature: 'Core',
      status: 'INFO',
    );
    _presenceChannel?.unsubscribe();
    _presenceChannel = null;
    _trackedUserId = null;
    _isSettingUp = false;
    onlineUsers.clear();
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'PresenceService',
      method: 'onClose',
      feature: 'Core',
      status: 'INFO',
    );
    _authSubscription?.cancel();
    _cleanupPresence();
    super.onClose();
  }
}
