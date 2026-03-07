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

class CyclePatti extends StatefulWidget {
  final String gameName;
  final String gameId;
  final String marketId;
  final String marketName;
  final String closeTimeOpen;
  final String closeTimeClose;

  const CyclePatti({
    super.key,
    required this.gameName,
    required this.gameId,
    required this.marketId,
    required this.marketName,
    required this.closeTimeOpen,
    required this.closeTimeClose,
  });

  @override
  State<CyclePatti> createState() => _CyclePattiState();
}

class _CyclePattiState extends State<CyclePatti>
    with SingleTickerProviderStateMixin {
  String selectedSession = 'Open';
  String? selectedPana;
  bool showConfirmation = false;
  bool _isSubmitting = false;
  double walletAmount = 0.0;
  User? currentUser;
  bool isOpenSessionDisabled = false;
  bool isCloseSessionDisabled = false;

  final TextEditingController _amountController = TextEditingController();
  double _perPanaAmount = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _confirmCtrl;
  late Animation<double> _confirmAnim;

  late final BidService _bidService;
  late final AuthService _authService;
  late final TransactionService _transactionService;
  late final WalletService _walletService;

  // ─── Cycle Patti Data ──────────────────────────────────────
  final Map<String, List<String>> cyclePatti = {
    '00': [
      '100',
      '200',
      '300',
      '400',
      '500',
      '600',
      '700',
      '800',
      '900',
      '000',
    ],
    '10': [
      '110',
      '120',
      '130',
      '140',
      '150',
      '160',
      '170',
      '180',
      '190',
      '100',
    ],
    '11': [
      '111',
      '112',
      '113',
      '114',
      '115',
      '116',
      '117',
      '118',
      '119',
      '110',
    ],
    '12': [
      '112',
      '122',
      '123',
      '124',
      '125',
      '126',
      '127',
      '128',
      '129',
      '120',
    ],
    '13': [
      '113',
      '123',
      '133',
      '134',
      '135',
      '136',
      '137',
      '138',
      '139',
      '130',
    ],
    '14': [
      '114',
      '124',
      '134',
      '144',
      '145',
      '146',
      '147',
      '148',
      '149',
      '140',
    ],
    '15': [
      '115',
      '125',
      '135',
      '145',
      '155',
      '156',
      '157',
      '158',
      '159',
      '150',
    ],
    '16': [
      '116',
      '126',
      '136',
      '146',
      '156',
      '166',
      '167',
      '168',
      '169',
      '160',
    ],
    '17': [
      '117',
      '127',
      '137',
      '147',
      '157',
      '167',
      '177',
      '178',
      '179',
      '170',
    ],
    '18': [
      '118',
      '128',
      '138',
      '148',
      '158',
      '168',
      '178',
      '188',
      '189',
      '180',
    ],
    '19': [
      '119',
      '129',
      '139',
      '149',
      '159',
      '169',
      '179',
      '189',
      '199',
      '190',
    ],
    '20': [
      '120',
      '220',
      '230',
      '240',
      '250',
      '260',
      '270',
      '280',
      '290',
      '200',
    ],
    '22': [
      '122',
      '222',
      '223',
      '224',
      '225',
      '226',
      '227',
      '228',
      '229',
      '220',
    ],
    '23': [
      '123',
      '223',
      '233',
      '234',
      '235',
      '236',
      '237',
      '238',
      '239',
      '230',
    ],
    '24': [
      '124',
      '224',
      '234',
      '244',
      '245',
      '246',
      '247',
      '248',
      '249',
      '240',
    ],
    '25': [
      '125',
      '225',
      '235',
      '245',
      '255',
      '256',
      '257',
      '258',
      '259',
      '250',
    ],
    '26': [
      '126',
      '226',
      '236',
      '246',
      '256',
      '266',
      '267',
      '268',
      '269',
      '260',
    ],
    '27': [
      '127',
      '227',
      '237',
      '247',
      '257',
      '267',
      '277',
      '278',
      '279',
      '270',
    ],
    '28': [
      '128',
      '228',
      '238',
      '248',
      '258',
      '268',
      '278',
      '288',
      '289',
      '280',
    ],
    '29': [
      '129',
      '229',
      '239',
      '249',
      '259',
      '269',
      '279',
      '289',
      '299',
      '290',
    ],
    '30': [
      '130',
      '230',
      '330',
      '340',
      '350',
      '360',
      '370',
      '380',
      '390',
      '300',
    ],
    '33': [
      '133',
      '233',
      '333',
      '334',
      '335',
      '336',
      '337',
      '338',
      '339',
      '330',
    ],
    '34': [
      '134',
      '234',
      '334',
      '344',
      '345',
      '346',
      '347',
      '348',
      '349',
      '340',
    ],
    '35': [
      '135',
      '235',
      '335',
      '345',
      '355',
      '356',
      '357',
      '358',
      '359',
      '350',
    ],
    '36': [
      '136',
      '236',
      '336',
      '346',
      '356',
      '366',
      '367',
      '368',
      '369',
      '360',
    ],
    '37': [
      '137',
      '237',
      '337',
      '347',
      '357',
      '367',
      '377',
      '378',
      '379',
      '370',
    ],
    '38': [
      '138',
      '238',
      '338',
      '348',
      '358',
      '368',
      '378',
      '388',
      '389',
      '380',
    ],
    '39': [
      '139',
      '239',
      '339',
      '349',
      '359',
      '369',
      '379',
      '389',
      '399',
      '390',
    ],
    '40': [
      '140',
      '240',
      '340',
      '440',
      '450',
      '460',
      '470',
      '480',
      '490',
      '400',
    ],
    '44': [
      '144',
      '244',
      '344',
      '444',
      '445',
      '446',
      '447',
      '448',
      '449',
      '440',
    ],
    '45': [
      '145',
      '245',
      '345',
      '445',
      '455',
      '456',
      '457',
      '458',
      '459',
      '450',
    ],
    '46': [
      '146',
      '246',
      '346',
      '446',
      '456',
      '466',
      '467',
      '468',
      '469',
      '460',
    ],
    '47': [
      '147',
      '247',
      '347',
      '447',
      '457',
      '467',
      '477',
      '478',
      '479',
      '470',
    ],
    '48': [
      '148',
      '248',
      '348',
      '448',
      '458',
      '468',
      '478',
      '488',
      '489',
      '480',
    ],
    '49': [
      '149',
      '249',
      '349',
      '449',
      '459',
      '469',
      '479',
      '489',
      '499',
      '490',
    ],
    '50': [
      '150',
      '250',
      '350',
      '450',
      '550',
      '560',
      '570',
      '580',
      '590',
      '500',
    ],
    '55': [
      '155',
      '255',
      '355',
      '455',
      '555',
      '556',
      '557',
      '558',
      '559',
      '550',
    ],
    '56': [
      '156',
      '256',
      '356',
      '456',
      '556',
      '566',
      '567',
      '568',
      '569',
      '560',
    ],
    '57': [
      '157',
      '257',
      '357',
      '457',
      '557',
      '567',
      '577',
      '578',
      '579',
      '570',
    ],
    '58': [
      '158',
      '258',
      '358',
      '458',
      '558',
      '568',
      '578',
      '588',
      '589',
      '580',
    ],
    '59': [
      '159',
      '259',
      '359',
      '459',
      '559',
      '569',
      '579',
      '589',
      '599',
      '590',
    ],
    '60': [
      '160',
      '260',
      '360',
      '460',
      '560',
      '660',
      '670',
      '680',
      '690',
      '600',
    ],
    '66': [
      '166',
      '266',
      '366',
      '466',
      '566',
      '666',
      '667',
      '668',
      '669',
      '660',
    ],
    '67': [
      '167',
      '267',
      '367',
      '467',
      '567',
      '667',
      '677',
      '678',
      '679',
      '670',
    ],
    '68': [
      '168',
      '268',
      '368',
      '468',
      '568',
      '668',
      '678',
      '688',
      '689',
      '680',
    ],
    '69': [
      '169',
      '269',
      '369',
      '469',
      '569',
      '669',
      '679',
      '689',
      '699',
      '690',
    ],
    '70': [
      '170',
      '270',
      '370',
      '470',
      '570',
      '670',
      '770',
      '780',
      '790',
      '700',
    ],
    '77': [
      '177',
      '277',
      '377',
      '477',
      '577',
      '677',
      '777',
      '778',
      '779',
      '770',
    ],
    '78': [
      '178',
      '278',
      '378',
      '478',
      '578',
      '678',
      '778',
      '788',
      '789',
      '780',
    ],
    '79': [
      '179',
      '279',
      '379',
      '479',
      '579',
      '679',
      '779',
      '789',
      '799',
      '790',
    ],
    '80': [
      '180',
      '280',
      '380',
      '480',
      '580',
      '680',
      '780',
      '880',
      '890',
      '800',
    ],
    '88': [
      '188',
      '288',
      '388',
      '488',
      '588',
      '688',
      '788',
      '888',
      '889',
      '880',
    ],
    '89': [
      '189',
      '289',
      '389',
      '489',
      '589',
      '689',
      '789',
      '889',
      '899',
      '890',
    ],
    '90': [
      '190',
      '290',
      '390',
      '490',
      '590',
      '690',
      '790',
      '890',
      '990',
      '900',
    ],
    '99': [
      '199',
      '299',
      '399',
      '499',
      '599',
      '699',
      '799',
      '899',
      '999',
      '990',
    ],
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
        _perPanaAmount = double.tryParse(_amountController.text.trim()) ?? 0;
      });
    });

    _loadUserData();
    _checkSessions();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ─── Computed helpers ──────────────────────────────────────
  int get _childCount =>
      selectedPana != null ? cyclePatti[selectedPana]!.length : 0;

  double get _totalAmount => _perPanaAmount * _childCount;

  // ─── Session check ─────────────────────────────────────────
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
        pana: selectedPana ?? '',
        digit: '',
      ),
    );
  }

  // ─── Filtered pana keys ────────────────────────────────────
  List<String> get _filteredKeys {
    if (_searchQuery.isEmpty) return cyclePatti.keys.toList();
    return cyclePatti.keys.where((k) => k.contains(_searchQuery)).toList();
  }

  // ─── Actions ───────────────────────────────────────────────
  void _onContinue() {
    if (selectedPana == null) {
      _snack('Please select a cycle patti', isError: true);
      return;
    }
    if (_perPanaAmount <= 0) {
      _snack('Enter a bid amount', isError: true);
      return;
    }
    if (_perPanaAmount < MINIMUM_BID_AMOUNT) {
      _snack('Minimum bid per pana is ₹$MINIMUM_BID_AMOUNT', isError: true);
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
      if (selectedPana == null) throw Exception('No pana selected');

      if (_perPanaAmount <= 0) throw Exception('Invalid bid amount');
      if (_perPanaAmount < MINIMUM_BID_AMOUNT) {
        throw Exception('Minimum bid per pana is ₹$MINIMUM_BID_AMOUNT');
      }
      if ((double.tryParse(user.walletAmount ?? '0') ?? 0) < _totalAmount) {
        throw Exception('Insufficient balance');
      }
      if ((selectedSession == 'Open' && isOpenSessionDisabled) ||
          (selectedSession == 'Close' && isCloseSessionDisabled)) {
        throw Exception('$selectedSession session is closed');
      }

      final amtStr = _perPanaAmount.toStringAsFixed(2);

      final futures = cyclePatti[selectedPana]!
          .map(
            (child) => _bidService.createBid(
              BidRequest(
                marketId: widget.marketId,
                userId: user.id,
                gameId: widget.gameId,
                name: user.name,
                mobile: user.number,
                market: widget.marketName,
                session: selectedSession,
                digit: '',
                pana: child,
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
        'Bids placed! $selectedPana · $_childCount × ₹${_perPanaAmount.toStringAsFixed(0)} = ₹${_totalAmount.toStringAsFixed(2)}',
        isError: false,
      );

      await _loadUserData();
      _amountController.clear();
      setState(() {
        showConfirmation = false;
        selectedPana = null;
        _perPanaAmount = 0;
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
      // ── Sticky bottom panel — never overlaps scroll content ──
      bottomNavigationBar: selectedPana != null ? _buildBottomPanel() : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Session toggles + time badges
          SliverToBoxAdapter(child: _buildSessionAndTimes()),

          // Horizontally-scrollable pana chip selector
          SliverToBoxAdapter(child: _buildPanaSelector()),

          if (selectedPana != null) ...[
            // Single amount input
            SliverToBoxAdapter(child: _buildAmountInput()),

            // Grid section header
            SliverToBoxAdapter(child: _buildChildPanaGridHeader()),

            // Inline grid — grows naturally, no fixed height
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                ),
                delegate: SliverChildBuilderDelegate((_, idx) {
                  final child = cyclePatti[selectedPana]![idx];
                  final active = _perPanaAmount > 0;
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
                          color: active ? _C.bg : _C.txt,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }, childCount: cyclePatti[selectedPana]!.length),
              ),
            ),
          ] else ...[
            // Empty state fills remaining viewport
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

  // ─── Pana Selector ─────────────────────────────────────────
  Widget _buildPanaSelector() {
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
                'Select Cycle Patti',
                style: TextStyle(
                  color: _C.txt,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedPana != null) ...[
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
                    'Selected: $selectedPana',
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
              hintText: 'Search pana (e.g. 12)',
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

          // Horizontally scrollable chip grid — 2 rows
          SizedBox(
            height: 108,
            child: keys.isEmpty
                ? Center(
                    child: Text(
                      'No pana found for "$_searchQuery"',
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
                          childAspectRatio: 0.42,
                        ),
                    itemCount: keys.length,
                    itemBuilder: (_, i) {
                      final pana = keys[i];
                      final sel = selectedPana == pana;
                      final count = cyclePatti[pana]!.length;
                      return GestureDetector(
                        onTap: () => setState(() {
                          selectedPana = pana;
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
                                pana,
                                style: TextStyle(
                                  color: sel ? _C.bg : _C.txt,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count panas',
                                style: TextStyle(
                                  color: sel
                                      ? _C.bg.withOpacity(0.65)
                                      : _C.muted,
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
        ],
      ),
    );
  }

  // ─── Single Amount Input ───────────────────────────────────
  Widget _buildAmountInput() {
    final hasAmt = _perPanaAmount > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasAmt ? _C.gold.withOpacity(0.4) : _C.border,
        ),
        boxShadow: hasAmt
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
                'Bid Amount Per Pana',
                style: TextStyle(
                  color: _C.txt,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (hasAmt)
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
                    '₹${_perPanaAmount.toStringAsFixed(0)} × $_childCount = ₹${_totalAmount.toStringAsFixed(0)}',
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
            style: TextStyle(
              color: hasAmt ? _C.goldLt : _C.txt,
              fontWeight: hasAmt ? FontWeight.bold : FontWeight.normal,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: 'Enter amount...',
              hintStyle: TextStyle(
                color: _C.muted.withOpacity(0.4),
                fontSize: 15,
              ),
              prefixText: hasAmt ? '₹  ' : null,
              prefixStyle: const TextStyle(
                color: _C.gold,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              filled: true,
              fillColor: hasAmt
                  ? _C.gold.withOpacity(0.06)
                  : _C.surface.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasAmt
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
          if (hasAmt) ...[
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
                      '₹${_perPanaAmount.toStringAsFixed(0)} will be placed on all $_childCount panas in cycle $selectedPana',
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

  // ─── Child Pana Grid Header ────────────────────────────────
  Widget _buildChildPanaGridHeader() {
    final active = _perPanaAmount > 0;
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
          const Icon(Icons.cyclone_rounded, color: _C.gold, size: 15),
          const SizedBox(width: 8),
          Text(
            'Cycle $selectedPana — $_childCount Panas',
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
                  ? '₹${_perPanaAmount.toStringAsFixed(0)} each'
                  : 'Enter amount above',
              style: TextStyle(
                color: active ? _C.green : _C.muted,
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
            child: const Icon(Icons.cyclone_rounded, color: _C.gold, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a cycle patti to place bids',
            style: TextStyle(color: _C.muted, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Search or scroll to find your pana',
            style: TextStyle(color: _C.muted.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Panel (sticky via bottomNavigationBar) ─────────
  Widget _buildBottomPanel() {
    final total = _totalAmount;
    final ok = walletAmount >= total;
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
                'Per Pana',
                _perPanaAmount > 0
                    ? '₹${_perPanaAmount.toStringAsFixed(0)}'
                    : '—',
                _C.txt,
              ),
            ),
            Container(width: 1, height: 40, color: _C.border),
            Expanded(child: _tile('× Panas', '$_childCount', _C.muted)),
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
              total > 0 ? 'Continue  →' : 'Enter amount to continue',
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
                _row('Cycle Patti', selectedPana ?? '—'),
                const SizedBox(height: 7),
                _row('Per Pana', '₹${_perPanaAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 7),
                _row('Pana Count', '$_childCount panas'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: _C.border, height: 1),
                ),
                _row(
                  '₹${_perPanaAmount.toStringAsFixed(0)} × $_childCount',
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
