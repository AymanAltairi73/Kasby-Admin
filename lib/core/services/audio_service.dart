import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'app_logger_service.dart';

class AudioService extends GetxService {
  late AudioPlayer _player;

  @override
  void onInit() {
    super.onInit();
    _player = AudioPlayer();
  }

  Future<void> playMessageSent() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/message_sent.mp3'));
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AudioService',
        method: 'playMessageSent',
        error: e,
        stackTrace: stackTrace,
      );
      Get.log('Error playing sound: $e');
    }
  }

  Future<void> playNotification() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/notification.mp3'));
    } catch (e, stackTrace) {
      AppLoggerService.logError(
        controller: 'AudioService',
        method: 'playNotification',
        error: e,
        stackTrace: stackTrace,
      );
      Get.log('Error playing sound: $e');
    }
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
