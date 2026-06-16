import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'app_logger_service.dart';

class AudioService extends GetxService {
  late AudioPlayer _player;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'AudioService',
      method: 'onInit',
      feature: 'Core',
      status: 'INFO',
    );
    super.onInit();
    _player = AudioPlayer();
  }

  Future<void> playMessageSent() async {
    AppLoggerService.debugTrace(
      className: 'AudioService',
      method: 'playMessageSent',
      feature: 'Core',
      status: 'INFO',
    );
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/message_sent.mp3'));
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AudioService',
        method: 'playMessageSent',
        feature: 'Core',
        status: 'FAILED',
        error: e,
      );
    }
  }

  Future<void> playNotification() async {
    AppLoggerService.debugTrace(
      className: 'AudioService',
      method: 'playNotification',
      feature: 'Core',
      status: 'INFO',
    );
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      AppLoggerService.debugTrace(
        className: 'AudioService',
        method: 'playNotification',
        feature: 'Core',
        status: 'FAILED',
        error: e,
      );
    }
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'AudioService',
      method: 'onClose',
      feature: 'Core',
      status: 'INFO',
    );
    _player.dispose();
    super.onClose();
  }
}
