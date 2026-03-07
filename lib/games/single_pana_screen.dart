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

class SinglePanaScreen extends StatefulWidget {
  final String gameName;
  final String gameId;
  final String marketId;
  final String marketName;
  final String closeTimeOpen;
  final String closeTimeClose;

  const SinglePanaScreen({
    super.key,
    required this.gameName,
    required this.gameId,
    required this.marketId,
    required this.marketName,
    required this.closeTimeOpen,
    required this.closeTimeClose,
  });

  @override
  State<SinglePanaScreen> createState() => _SinglePanaScreenState();
}

class _SinglePanaScreenState extends State<SinglePanaScreen>
    with SingleTickerProviderStateMixin {
  String selectedSession = 'Open';
  String? selectedDigit;
  bool showConfirmation = false;
  bool _isSubmitting = false;
  double walletAmount = 0.0;
  User? currentUser;
  bool isOpenSessionDisabled = false;
  bool isCloseSessionDisabled = false;

  late AnimationController _confirmCtrl;
  late Animation<double> _confirmAnim;

  late final BidService _bidService;
  late final AuthService _authService;
  late final TransactionService _transactionService;
  late final WalletService _walletService;

  final Map<String, List<String>> panaCombinations = GameData.panaCombinations;

  final Map<String, TextEditingController> amountControllers = {};

  // ─── lifecycle ─────────────────────────────────────────────
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

    for (final combos in panaCombinations.values) {
      for (final combo in combos) {
        amountControllers[combo] = TextEditingController();
      }
    }

    _loadUserData();
    _checkSessions();
  }

  @override
  void dispose() {
    for (final c in amountControllers.values) {
      c.dispose();
    }
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _checkSessions() {
    final now = TimeOfDay.now();
    bool past(String t) {
      final parts = t.split(':');
      final ct = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      return now.hour > ct.hour ||
          (now.hour == ct.hour && now.minute >= ct.minute);
    }

    setState(() {
      isOpenSessionDisabled = past(widget.closeTimeOpen);
      isCloseSessionDisabled = past(widget.closeTimeClose);
      if (isOpenSessionDisabled &&
          selectedSession == 'Open' &&
          !isCloseSessionDisabled) {
        selectedSession = 'Close';
      }
    });
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
    final resp = await http.put(
      Uri.parse('https://api.ekadantaa.in/api/user/${currentUser!.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _authService.getToken()}',
      },
      body: json.encode(updated.toJson()),
    );
    if (resp.statusCode == 200) {
      setState(() => walletAmount -= amount);
      await _authService.refreshUserData();
    } else {
      throw Exception('Failed to update wallet: ${resp.statusCode}');
    }
  }

  Future<void> _createTransaction(double amount, String pana) async {
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
        pana: pana,
        digit: '',
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    if (selectedDigit != null) {
      for (final pana in panaCombinations[selectedDigit]!) {
        total += double.tryParse(amountControllers[pana]!.text) ?? 0;
      }
    }
    return total;
  }

  void _onContinue() {
    final total = _calculateTotal();
    if (total <= 0) {
      _snack('Enter at least one bid amount', isError: true);
      return;
    }
    if (total < MINIMUM_BID_AMOUNT) {
      _snack('Minimum bid is ₹$MINIMUM_BID_AMOUNT', isError: true);
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
        throw Exception('Minimum bid is ₹$MINIMUM_BID_AMOUNT');
      }
      if ((double.tryParse(user.walletAmount ?? '0') ?? 0) < total) {
        throw Exception('Insufficient balance');
      }
      if ((selectedSession == 'Open' && isOpenSessionDisabled) ||
          (selectedSession == 'Close' && isCloseSessionDisabled)) {
        throw Exception('$selectedSession session is closed');
      }

      final futures = <Future<void>>[];
      for (final pana in panaCombinations[selectedDigit]!) {
        final amt = amountControllers[pana]!.text;
        if (amt.isNotEmpty && double.tryParse(amt) != null) {
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
                digit: '',
                pana: pana,
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

      _snack('Bids placed! Digit $selectedDigit · ₹$total', isError: false);
      for (final pana in panaCombinations[selectedDigit]!) {
        amountControllers[pana]!.clear();
      }
      await _loadUserData();
      setState(() {
        showConfirmation = false;
        selectedDigit = null;
        _isSubmitting = false;
      });
      _confirmCtrl.reverse();
    } catch (e) {
      setState(() => _isSubmitting = false);
      _snack('Failed: $e', isError: true);
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
          _buildSessionAndTimes(),
          _buildDigitPicker(),
          if (selectedDigit != null) ...[
            Expanded(child: _buildPanaTable()),
            _buildBottomPanel(),
          ] else
            Expanded(child: _buildEmptyState()),
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

  // ─── Session + Times ───────────────────────────────────────
  Widget _buildSessionAndTimes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              _sessionBtn('Open', isOpenSessionDisabled),
              const SizedBox(width: 12),
              _sessionBtn('Close', isCloseSessionDisabled),
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
              Expanded(
                child: _timeBadge(
                  'Close',
                  widget.closeTimeClose,
                  isCloseSessionDisabled,
                ),
              ),
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
            '$label: $time',
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

  // ─── Digit Picker ──────────────────────────────────────────
  Widget _buildDigitPicker() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_C.gold, _C.goldLt],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Select Digit',
                style: TextStyle(
                  color: _C.txt,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedDigit != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.gold, _C.goldLt],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Selected: $selectedDigit',
                    style: const TextStyle(
                      color: _C.bg,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (i) {
              final digit = i == 9 ? '0' : '${i + 1}';
              final selected = selectedDigit == digit;
              return GestureDetector(
                onTap: () => setState(() {
                  selectedDigit = digit;
                  showConfirmation = false;
                  _confirmCtrl.reverse();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(colors: [_C.gold, _C.goldLt])
                        : null,
                    color: selected ? null : _C.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.transparent : _C.border,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _C.gold.withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      digit,
                      style: TextStyle(
                        color: selected ? _C.bg : _C.txt,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _C.gold.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _C.gold.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: _C.gold,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a digit to place bids',
            style: TextStyle(color: _C.muted, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap any digit above to get started',
            style: TextStyle(color: _C.muted.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── Pana Table ────────────────────────────────────────────
  Widget _buildPanaTable() {
    final combos = panaCombinations[selectedDigit]!;
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
            // Header
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
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'PANA',
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
                itemCount: combos.length,
                separatorBuilder: (_, _) =>
                    Container(height: 1, color: _C.border.withOpacity(0.4)),
                itemBuilder: (_, idx) {
                  final pana = combos[idx];
                  final ctrl = amountControllers[pana]!;
                  final hasVal = ctrl.text.isNotEmpty && ctrl.text != '0';

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
                                '$selectedDigit-$pana',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: hasVal ? _C.bg : _C.txt,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
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
                              hintText: '—',
                              hintStyle: TextStyle(
                                color: _C.muted.withOpacity(0.4),
                                fontSize: 16,
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
          ],
        ),
      ),
    );
  }

  // ─── Bottom Panel ───────────────────────────────────────────
  Widget _buildBottomPanel() {
    final total = _calculateTotal();
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
            ? _buildConfirmPanel(total)
            : _buildSummaryPanel(total, ok),
      ),
    );
  }

  Widget _buildSummaryPanel(double total, bool ok) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _tile('Total Bid', '₹${total.toStringAsFixed(2)}', _C.txt),
            ),
            Container(width: 1, height: 40, color: _C.border),
            Expanded(
              child: _tile(
                'Balance',
                '₹${walletAmount.toStringAsFixed(2)}',
                total > 0 ? (ok ? _C.green : _C.red) : _C.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: total > 0 ? _onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.gold,
              disabledBackgroundColor: _C.dim,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
                _row('Digit', selectedDigit ?? '—'),
                const SizedBox(height: 7),
                _row('Total', '₹${total.toStringAsFixed(2)}', vc: _C.gold),
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
