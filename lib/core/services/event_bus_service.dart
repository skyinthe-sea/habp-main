import 'package:get/get.dart';

class EventBusService extends GetxService {
  // 거래 추가/수정/삭제 이벤트
  final RxBool transactionChanged = false.obs;

  // 이벤트 발생 메서드
  void emitTransactionChanged() {
    transactionChanged.value = !transactionChanged.value; // 값을 토글하여 이벤트 발생
  }

  // 서비스 초기화
  Future<EventBusService> init() async {
    return this;
  }
}