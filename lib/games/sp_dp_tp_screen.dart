import 'package:ekdant/services/wllet_service.dart';
import 'package:flutter/material.dart';
import 'package:ekdant/models/bid_model.dart';
import 'package:ekdant/models/transaction_model.dart';
import 'package:ekdant/services/auth_service.dart';
import 'package:ekdant/services/bid_service.dart';
import 'package:ekdant/services/transaction_service.dart';

const double MINIMUM_BID_AMOUNT = 5.0;
const String SINGLE_PANA_ID = "686e2008a47a0a55b623f796";
const String DOUBLE_PANA_ID = "686e201ba47a0a55b623f797";
const String TRIPLE_PANA_ID = "686e2036a47a0a55b623f798";

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
  static const purple = Color(0xFF8B5CF6);
  static const txt = Color(0xFFF0F4FF);
  static const muted = Color(0xFF8A9BB5);
  static const dim = Color(0xFF2A3A55);
}

class SpDpTpScreen extends StatefulWidget {
  final String gameName;
  final String gameId;
  final String marketId;
  final String marketName;
  final String closeTimeOpen;

  const SpDpTpScreen({
    super.key,
    required this.gameName,
    required this.gameId,
    required this.marketId,
    required this.marketName,
    required this.closeTimeOpen,
  });

  @override
  State<SpDpTpScreen> createState() => _SpDpTpScreenState();
}

class _SpDpTpScreenState extends State<SpDpTpScreen>
    with SingleTickerProviderStateMixin {
  String selectedSession = 'Open';
  String selectedDigit = '1';
  bool showConfirmation = false;
  bool _isSubmitting = false;
  double walletAmount = 0.0;
  bool isOpenSessionDisabled = false;
  User? currentUser;

  // Which game types are active
  Map<String, bool> selectedGameTypes = {'SP': true, 'DP': false, 'TP': false};

  // bid key = "SP_127" → amount
  Map<String, double> bids = {};

  // "Apply to all" controllers
  final Map<String, TextEditingController> applyAllControllers = {
    'SP': TextEditingController(),
    'DP': TextEditingController(),
    'TP': TextEditingController(),
  };

  // Per-row controllers (rebuilt on digit/type change)
  final Map<String, TextEditingController> _rowControllers = {};

  late AnimationController _confirmCtrl;
  late Animation<double> _confirmAnim;

  late final BidService _bidService;
  late final AuthService _authService;
  late final TransactionService _transactionService;
  late final WalletService _walletService;

  // Game type accent colours
  static const Map<String, Color> _typeColor = {
    'SP': _C.green,
    'DP': _C.blue,
    'TP': _C.purple,
  };

  // ─── pana data ────────────────────────────────────────────
  static const Map<String, List<String>> singlePana = {
    '0': [
      '127',
      '136',
      '145',
      '190',
      '235',
      '280',
      '370',
      '389',
      '460',
      '479',
      '569',
      '578',
    ],
    '1': [
      '128',
      '137',
      '146',
      '236',
      '245',
      '290',
      '380',
      '470',
      '489',
      '560',
      '579',
      '678',
    ],
    '2': [
      '129',
      '138',
      '147',
      '156',
      '237',
      '246',
      '345',
      '390',
      '480',
      '570',
      '589',
      '679',
    ],
    '3': [
      '120',
      '139',
      '148',
      '157',
      '238',
      '247',
      '256',
      '346',
      '490',
      '580',
      '670',
      '689',
    ],
    '4': [
      '130',
      '149',
      '158',
      '167',
      '239',
      '248',
      '257',
      '347',
      '356',
      '590',
      '680',
      '789',
    ],
    '5': [
      '140',
      '159',
      '168',
      '230',
      '249',
      '258',
      '267',
      '348',
      '357',
      '456',
      '690',
      '780',
    ],
    '6': [
      '123',
      '150',
      '169',
      '178',
      '240',
      '259',
      '268',
      '349',
      '358',
      '367',
      '457',
      '790',
    ],
    '7': [
      '124',
      '160',
      '179',
      '250',
      '269',
      '278',
      '340',
      '359',
      '368',
      '458',
      '467',
      '890',
    ],
    '8': [
      '125',
      '134',
      '170',
      '189',
      '260',
      '279',
      '350',
      '369',
      '378',
      '459',
      '468',
      '567',
    ],
    '9': [
      '126',
      '135',
      '180',
      '234',
      '270',
      '289',
      '360',
      '379',
      '450',
      '469',
      '478',
      '568',
    ],
  };
  static const Map<String, List<String>> doublePana = {
    '0': ['118', '226', '244', '299', '334', '488', '550', '668', '677'],
    '1': ['100', '119', '155', '227', '335', '344', '399', '588', '669'],
    '2': ['110', '200', '228', '255', '336', '499', '660', '688', '778'],
    '3': ['166', '229', '300', '337', '355', '445', '599', '779', '788'],
    '4': ['112', '220', '266', '338', '400', '446', '455', '699', '770'],
    '5': ['113', '122', '177', '339', '366', '447', '500', '799', '889'],
    '6': ['114', '227', '330', '448', '466', '556', '600', '880', '899'],
    '7': ['115', '133', '188', '223', '337', '449', '557', '556', '700'],
    '8': ['116', '224', '233', '288', '440', '477', '558', '800', '990'],
    '9': ['117', '144', '199', '225', '388', '559', '577', '667', '900'],
  };
  static const Map<String, List<String>> triplePana = {
    '0': ['000'],
    '1': ['777'],
    '2': ['444'],
    '3': ['111'],
    '4': ['888'],
    '5': ['555'],
    '6': ['222'],
    '7': ['999'],
    '8': ['666'],
    '9': ['333'],
  };

  Map<String, List<String>> get _combosForType => {
    'SP': singlePana[selectedDigit] ?? [],
    'DP': doublePana[selectedDigit] ?? [],
    'TP': triplePana[selectedDigit] ?? [],
  };

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

    _loadUserData();
    _checkSession();
    _rebuildRowControllers();
  }

  @override
  void dispose() {
    for (final c in applyAllControllers.values) {
      c.dispose();
    }
    for (final c in _rowControllers.values) {
      c.dispose();
    }
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _rebuildRowControllers() {
    for (final c in _rowControllers.values) {
      c.dispose();
    }
    _rowControllers.clear();
    for (final type in ['SP', 'DP', 'TP']) {
      for (final pana in _combosForType[type]!) {
        final key = '${type}_$pana';
        final existing = bids[key] ?? 0;
        _rowControllers[key] = TextEditingController(
          text: existing > 0 ? existing.toStringAsFixed(0) : '',
        );
      }
    }
  }

  void _checkSession() {
    try {
      final parts = widget.closeTimeOpen.split(':');
      final now = DateTime.now();
      final close = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (now.isAfter(close)) {
        setState(() {
          isOpenSessionDisabled = true;
          selectedSession = 'Close';
        });
      }
    } catch (e) {
      debugPrint('session check: $e');
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

  void _applyToAll(String type, double amount) {
    setState(() {
      for (final pana in _combosForType[type]!) {
        final key = '${type}_$pana';
        if (amount > 0) {
          bids[key] = amount;
          _rowControllers[key]?.text = amount.toStringAsFixed(0);
        } else {
          bids.remove(key);
          _rowControllers[key]?.clear();
        }
      }
    });
  }

  void _clearType(String type) {
    setState(() {
      for (final pana in _combosForType[type]!) {
        final key = '${type}_$pana';
        bids.remove(key);
        _rowControllers[key]?.clear();
      }
      applyAllControllers[type]?.clear();
    });
  }

  double _calculateTotal() => bids.values.fold(0, (s, v) => s + v);

  void _onContinue() {
    final total = _calculateTotal();
    if (total <= 0) {
      _snack('Enter at least one bid', isError: true);
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
    if (currentUser == null) {
      _snack('User not logged in', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final total = _calculateTotal();
      if (total <= 0) throw Exception('Invalid amount');
      if (total < MINIMUM_BID_AMOUNT) {
        throw Exception('Minimum bid is ₹$MINIMUM_BID_AMOUNT');
      }
      if (walletAmount < total) throw Exception('Insufficient balance');

      for (final entry in bids.entries) {
        final parts = entry.key.split('_');
        await _bidService.createBid(
          BidRequest(
            marketId: widget.marketId,
            userId: currentUser!.id,
            gameId: widget.gameId,
            name: currentUser!.name,
            mobile: currentUser!.number,
            market: widget.marketName,
            session: selectedSession,
            digit: selectedDigit,
            pana: parts[1],
            points: entry.value.toString(),
            date: DateTime.now(),
            id: '',
            win: '',
          ),
        );
      }

      await _transactionService.createTransaction(
        TransactionModel(
          id: '',
          userId: currentUser!.id,
          type: 'debit',
          date: DateTime.now().toIso8601String(),
          amount: total.toStringAsFixed(2),
        ),
      );

      await _walletService.updateWallet(currentUser!.id, walletAmount - total);

      _snack('Bids placed! ₹$total', isError: false);
      setState(() {
        bids.clear();
        for (final c in applyAllControllers.values) {
          c.clear();
        }
        for (final c in _rowControllers.values) {
          c.clear();
        }
        walletAmount -= total;
        showConfirmation = false;
        _isSubmitting = false;
      });
      _confirmCtrl.reverse();
      await _loadUserData();
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
          _buildControls(),
          Expanded(child: _buildTables()),
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

  // ─── Controls: session + game types + digit ────────────────
  Widget _buildControls() {
    return Container(
      color: _C.card,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          // Session
          Row(
            children: [
              _sessionBtn('Open', isOpenSessionDisabled),
              const SizedBox(width: 12),
              _sessionBtn('Close', false),
            ],
          ),
          const SizedBox(height: 14),

          // Game types + digit row
          Row(
            children: [
              // SP / DP / TP chips
              ..._typeColor.keys.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _gameTypeChip(t),
                ),
              ),
              const Spacer(),
              // Digit picker
              _digitDropdown(),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [_C.gold, _C.goldLt])
                : null,
            color: disabled
                ? _C.dim.withOpacity(0.3)
                : (!selected ? _C.surface : null),
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
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameTypeChip(String type) {
    final selected = selectedGameTypes[type] == true;
    final color = _typeColor[type]!;
    return GestureDetector(
      onTap: () => setState(() {
        selectedGameTypes[type] = !selected;
        showConfirmation = false;
        _confirmCtrl.reverse();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : _C.border),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8)]
              : null,
        ),
        child: Text(
          type,
          style: TextStyle(
            color: selected ? color : _C.muted,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _digitDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDigit,
          dropdownColor: _C.card,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _C.muted,
            size: 18,
          ),
          style: const TextStyle(
            color: _C.txt,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          items: List.generate(10, (i) {
            final d = i.toString();
            return DropdownMenuItem(value: d, child: Text('Digit  $d'));
          }),
          onChanged: (v) {
            setState(() {
              selectedDigit = v!;
              bids.clear();
              for (final c in applyAllControllers.values) {
                c.clear();
              }
              showConfirmation = false;
              _confirmCtrl.reverse();
              _rebuildRowControllers();
            });
          },
        ),
      ),
    );
  }

  // ─── Tables ────────────────────────────────────────────────
  Widget _buildTables() {
    final active = selectedGameTypes.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    if (active.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _C.gold.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _C.gold.withOpacity(0.2)),
              ),
              child: const Icon(Icons.tune_rounded, color: _C.gold, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select a game type above',
              style: TextStyle(color: _C.muted, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      children: active.map((t) => _buildTypeSection(t)).toList(),
    );
  }

  Widget _buildTypeSection(String type) {
    final combos = _combosForType[type]!;
    final color = _typeColor[type]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$type Pana — Digit $selectedDigit',
                  style: const TextStyle(
                    color: _C.txt,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),

                // Apply-all field
                SizedBox(
                  width: 70,
                  height: 34,
                  child: TextField(
                    controller: applyAllControllers[type],
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: _C.txt, fontSize: 13),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'All',
                      hintStyle: TextStyle(
                        color: _C.muted.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: _C.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide(color: color, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _iconBtn(Icons.check_rounded, color, () {
                  final amt =
                      double.tryParse(applyAllControllers[type]!.text) ?? 0;
                  _applyToAll(type, amt);
                }),
                _iconBtn(Icons.close_rounded, _C.red, () => _clearType(type)),
              ],
            ),
          ),

          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _C.surface.withOpacity(0.6),
              border: Border(
                top: BorderSide(color: _C.border),
                bottom: BorderSide(color: _C.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'PANA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
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
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),

          // Rows
          ...combos.asMap().entries.map(
            (e) => _buildRow(type, e.value, color, e.key == combos.length - 1),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String type, String pana, Color color, bool isLast) {
    final key = '${type}_$pana';
    final hasVal = (bids[key] ?? 0) > 0;

    return Container(
      decoration: BoxDecoration(
        color: hasVal ? color.withOpacity(0.04) : Colors.transparent,
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: _C.border.withOpacity(0.4))),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: [
          // Pana badge
          Expanded(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: hasVal
                      ? LinearGradient(colors: [color, color.withOpacity(0.7)])
                      : null,
                  color: hasVal ? null : _C.surface,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: hasVal ? Colors.transparent : _C.border,
                  ),
                  boxShadow: hasVal
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  pana,
                  style: TextStyle(
                    color: hasVal ? Colors.white : _C.txt,
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
              controller: _rowControllers[key],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: hasVal ? _C.goldLt : _C.txt,
                fontWeight: hasVal ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
              onChanged: (v) {
                final amt = double.tryParse(v) ?? 0;
                setState(() {
                  if (amt > 0) {
                    bids[key] = amt;
                  } else {
                    bids.remove(key);
                  }
                });
              },
              decoration: InputDecoration(
                hintText: '—',
                hintStyle: TextStyle(
                  color: _C.muted.withOpacity(0.4),
                  fontSize: 16,
                ),
                prefixText: hasVal ? '₹ ' : null,
                prefixStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: hasVal
                    ? color.withOpacity(0.08)
                    : _C.surface.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: hasVal ? color.withOpacity(0.3) : Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // Delete
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                bids.remove(key);
                _rowControllers[key]?.clear();
              });
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: hasVal ? _C.red.withOpacity(0.1) : _C.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close_rounded,
                color: hasVal ? _C.red : _C.muted.withOpacity(0.4),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 16),
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
            ? _buildConfirm(total)
            : _buildSummary(total, ok),
      ),
    );
  }

  Widget _buildSummary(double total, bool ok) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _tile('Total Bids', '${bids.length}', _C.muted)),
            Container(width: 1, height: 40, color: _C.border),
            Expanded(
              child: _tile(
                'Total Amount',
                '₹${total.toStringAsFixed(2)}',
                _C.txt,
              ),
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
            fontSize: 10,
            letterSpacing: 0.5,
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

  Widget _buildConfirm(double total) {
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
                _row('Market', widget.marketName),
                const SizedBox(height: 7),
                _row('Session', selectedSession),
                const SizedBox(height: 7),
                _row('Digit', selectedDigit),
                const SizedBox(height: 7),
                _row('Total Bids', '${bids.length}'),
                const SizedBox(height: 7),
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
