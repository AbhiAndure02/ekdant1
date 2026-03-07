import 'dart:convert';
import 'package:ekdant/data/gameData.dart';
import 'package:ekdant/services/wllet_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ekdant/models/bid_model.dart';
import 'package:ekdant/models/transaction_model.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:ekdant/services/bid_service.dart';
import 'package:ekdant/services/transaction_service.dart';

const double MINIMUM_BID_AMOUNT = 5.0;

class DoublePanaScreen extends StatefulWidget {
  final String gameName;
  final String gameId;
  final String marketId;
  final String marketName;
  final String closeTimeOpen;

  const DoublePanaScreen({
    super.key,
    required this.gameName,
    required this.gameId,
    required this.marketId,
    required this.marketName,
    required this.closeTimeOpen,
  });

  @override
  State<DoublePanaScreen> createState() => _DoublePanaScreenState();
}

class _DoublePanaScreenState extends State<DoublePanaScreen> {
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

  String selectedSession = 'Open';
  final Map<String, List<String>> digitPanaMap = GameData.digitPanaMap;

  final Map<String, TextEditingController> amountControllers = {};
  bool showConfirmation = false;
  String? selectedDigit;
  bool _isSubmitting = false;
  double walletAmount = 0.0;
  User? currentUser;
  bool isOpenSessionDisabled = false;

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
    _checkSessionAvailability();

    for (var combinations in digitPanaMap.values) {
      for (var combo in combinations) {
        amountControllers[combo] = TextEditingController();
      }
    }
    selectedDigit = digitPanaMap.keys.first;
  }

  void _checkSessionAvailability() {
    try {
      final parts = widget.closeTimeOpen.split(':');
      final closeHour = int.parse(parts[0]);
      final closeMinute = int.parse(parts[1]);
      final now = DateTime.now();
      final closeDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        closeHour,
        closeMinute,
      );
      if (now.isAfter(closeDateTime)) {
        setState(() {
          isOpenSessionDisabled = true;
          selectedSession = 'Close';
        });
      }
    } catch (e) {
      debugPrint('Error checking session availability: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUserData();
      if (user != null && mounted) {
        final walletResponse = await _walletService.getWallet(user.id);
        setState(() {
          currentUser = user;
          walletAmount = walletResponse.walletAmount;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) _showSnackbar('Error loading wallet: $e', _red);
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
        await _loadUserData();
      } else {
        throw Exception('Failed to update wallet: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update wallet: $e');
    }
  }

  Future<void> _createTransactionForPana(String pana, double amount) async {
    if (currentUser == null) return;
    final transaction = TransactionModel(
      id: '',
      userId: currentUser!.id,
      type: 'bid',
      date: DateTime.now().toIso8601String(),
      amount: amount.toStringAsFixed(2),
      marketName: widget.marketName,
      gameName: widget.gameName,
      digit: selectedDigit ?? '',
      pana: pana,
    );
    try {
      await _transactionService.createTransaction(transaction);
    } catch (e) {
      throw Exception('Failed to create transaction for pana $pana');
    }
  }

  @override
  void dispose() {
    for (var controller in amountControllers.values) {
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
    if (selectedDigit != null) {
      for (var pana in digitPanaMap[selectedDigit]!) {
        if (amountControllers[pana]!.text.isNotEmpty) {
          total += double.tryParse(amountControllers[pana]!.text) ?? 0;
        }
      }
    }
    return total;
  }

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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _gold.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildSessionButton('Open')),
                        const SizedBox(width: 4),
                        Expanded(child: _buildSessionButton('Close')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Digit selector
                  const Text(
                    'Select Digit',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: digitPanaMap.keys.map((digit) {
                        final isSelected = selectedDigit == digit;
                        return GestureDetector(
                          onTap: () => setState(() => selectedDigit = digit),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSelected ? _gold : _cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? _gold
                                    : _gold.withOpacity(0.2),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _gold.withOpacity(0.35),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                digit,
                                style: TextStyle(
                                  color: isSelected ? _dark : _textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Pana table
                  if (selectedDigit != null)
                    Container(
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _gold.withOpacity(0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: _gold.withOpacity(0.15),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Pana',
                                    style: TextStyle(
                                      color: _gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Amount (₹)',
                                    style: TextStyle(
                                      color: _gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rows
                          ...digitPanaMap[selectedDigit]!.asMap().entries.map((
                            entry,
                          ) {
                            final idx = entry.key;
                            final pana = entry.value;
                            final isEven = idx % 2 == 0;
                            return Container(
                              decoration: BoxDecoration(
                                color: isEven
                                    ? _cardBg
                                    : _surface.withOpacity(0.6),
                                borderRadius:
                                    idx ==
                                        digitPanaMap[selectedDigit]!.length - 1
                                    ? const BorderRadius.vertical(
                                        bottom: Radius.circular(16),
                                      )
                                    : BorderRadius.zero,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pana,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: amountControllers[pana],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        hintStyle: TextStyle(
                                          color: _textSecondary.withOpacity(
                                            0.5,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: _surface,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: _gold,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  const SizedBox(height: 100), // bottom padding for fixed bar
                ],
              ),
            ),
          ),

          // Bottom action bar
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

  Widget _buildSessionButton(String session) {
    final isDisabled = session == 'Open' && isOpenSessionDisabled;
    final isSelected = selectedSession == session;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () => setState(() => selectedSession = session),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled
              ? _textSecondary.withOpacity(0.1)
              : isSelected
              ? _gold
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected && !isDisabled
              ? [BoxShadow(color: _gold.withOpacity(0.3), blurRadius: 8)]
              : [],
        ),
        child: Center(
          child: Text(
            session,
            style: TextStyle(
              color: isDisabled
                  ? _textSecondary.withOpacity(0.4)
                  : isSelected
                  ? _dark
                  : _textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
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
                color: _gold,
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
              _confirmDetail('Session', selectedSession),
              _divider(),
              _confirmDetail('Digit', selectedDigit ?? '—'),
              _divider(),
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

  Widget _divider() {
    return Container(width: 1, height: 32, color: _gold.withOpacity(0.15));
  }

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
      if (walletAmount < totalAmount) {
        throw Exception('Insufficient wallet balance');
      }

      List<Future<void>> bidFutures = [];

      for (var pana in digitPanaMap[selectedDigit]!) {
        final amountText = amountControllers[pana]!.text;
        if (amountText.isNotEmpty) {
          final amount = double.tryParse(amountText) ?? 0;
          if (amount > 0) {
            final bidRequest = BidRequest(
              marketId: widget.marketId,
              userId: user.id,
              gameId: widget.gameId,
              name: user.name,
              mobile: user.number,
              market: widget.marketName,
              session: selectedSession,
              digit: selectedDigit ?? '',
              pana: pana,
              points: amountText,
              date: DateTime.now(),
              id: '',
              win: '',
            );
            bidFutures.add(_bidService.createBid(bidRequest));
            bidFutures.add(_createTransactionForPana(pana, amount));
          }
        }
      }

      await Future.wait(bidFutures);
      await _updateUserWallet(totalAmount);

      if (mounted) {
        _showSnackbar(
          '🎯 Bids placed for digit $selectedDigit ($selectedSession) — ₹$totalAmount',
          _green,
        );
        for (var pana in digitPanaMap[selectedDigit]!) {
          amountControllers[pana]!.clear();
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
