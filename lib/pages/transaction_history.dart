import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:ekdant/models/transaction_model.dart';
import 'package:ekdant/services/transaction_service.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  bool _showTransactions = false;
  bool _isLoading = false;
  List<TransactionModel> _transactions = [];
  String? _userId;
  User? _currentUser;

  final AuthService _authService = AuthService();
  final TransactionService _transactionService = TransactionService();

  // Theme
  static const Color _dark = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF162040);
  static const Color _cardBg = Color(0xFF1A2940);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldLight = Color(0xFFF0C860);
  static const Color _green = Color(0xFF27AE60);
  static const Color _red = Color(0xFFE74C3C);
  static const Color _blue = Color(0xFF3498DB);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textSecondary = Color(0xFF8A9BB5);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUserData();
    if (user != null) {
      setState(() {
        _currentUser = user;
        _userId = user.id;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _gold,
            onPrimary: _dark,
            surface: _surface,
            onSurface: _textPrimary,
          ),
          dialogTheme: DialogThemeData(backgroundColor: _cardBg),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _showTransactions = false;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _gold,
            onPrimary: _dark,
            surface: _surface,
            onSurface: _textPrimary,
          ),
          dialogTheme: DialogThemeData(backgroundColor: _cardBg),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _showTransactions = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_userId == null || _userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not logged in'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transactions = await _transactionService.getTransactionsByUser(
        _userId!,
      );
      final filteredTransactions = transactions.where((transaction) {
        try {
          final transactionDate = DateTime.parse(transaction.date);
          return transactionDate.isAfter(
                _startDate.subtract(const Duration(days: 1)),
              ) &&
              transactionDate.isBefore(_endDate.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();

      setState(() {
        _transactions = filteredTransactions;
        _showTransactions = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching transactions: $e'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _dark,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF162040)],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date Range Card
            Container(
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_gold, _goldLight],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Select Date Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          'Start Date',
                          _startDate,
                          () => _selectStartDate(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDatePicker(
                          'End Date',
                          _endDate,
                          () => _selectEndDate(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _dark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: _dark,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SHOW TRANSACTIONS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_showTransactions)
              Expanded(
                child: _transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 56,
                              color: _textSecondary.withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No transactions found',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          return _buildTransactionItem(
                            transaction.type,
                            transaction.date,
                            transaction.amount,
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _gold.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateFormat.format(date),
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.calendar_month_rounded,
                  color: _gold,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getTransactionColor(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return _green;
      case 'withdrawal':
        return _red;
      case 'transfer':
        return _blue;
      default:
        return _gold;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return Icons.arrow_downward_rounded;
      case 'withdrawal':
        return Icons.arrow_upward_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.currency_rupee_rounded;
    }
  }

  Widget _buildTransactionItem(String title, String date, String amount) {
    final color = _getTransactionColor(title);
    final icon = _getTransactionIcon(title);
    final isCredit = title.toLowerCase() == 'deposit';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTransactionDate(date),
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₹$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTransactionDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
