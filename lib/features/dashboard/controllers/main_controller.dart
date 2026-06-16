import 'package:get/get.dart';
import '../../../core/services/app_logger_service.dart';

class MainController extends GetxController {
  var currentIndex = 0.obs;

  @override
  void onInit() {
    AppLoggerService.debugTrace(
      className: 'MainController',
      method: 'onInit',
      feature: 'Dashboard',
      status: 'INFO',
    );
    super.onInit();
  }

  @override
  void onClose() {
    AppLoggerService.debugTrace(
      className: 'MainController',
      method: 'onClose',
      feature: 'Dashboard',
      status: 'INFO',
    );
    super.onClose();
  }

  void changePage(int index) {
    AppLoggerService.debugTrace(
      className: 'MainController',
      method: 'changePage',
      feature: 'Dashboard',
      status: 'INFO',
      params: {'index': index},
    );
    currentIndex.value = index;
  }
}
