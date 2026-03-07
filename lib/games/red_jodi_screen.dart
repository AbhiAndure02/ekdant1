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
  static const blue = Color(0xFF3498DB);
  static const purple = Color(0xFF9B59B6);
}

class RedJodiScreen extends StatefulWidget {
  final String gameName;
  final String gameId;
  final String marketId;
  final String marketName;
  final String closeTimeOpen;
  final String closeTimeClose;

  const RedJodiScreen({
    super.key,
    required this.gameName,
    required this.gameId,
    required this.marketId,
    required this.marketName,
    required this.closeTimeOpen,
    required this.closeTimeClose,
  });

  @override
  State<RedJodiScreen> createState() => _RedJodiScreenState();
}

class _RedJodiScreenState extends State<RedJodiScreen>
    with SingleTickerProviderStateMixin {
  bool showConfirmation = false;
  bool _isSubmitting = false;
  double walletAmount = 0.0;
  User? currentUser;
  bool isOpenSessionDisabled = false;

  // Individual selection sets for each array
  final Set<String> _selectedFirst = {};
  final Set<String> _selectedSecond = {};

  final TextEditingController _amountController = TextEditingController();
  double _perJodiAmount = 0;

  late AnimationController _confirmCtrl;
  late Animation<double> _confirmAnim;

  late final BidService _bidService;
  late final AuthService _authService;
  late final TransactionService _transactionService;
  late final WalletService _walletService;

  // ─── Jodi Data ─────────────────────────────────────────────
  final List<String> firstArray = [
    '11',
    '22',
    '33',
    '44',
    '55',
    '66',
    '77',
    '88',
    '99',
    '00',
  ];

  final List<String> secondArray = [
    '16',
    '61',
    '27',
    '72',
    '38',
    '83',
    '49',
    '94',
    '50',
    '05',
  ];

  // ─── Computed ──────────────────────────────────────────────
  Set<String> get _allSelected => {..._selectedFirst, ..._selectedSecond};
  int get _selectedCount => _allSelected.length;
  double get _totalAmount => _perJodiAmount * _selectedCount;
  bool get _hasSelections => _selectedCount > 0;

  bool get _isFirstAllSelected =>
      firstArray.every((j) => _selectedFirst.contains(j));
  bool get _isSecondAllSelected =>
      secondArray.every((j) => _selectedSecond.contains(j));

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
    _confirmCtrl.dispose();
    super.dispose();
  }

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

    setState(() => isOpenSessionDisabled = past(widget.closeTimeOpen));
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
        pana: '',
        digit: '',
      ),
    );
  }

  // ─── Selection Methods ─────────────────────────────────────

  /// Toggle a single jodi in the first array
  void _toggleFirstJodi(String jodi) {
    if (isOpenSessionDisabled) return;
    setState(() {
      if (_selectedFirst.contains(jodi)) {
        _selectedFirst.remove(jodi);
      } else {
        _selectedFirst.add(jodi);
      }
      _resetConfirmation();
    });
  }

  /// Toggle a single jodi in the second array
  void _toggleSecondJodi(String jodi) {
    if (isOpenSessionDisabled) return;
    setState(() {
      if (_selectedSecond.contains(jodi)) {
        _selectedSecond.remove(jodi);
      } else {
        _selectedSecond.add(jodi);
      }
      _resetConfirmation();
    });
  }

  /// Select / deselect all in first array
  void _toggleAllFirst() {
    if (isOpenSessionDisabled) return;
    setState(() {
      if (_isFirstAllSelected) {
        _selectedFirst.clear();
      } else {
        _selectedFirst.addAll(firstArray);
      }
      _resetConfirmation();
    });
  }

  /// Select / deselect all in second array
  void _toggleAllSecond() {
    if (isOpenSessionDisabled) return;
    setState(() {
      if (_isSecondAllSelected) {
        _selectedSecond.clear();
      } else {
        _selectedSecond.addAll(secondArray);
      }
      _resetConfirmation();
    });
  }

  void _clearAll() {
    setState(() {
      _selectedFirst.clear();
      _selectedSecond.clear();
      _resetConfirmation();
    });
  }

  void _resetConfirmation() {
    showConfirmation = false;
    _confirmCtrl.reverse();
  }

  // ─── Actions ───────────────────────────────────────────────
  void _onContinue() {
    if (isOpenSessionDisabled) {
      _snack('Open session is closed', isError: true);
      return;
    }
    if (!_hasSelections) {
      _snack('Please select at least one jodi', isError: true);
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
    setState(() => showConfirmation = true);
    _confirmCtrl.forward(from: 0);
  }

  Future<void> _confirmOrder() async {
    setState(() => _isSubmitting = true);
    try {
      final user = await _authService.getUserData();
      if (user == null) throw Exception('User not logged in');
      if (_perJodiAmount < MINIMUM_BID_AMOUNT) {
        throw Exception('Minimum bid per jodi is ₹$MINIMUM_BID_AMOUNT');
      }
      if ((double.tryParse(user.walletAmount ?? '0') ?? 0) < _totalAmount) {
        throw Exception('Insufficient balance');
      }
      if (isOpenSessionDisabled) throw Exception('Open session is closed');

      final amtStr = _perJodiAmount.toStringAsFixed(2);

      final bidFutures = _allSelected.map(
        (jodi) => _bidService.createBid(
          BidRequest(
            marketId: widget.marketId,
            userId: user.id,
            gameId: widget.gameId,
            name: user.name,
            mobile: user.number,
            market: widget.marketName,
            session: 'Open',
            digit: jodi,
            pana: '',
            points: amtStr,
            date: DateTime.now(),
            id: '',
            win: '',
          ),
        ),
      );

      await Future.wait(bidFutures);
      await _createTransaction(_totalAmount);
      await _updateUserWallet(_totalAmount);

      _snack(
        '$_selectedCount jodis placed × ₹${_perJodiAmount.toStringAsFixed(0)} = ₹${_totalAmount.toStringAsFixed(2)}',
        isError: false,
      );

      await _loadUserData();
      _amountController.clear();
      setState(() {
        showConfirmation = false;
        _selectedFirst.clear();
        _selectedSecond.clear();
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
      bottomNavigationBar: _hasSelections && _perJodiAmount > 0
          ? _buildBottomPanel()
          : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildSessionInfo()),
          SliverToBoxAdapter(child: _buildAmountInput()),
          SliverToBoxAdapter(
            child: _buildArraySection(
              title: '11',
              icon: Icons.looks_one_rounded,
              accentColor: _C.red,
              items: firstArray,
              selected: _selectedFirst,
              isAllSelected: _isFirstAllSelected,
              onToggleAll: _toggleAllFirst,
              onToggleItem: _toggleFirstJodi,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildArraySection(
              title: '16',
              icon: Icons.looks_two_rounded,
              accentColor: _C.blue,
              items: secondArray,
              selected: _selectedSecond,
              isAllSelected: _isSecondAllSelected,
              onToggleAll: _toggleAllSecond,
              onToggleItem: _toggleSecondJodi,
            ),
          ),
          if (_hasSelections)
            SliverToBoxAdapter(child: _buildSelectionSummary()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          if (!_hasSelections)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            ),
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

  // ─── Session Info ──────────────────────────────────────────
  Widget _buildSessionInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
        ],
      ),
    );
  }

  // ─── Amount Input ──────────────────────────────────────────
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
              _accentBar(_C.gold),
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
              if (hasAmt && _hasSelections && !isDisabled)
                Container(
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
                    '₹${_perJodiAmount.toStringAsFixed(0)} × $_selectedCount = ₹${_totalAmount.toStringAsFixed(0)}',
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
            enabled: !isDisabled,
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
        ],
      ),
    );
  }

  // ─── Array Section ─────────────────────────────────────────
  Widget _buildArraySection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<String> items,
    required Set<String> selected,
    required bool isAllSelected,
    required VoidCallback onToggleAll,
    required void Function(String) onToggleItem,
  }) {
    final isDisabled = isOpenSessionDisabled;
    final selectedInThisArray = items.where((j) => selected.contains(j)).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selectedInThisArray > 0
              ? accentColor.withOpacity(0.35)
              : _C.border,
        ),
        boxShadow: selectedInThisArray > 0
            ? [BoxShadow(color: accentColor.withOpacity(0.08), blurRadius: 14)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDisabled ? _C.muted : accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDisabled ? _C.muted : _C.txt,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$selectedInThisArray / ${items.length} selected',
                      style: TextStyle(
                        color: selectedInThisArray > 0 ? accentColor : _C.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Select All toggle
              GestureDetector(
                onTap: isDisabled ? null : onToggleAll,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAllSelected
                        ? accentColor.withOpacity(0.15)
                        : _C.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAllSelected
                          ? accentColor.withOpacity(0.5)
                          : _C.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAllSelected
                            ? Icons.deselect_rounded
                            : Icons.select_all_rounded,
                        size: 13,
                        color: isAllSelected
                            ? accentColor
                            : (isDisabled ? _C.muted : _C.muted),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAllSelected ? 'Deselect All' : 'Select All',
                        style: TextStyle(
                          color: isAllSelected
                              ? accentColor
                              : (isDisabled ? _C.muted : _C.muted),
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

          const SizedBox(height: 14),

          // ── Jodi grid ───────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((jodi) {
              final isSelected = selected.contains(jodi);
              return GestureDetector(
                onTap: isDisabled ? null : () => onToggleItem(jodi),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: (MediaQuery.of(context).size.width - 100) / 5,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withOpacity(0.18)
                        : _C.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : (isDisabled
                                ? _C.border.withOpacity(0.3)
                                : _C.border.withOpacity(0.6)),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: accentColor.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        jodi,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? accentColor
                              : (isDisabled ? _C.muted : _C.txt),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: accentColor,
                            size: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Selection Summary ─────────────────────────────────────
  Widget _buildSelectionSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _C.gold, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: _C.muted, fontSize: 12),
                children: [
                  TextSpan(
                    text: '$_selectedCount',
                    style: const TextStyle(
                      color: _C.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' jodis selected'),
                  if (_selectedFirst.isNotEmpty)
                    TextSpan(
                      text: ' · ${_selectedFirst.length} from First',
                      style: const TextStyle(color: _C.red),
                    ),
                  if (_selectedSecond.isNotEmpty)
                    TextSpan(
                      text: ' · ${_selectedSecond.length} from Second',
                      style: const TextStyle(color: _C.blue),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _C.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.red.withOpacity(0.3)),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: _C.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
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
              Icons.touch_app_rounded,
              color: _C.gold,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap any jodi to select it',
            style: TextStyle(color: _C.muted, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            isOpenSessionDisabled
                ? 'Open session is closed'
                : 'Select from First or Second array',
            style: TextStyle(
              color: isOpenSessionDisabled ? _C.red : _C.muted.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Panel ──────────────────────────────────────────
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
            Expanded(child: _tile('First', '${_selectedFirst.length}', _C.red)),
            Container(width: 1, height: 40, color: _C.border),
            Expanded(
              child: _tile('Second', '${_selectedSecond.length}', _C.blue),
            ),
            Container(width: 1, height: 40, color: _C.border),
            Expanded(child: _tile('Total Jodis', '$_selectedCount', _C.muted)),
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
            fontSize: 10,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: vc,
            fontSize: 15,
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
                _row(
                  'First Array',
                  '${_selectedFirst.length} jodis',
                  vc: _C.red,
                ),
                const SizedBox(height: 7),
                _row(
                  'Second Array',
                  '${_selectedSecond.length} jodis',
                  vc: _C.blue,
                ),
                const SizedBox(height: 7),
                _row('Total Jodis', '$_selectedCount'),
                const SizedBox(height: 7),
                _row('Per Jodi', '₹${_perJodiAmount.toStringAsFixed(2)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: _C.border, height: 1),
                ),
                _row(
                  '₹${_perJodiAmount.toStringAsFixed(0)} × $_selectedCount',
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

  // ─── Helpers ───────────────────────────────────────────────
  Widget _accentBar(Color color) {
    return Container(
      width: 3,
      height: 16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
