import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:qingyu_bill/constants/app_constants.dart';
import 'package:qingyu_bill/models/transaction.dart';
import 'package:qingyu_bill/screens/add_transaction_screen.dart';
import 'package:qingyu_bill/services/data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataService _service = DataService();
  late List<Transaction> _transactions;
  late double _budgetLimit;
  double get _totalSpent =>
      _transactions.where((t) => isSameMonth(t.date, DateTime.now())).fold(
            0.0,
            (sum, t) => sum + t.amount,
          );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _transactions = _service.getTransactions();
    _budgetLimit = _service.getBudget().monthlyLimit;
    setState(() {});
  }

  bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  @override
  Widget build(BuildContext context) {
    final spent = _totalSpent;
    final percent = (spent / _budgetLimit * 100).clamp(0.0, 100.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('轻语账单'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              ).then((_) => _loadData());
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '本月预算',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥${NumberFormat('#,##0.##').format(_budgetLimit)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: percent / 100,
                      color: spent > _budgetLimit ? Colors.red : kPrimaryColor,
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '已花 ¥${NumberFormat('#,##0.##').format(spent)} (${percent.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: spent > _budgetLimit ? Colors.red : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (spent > _budgetLimit)
                      const Text(
                        '⚠️ 超出预算！',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._transactions
                .where((t) => isSameMonth(t.date, DateTime.now()))
                .map((t) => ListTile(
                      title: Text(t.title),
                      subtitle: Text('${t.category} • ${DateFormat('MM-dd').format(t.date)}'),
                      trailing: Text('¥${t.amount.toStringAsFixed(2)}'),
                      onTap: () {},
                    ))
                .toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          ).then((_) => _loadData());
        },
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}