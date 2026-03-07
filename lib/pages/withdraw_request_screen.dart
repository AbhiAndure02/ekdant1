import 'dart:async';
import 'dart:convert';
import 'package:ekdant/pages/home_screen.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class WithdrawalRequestScreen extends StatefulWidget {
  const WithdrawalRequestScreen({super.key});

  @override
  State<WithdrawalRequestScreen> createState() =>
      _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState extends State<WithdrawalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _bankIfscController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();

  String _selectedMethod = 'Bank Transfer';
  final List<String> _withdrawalMethods = ['Bank Transfer', 'UPI'];

  double _availableBalance = 0;
  late StreamSubscription<double> _walletSubscription;
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasBankDetails = false;

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
    _initializeData();
    _walletSubscription = _authService.walletUpdates.listen((balance) {
      if (mounted) {
        setState(() {
          _availableBalance = balance;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _initializeData() async {
    try {
      final user = await _authService.getUserData();
      if (user != null) {
        final balance = await _authService.getCurrentWallet();
        if (user.bankName != null &&
            user.bankName!.isNotEmpty &&
            user.accountNumber != null &&
            user.accountNumber!.isNotEmpty) {
          setState(() {
            _hasBankDetails = true;
            _bankNameController.text = user.bankName ?? '';
            _accountNumberController.text = user.accountNumber ?? '';
            _accountNameController.text = user.bankHolderName ?? '';
            _bankIfscController.text = user.ifsc ?? '';
          });
        }
        if (mounted) {
          setState(() {
            _availableBalance = balance;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackbar('Failed to load wallet: $e', _red);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _bankIfscController.dispose();
    _upiIdController.dispose();
    _walletSubscription.cancel();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = await _authService.getUserData();
      if (user == null) throw Exception('User not authenticated');

      final amount = double.parse(_amountController.text);
      final newBalance = _availableBalance - amount;

      final requestData = {
        'userId': user.id,
        'name': user.name,
        'balance': _availableBalance.toStringAsFixed(2),
        'amount': amount.toStringAsFixed(2),
        'reason': 'Withdrawal request',
        'status': 'PENDING',
        'reqDateTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'method': _selectedMethod,
      };

      if (_selectedMethod == 'Bank Transfer') {
        requestData.addAll({
          'toAccount': _accountNumberController.text,
          'bankHolderName': _accountNameController.text,
          'bankName': _bankNameController.text,
          'ifsc': _bankIfscController.text,
        });
      } else if (_selectedMethod == 'UPI') {
        requestData['upiId'] = _upiIdController.text;
      }

      final updateResponse = await http.put(
        Uri.parse('https://api.ekadantaa.in/api/user/${user.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _authService.getToken()}',
        },
        body: json.encode({
          'walletAmount': newBalance.toStringAsFixed(2),
          if (_selectedMethod == 'Bank Transfer' && !_hasBankDetails)
            'bankName': _bankNameController.text,
          'accountNumber': _accountNumberController.text,
          'bankHolderName': _accountNameController.text,
          'ifsc': _bankIfscController.text,
        }),
      );

      if (updateResponse.statusCode != 200) {
        throw Exception('Failed to update user details');
      }

      final withdrawResponse = await http.post(
        Uri.parse('https://api.ekadantaa.in/api/withdraws'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _authService.getToken()}',
        },
        body: json.encode(requestData),
      );

      if (withdrawResponse.statusCode != 200) {
        throw Exception('Failed to create withdrawal request');
      }

      if (mounted) {
        setState(() => _availableBalance = newBalance);
        await _authService.refreshUserData();
        _showSuccessDialog(amount);
      }
    } catch (e) {
      if (mounted) _showSnackbar('Failed to submit: ${e.toString()}', _red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _green,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Request Submitted!',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _dialogRow(
                      'Amount',
                      '₹${amount.toStringAsFixed(2)}',
                      _gold,
                    ),
                    const SizedBox(height: 8),
                    _dialogRow('Method', _selectedMethod, _textSecondary),
                    if (_selectedMethod == 'Bank Transfer') ...[
                      const SizedBox(height: 8),
                      _dialogRow(
                        'Account',
                        _accountNumberController.text,
                        _textSecondary,
                      ),
                    ],
                    if (_selectedMethod == 'UPI') ...[
                      const SizedBox(height: 8),
                      _dialogRow(
                        'UPI ID',
                        _upiIdController.text,
                        _textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your request will be processed within 45 minutes.',
                style: TextStyle(color: _textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: _dark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        title: const Text(
          'Withdraw Funds',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _dark,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: _textPrimary,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          ),
        ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A2940), Color(0xFF162040)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _gold.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: _gold,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                NumberFormat.currency(
                                  symbol: '₹',
                                  decimalDigits: 2,
                                ).format(_availableBalance),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: _gold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Withdrawable Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _sectionLabel('Withdrawal Method'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _gold.withOpacity(0.2)),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedMethod,
                        dropdownColor: _surface,
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: _gold,
                        ),
                        style: const TextStyle(color: _textPrimary),
                        items: _withdrawalMethods
                            .map(
                              (method) => DropdownMenuItem(
                                value: method,
                                child: Text(
                                  method,
                                  style: const TextStyle(color: _textPrimary),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedMethod = value!),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _sectionLabel('Amount to Withdraw'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _amountController,
                      hint: 'Enter amount',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefix: const Text(
                        '₹ ',
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        if (amount > _availableBalance) {
                          return 'Amount exceeds available balance';
                        }
                        if (amount < 500) {
                          return 'Minimum withdrawal amount is ₹500';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_rounded, color: _blue, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Withdraw Time: 10AM – 7PM\nProcessing time: ~45 minutes',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // UPI Fields
                    if (_selectedMethod == 'UPI') ...[
                      _sectionLabel('UPI ID'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _upiIdController,
                        hint: 'e.g. name@upi',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter UPI ID';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid UPI ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Bank Fields
                    if (_selectedMethod == 'Bank Transfer' &&
                        !_hasBankDetails) ...[
                      _sectionLabel('Bank Account Details'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _accountNameController,
                        hint: 'Bank Holder Name',
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please enter bank holder name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _bankNameController,
                        hint: 'Bank Name',
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please enter bank name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _accountNumberController,
                        hint: 'Account Number',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter account number';
                          }
                          if (v.length < 9) {
                            return 'Enter a valid account number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _bankIfscController,
                        hint: 'IFSC Code',
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter IFSC Code';
                          }
                          if (v.length < 8) return 'Enter a valid IFSC Code';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: _dark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: _dark,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'REQUEST WITHDRAWAL',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        'By submitting, you agree to our terms. Withdrawals may take up to 45 minutes.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _textSecondary.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: _textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    Widget? prefix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textSecondary),
        prefix: prefix,
        filled: true,
        fillColor: _cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _gold.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _gold.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _red),
        ),
        errorStyle: const TextStyle(color: _red),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}
