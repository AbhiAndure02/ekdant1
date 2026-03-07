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

// ─── Palette ────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF070E1A);
  static const card = Color(0xFF111E33);
  static const surface = Color(0xFF162040);
  static const border = Color(0xFF1E3050);
  static const gold = Color(0xFFD4A843);
  static const goldLt = Color(0xFFF5D078);
  static const green = Color(0xFF1DB954);
  static const red = Color(0xFFE74C3C);
  static const txt = Color(0xFFF0F4FF);
  static const muted = Color(0xFF8A9BB5);
  static const dim = Color(0xFF2A3A55);
}

class SingleDigitScreen extends StatefulWidget {
  final String gameName;
  final String gameId;
  final String marketId;
  final String marketName;
  final String closeTimeOpen;

  const SingleDigitScreen({
    super.key,
    required this.gameName,
    required this.gameId,
    required this.marketId,
    required this.marketName,
    required this.closeTimeOpen,
  });

  @override
  State<SingleDigitScreen> createState() => _SingleDigitScreenState();
}

class _SingleDigitScreenState extends State<SingleDigitScreen>
    with SingleTickerProviderStateMixin {
  String selectedSession = 'Open';
  final List<TextEditingController> _amountControllers = List.generate(
    10,
    (_) => TextEditingController(),
  );

  bool showConfirmation = false;
  bool _isSubmitting = false;
  double walletAmount = 0.0;
  User? currentUser;
  bool isOpenSessionDisabled = false;

  late AnimationController _confirmCtrl;
  late Animation<double> _confirmAnim;

  late final BidService _bidService;
  late final AuthService _authService;
  late final TransactionService _transactionService;
  late final WalletService _walletService;

  // ─── lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _bidService = BidService();
    _walletService = WalletService();
    _authService = AuthService();
    _transactionService = TransactionService();

    _confirmCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _confirmAnim = CurvedAnimation(
      parent: _confirmCtrl,
      curve: Curves.easeOutCubic,
    );

    _loadUserData();
    _checkSession();
  }

  @override
  void dispose() {
    for (final c in _amountControllers) {
      c.dispose();
    }
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _checkSession() {
    final now = TimeOfDay.now();
    final parts = widget.closeTimeOpen.split(':');
    final close = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    if (now.hour > close.hour ||
        (now.hour == close.hour && now.minute >= close.minute)) {
      setState(() {
        isOpenSessionDisabled = true;
        selectedSession = 'Close';
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUserData();
    if (user != null && mounted) {
      final wallet = await _walletService.getWallet(user.id);
      setState(() {
        currentUser = user;
        walletAmount = wallet.walletAmount;
      });
    }
  }

  Future<void> _updateUserWallet(double amount) async {
    if (currentUser == null) return;
    final updated = User(
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
      body: json.encode(updated.toJson()),
    );
    if (response.statusCode == 200) {
      setState(() => walletAmount -= amount);
      await _authService.refreshUserData();
    } else {
      throw Exception('Failed to update wallet: ${response.statusCode}');
    }
  }

  Future<void> _createTransaction(double amount, String digit) async {
    if (currentUser == null) return;
    await _transactionService.createTransaction(
      TransactionModel(
        id: '',
        userId: currentUser!.id,
        type: 'bid',
        date: DateTime.now().toIso8601String(),
        amount: amount.toStringAsFixed(2),
        marketName: widget.gameName,
        gameName: widget.gameName,
        pana: '',
        digit: digit,
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (final c in _amountControllers) {
      total += double.tryParse(c.text) ?? 0;
    }
    return total;
  }

  void _onContinue() {
    final total = _calculateTotal();
    if (total <= 0) {
      _snack('Please enter at least one bid amount', isError: true);
      return;
    }
    if (total < MINIMUM_BID_AMOUNT) {
      _snack('Minimum bid amount is ₹$MINIMUM_BID_AMOUNT', isError: true);
      return;
    }
    if (walletAmount < total) {
      _snack('Insufficient wallet balance', isError: true);
      return;
    }
    setState(() => showConfirmation = true);
    _confirmCtrl.forward(from: 0);
  }

  Future<void> _confirmOrder() async {
    setState(() => _isSubmitting = true);
    try {
      final user = await _authService.getUserData();
      if (user == null) throw Exception('User not logged in');
      final total = _calculateTotal();
      if (total <= 0) throw Exception('Invalid bid amount');
      if (total < MINIMUM_BID_AMOUNT) {
        throw Exception('Minimum bid amount is ₹$MINIMUM_BID_AMOUNT');
      }
      final currentWallet = double.tryParse(user.walletAmount ?? '0') ?? 0;
      if (currentWallet < total) throw Exception('Insufficient wallet balance');
      if (selectedSession == 'Open' && isOpenSessionDisabled) {
        throw Exception('Open session is now closed');
      }

      final futures = <Future<void>>[];
      for (int i = 0; i < _amountControllers.length; i++) {
        final amt = _amountControllers[i].text;
        if (amt.isNotEmpty && double.tryParse(amt) != null) {
          final digit = i == 9 ? '0' : (i + 1).toString();
          futures.add(
            _bidService.createBid(
              BidRequest(
                marketId: widget.marketId,
                userId: user.id,
                gameId: widget.gameId,
                name: user.name,
                mobile: user.number,
                market: widget.marketName,
                session: selectedSession,
                digit: digit,
                pana: '',
                points: amt,
                date: DateTime.now(),
                id: '',
                win: '',
              ),
            ),
          );
        }
      }
      await Future.wait(futures);
      await _createTransaction(total, '');
      await _updateUserWallet(total);

      _snack('Bids placed! Total: ₹$total', isError: false);
      for (final c in _amountControllers) {
        c.clear();
      }
      await _loadUserData();
      setState(() {
        showConfirmation = false;
        _isSubmitting = false;
      });
      _confirmCtrl.reverse();
    } catch (e) {
      setState(() => _isSubmitting = false);
      _snack('Failed: ${e.toString()}', isError: true);
    }
  }

  void _snack(String msg, {required bool isError}) {
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
            Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? _C.red : _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSessionPicker(),
          Expanded(child: _buildDigitTable()),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _C.txt,
            size: 15,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.gameName,
            style: const TextStyle(
              color: _C.txt,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.marketName,
            style: const TextStyle(color: _C.muted, fontSize: 12),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.gold, _C.goldLt]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: _C.gold.withOpacity(0.3), blurRadius: 10),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: _C.bg,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                '₹${walletAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _C.bg,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border.withOpacity(0.5)),
      ),
    );
  }

  // ─── Session Picker ─────────────────────────────────────────
  Widget _buildSessionPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sessionBtn('Open'),
              const SizedBox(width: 12),
              _sessionBtn('Close'),
            ],
          ),
          if (isOpenSessionDisabled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: _C.red,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Open session closed at ${widget.closeTimeOpen}',
                    style: const TextStyle(color: _C.red, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sessionBtn(String session) {
    final isDisabled = session == 'Open' && isOpenSessionDisabled;
    final isSelected = selectedSession == session && !isDisabled;

    return Expanded(
      child: GestureDetector(
        onTap: isDisabled
            ? null
            : () => setState(() => selectedSession = session),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [_C.gold, _C.goldLt])
                : null,
            color: isDisabled
                ? _C.dim.withOpacity(0.4)
                : (!isSelected ? _C.card : null),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDisabled ? _C.dim : _C.border),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _C.gold.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              session,
              style: TextStyle(
                color: isSelected ? _C.bg : (isDisabled ? _C.muted : _C.txt),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Digit Table ────────────────────────────────────────────
  Widget _buildDigitTable() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.gold.withOpacity(0.12),
                    _C.gold.withOpacity(0.04),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'DIGIT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _C.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'AMOUNT (₹)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _C.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: _C.border),

            // Rows
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: 10,
                separatorBuilder: (_, _) =>
                    Container(height: 1, color: _C.border.withOpacity(0.5)),
                itemBuilder: (_, index) {
                  final digit = index == 9 ? '0' : (index + 1).toString();
                  final hasValue =
                      _amountControllers[index].text.isNotEmpty &&
                      (_amountControllers[index].text) != '0';
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: hasValue
                        ? _C.gold.withOpacity(0.05)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Digit badge
                        Expanded(
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: hasValue
                                    ? const LinearGradient(
                                        colors: [_C.gold, _C.goldLt],
                                      )
                                    : null,
                                color: hasValue ? null : _C.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasValue
                                      ? Colors.transparent
                                      : _C.border,
                                ),
                                boxShadow: hasValue
                                    ? [
                                        BoxShadow(
                                          color: _C.gold.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  digit,
                                  style: TextStyle(
                                    color: hasValue ? _C.bg : _C.txt,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Amount input
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _amountControllers[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: hasValue ? _C.goldLt : _C.txt,
                              fontWeight: hasValue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 16,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: '—',
                              hintStyle: TextStyle(
                                color: _C.muted.withOpacity(0.4),
                                fontSize: 18,
                              ),
                              prefixText: hasValue ? '₹ ' : null,
                              prefixStyle: const TextStyle(
                                color: _C.gold,
                                fontWeight: FontWeight.w600,
                              ),
                              filled: true,
                              fillColor: hasValue
                                  ? _C.gold.withOpacity(0.08)
                                  : _C.surface.withOpacity(0.6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: hasValue
                                      ? _C.gold.withOpacity(0.3)
                                      : Colors.transparent,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: _C.gold,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
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
    );
  }

  // ─── Bottom Panel ───────────────────────────────────────────
  Widget _buildBottomPanel() {
    final total = _calculateTotal();
    final sufficient = walletAmount >= total;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: showConfirmation
            ? _buildConfirmPanel(total)
            : _buildSummaryPanel(total, sufficient),
      ),
    );
  }

  Widget _buildSummaryPanel(double total, bool sufficient) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryTile(
                'Total Bid',
                '₹${total.toStringAsFixed(2)}',
                _C.txt,
              ),
            ),
            Container(width: 1, height: 40, color: _C.border),
            Expanded(
              child: _summaryTile(
                'Balance',
                '₹${walletAmount.toStringAsFixed(2)}',
                total > 0 ? (sufficient ? _C.green : _C.red) : _C.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: total > 0 ? _onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.gold,
              disabledBackgroundColor: _C.dim,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: _C.gold.withOpacity(0.4),
            ),
            child: Text(
              total > 0 ? 'Continue  →' : 'Enter amounts to continue',
              style: TextStyle(
                color: total > 0 ? _C.bg : _C.muted,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryTile(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _C.muted,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPanel(double total) {
    return FadeTransition(
      opacity: _confirmAnim,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confirm header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: _C.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Confirm Order',
                style: TextStyle(
                  color: _C.txt,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              children: [
                _confirmRow('Game', widget.gameName),
                const SizedBox(height: 8),
                _confirmRow('Session', selectedSession),
                const SizedBox(height: 8),
                _confirmRow(
                  'Total Amount',
                  '₹${total.toStringAsFixed(2)}',
                  valueColor: _C.gold,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => showConfirmation = false);
                    _confirmCtrl.reverse();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _C.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      color: _C.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.green,
                    disabledBackgroundColor: _C.green.withOpacity(0.5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Place Bids',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value, {Color valueColor = _C.txt}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _C.muted, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
