import 'package:hive/hive.dart';
import 'package:qingyu_bill/models/budget.dart';
import 'package:qingyu_bill/models/frequent_note.dart';
import 'package:qingyu_bill/models/transaction.dart';
import 'package:qingyu_bill/models/voice_draft.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  late Box<Transaction> _transactionBox;
  late Box<Budget> _budgetBox;
  late Box<FrequentNote> _noteBox;
  late Box<VoiceDraft> _voiceBox;

  Future<void> init() async {
    _transactionBox = await Hive.openBox<Transaction>('transactions');
    _budgetBox = await Hive.openBox<Budget>('budgets');
    _noteBox = await Hive.openBox<FrequentNote>('frequent_notes');
    _voiceBox = await Hive.openBox<VoiceDraft>('voice_drafts');

    if (_budgetBox.isEmpty) {
      _budgetBox.add(Budget(monthlyLimit: 3000));
    }
  }

  List<Transaction> getTransactions() => _transactionBox.values.toList();
  Future<void> addTransaction(Transaction t) => _transactionBox.add(t);
  Future<void> deleteTransaction(String id) => _transactionBox.delete(id);

  Budget getBudget() => _budgetBox.getAt(0)!;
  Future<void> updateBudget(Budget b) => _budgetBox.putAt(0, b);

  List<FrequentNote> getFrequentNotes(String category) {
    return _noteBox.values
        .where((n) => n.category == category)
        .toList()
      ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
  }

  Future<void> recordFrequentNote(String note, String category) async {
    final existing = _noteBox.values
        .firstWhereOrNull((n) => n.note == note && n.category == category);
    if (existing != null) {
      existing.count++;
      existing.lastUsed = DateTime.now();
      await existing.save();
    } else {
      await _noteBox.add(FrequentNote(note: note, category: category));
    }
  }

  Future<void> saveVoiceDraft(String text) {
    return _voiceBox.add(VoiceDraft(rawText: text));
  }
}