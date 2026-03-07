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

class FullSangamScreen extends StatefulWidget {
  final String gameName;
  final String gameId;
  final String marketId;
  final String marketName;

  const FullSangamScreen({
    super.key,
    required this.gameName,
    required this.gameId,
    required this.marketId,
    required this.marketName,
  });

  @override
  State<FullSangamScreen> createState() => _FullSangamScreenState();
}

class _FullSangamScreenState extends State<FullSangamScreen> {
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
  final TextEditingController openPanaController = TextEditingController();
  final TextEditingController closePanaController = TextEditingController();
  final TextEditingController bidAmountController = TextEditingController();
  final List<Map<String, String>> bids = [];
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

  Future<void> _createTransaction(double amount) async {
    if (currentUser == null) return;
    final transaction = TransactionModel(
      id: '',
      userId: currentUser!.id,
      type: 'debit',
      date: DateTime.now().toIso8601String(),
      amount: amount.toStringAsFixed(2),
      marketName: '',
      gameName: '',
      digit: '',
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
    openPanaController.dispose();
    closePanaController.dispose();
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

  void _addBid() {
    final openPana = openPanaController.text.trim();
    final closePana = closePanaController.text.trim();
    final amount = bidAmountController.text.trim();

    if (openPana.isEmpty || closePana.isEmpty || amount.isEmpty) {
      _showSnackbar('Please fill all fields', _red);
      return;
    }
    if (openPana.length != 3) {
      _showSnackbar('Open Pana must be exactly 3 digits', _red);
      return;
    }
    if (closePana.length != 3) {
      _showSnackbar('Close Pana must be exactly 3 digits', _red);
      return;
    }
    final amountValue = double.tryParse(amount) ?? 0;
    if (amountValue < MINIMUM_BID_AMOUNT) {
      _showSnackbar('Minimum bid amount is ₹$MINIMUM_BID_AMOUNT', _red);
      return;
    }

    setState(() {
      bids.add({
        'open': openPana,
        'close': closePana,
        'amount': amount,
        'session': selectedSession,
      });
      openPanaController.clear();
      closePanaController.clear();
      bidAmountController.clear();
    });
  }

  void _removeBid(int index) => setState(() => bids.removeAt(index));

  double _calculateTotalAsDouble() {
    return bids.fold(
      0,
      (sum, bid) => sum + (double.tryParse(bid['amount'] ?? '0') ?? 0),
    );
  }

  String _calculateTotal() => _calculateTotalAsDouble().toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotalAsDouble();
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
                  // ── Input Card ──────────────────────────────────────
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
                        _sectionHeader('Enter Full Sangam'),
                        const SizedBox(height: 16),

                        // Open × Close pana row
                        Row(
                          children: [
                            Expanded(
                              child: _buildPanaField(
                                controller: openPanaController,
                                label: 'Open Pana',
                                hint: '3 digits',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
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
                              child: _buildPanaField(
                                controller: closePanaController,
                                label: 'Close Pana',
                                hint: '3 digits',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Bid amount
                        _buildInputField(
                          controller: bidAmountController,
                          label: 'Bid Amount',
                          hint: 'Enter amount in ₹',
                          prefix: const Text(
                            '₹ ',
                            style: TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addBid,
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
                              backgroundColor: _gold,
                              foregroundColor: _dark,
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

                  // ── Bids List ───────────────────────────────────────
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
                        // Header
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
                                              '${bid['open']} × ${bid['close']}',
                                              style: const TextStyle(
                                                color: _textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '${bid['session']}  ·  ₹${bid['amount']}',
                                              style: const TextStyle(
                                                color: _textSecondary,
                                                fontSize: 12,
                                              ),
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

          // ── Bottom Bar ──────────────────────────────────────────────
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
                      onPressed: _isSubmitting ? null : _confirmBids,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
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

  Widget _buildPanaField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
          maxLength: 3,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 4,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _textSecondary.withOpacity(0.4),
              fontSize: 12,
              letterSpacing: 0,
            ),
            counterText: '',
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _gold),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Widget? prefix,
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
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textSecondary.withOpacity(0.4)),
            prefix: prefix,
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _gold),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 13,
              horizontal: 14,
            ),
          ),
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
        final bidRequest = BidRequest(
          marketId: widget.marketId,
          userId: user.id,
          gameId: widget.gameId,
          name: user.name,
          mobile: user.number,
          market: widget.marketName,
          session: bid['session'] ?? selectedSession,
          digit: '',
          pana: '${bid['open']}-${bid['close']}',
          points: bid['amount'] ?? '0',
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
