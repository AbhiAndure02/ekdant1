import 'dart:convert';
import 'package:ekdant/services/wllet_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ekdant/models/bid_model.dart';
import 'package:ekdant/models/transaction_model.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:ekdant/services/bid_service.dart';
import 'package:ekdant/services/transaction_service.dart';

const double MINIMUM_BID_AMOUNT = 5.0;

class JodiDigitScreen extends StatefulWidget {
  final String gameName;
  final String gameId;
  final String marketId;
  final String marketName;

  const JodiDigitScreen({
    super.key,
    required this.gameName,
    required this.gameId,
    required this.marketId,
    required this.marketName,
  });

  @override
  State<JodiDigitScreen> createState() => _JodiDigitScreenState();
}

class _JodiDigitScreenState extends State<JodiDigitScreen> {
  // Theme
  static const Color _dark = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF162040);
  static const Color _cardBg = Color(0xFF1A2940);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldLight = Color(0xFFF0C860);
  static const Color _green = Color(0xFF27AE60);
  static const Color _red = Color(0xFFE74C3C);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textSecondary = Color(0xFF8A9BB5);

  final List<TextEditingController> _amountControllers = List.generate(
    100,
    (index) => TextEditingController(),
  );
  bool showConfirmation = false;
  bool _isSubmitting = false;
  double walletAmount = 0.0;
  User? currentUser;

  late final BidService _bidService;
  late final AuthService _authService;
  late final TransactionService _transactionService;
  late final WalletService _walletService;

  @override
  void initState() {
    super.initState();
    _bidService = BidService();
    _authService = AuthService();
    _transactionService = TransactionService();
    _walletService = WalletService();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUserData();
    if (user != null && mounted) {
      final walletResponse = await _walletService.getWallet(user.id);
      setState(() {
        currentUser = user;
        walletAmount = walletResponse.walletAmount;
      });
    }
  }

  Future<void> _updateUserWallet(double amount) async {
    if (currentUser == null) return;
    try {
      final updatedUser = User(
        id: currentUser!.id,
        name: currentUser!.name,
        number: currentUser!.number,
        password: currentUser!.password,
        walletAmount: (walletAmount - amount).toStringAsFixed(2),
        status: currentUser!.status,
        role: currentUser!.role,
        registrationDate: currentUser!.registrationDate,
        isActive: currentUser!.isActive,
        apiToken: currentUser!.apiToken,
        deviceToken: currentUser!.deviceToken,
        autoDepoositeStatus: currentUser!.autoDepoositeStatus,
        referalCode: currentUser!.referalCode,
        referalTo: currentUser!.referalTo,
        accountNumber: currentUser!.accountNumber,
        bankHolderName: currentUser!.bankHolderName,
        bankName: currentUser!.bankName,
        upi: currentUser!.upi,
        waNumber: currentUser!.waNumber,
        ifsc: currentUser!.ifsc,
      );
      final response = await http.put(
        Uri.parse('https://api.ekadantaa.in/api/user/${currentUser!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _authService.getToken()}',
        },
        body: json.encode(updatedUser.toJson()),
      );
      if (response.statusCode == 200) {
        setState(() => walletAmount -= amount);
        await _authService.refreshUserData();
      } else {
        throw Exception('Failed to update wallet: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update wallet: $e');
    }
  }

  Future<void> _createTransaction(double amount, String digit) async {
    if (currentUser == null) return;
    final transaction = TransactionModel(
      id: '',
      userId: currentUser!.id,
      type: 'bid',
      date: DateTime.now().toIso8601String(),
      amount: amount.toStringAsFixed(2),
      marketName: widget.marketName,
      gameName: widget.gameName,
      digit: digit,
      pana: '',
    );
    try {
      await _transactionService.createTransaction(transaction);
    } catch (e) {
      throw Exception('Failed to create transaction');
    }
  }

  @override
  void dispose() {
    for (var controller in _amountControllers) {
      controller.dispose();
    }
    super.dispose();
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

  double _calculateTotal() {
    double total = 0;
    for (var controller in _amountControllers) {
      if (controller.text.isNotEmpty) {
        total += double.tryParse(controller.text) ?? 0;
      }
    }
    return total;
  }

  int _filledCount() => _amountControllers
      .where((c) => c.text.isNotEmpty && (double.tryParse(c.text) ?? 0) > 0)
      .length;

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();
    final hasSufficientBalance = walletAmount >= total;

    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.gameName,
                style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_gold, _goldLight]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: _dark,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '₹${walletAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: _dark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Jodi Table ────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _gold.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      border: Border(
                        bottom: BorderSide(color: _gold.withOpacity(0.15)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Jodi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Amount (₹)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: 100,
                      itemBuilder: (context, index) {
                        final digit = index.toString().padLeft(2, '0');
                        final isEven = index % 2 == 0;
                        final hasValue =
                            _amountControllers[index].text.isNotEmpty &&
                            (double.tryParse(_amountControllers[index].text) ??
                                    0) >
                                0;

                        return Container(
                          color: isEven ? _cardBg : _surface.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    digit,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: hasValue ? _gold : _textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _amountControllers[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: hasValue ? _gold : _textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: _textSecondary.withOpacity(0.4),
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: hasValue
                                        ? _gold.withOpacity(0.08)
                                        : _surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: _gold,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Bar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: BoxDecoration(
              color: _surface,
              border: Border(top: BorderSide(color: _gold.withOpacity(0.15))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: showConfirmation
                ? _buildConfirmationPanel(total)
                : _buildActionPanel(total, hasSufficientBalance),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel(double total, bool hasSufficientBalance) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _statPill('Total Bid', '₹$total', _gold),
            _statPill(
              'Wallet',
              '₹${walletAmount.toStringAsFixed(2)}',
              hasSufficientBalance ? _green : _red,
            ),
            if (_filledCount() > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withOpacity(0.25)),
                ),
                child: Text(
                  '${_filledCount()} jodis',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (total <= 0) {
                _showSnackbar('Please enter at least one bid amount', _red);
              } else if (!hasSufficientBalance) {
                _showSnackbar('Insufficient wallet balance', _red);
              } else if (total < MINIMUM_BID_AMOUNT) {
                _showSnackbar(
                  'Minimum bid amount is ₹$MINIMUM_BID_AMOUNT',
                  _red,
                );
              } else {
                setState(() => showConfirmation = true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _dark,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationPanel(double total) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, _goldLight],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Confirm Order',
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _confirmDetail('Session', 'Open'),
              _vDivider(),
              _confirmDetail('Jodis', '${_filledCount()}'),
              _vDivider(),
              _confirmDetail('Total', '₹$total', valueColor: _gold),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => showConfirmation = false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(color: _textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirm Bid',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statPill(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _confirmDetail(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: _gold.withOpacity(0.15));

  Future<void> _confirmOrder() async {
    setState(() => _isSubmitting = true);
    try {
      final user = await _authService.getUserData();
      if (user == null) throw Exception('User not logged in');

      final totalAmount = _calculateTotal();
      if (totalAmount <= 0) throw Exception('Invalid bid amount');
      if (totalAmount < MINIMUM_BID_AMOUNT) {
        throw Exception('Minimum bid amount is ₹$MINIMUM_BID_AMOUNT');
      }

      final currentWallet = double.tryParse(user.walletAmount ?? '0.0') ?? 0.0;
      if (currentWallet < totalAmount) {
        throw Exception('Insufficient wallet balance');
      }

      List<Future<void>> bidFutures = [];
      for (int i = 0; i < _amountControllers.length; i++) {
        final amount = _amountControllers[i].text;
        if (amount.isNotEmpty && double.tryParse(amount) != null) {
          final digit = i.toString().padLeft(2, '0');
          final bidRequest = BidRequest(
            marketId: widget.marketId,
            userId: user.id,
            gameId: widget.gameId,
            name: user.name,
            mobile: user.number,
            market: widget.marketName,
            session: 'Open',
            digit: digit,
            pana: '',
            points: amount,
            date: DateTime.now(),
            id: '',
            win: '',
          );
          bidFutures.add(_bidService.createBid(bidRequest));
        }
      }

      await Future.wait(bidFutures);
      await _createTransaction(totalAmount, '');
      await _updateUserWallet(totalAmount);

      if (mounted) {
        _showSnackbar(
          '🎯 ${_filledCount()} jodi bid${_filledCount() == 1 ? '' : 's'} placed — ₹$totalAmount',
          _green,
        );
        for (var c in _amountControllers) {
          c.clear();
        }
        await _loadUserData();
        setState(() {
          showConfirmation = false;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackbar('Failed to place bids: ${e.toString()}', _red);
      }
      debugPrint('Error placing bids: $e');
    }
  }
}
