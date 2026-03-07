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
  static const blue = Color(0xFF3D8BF8);
  static const txt = Color(0xFFF0F4FF);
  static const muted = Color(0xFF8A9BB5);
  static const dim = Color(0xFF2A3A55);
}

class TriplePanaScreen extends StatefulWidget {
  final String gameName;
  final String gameId;
  final String marketId;
  final String marketName;
  final String closeTimeOpen;

  const TriplePanaScreen({
    super.key,
    required this.gameName,
    required this.gameId,
    required this.marketId,
    required this.marketName,
    required this.closeTimeOpen,
  });

  @override
  State<TriplePanaScreen> createState() => _TriplePanaScreenState();
}

class _TriplePanaScreenState extends State<TriplePanaScreen>
    with SingleTickerProviderStateMixin {
  String selectedSession = 'Open';
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

  // Use the correct data source for Triple Pana
  final List<String> triplePanaCombinations = GameData.triplePanaCombinations;

  final Map<String, TextEditingController> amountControllers = {};

  @override
  void initState() {
    super.initState();
    _bidService = BidService();
    _authService = AuthService();
    _transactionService = TransactionService();
    _walletService = WalletService();

    _confirmCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _confirmAnim = CurvedAnimation(
      parent: _confirmCtrl,
      curve: Curves.easeOutCubic,
    );

    // Initialize controllers for all triple pana combinations
    for (var combo in triplePanaCombinations) {
      amountControllers[combo] = TextEditingController();
    }

    _loadUserData();
    _checkSessionAvailability();
  }

  @override
  void dispose() {
    for (var controller in amountControllers.values) {
      controller.dispose();
    }
    _confirmCtrl.dispose();
    super.dispose();
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
      setState(() {
        isOpenSessionDisabled = false;
      });
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
        setState(() {
          walletAmount -= amount;
        });
        await _authService.refreshUserData();
      } else {
        throw Exception('Failed to update wallet: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update wallet: $e');
    }
  }

  Future<void> _createTransaction(double amount, String pana) async {
    if (currentUser == null) return;

    final transaction = TransactionModel(
      id: '',
      userId: currentUser!.id,
      type: 'debit',
      date: DateTime.now().toIso8601String(),
      amount: amount.toStringAsFixed(2),
      marketName: widget.gameName,
      gameName: widget.gameName,
      pana: pana,
      digit: "",
    );

    try {
      await _transactionService.createTransaction(transaction);
    } catch (e) {
      debugPrint('Failed to create transaction: $e');
      throw Exception('Failed to create transaction');
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (var controller in amountControllers.values) {
      if (controller.text.isNotEmpty) {
        total += double.tryParse(controller.text) ?? 0;
      }
    }
    return total;
  }

  int _getActiveBidsCount() {
    int count = 0;
    for (var controller in amountControllers.values) {
      final value = double.tryParse(controller.text) ?? 0;
      if (value > 0) count++;
    }
    return count;
  }

  void _onContinue() {
    final total = _calculateTotal();
    final activeCount = _getActiveBidsCount();

    if (activeCount == 0) {
      _snack('Enter at least one bid amount', isError: true);
      return;
    }
    if (total < MINIMUM_BID_AMOUNT) {
      _snack('Minimum total bid is ₹$MINIMUM_BID_AMOUNT', isError: true);
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

      final totalAmount = _calculateTotal();
      final activeCount = _getActiveBidsCount();

      if (activeCount == 0) throw Exception('No bids to place');
      if (totalAmount < MINIMUM_BID_AMOUNT) {
        throw Exception('Minimum bid amount is ₹$MINIMUM_BID_AMOUNT');
      }

      final currentWallet = double.tryParse(user.walletAmount ?? '0.0') ?? 0.0;
      if (currentWallet < totalAmount) {
        throw Exception('Insufficient wallet balance');
      }

      List<Future<void>> bidFutures = [];
      for (var pana in triplePanaCombinations) {
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
              digit: "",
              pana: pana,
              points: amountText,
              date: DateTime.now(),
              id: '',
              win: '',
            );
            bidFutures.add(_bidService.createBid(bidRequest));
            bidFutures.add(_createTransaction(amount, pana));
          }
        }
      }

      await Future.wait(bidFutures);
      await _updateUserWallet(totalAmount);

      _snack(
        '✅ $activeCount bids placed! Total: ₹$totalAmount',
        isError: false,
      );

      for (var controller in amountControllers.values) {
        controller.clear();
      }

      await _loadUserData();

      setState(() {
        showConfirmation = false;
        _isSubmitting = false;
      });
      _confirmCtrl.reverse();
    } catch (e) {
      setState(() => _isSubmitting = false);
      _snack('Failed: $e', isError: true);
      debugPrint('Error placing bids: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSessionAndTime(),
          Expanded(child: _buildPanaTable()),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────
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

  // ─── Session + Time ────────────────────────────────────────
  Widget _buildSessionAndTime() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              _sessionBtn('Open', isOpenSessionDisabled),
              const SizedBox(width: 12),
              _sessionBtn('Close', false),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _timeBadge(
                  'Open',
                  widget.closeTimeOpen,
                  isOpenSessionDisabled,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _timeBadge('Close', 'N/A', false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sessionBtn(String session, bool disabled) {
    final selected = selectedSession == session;
    return Expanded(
      child: GestureDetector(
        onTap: disabled
            ? null
            : () => setState(() => selectedSession = session),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [_C.gold, _C.goldLt])
                : null,
            color: disabled
                ? _C.dim.withOpacity(0.3)
                : (!selected ? _C.card : null),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (disabled ? _C.dim : _C.border),
            ),
            boxShadow: selected
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
                color: selected ? _C.bg : (disabled ? _C.muted : _C.txt),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeBadge(String label, String time, bool closed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: closed ? _C.red.withOpacity(0.08) : _C.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: closed ? _C.red.withOpacity(0.2) : _C.green.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            closed ? Icons.lock_rounded : Icons.access_time_rounded,
            color: closed ? _C.red : _C.green,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            time == 'N/A' ? label : '$label: $time',
            style: TextStyle(
              color: closed ? _C.red : _C.green,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pana Table ────────────────────────────────────────────
  Widget _buildPanaTable() {
    final activeCount = _getActiveBidsCount();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
            // Header with count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'TRIPLE PANA (${triplePanaCombinations.length})',
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

            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: triplePanaCombinations.length,
                separatorBuilder: (_, _) =>
                    Container(height: 1, color: _C.border.withOpacity(0.4)),
                itemBuilder: (_, idx) {
                  final pana = triplePanaCombinations[idx];
                  final ctrl = amountControllers[pana]!;
                  final value = double.tryParse(ctrl.text) ?? 0;
                  final hasVal = value > 0;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: hasVal
                        ? _C.gold.withOpacity(0.04)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        // Pana badge
                        Expanded(
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: hasVal
                                    ? const LinearGradient(
                                        colors: [_C.gold, _C.goldLt],
                                      )
                                    : null,
                                color: hasVal ? null : _C.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: hasVal
                                      ? Colors.transparent
                                      : _C.border,
                                ),
                                boxShadow: hasVal
                                    ? [
                                        BoxShadow(
                                          color: _C.gold.withOpacity(0.25),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                pana,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: hasVal ? _C.bg : _C.txt,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Amount input
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: hasVal ? _C.goldLt : _C.txt,
                              fontWeight: hasVal
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 15,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(
                                color: _C.muted.withOpacity(0.4),
                                fontSize: 14,
                              ),
                              prefixText: hasVal ? '₹ ' : null,
                              prefixStyle: const TextStyle(
                                color: _C.gold,
                                fontWeight: FontWeight.w600,
                              ),
                              filled: true,
                              fillColor: hasVal
                                  ? _C.gold.withOpacity(0.08)
                                  : _C.surface.withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: hasVal
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
                                vertical: 11,
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

            // Footer with summary
            if (activeCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(color: _C.gold.withOpacity(0.15)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active: $activeCount bids',
                      style: const TextStyle(color: _C.muted, fontSize: 12),
                    ),
                    Text(
                      'Total: ₹${_calculateTotal().toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: _C.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
    final activeCount = _getActiveBidsCount();
    final ok = walletAmount >= total;

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
        padding: const EdgeInsets.all(18),
        child: showConfirmation
            ? _buildConfirmPanel(total, activeCount)
            : _buildSummaryPanel(total, ok, activeCount),
      ),
    );
  }

  Widget _buildSummaryPanel(double total, bool ok, int activeCount) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _tile('Active Bids', '$activeCount', _C.gold)),
            Container(width: 1, height: 40, color: _C.border),
            Expanded(
              child: _tile('Total Bid', '₹${total.toStringAsFixed(2)}', _C.txt),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _tile(
                'Wallet',
                '₹${walletAmount.toStringAsFixed(2)}',
                total > 0 ? (ok ? _C.green : _C.red) : _C.muted,
              ),
            ),
            Container(width: 1, height: 40, color: _C.border),
            Expanded(
              child: _tile(
                'Session',
                selectedSession,
                selectedSession == 'Open' && isOpenSessionDisabled
                    ? _C.red
                    : _C.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: activeCount > 0 ? _onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.gold,
              disabledBackgroundColor: _C.dim,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              activeCount > 0 ? 'Continue  →' : 'Enter amounts to continue',
              style: TextStyle(
                color: activeCount > 0 ? _C.bg : _C.muted,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(String label, String value, Color vc) {
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
            color: vc,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildConfirmPanel(double total, int activeCount) {
    return FadeTransition(
      opacity: _confirmAnim,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              children: [
                _row('Game', widget.gameName),
                const SizedBox(height: 7),
                _row('Session', selectedSession),
                const SizedBox(height: 7),
                _row('Active Bids', '$activeCount'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Divider(color: _C.border, height: 1),
                ),
                _row(
                  'Total Amount',
                  '₹${total.toStringAsFixed(2)}',
                  vc: _C.gold,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
                    padding: const EdgeInsets.symmetric(vertical: 13),
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
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.green,
                    disabledBackgroundColor: _C.green.withOpacity(0.5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
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

  Widget _row(String label, String value, {Color vc = _C.txt}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: _C.muted, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: vc,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
