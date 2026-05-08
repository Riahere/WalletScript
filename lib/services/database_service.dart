import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/note_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('walletscript.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path,
        version: 3, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      grp TEXT NOT NULL DEFAULT 'Others',
      type TEXT NOT NULL,
      balance REAL NOT NULL,
      currency TEXT NOT NULL,
      icon TEXT NOT NULL,
      color TEXT NOT NULL)''');

    await db.execute('''CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category TEXT NOT NULL,
      currency TEXT NOT NULL, accountId TEXT NOT NULL,
      toAccountId TEXT, date TEXT NOT NULL,
      note TEXT, attachmentPath TEXT)''');

    await db.execute('''CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL, emoji TEXT NOT NULL,
      targetAmount REAL NOT NULL, currentAmount REAL NOT NULL,
      currency TEXT NOT NULL, deadline TEXT, color TEXT NOT NULL)''');

    await db.execute('''CREATE TABLE notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL, content TEXT NOT NULL,
      createdAt TEXT NOT NULL, updatedAt TEXT,
      color TEXT NOT NULL DEFAULT '#FFFFFF',
      isPinned INTEGER NOT NULL DEFAULT 0,
      hasReminder INTEGER NOT NULL DEFAULT 0,
      reminderDate TEXT)''');

    await db.insert('accounts', {
      'name': 'Cash',
      'grp': 'Cash',
      'type': 'cash',
      'balance': 0.0,
      'currency': 'IDR',
      'icon': 'wallet',
      'color': '0xFF10B981'
    });
    await db.insert('accounts', {
      'name': 'Bank BCA',
      'grp': 'Debit Card',
      'type': 'bank',
      'balance': 0.0,
      'currency': 'IDR',
      'icon': 'bank',
      'color': '0xFF6C63FF'
    });
    await db.insert('accounts', {
      'name': 'Tabungan',
      'grp': 'Savings',
      'type': 'savings',
      'balance': 0.0,
      'currency': 'IDR',
      'icon': 'savings',
      'color': '0xFF10B981'
    });
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE notes ADD COLUMN hasReminder INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE notes ADD COLUMN reminderDate TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE accounts ADD COLUMN grp TEXT NOT NULL DEFAULT 'Others'");
    }
  }

  // ─── Accounts ───────────────────────────────────────────────

  Future<List<AppAccount>> getAccounts() async {
    final db = await database;
    final maps = await db.query('accounts');
    return maps.map((e) => AppAccount.fromMap(e)).toList();
  }

  Future<AppAccount> insertAccount(AppAccount account) async {
    final db = await database;
    final id = await db.insert('accounts', account.toMap());
    return account.copyWith(id: id);
  }

  Future updateAccount(AppAccount account) async {
    final db = await database;
    await db.update('accounts', account.toMap(),
        where: 'id = ?', whereArgs: [account.id]);
  }

  Future updateAccountBalance(int id, double newBalance) async {
    final db = await database;
    await db.update('accounts', {'balance': newBalance},
        where: 'id = ?', whereArgs: [id]);
  }

  Future deleteAccount(int id) async {
    final db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Transactions ────────────────────────────────────────────

  Future<List<AppTransaction>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((e) => AppTransaction.fromMap(e)).toList();
  }

  Future<AppTransaction> insertTransaction(AppTransaction tx) async {
    final db = await database;
    final id = await db.insert('transactions', tx.toMap());
    return AppTransaction(
        id: id,
        title: tx.title,
        amount: tx.amount,
        type: tx.type,
        category: tx.category,
        currency: tx.currency,
        accountId: tx.accountId,
        toAccountId: tx.toAccountId,
        date: tx.date,
        note: tx.note,
        attachmentPath: tx.attachmentPath);
  }

  Future deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Budgets ─────────────────────────────────────────────────

  Future<List<AppBudget>> getBudgets() async {
    final db = await database;
    final maps = await db.query('budgets');
    return maps.map((e) => AppBudget.fromMap(e)).toList();
  }

  Future<AppBudget> insertBudget(AppBudget budget) async {
    final db = await database;
    final id = await db.insert('budgets', budget.toMap());
    return AppBudget(
        id: id,
        title: budget.title,
        emoji: budget.emoji,
        targetAmount: budget.targetAmount,
        currentAmount: budget.currentAmount,
        currency: budget.currency,
        deadline: budget.deadline,
        color: budget.color);
  }

  Future updateBudgetAmount(int id, double newAmount) async {
    final db = await database;
    await db.update('budgets', {'currentAmount': newAmount},
        where: 'id = ?', whereArgs: [id]);
  }

  Future deleteBudget(int id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Notes ───────────────────────────────────────────────────

  Future<List<AppNote>> getNotes() async {
    final db = await database;
    final maps =
        await db.query('notes', orderBy: 'isPinned DESC, updatedAt DESC');
    return maps.map((e) => AppNote.fromMap(e)).toList();
  }

  Future<int> insertNote(AppNote note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future updateNote(AppNote note) async {
    final db = await database;
    await db
        .update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async => (await database).close();
}
