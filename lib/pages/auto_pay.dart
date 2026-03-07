import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/deposit_service.dart';
import '../models/deposit.dart';
import '../services/auth_service.dart';

class AutoPay extends StatefulWidget {
  const AutoPay({super.key});

  @override
  State<AutoPay> createState() => _AutoPayState();
}

class _AutoPayState extends State<AutoPay> {
  bool _isLoading = true;
  String _errorMessage = '';
  String _upiId = '';
  final TextEditingController _amountController = TextEditingController();
  final DepositService _depositService = DepositService();
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isSubmitting = false;

  static const Color _dark = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF162040);
  static const Color _cardBg = Color(0xFF1A2940);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldLight = Color(0xFFF0C860);
  static const Color _green = Color(0xFF27AE60);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textSecondary = Color(0xFF8A9BB5);

  // Quick amount chips
  final List<int> _quickAmounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getUserData();
      if (user != null) {
        setState(() => _currentUser = user);
        await _fetchUpiId(user.id);
      } else {
        setState(() {
          _errorMessage = "User not logged in";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load user";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUpiId(String userId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('https://api.ekadantaa.in/api/user/69a44e9b33b9207fc0985ac2'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _upiId = data['upi'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load UPI ID.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error.';
        _isLoading = false;
      });
    }
  }

  Future<void> _initiateUpiPayment() async {
    if (_upiId.isEmpty) return;
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      _showSnackbar('Please enter an amount', isError: true);
      return;
    }
    final amountVal = double.tryParse(amount);
    if (amountVal == null) {
      _showSnackbar('Please enter a valid number', isError: true);
      return;
    }
    if (amountVal <= 99) {
      _showSnackbar('Minimum amount is ₹100', isError: true);
      return;
    }

    final upiUrl = Uri.parse(
      'upi://pay?pa=$_upiId&pn=Ekdant Enterprises&am=$amount&cu=INR&tn=Ekdant Enterprises',
    );

    try {
      bool launched = await launchUrl(
        upiUrl,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        setState(() => _isSubmitting = true);

        // Wait silently for user to complete payment
        await Future.delayed(const Duration(seconds: 40));

        await _createDepositRecord(amount);
        setState(() => _isSubmitting = false);
        _showSnackbar('Deposit request submitted!', isError: false);
      } else {
        _showSnackbar('Could not launch UPI app', isError: true);
      }
    } catch (e) {
      _showSnackbar('Error: $e', isError: true);
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createDepositRecord(String amount) async {
    if (_currentUser == null) return;
    try {
      final deposit = Deposit(
        id: '',
        userId: _currentUser!.id,
        name: _currentUser!.name,
        balance: _currentUser!.walletAmount ?? '0',
        utrNumber: 'Generated_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        upiName: _upiId.split('@')[0],
        status: 'pending',
        reqDateTime: DateTime.now(),
        approvalDateTime: null,
      );
      await _depositService.createDeposit(deposit);
      _amountController.clear();
      await _authService.refreshWalletById(_currentUser!.id);
    } catch (e) {
      _showSnackbar('Failed to create deposit record: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE74C3C) : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _dark,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_gold),
                strokeWidth: 2,
              ),
            )
          : _errorMessage.isNotEmpty
          ? _buildError()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPayCard(),
                  const SizedBox(height: 16),
                  _buildSecurityNote(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: _textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: const TextStyle(color: _textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _currentUser != null
                ? _fetchUpiId(_currentUser!.id)
                : _loadUser(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _dark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_gold.withOpacity(0.12), _gold.withOpacity(0.04)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_gold, _goldLight]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: _dark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instant UPI Payment',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Redirects to your UPI app',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withOpacity(0.06)),

          Padding(
            padding: const EdgeInsets.all(20),
            child: _isSubmitting ? _buildCountdown() : _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // UPI info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _dark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _gold.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.alternate_email_rounded, color: _gold, size: 16),
              const SizedBox(width: 8),
              Text(
                'UPI: ',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
              Text(
                _upiId,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Amount input
        Text(
          'Enter Amount',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 12,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(
              color: _textSecondary.withOpacity(0.5),
              fontSize: 18,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '₹',
                style: TextStyle(
                  color: _gold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            filled: true,
            fillColor: _dark.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _textSecondary.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _textSecondary.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _gold, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick amount chips
        Text(
          'Quick Select',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 12,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickAmounts
              .map(
                (amt) => GestureDetector(
                  onTap: () =>
                      setState(() => _amountController.text = amt.toString()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _amountController.text == amt.toString()
                          ? _gold.withOpacity(0.15)
                          : _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _amountController.text == amt.toString()
                            ? _gold
                            : _textSecondary.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      '₹$amt',
                      style: TextStyle(
                        color: _amountController.text == amt.toString()
                            ? _gold
                            : _textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),

        // Pay button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _initiateUpiPayment,
            icon: const Icon(Icons.flash_on_rounded, size: 20),
            label: const Text(
              'Pay Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _dark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(_gold),
          strokeWidth: 2,
        ),
        const SizedBox(height: 24),
        const Text(
          'Processing Payment',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please complete the payment in your UPI app.\nDo not close this screen.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.security_rounded, color: _green, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Secure Payment',
                  style: TextStyle(
                    color: _green,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Powered by UPI — your bank credentials are never shared',
                  style: TextStyle(color: Color(0xFF8A9BB5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
