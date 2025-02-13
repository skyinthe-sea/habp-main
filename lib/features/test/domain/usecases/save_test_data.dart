import '../repositories/test_repository.dart';

class SaveTestDataUseCase {
  final TestRepository repository;

  SaveTestDataUseCase(this.repository);

  Future<void> execute(String data) async {
    await repository.saveTestData(data);
  }
}