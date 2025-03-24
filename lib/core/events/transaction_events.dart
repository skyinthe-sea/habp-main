// lib/core/events/transaction_events.dart
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class TransactionEvent {
  static final RxInt count = 0.obs;

  // 이벤트 발생 메서드
  static void emit() {
    // 단순히 값을 증가시켜 이벤트 발생
    count.value++;
  }
}