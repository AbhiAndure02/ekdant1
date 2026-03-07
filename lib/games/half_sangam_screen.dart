import 'dart:convert';
import 'package:ekdant/services/wllet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ekdant/models/bid_model.dart';
import 'package:ekdant/models/transaction_model.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:ekdant/services/bid_service.dart';
import 'package:ekdant/services/transaction_service.dart';

const double MINIMUM_BID_AMOUNT = 5.0;

class HalfSangamScreen extends StatefulWidget {
  final String gameName;
  final String gameId;
  final String marketId;
  final String marketName;
  final String closeTimeOpen;

  const HalfSangamScreen({
    super.key,
    required this.gameName,
    required this.gameId,
    required this.marketId,
    required this.marketName,
    required this.closeTimeOpen,
  });

  @override
  State<HalfSangamScreen> createState() => _HalfSangamScreenState();
}

class _HalfSangamScreenState extends State<HalfSangamScreen> {
  // Theme
  static const Color _dark = Color(0xFF0A1628);
  static const Color _surface = Color(0xFF162040);
  static const Color _cardBg = Color(0xFF1A2940);
  static const Color _gold = Color(0xFFD4A843);
  static const Color _goldLight = Color(0xFFF0C860);
  static const Color _green = Color(0xFF27AE60);
  static const Color _red = Color(0xFFE74C3C);
  static const Color _orange = Color(0xFFE67E22);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textSecondary = Color(0xFF8A9BB5);

  String selectedSession = 'Open';
  final TextEditingController firstFieldController = TextEditingController();
  final TextEditingController secondFieldController = TextEditingController();
  final TextEditingController bidAmountController = TextEditingController();
  final List<Map<String, String>> bids = [];
  bool _isSubmitting = false;
  double walletAmount = 0.0;
  User? currentUser;
  bool isOpenSessionDisabled = false;
  bool isCloseSessionDisabled = false;

  late final BidService _bidService;
  late final AuthService _authService;
  late final TransactionService _transactionService;
  late final WalletService _walletService;

  @override
  void initState() {
    super.initState();
    _bidService = BidService();
    _authService = AuthService();
    _walletService = WalletService();
    _transactionService = TransactionService();
    _loadUserData();
    _checkSessionAvailability();
  }

  void _checkSessionAvailability() {
    try {
      final now = DateTime.now();
      final openParts = widget.closeTimeOpen.split(':');
      final openCloseTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(openParts[0]),
        int.parse(openParts[1]),
      );
      setState(() {
        isOpenSessionDisabled = now.isAfter(openCloseTime);
        if (isOpenSessionDisabled && !isCloseSessionDisabled) {
          selectedSession = 'Close';
        } else if (isCloseSessionDisabled && !isOpenSessionDisabled) {
          selectedSession = 'Open';
        }
      });
    } catch (e) {
      debugPrint('Error checking session availability: $e');
    }
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
      final response = await http.put(
        Uri.parse('https://api.ekadantaa.in/api/user/${currentUser!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _authService.getToken()}',
        },
        body: json.encode({
          'walletAmount': (walletAmount - amount).toStringAsFixed(2),
        }),
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

  Future<void> _createTransaction(double amount) async {
    if (currentUser == null) return;
    final transaction = TransactionModel(
      id: '',
      userId: currentUser!.id,
      type: 'debit',
      date: DateTime.now().toIso8601String(),
      amount: amount.toStringAsFixed(2),
    );
    try {
      await _transactionService.createTransaction(transaction);
    } catch (e) {
      throw Exception('Failed to create transaction');
    }
  }

  @override
  void dispose() {
    firstFieldController.dispose();
    secondFieldController.dispose();
    bidAmountController.dispose();
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

  bool get _isCurrentSessionDisabled =>
      (selectedSession == 'Open' && isOpenSessionDisabled) ||
      (selectedSession == 'Close' && isCloseSessionDisabled);

  void _addBid() {
    final firstField = firstFieldController.text.trim();
    final secondField = secondFieldController.text.trim();
    final amount = bidAmountController.text.trim();

    if (firstField.isEmpty || secondField.isEmpty || amount.isEmpty) {
      _showSnackbar('Please fill all fields', _red);
      return;
    }
    if (selectedSession == 'Open') {
      if (firstField.length != 3) {
        _showSnackbar('Open Pana must be exactly 3 digits', _red);
        return;
      }
      if (secondField.length != 1) {
        _showSnackbar('Close Digit must be exactly 1 digit', _red);
        return;
      }
    } else {
      if (firstField.length != 1) {
        _showSnackbar('Open Digit must be exactly 1 digit', _red);
        return;
      }
      if (secondField.length != 3) {
        _showSnackbar('Close Pana must be exactly 3 digits', _red);
        return;
      }
    }
    final amountValue = double.tryParse(amount) ?? 0;
    if (amountValue < MINIMUM_BID_AMOUNT) {
      _showSnackbar('Minimum bid amount is ₹$MINIMUM_BID_AMOUNT', _red);
      return;
    }

    setState(() {
      bids.add({
        'first': firstField,
        'second': secondField,
        'amount': amount,
        'session': selectedSession,
      });
      firstFieldController.clear();
      secondFieldController.clear();
      bidAmountController.clear();
    });
  }

  void _removeBid(int index) => setState(() => bids.removeAt(index));

  double _calculateTotalAsDouble() => bids.fold(
    0,
    (sum, bid) => sum + (double.tryParse(bid['amount'] ?? '0') ?? 0),
  );

  String _calculateTotal() => _calculateTotalAsDouble().toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotalAsDouble();
    final hasSufficientBalance = walletAmount >= total;
    final bothClosed = isOpenSessionDisabled && isCloseSessionDisabled;

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
                  // Session toggle
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
                  const SizedBox(height: 12),

                  // Session closed warning
                  if (isOpenSessionDisabled || isCloseSessionDisabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _orange.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: _orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bothClosed
                                  ? 'Both sessions are closed for bidding'
                                  : selectedSession == 'Open' &&
                                        isOpenSessionDisabled
                                  ? 'Open session is currently closed'
                                  : selectedSession == 'Close' &&
                                        isCloseSessionDisabled
                                  ? 'Close session is currently closed'
                                  : '',
                              style: TextStyle(
                                color: _orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Input card
                  Container(
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
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Enter Half Sangam'),
                        const SizedBox(height: 16),

                        // Dynamic label hint
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _gold.withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                selectedSession == 'Open'
                                    ? 'Open Pana (3 digits)  ×  Close Digit (1 digit)'
                                    : 'Open Digit (1 digit)  ×  Close Pana (3 digits)',
                                style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // First × Second row
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: firstFieldController,
                                label: selectedSession == 'Open'
                                    ? 'Open Pana'
                                    : 'Open Digit',
                                hint: selectedSession == 'Open'
                                    ? '3 digits'
                                    : '1 digit',
                                maxLength: selectedSession == 'Open' ? 3 : 1,
                                enabled: !_isCurrentSessionDisabled,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 18,
                                left: 10,
                                right: 10,
                              ),
                              child: Text(
                                '×',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: _gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _buildInputField(
                                controller: secondFieldController,
                                label: selectedSession == 'Open'
                                    ? 'Close Digit'
                                    : 'Close Pana',
                                hint: selectedSession == 'Open'
                                    ? '1 digit'
                                    : '3 digits',
                                maxLength: selectedSession == 'Open' ? 1 : 3,
                                enabled: !_isCurrentSessionDisabled,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _buildInputField(
                          controller: bidAmountController,
                          label: 'Bid Amount',
                          hint: 'Enter amount in ₹',
                          prefix: Text(
                            '₹ ',
                            style: TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          enabled: !_isCurrentSessionDisabled,
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isCurrentSessionDisabled
                                ? null
                                : _addBid,
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Add Bid',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCurrentSessionDisabled
                                  ? _textSecondary.withOpacity(0.2)
                                  : _gold,
                              foregroundColor: _isCurrentSessionDisabled
                                  ? _textSecondary
                                  : _dark,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bids list
                  Container(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _sectionHeader('Your Bids'),
                              if (bids.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _gold.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _gold.withOpacity(0.25),
                                    ),
                                  ),
                                  child: Text(
                                    '${bids.length} bid${bids.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      color: _gold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (bids.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.playlist_add_rounded,
                                    size: 40,
                                    color: _textSecondary.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No bids added yet',
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.35,
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              itemCount: bids.length,
                              separatorBuilder: (_, _) => Divider(
                                color: _gold.withOpacity(0.08),
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final bid = bids[index];
                                final isOpen = bid['session'] == 'Open';
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: _gold.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: _gold,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${bid['first']} × ${bid['second']}',
                                              style: const TextStyle(
                                                color: _textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                _sessionTag(
                                                  bid['session'] ?? '',
                                                  isOpen ? _green : _gold,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '₹${bid['amount']}',
                                                  style: const TextStyle(
                                                    color: _textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _removeBid(index),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: _red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: _red,
                                            size: 16,
                                          ),
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
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom bar
          if (bids.isNotEmpty)
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statPill('Total Bid', '₹${_calculateTotal()}', _gold),
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
                      onPressed: (_isSubmitting || _isCurrentSessionDisabled)
                          ? null
                          : _confirmBids,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_isSubmitting || _isCurrentSessionDisabled)
                            ? _textSecondary.withOpacity(0.2)
                            : _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
                          : Text(
                              'Confirm ${bids.length} Bid${bids.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionButton(String session) {
    final isDisabled =
        (session == 'Open' && isOpenSessionDisabled) ||
        (session == 'Close' && isCloseSessionDisabled);
    final isSelected = selectedSession == session;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () => setState(() {
              selectedSession = session;
              firstFieldController.clear();
              secondFieldController.clear();
            }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled
              ? _textSecondary.withOpacity(0.08)
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
                  ? _textSecondary.withOpacity(0.35)
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLength,
    Widget? prefix,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: maxLength,
          enabled: enabled,
          textAlign: maxLength != null && maxLength <= 3
              ? TextAlign.center
              : TextAlign.start,
          style: TextStyle(
            color: enabled ? _textPrimary : _textSecondary.withOpacity(0.4),
            fontWeight: FontWeight.bold,
            fontSize: maxLength != null && maxLength <= 3 ? 18 : 15,
            letterSpacing: maxLength != null && maxLength <= 3 ? 4 : 0,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _textSecondary.withOpacity(0.35),
              fontSize: 12,
              letterSpacing: 0,
            ),
            counterText: '',
            prefix: prefix,
            filled: true,
            fillColor: enabled ? _surface : _surface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _gold),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 13,
              horizontal: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
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
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _sessionTag(String session, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        session,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
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

  Future<void> _confirmBids() async {
    setState(() => _isSubmitting = true);
    try {
      final user = await _authService.getUserData();
      if (user == null) throw Exception('User not logged in');

      final totalAmount = _calculateTotalAsDouble();
      if (totalAmount <= 0) throw Exception('Invalid bid amount');
      if (totalAmount < MINIMUM_BID_AMOUNT) {
        throw Exception('Minimum bid amount is ₹$MINIMUM_BID_AMOUNT');
      }

      final currentWallet = double.tryParse(user.walletAmount ?? '0.0') ?? 0.0;
      if (currentWallet < totalAmount) {
        throw Exception('Insufficient wallet balance');
      }

      List<Future<void>> bidFutures = [];
      for (var bid in bids) {
        final isOpenSession = bid['session'] == 'Open';
        final bidRequest = BidRequest(
          marketId: widget.marketId,
          userId: user.id,
          gameId: widget.gameId,
          name: user.name,
          mobile: user.number,
          market: widget.marketName,
          session: bid['session']!,
          digit: isOpenSession ? bid['second']! : bid['first']!,
          pana: '${bid['first']}-${bid['second']}',
          points: bid['amount']!,
          date: DateTime.now(),
          id: '',
          win: '',
        );
        bidFutures.add(_bidService.createBid(bidRequest));
      }

      await Future.wait(bidFutures);
      await _createTransaction(totalAmount);
      await _updateUserWallet(totalAmount);

      if (mounted) {
        _showSnackbar(
          '🎯 ${bids.length} bid${bids.length == 1 ? '' : 's'} placed — ₹${_calculateTotal()}',
          _green,
        );
        setState(() {
          bids.clear();
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
