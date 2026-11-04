import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ExpenseStore()..load(),
      child: const ExpenseTrackerApp(),
    ),
  );
}

// -----------------------------------------------------------------------------
// MODEL
// -----------------------------------------------------------------------------
class Expense {
  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  final String id;
  final String title;
  final String category;
  final String note;
  final double amount;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        note: (json['note'] as String?) ?? '',
      );
}

// -----------------------------------------------------------------------------
// PROVIDER STORE (GP 2: Real Data / SharedPreferences, GP 6: Shared State)
// -----------------------------------------------------------------------------
class ExpenseStore extends ChangeNotifier {
  List<Expense> items = [];
  bool loading = true;
  String? error;

  double get total => items.fold(0.0, (sum, item) => sum + item.amount);

  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {
      'Food': 0.0,
      'Travel': 0.0,
      'Bills': 0.0,
      'Shopping': 0.0,
      'Health': 0.0,
      'Other': 0.0,
    };
    for (final e in items) {
      totals[e.category] = (totals[e.category] ?? 0.0) + e.amount;
    }
    return totals;
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('expenses') ?? [];
      items = raw
          .map((s) => Expense.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      error = 'Could not load saved expenses. Please tap Retry.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> add(Expense expense) async {
    items = [expense, ...items];
    await _save();
  }

  Future<void> remove(String id) async {
    items.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'expenses',
        items.map((e) => jsonEncode(e.toJson())).toList(),
      );
      error = null;
    } catch (_) {
      error = 'Could not save changes to device storage.';
    }
    notifyListeners();
  }
}

// -----------------------------------------------------------------------------
// MAIN APP & THEME (GP 7: Consistent Material 3 Theme)
// -----------------------------------------------------------------------------
class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff176b5b),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff6f8f6),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const ExpenseHomeScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// HOME SCREEN (GP 1, GP 3: Four States - Loading, Error, Empty, Data)
// -----------------------------------------------------------------------------
class ExpenseHomeScreen extends StatefulWidget {
  const ExpenseHomeScreen({super.key});

  @override
  State<ExpenseHomeScreen> createState() => _ExpenseHomeScreenState();
}

class _ExpenseHomeScreenState extends State<ExpenseHomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTab == 0 ? 'Expense Tracker' : 'Expense Summary',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ExpenseStore>().load(),
          ),
        ],
      ),
      body: Consumer<ExpenseStore>(
        builder: (context, store, _) {
          // State 1: Loading
          if (store.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // State 2: Error (when list is empty)
          if (store.error != null && store.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      store.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: store.load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Render selected tab: 0 -> Expenses list, 1 -> Category Summary
          if (_currentTab == 1) {
            return SummaryView(store: store);
          }

          // State 3 & 4: Empty or Data
          return Column(
            children: [
              // Total Banner
              GestureDetector(
                onTap: () => setState(() => _currentTab = 1),
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.account_balance_wallet,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Expenses',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${store.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.pie_chart_outline, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),

              if (store.error != null)
                MaterialBanner(
                  content: Text(store.error!),
                  actions: [
                    TextButton(
                      onPressed: () => store.load(),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),

              // State 3: Empty state
              if (store.items.isEmpty)
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.teal,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No expenses added yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the button below to add your first expense.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              // State 4: Data list
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 80),
                    itemCount: store.items.length,
                    itemBuilder: (context, index) {
                      final item = store.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xffe2f3ee),
                            child: Icon(
                              _categoryIcon(item.category),
                              color: const Color(0xff176b5b),
                            ),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${item.category} • ${_formatDate(item.date)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Text(
                            '₹${item.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExpenseDetailScreen(expense: item),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (idx) => setState(() => _currentTab = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart),
            label: 'Category Summary',
          ),
        ],
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            )
          : null,
    );
  }
}

// -----------------------------------------------------------------------------
// SUMMARY VIEW (Topic Requirement: Totals per category)
// -----------------------------------------------------------------------------
class SummaryView extends StatelessWidget {
  const SummaryView({super.key, required this.store});
  final ExpenseStore store;

  @override
  Widget build(BuildContext context) {
    final totals = store.categoryTotals;
    final totalOverall = store.total;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spending by Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Overall: ₹${totalOverall.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xff176b5b),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...totals.entries.map((entry) {
          final percentage =
              totalOverall > 0 ? (entry.value / totalOverall) : 0.0;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xffe2f3ee),
                        child: Icon(
                          _categoryIcon(entry.key),
                          size: 20,
                          color: const Color(0xff176b5b),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: percentage,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(Color(0xff176b5b)),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ADD EXPENSE SCREEN (GP 4: Validated Form with Clear Error Messages)
// -----------------------------------------------------------------------------
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _category = 'Food';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Expense Title *',
                hintText: 'e.g., Grocery shopping, Bus pass',
                prefixIcon: Icon(Icons.edit_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter an expense name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (₹) *',
                hintText: 'e.g., 250.00',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                final numVal = double.tryParse(val?.trim() ?? '');
                if (numVal == null || !numVal.isFinite || numVal <= 0) {
                  return 'Please enter an amount greater than ₹0.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: ['Food', 'Travel', 'Bills', 'Shopping', 'Health', 'Other']
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(_formatDate(_date)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLength: 200,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Optional Note',
                hintText: 'Add details or remarks',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _saving = true);
                      final newExpense = Expense(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        title: _titleController.text.trim(),
                        amount: double.parse(_amountController.text.trim()),
                        category: _category,
                        date: _date,
                        note: _noteController.text.trim(),
                      );
                      await context.read<ExpenseStore>().add(newExpense);
                      if (context.mounted) {
                        setState(() => _saving = false);
                        Navigator.pop(context);
                      }
                    },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(_saving ? 'Saving...' : 'Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DETAIL SCREEN (GP 5: Detail View with More Information)
// -----------------------------------------------------------------------------
class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xffe2f3ee),
                      child: Icon(
                        _categoryIcon(expense.category),
                        color: const Color(0xff176b5b),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${expense.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Color(0xff176b5b),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 36),
                _detailRow('Category', expense.category),
                _detailRow('Date', _formatDate(expense.date)),
                _detailRow(
                  'Note',
                  expense.note.isEmpty ? 'No notes provided' : expense.note,
                ),
                _detailRow('Entry ID', expense.id),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () async {
                    await context.read<ExpenseStore>().remove(expense.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HELPER FUNCTIONS
// -----------------------------------------------------------------------------
IconData _categoryIcon(String category) {
  switch (category) {
    case 'Food':
      return Icons.restaurant;
    case 'Travel':
      return Icons.directions_bus;
    case 'Bills':
      return Icons.receipt_long;
    case 'Shopping':
      return Icons.shopping_bag;
    case 'Health':
      return Icons.medical_services;
    default:
      return Icons.category;
  }
}

String _formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
