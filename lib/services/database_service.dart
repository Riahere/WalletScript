import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/note_model.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'walletscript.db');
    return openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT, amount REAL, type TEXT,
        category TEXT, currency TEXT,
        accountId TEXT, date TEXT, note TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT, emoji TEXT, targetAmount REAL,
        currentAmount REAL, currency TEXT, color TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT, content TEXT, createdAt TEXT,
        updatedAt TEXT, reminderDate TEXT,
        hasReminder INTEGER DEFAULT 0,
        isPinned INTEGER DEFAULT 0,
        color TEXT DEFAULT "#FFFFFF"
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE notes ADD COLUMN reminderDate TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE notes ADD COLUMN hasReminder INTEGER DEFAULT 0'); } catch (_) {}
    }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE notes ADD COLUMN updatedAt TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE notes ADD COLUMN isPinned INTEGER DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE notes ADD COLUMN color TEXT DEFAULT "#FFFFFF"'); } catch (_) {}
    }
  }

  // -- Transactions --
  Future<int> insertTransaction(AppTransaction t) async {
    final db = await database;
    return db.insert('transactions', t.toMap());
  }

  Future<List<AppTransaction>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => AppTransaction.fromMap(m)).toList();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // -- Budgets --
  Future<int> insertBudget(AppBudget b) async {
    final db = await database;
    return db.insert('budgets', b.toMap());
  }

  Future<List<AppBudget>> getBudgets() async {
    final db = await database;
    final maps = await db.query('budgets');
    return maps.map((m) => AppBudget.fromMap(m)).toList();
  }

  Future<void> updateBudgetAmount(int id, double amount) async {
    final db = await database;
    await db.update('budgets', {'currentAmount': amount},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteBudget(int id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // -- Notes --
  Future<int> insertNote(AppNote n) async {
    final db = await database;
    return db.insert('notes', n.toMap());
  }

  Future<List<AppNote>> getNotes() async {
    final db = await database;
    final maps = await db.query('notes', orderBy: 'isPinned DESC, createdAt DESC');
    return maps.map((m) => AppNote.fromMap(m)).toList();
  }

  Future<void> updateNote(AppNote n) async {
    final db = await database;
    await db.update('notes', n.toMap(), where: 'id = ?', whereArgs: [n.id]);
  }

  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
