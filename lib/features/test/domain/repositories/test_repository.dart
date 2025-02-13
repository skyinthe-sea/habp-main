abstract class TestRepository {
  Future<void> saveTestData(String data);
  Future<String?> getLatestTestData();
}