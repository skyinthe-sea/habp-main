import 'package:get/get.dart';

class EventBusService extends GetxService {
  // 거래 추가/수정/삭제 이벤트
  final RxBool transactionChanged = false.obs;

  // 고정 소득 변경 이벤트 추가
  final RxBool fixedIncomeChanged = false.obs;

  // 이벤트 발생 메서드
  void emitTransactionChanged() {
    transactionChanged.value = !transactionChanged.value; // 값을 토글하여 이벤트 발생
  }

  // 고정 소득 변경 이벤트 발생 메서드
  void emitFixedIncomeChanged() {
    fixedIncomeChanged.value = !fixedIncomeChanged.value; // 값을 토글하여 이벤트 발생
    // 고정 소득 변경은 거래 데이터에도 영향을 주므로 거래 변경 이벤트도 함께 발생시킵니다
    emitTransactionChanged();
  }

  // 서비스 초기화
  Future<EventBusService> init() async {
    return this;
  }
}