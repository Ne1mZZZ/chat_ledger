import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

/// 本地存储层：数据只存在手机里，不联网、不上传、不需要任何权限申请。
/// sqflite 用的是系统自带 SQLite，库本身只有几百 KB。
class ExpenseDb {
  ExpenseDb._();
  static final ExpenseDb instance = ExpenseDb._();

  Database? _db;

  Future<Database> get database async {
    final Database? existing = _db;
    if (existing != null) return existing;
    final String dir = await getDatabasesPath();
    final String path = p.join(dir, 'chat_ledger.db');
    final Database db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            amount   REAL    NOT NULL,
            category TEXT    NOT NULL,
            note     TEXT    NOT NULL DEFAULT '',
            raw_text TEXT    NOT NULL DEFAULT '',
            date     INTEGER NOT NULL
          )
        ''');
        // 按日期建索引：账单按月查、统计按 6 个月查都走它，数据多了也快
        await db.execute(
            'CREATE INDEX idx_expenses_date ON expenses (date)');
      },
    );
    _db = db;
    return db;
  }

  Future<int> insert(Expense e) async {
    final Database db = await database;
    return db.insert('expenses', e.toMap());
  }

  Future<void> update(Expense e) async {
    if (e.id == null) return;
    final Database db = await database;
    await db.update(
      'expenses',
      e.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[e.id],
    );
  }

  Future<void> delete(int id) async {
    final Database db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// 查某个时间区间 [from, to) 的流水，按时间倒序
  Future<List<Expense>> queryRange(DateTime from, DateTime to) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'expenses',
      where: 'date >= ? AND date < ?',
      whereArgs: <Object?>[
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  /// 对话页只显示最近 30 条，避免记录多了以后列表越来越长、越滑越卡
  Future<List<Expense>> queryRecent({int limit = 30}) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'expenses',
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(Expense.fromMap).toList();
  }
}
