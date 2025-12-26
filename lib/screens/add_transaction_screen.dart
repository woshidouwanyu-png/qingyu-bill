import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import 'package:qingyu_bill/constants/app_constants.dart';
import 'package:qingyu_bill/models/transaction.dart';
import 'package:qingyu_bill/services/data_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final DataService _service = DataService();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = kCategories.first;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _hasSpeechSupport = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final hasSpeech = await _speech.initialize(
      onError: (error) => debugPrint("语音错误: $error"),
      onStatus: (status) => debugPrint("语音状态: $status"),
    );
    if (!mounted) return;
    setState(() => _hasSpeechSupport = hasSpeech);
  }

  Future<void> _startListening() async {
    if (!_hasSpeechSupport) return;
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          _handleSpeechResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 2),
      localeId: 'zh_CN',
    );
  }

  void _stopListening() {
    _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  void _handleSpeechResult(String text) {
    _service.saveVoiceDraft(text);
    final amountRegex = RegExp(r'(\\d+(\\.\\d+)?)');
    final match = amountRegex.firstMatch(text);
    if (match != null) {
      final amount = double.tryParse(match.group(1)!);
      if (amount != null && amount > 0) {
        String note = text
            .replaceAll(amountRegex, '')
            .replaceAll(RegExp(r'[元块块钱]'), '')
            .trim();
        if (note.isEmpty) note = '语音记账';
        _titleController.text = note;
        _amountController.text = amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2);
      }
    } else {
      _titleController.text = text;
    }
    _stopListening();
  }

  Future<void> _saveTransaction() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整')),
      );
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('金额无效')),
      );
      return;
    }
    final transaction = Transaction(
      id: const Uuid().v4(),
      amount: amount,
      title: _titleController.text,
      category: _selectedCategory,
      date: DateTime.now(),
    );
    await _service.addTransaction(transaction);
    await _service.recordFrequentNote(_titleController.text, _selectedCategory);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记一笔')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '备注'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '金额（元）'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: kCategories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
              decoration: const InputDecoration(labelText: '分类'),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_hasSpeechSupport)
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    color: _isListening ? Colors.red : kPrimaryColor,
                    onPressed: _isListening ? _stopListening : _startListening,
                    tooltip: '说出“早餐 15 元”',
                  )
                else
                  const Tooltip(
                    message: '设备不支持语音输入',
                    child: Icon(Icons.mic_off, color: Colors.grey),
                  ),
                ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}