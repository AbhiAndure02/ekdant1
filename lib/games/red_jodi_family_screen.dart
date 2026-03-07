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

class RedJodiFamilyScreen extends StatefulWidget {
  final String gameName;
  final String gameId;
  final String marketId;
  final String marketName;
  final String closeTimeOpen;
  final String closeTimeClose;

  const RedJodiFamilyScreen({
    super.key,
    required this.gameName,
    required this.gameId,
    required this.marketId,
    required this.marketName,
    required this.closeTimeOpen,
    required this.closeTimeClose,
  });

  @override
  State<RedJodiFamilyScreen> createState() => _RedJodiFamilyScreenState();
}

class _RedJodiFamilyScreenState extends State<RedJodiFamilyScreen>
    with SingleTickerProviderStateMixin {
  // Only Open session - no Close
  bool showConfirmation = false;
  bool _isSubmitting = false;
  double walletAmount = 0.0;
  User? currentUser;
  bool isOpenSessionDisabled = false;

  String? selectedRedJodiFamily;

  // Single shared amount for ALL jodis in family
  final TextEditingController _amountController = TextEditingController();
  double _perJodiAmount = 0;

  // Search / filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _confirmCtrl;
  late Animation<double> _confirmAnim;

  late final BidService _bidService;
  late final AuthService _authService;
  late final TransactionService _transactionService;
  late final WalletService _walletService;

  // ─── Red Jodi Family Data ──────────────────────────────────────
  // Format: Family Header -> List of Jodi digits
  final Map<String, List<String>> redJodiFamily = {
    '00': ['00', '55', '05', '50'],
    '11': ['11', '66', '16', '61'],
    '22': ['22', '77', '27', '72'],
    '33': ['33', '88', '38', '83'],
    '44': ['44', '99', '49', '94'],
  };

  // ─── Lifecycle ─────────────────────────────────────────────
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

    _amountController.addListener(() {
      setState(() {
        _perJodiAmount = double.tryParse(_amountController.text.trim()) ?? 0;
      });
    });

    _loadUserData();
    _checkOpenSession();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ─── Computed helpers ──────────────────────────────────────
  int get _childCount => selectedRedJodiFamily != null
      ? redJodiFamily[selectedRedJodiFamily]!.length
      : 0;

  double get _totalAmount => _perJodiAmount * _childCount;

  // ─── Session check ─────────────────────────────────────────
  void _checkOpenSession() {
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
    });
  }

  // ─── Data loading ──────────────────────────────────────────
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

  Future<void> _createTransaction(double amount) async {
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
        pana: selectedRedJodiFamily ?? '',
        digit: '',
      ),
    );
  }

  // ─── Filtered red jodi family keys ────────────────────────────────────
  List<String> get _filteredKeys {
    if (_searchQuery.isEmpty) return redJodiFamily.keys.toList();
    return redJodiFamily.keys.where((k) => k.contains(_searchQuery)).toList();
  }

  // ─── Actions ───────────────────────────────────────────────
  void _onContinue() {
    if (selectedRedJodiFamily == null) {
      _snack('Please select a red jodi family', isError: true);
      return;
    }
    if (_perJodiAmount <= 0) {
      _snack('Enter a bid amount', isError: true);
      return;
    }
    if (_perJodiAmount < MINIMUM_BID_AMOUNT) {
      _snack('Minimum bid per jodi is ₹$MINIMUM_BID_AMOUNT', isError: true);
      return;
    }
    if (walletAmount < _totalAmount) {
      _snack('Insufficient wallet balance', isError: true);
      return;
    }
    if (isOpenSessionDisabled) {
      _snack('Open session is closed', isError: true);
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
      if (selectedRedJodiFamily == null) {
        throw Exception('No red jodi family selected');
      }

      if (_perJodiAmount <= 0) throw Exception('Invalid bid amount');
      if (_perJodiAmount < MINIMUM_BID_AMOUNT) {
        throw Exception('Minimum bid per jodi is ₹$MINIMUM_BID_AMOUNT');
      }
      if ((double.tryParse(user.walletAmount ?? '0') ?? 0) < _totalAmount) {
        throw Exception('Insufficient balance');
      }
      if (isOpenSessionDisabled) {
        throw Exception('Open session is closed');
      }

      final amtStr = _perJodiAmount.toStringAsFixed(2);

      final futures = redJodiFamily[selectedRedJodiFamily]!
          .map(
            (child) => _bidService.createBid(
              BidRequest(
                marketId: widget.marketId,
                userId: user.id,
                gameId: widget.gameId,
                name: user.name,
                mobile: user.number,
                market: widget.marketName,
                session: 'Open', // Always Open
                digit: child,
                pana: '',
                points: amtStr,
                date: DateTime.now(),
                id: '',
                win: '',
              ),
            ),
          )
          .toList();

      await Future.wait(futures);
      await _createTransaction(_totalAmount);
      await _updateUserWallet(_totalAmount);

      _snack(
        'Bids placed! Red Family $selectedRedJodiFamily · $_childCount × ₹${_perJodiAmount.toStringAsFixed(0)} = ₹${_totalAmount.toStringAsFixed(2)}',
        isError: false,
      );

      await _loadUserData();
      _amountController.clear();
      setState(() {
        showConfirmation = false;
        selectedRedJodiFamily = null;
        _perJodiAmount = 0;
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
      bottomNavigationBar: selectedRedJodiFamily != null
          ? _buildBottomPanel()
          : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildOpenSessionInfo()),
          SliverToBoxAdapter(child: _buildRedJodiFamilySelector()),

          if (selectedRedJodiFamily != null) ...[
            SliverToBoxAdapter(child: _buildAmountInput()),
            SliverToBoxAdapter(child: _buildChildJodiGridHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                delegate: SliverChildBuilderDelegate((_, idx) {
                  final child = redJodiFamily[selectedRedJodiFamily]![idx];
                  final active = _perJodiAmount > 0 && !isOpenSessionDisabled;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(colors: [_C.gold, _C.goldLt])
                          : null,
                      color: active ? null : _C.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? Colors.transparent : _C.border,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: _C.gold.withOpacity(0.22),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        child,
                        style: TextStyle(
                          color: active
                              ? _C.bg
                              : (isOpenSessionDisabled ? _C.muted : _C.txt),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }, childCount: redJodiFamily[selectedRedJodiFamily]!.length),
              ),
            ),
          ] else ...[
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            ),
          ],
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

  // ─── Open Session Info ─────────────────────────────────────
  Widget _buildOpenSessionInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          // Open Session Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            decoration: BoxDecoration(
              gradient: isOpenSessionDisabled
                  ? null
                  : const LinearGradient(colors: [_C.gold, _C.goldLt]),
              color: isOpenSessionDisabled ? _C.dim.withOpacity(0.3) : null,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isOpenSessionDisabled ? _C.dim : Colors.transparent,
              ),
              boxShadow: isOpenSessionDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: _C.gold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOpenSessionDisabled
                      ? Icons.lock_rounded
                      : Icons.access_time_rounded,
                  color: isOpenSessionDisabled ? _C.muted : _C.bg,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isOpenSessionDisabled
                      ? 'Open Session Closed'
                      : 'Open Session • Active',
                  style: TextStyle(
                    color: isOpenSessionDisabled ? _C.muted : _C.bg,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Time info
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isOpenSessionDisabled
                        ? _C.red.withOpacity(0.08)
                        : _C.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOpenSessionDisabled
                          ? _C.red.withOpacity(0.2)
                          : _C.green.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: isOpenSessionDisabled ? _C.red : _C.green,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Close Time: ${widget.closeTimeOpen}',
                        style: TextStyle(
                          color: isOpenSessionDisabled ? _C.red : _C.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Red Jodi Family Selector ─────────────────────────────────────────
  Widget _buildRedJodiFamilySelector() {
    final keys = _filteredKeys;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
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
                'Select Red Jodi Family',
                style: TextStyle(
                  color: _C.txt,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedRedJodiFamily != null) ...[
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
                    'Selected: $selectedRedJodiFamily',
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
          const SizedBox(height: 10),

          // Search field
          TextField(
            controller: _searchController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: _C.txt, fontSize: 14),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search red jodi family (e.g. 00, 11)',
              hintStyle: TextStyle(
                color: _C.muted.withOpacity(0.5),
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.search, color: _C.muted, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close, color: _C.muted, size: 16),
                    )
                  : null,
              filled: true,
              fillColor: _C.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _C.gold, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Horizontally scrollable red jodi family chips — 2 rows
          SizedBox(
            height: 108,
            child: keys.isEmpty
                ? Center(
                    child: Text(
                      'No red jodi family found for "$_searchQuery"',
                      style: const TextStyle(color: _C.muted, fontSize: 13),
                    ),
                  )
                : GridView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.45,
                        ),
                    itemCount: keys.length,
                    itemBuilder: (_, i) {
                      final family = keys[i];
                      final sel = selectedRedJodiFamily == family;
                      final count = redJodiFamily[family]!.length;
                      return GestureDetector(
                        onTap: isOpenSessionDisabled
                            ? null
                            : () => setState(() {
                                selectedRedJodiFamily = family;
                                showConfirmation = false;
                                _confirmCtrl.reverse();
                              }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: sel
                                ? const LinearGradient(
                                    colors: [_C.gold, _C.goldLt],
                                  )
                                : null,
                            color: sel ? null : _C.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel ? Colors.transparent : _C.border,
                            ),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color: _C.gold.withOpacity(0.35),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                family,
                                style: TextStyle(
                                  color: sel
                                      ? _C.bg
                                      : (isOpenSessionDisabled
                                            ? _C.muted
                                            : _C.txt),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count jodis',
                                style: TextStyle(
                                  color: sel
                                      ? _C.bg.withOpacity(0.65)
                                      : (isOpenSessionDisabled
                                            ? _C.muted.withOpacity(0.5)
                                            : _C.muted),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (isOpenSessionDisabled)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _C.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: _C.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Open session is closed. Cannot place bids.',
                        style: TextStyle(color: _C.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Single Amount Input ───────────────────────────────────
  Widget _buildAmountInput() {
    final hasAmt = _perJodiAmount > 0;
    final isDisabled = isOpenSessionDisabled;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasAmt && !isDisabled ? _C.gold.withOpacity(0.4) : _C.border,
        ),
        boxShadow: hasAmt && !isDisabled
            ? [BoxShadow(color: _C.gold.withOpacity(0.07), blurRadius: 14)]
            : null,
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
                'Bid Amount Per Jodi',
                style: TextStyle(
                  color: _C.txt,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (hasAmt && !isDisabled)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _C.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    '₹${_perJodiAmount.toStringAsFixed(0)} × $_childCount = ₹${_totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: _C.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            enabled: !isOpenSessionDisabled,
            style: TextStyle(
              color: hasAmt && !isDisabled ? _C.goldLt : _C.txt,
              fontWeight: hasAmt && !isDisabled
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: isDisabled ? 'Session closed' : 'Enter amount...',
              hintStyle: TextStyle(
                color: isDisabled ? _C.muted : _C.muted.withOpacity(0.4),
                fontSize: 15,
              ),
              prefixText: hasAmt && !isDisabled ? '₹  ' : null,
              prefixStyle: const TextStyle(
                color: _C.gold,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              filled: true,
              fillColor: isDisabled
                  ? _C.dim.withOpacity(0.3)
                  : (hasAmt
                        ? _C.gold.withOpacity(0.06)
                        : _C.surface.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasAmt && !isDisabled
                      ? _C.gold.withOpacity(0.35)
                      : Colors.transparent,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _C.gold, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),

          if (hasAmt && !isDisabled) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: _C.muted,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '₹${_perJodiAmount.toStringAsFixed(0)} will be placed on all $_childCount jodis in red family $selectedRedJodiFamily',
                      style: const TextStyle(color: _C.muted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Child Jodi Grid Header ────────────────────────────────
  Widget _buildChildJodiGridHeader() {
    final active = _perJodiAmount > 0 && !isOpenSessionDisabled;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        gradient: LinearGradient(
          colors: [_C.gold.withOpacity(0.10), _C.gold.withOpacity(0.03)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.color_lens_rounded, color: _C.gold, size: 15),
          const SizedBox(width: 8),
          Text(
            'Red Family $selectedRedJodiFamily — $_childCount Jodis',
            style: const TextStyle(
              color: _C.gold,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: active ? _C.green.withOpacity(0.1) : _C.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? _C.green.withOpacity(0.3) : _C.border,
              ),
            ),
            child: Text(
              active
                  ? '₹${_perJodiAmount.toStringAsFixed(0)} each'
                  : isOpenSessionDisabled
                  ? 'Session closed'
                  : 'Enter amount above',
              style: TextStyle(
                color: active
                    ? _C.green
                    : (isOpenSessionDisabled ? _C.red : _C.muted),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
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
              Icons.color_lens_rounded,
              color: _C.gold,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a red jodi family to place bids',
            style: TextStyle(color: _C.muted, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            isOpenSessionDisabled
                ? 'Open session is closed'
                : 'Search or scroll to find your red jodi family',
            style: TextStyle(
              color: isOpenSessionDisabled ? _C.red : _C.muted.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Panel ─────────────────────────
  Widget _buildBottomPanel() {
    final total = _totalAmount;
    final ok = walletAmount >= total && !isOpenSessionDisabled;
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        border: Border(top: BorderSide(color: _C.border.withOpacity(0.6))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: showConfirmation
          ? _buildConfirmPanel(total)
          : _buildSummaryPanel(total, ok),
    );
  }

  Widget _buildSummaryPanel(double total, bool ok) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _tile(
                'Per Jodi',
                _perJodiAmount > 0
                    ? '₹${_perJodiAmount.toStringAsFixed(0)}'
                    : '—',
                _C.txt,
              ),
            ),
            Container(width: 1, height: 40, color: _C.border),
            Expanded(child: _tile('× Jodis', '$_childCount', _C.muted)),
            Container(width: 1, height: 40, color: _C.border),
            Expanded(
              child: _tile(
                'Total',
                total > 0 ? '₹${total.toStringAsFixed(0)}' : '—',
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
            onPressed: (total > 0 && !isOpenSessionDisabled)
                ? _onContinue
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.gold,
              disabledBackgroundColor: _C.dim,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isOpenSessionDisabled
                  ? 'Session Closed'
                  : (total > 0 ? 'Continue  →' : 'Enter amount to continue'),
              style: TextStyle(
                color: (total > 0 && !isOpenSessionDisabled) ? _C.bg : _C.muted,
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
                _row('Session', 'Open'),
                const SizedBox(height: 7),
                _row('Red Jodi Family', selectedRedJodiFamily ?? '—'),
                const SizedBox(height: 7),
                _row('Per Jodi', '₹${_perJodiAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 7),
                _row('Jodi Count', '$_childCount jodis'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: _C.border, height: 1),
                ),
                _row(
                  '₹${_perJodiAmount.toStringAsFixed(0)} × $_childCount',
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
