import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';
import 'services/ocr_service.dart';

void main() => runApp(const ExpenseManagerApp());

class ExpenseManagerApp extends StatelessWidget {
  const ExpenseManagerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Expense Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087F8C)), useMaterial3: true),
        home: const DashboardPage(),
      );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService api = ApiService();
  final ImagePicker picker = ImagePicker();
  final OcrService ocr = OcrService();
  List<Map<String, dynamic>> transactions = [];
  Map<String, dynamic> summary = {'income': 0, 'expense': 0, 'balance': 0};
  bool loading = true;
  String error = '';
  String filter = 'All';
  final money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() { loading = true; error = ''; });
    try {
      final results = await Future.wait([api.getTransactions(), api.getSummary()]);
      if (!mounted) return;
      setState(() {
        transactions = results[0] as List<Map<String, dynamic>>;
        summary = results[1] as Map<String, dynamic>;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get visibleTransactions => transactions.where((t) => filter == 'All' || t['type'] == filter).toList();

  Future<void> openForm({Map<String, dynamic>? item}) async {
    final result = await showDialog<bool>(context: context, barrierDismissible: false,
      builder: (_) => TransactionDialog(item: item, api: api, picker: picker, ocr: ocr));
    if (result == true) refresh();
  }

  Future<void> deleteItem(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete transaction?'), content: Text('Delete "${item['title']}"?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))]));
    if (ok == true) { try { await api.deleteTransaction(int.parse('${item['id']}')); await refresh(); }
      catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } }
  }

  @override
  Widget build(BuildContext context) {
    final income = double.tryParse('${summary['income'] ?? 0}') ?? 0;
    final expense = double.tryParse('${summary['expense'] ?? 0}') ?? 0;
    final balance = double.tryParse('${summary['balance'] ?? income - expense}') ?? income - expense;
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF087F8C), foregroundColor: Colors.white,
        title: const Row(children: [Icon(Icons.account_balance_wallet), SizedBox(width: 10), Text('Expense Manager')]),
        actions: [IconButton(tooltip: 'Refresh', onPressed: refresh, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => openForm(), icon: const Icon(Icons.add), label: const Text('Add transaction')),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Your finances at a glance', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()), style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 650;
          final cards = [
            _SummaryCard(title: 'Balance', value: money.format(balance), icon: Icons.account_balance, color: Colors.blue),
            _SummaryCard(title: 'Income', value: money.format(income), icon: Icons.trending_up, color: Colors.green),
            _SummaryCard(title: 'Expenses', value: money.format(expense), icon: Icons.trending_down, color: Colors.deepOrange),
          ];
          return wide ? Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList())
            : Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList());
        }),
        const SizedBox(height: 22),
        Row(children: [const Expanded(child: Text('Transactions', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
          DropdownButton<String>(value: filter, items: const [DropdownMenuItem(value: 'All', child: Text('All')), DropdownMenuItem(value: 'income', child: Text('Income')), DropdownMenuItem(value: 'expense', child: Text('Expense'))], onChanged: (v) => setState(() => filter = v ?? 'All'))]),
        const SizedBox(height: 8),
        if (loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
        else if (error.isNotEmpty) Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [const Icon(Icons.cloud_off, color: Colors.red, size: 40), const Text('Could not connect to API', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(error, textAlign: TextAlign.center), const SizedBox(height: 8), const Text('Check XAMPP, import the SQL file and verify apiBaseUrl in lib/services/api_service.dart.', textAlign: TextAlign.center), FilledButton.icon(onPressed: refresh, icon: const Icon(Icons.refresh), label: const Text('Try again'))])))
        else if (visibleTransactions.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(28), child: Column(children: [Icon(Icons.receipt_long, size: 44, color: Colors.grey), SizedBox(height: 8), Text('No transactions yet'), Text('Add income or expenses to get started.')])) )
        else ...visibleTransactions.map((t) => Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
          leading: CircleAvatar(backgroundColor: t['type'] == 'income' ? Colors.green.shade50 : Colors.orange.shade50,
            child: Icon(t['type'] == 'income' ? Icons.south_west : Icons.north_east, color: t['type'] == 'income' ? Colors.green : Colors.deepOrange)),
          title: Text('${t['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${t['category'] ?? 'Other'} • ${t['transaction_date'] ?? ''}${('${t['notes'] ?? ''}').isNotEmpty ? '\n${t['notes']}' : ''}'),
          isThreeLine: ('${t['notes'] ?? ''}').isNotEmpty,
          trailing: SizedBox(width: 150, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Flexible(child: Text('${t['type'] == 'income' ? '+' : '-'}${money.format(double.tryParse('${t['amount']}') ?? 0)}', style: TextStyle(fontWeight: FontWeight.bold, color: t['type'] == 'income' ? Colors.green : Colors.deepOrange), overflow: TextOverflow.ellipsis)),
            IconButton(tooltip: 'Edit', onPressed: () => openForm(item: t), icon: const Icon(Icons.edit_outlined, size: 19)),
            IconButton(tooltip: 'Delete', onPressed: () => deleteItem(t), icon: const Icon(Icons.delete_outline, size: 19, color: Colors.red)),
          ])),
        ))),
        const SizedBox(height: 80),
      ]))),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color color;
  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
    CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: Colors.grey.shade700)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))]))
  ])));
}

class TransactionDialog extends StatefulWidget {
  final Map<String, dynamic>? item; final ApiService api; final ImagePicker picker; final OcrService ocr;
  const TransactionDialog({super.key, this.item, required this.api, required this.picker, required this.ocr});
  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController title, amount, notes;
  String type = 'expense', category = 'Food', date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool saving = false, scanning = false;
  String ocrText = '';
  final categories = const ['Food', 'Transport', 'Shopping', 'Bills', 'Salary', 'Education', 'Health', 'Other'];

  @override
  void initState() { super.initState(); final i = widget.item; title = TextEditingController(text: '${i?['title'] ?? ''}'); amount = TextEditingController(text: '${i?['amount'] ?? ''}'); notes = TextEditingController(text: '${i?['notes'] ?? ''}'); type = '${i?['type'] ?? 'expense'}'; category = categories.contains(i?['category']) ? '${i?['category']}' : 'Other'; date = '${i?['transaction_date'] ?? date}'; }
  @override
  void dispose() { title.dispose(); amount.dispose(); notes.dispose(); super.dispose(); }

  Future<void> scanReceipt() async {
    try {
      final image = await widget.picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;
      setState(() => scanning = true);
      final text = await widget.ocr.recognizeImagePath(image.path);
      if (!mounted) return;
      setState(() { scanning = false; ocrText = text; if (notes.text.isEmpty) notes.text = text; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OCR finished. Review the extracted text before saving.')));
    } catch (e) { if (mounted) { setState(() => scanning = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not scan receipt: $e'))); } }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.api.saveTransaction(id: widget.item == null ? null : int.parse('${widget.item!['id']}'), title: title.text.trim(), amount: double.parse(amount.text.replaceAll(',', '.')), type: type, category: category, date: date, notes: notes.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) { if (mounted) { setState(() => saving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'))); } }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'New transaction' : 'Edit transaction'),
    content: SizedBox(width: 480, child: SingleChildScrollView(child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      SegmentedButton<String>(segments: const [ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)), ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.add_circle_outline))], selected: {type}, onSelectionChanged: (s) => setState(() { type = s.first; category = type == 'income' ? 'Salary' : 'Food'; })),
      const SizedBox(height: 14), TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null),
      const SizedBox(height: 12), TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (VND)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.payments_outlined)), validator: (v) { final n = double.tryParse((v ?? '').replaceAll(',', '.')); return n == null || n <= 0 ? 'Enter an amount greater than 0' : null; }),
      const SizedBox(height: 12), DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => category = v ?? 'Other')),
      const SizedBox(height: 12), TextFormField(initialValue: date, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)), onChanged: (v) => date = v, validator: (v) => DateTime.tryParse(v ?? '') == null ? 'Use YYYY-MM-DD' : null),
      const SizedBox(height: 12), TextFormField(controller: notes, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Notes / receipt OCR text', border: OutlineInputBorder(), alignLabelWithHint: true)),
      const SizedBox(height: 10), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: scanning ? null : scanReceipt, icon: scanning ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.document_scanner_outlined), label: Text(scanning ? 'Reading receipt…' : 'Scan receipt with OCR')),
      ),
      if (ocrText.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Extracted ${ocrText.length} characters. Check the Notes field; OCR may make mistakes.', style: Theme.of(context).textTheme.bodySmall)),
    ])))),
    actions: [TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: saving ? null : save, child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'))],
  );
}
