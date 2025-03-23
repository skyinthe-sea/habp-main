// lib/features/onboarding/data/repositories/financial_account_repository.dart

import '../../../../../core/database/db_helper.dart';
import '../models/financial_account.dart';

class FinancialAccountRepository {
  final DBHelper _dbHelper = DBHelper();

  // 금융 계좌 추가
  Future<int> createFinancialAccount(FinancialAccount account) async {
    final db = await _dbHelper.database;
    return await db.insert('financial_account', account.toMap());
  }

  // 금융 계좌 조회
  Future<FinancialAccount?> getFinancialAccount(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'financial_account',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return FinancialAccount.fromMap(maps.first);
  }

  // 모든 금융 계좌 조회
  Future<List<FinancialAccount>> getAllFinancialAccounts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('financial_account');
    return List.generate(maps.length, (i) => FinancialAccount.fromMap(maps[i]));
  }

  // 사용자별 금융 계좌 조회
  Future<List<FinancialAccount>> getFinancialAccountsByUser(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'financial_account',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => FinancialAccount.fromMap(maps[i]));
  }

  // 계좌 유형별 조회
  Future<List<FinancialAccount>> getFinancialAccountsByType(AccountType type) async {
    final db = await _dbHelper.database;
    final typeStr = type.toString().split('.').last;

    final List<Map<String, dynamic>> maps = await db.query(
      'financial_account',
      where: 'type = ?',
      whereArgs: [typeStr],
    );

    return List.generate(maps.length, (i) => FinancialAccount.fromMap(maps[i]));
  }

  // 은행 계좌 조회
  Future<List<FinancialAccount>> getBankAccounts() async {
    return getFinancialAccountsByType(AccountType.BANK);
  }

  // 투자 계좌 조회
  Future<List<FinancialAccount>> getInvestmentAccounts() async {
    return getFinancialAccountsByType(AccountType.INVESTMENT);
  }

  // 주식 계좌 조회
  Future<List<FinancialAccount>> getStockAccounts() async {
    return getFinancialAccountsByType(AccountType.STOCK);
  }

  // 대출 계좌 조회
  Future<List<FinancialAccount>> getLoanAccounts() async {
    return getFinancialAccountsByType(AccountType.LOAN);
  }

  // 금융 계좌 업데이트
  Future<int> updateFinancialAccount(FinancialAccount account) async {
    final db = await _dbHelper.database;
    return await db.update(
      'financial_account',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  // 금융 계좌 잔액 업데이트
  Future<int> updateAccountBalance(int id, double newBalance) async {
    final account = await getFinancialAccount(id);
    if (account == null) return 0;

    final updatedAccount = account.copyWith(
      balance: newBalance,
      updatedAt: DateTime.now(),
    );

    return updateFinancialAccount(updatedAccount);
  }

  // 금융 계좌 삭제
  Future<int> deleteFinancialAccount(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'financial_account',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 총 잔액 계산 (계좌 유형별)
  Future<double> getTotalBalanceByType(AccountType type) async {
    final accounts = await getFinancialAccountsByType(type);
    return accounts.fold<double>(0.0, (total, account) => total + account.balance);
  }

  // 총 자산 계산 (모든 계좌)
  Future<double> getTotalAssets() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(balance) as total
      FROM financial_account
      WHERE type != ?
    ''', [AccountType.LOAN.toString().split('.').last]);

    if (result.isEmpty || result.first['total'] == null) {
      return 0.0;
    }
    return result.first['total'] as double;
  }

  // 총 부채 계산 (대출 계좌)
  Future<double> getTotalLiabilities() async {
    return getTotalBalanceByType(AccountType.LOAN);
  }
}