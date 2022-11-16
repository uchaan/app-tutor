import 'package:get/get_state_manager/get_state_manager.dart';

class Controller extends GetxController {
  int currentIndex = 0;

  void onTabTapped(int index) {
    currentIndex = index;
    update();
  }
}
