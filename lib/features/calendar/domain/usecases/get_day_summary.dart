import '../entities/day_summary.dart';
import '../repositories/calendar_repository.dart';

class GetDaySummary {
  final CalendarRepository repository;

  GetDaySummary(this.repository);

  Future<DaySummary> execute(DateTime date) async {
    return await repository.getDaySummary(date);
  }
}