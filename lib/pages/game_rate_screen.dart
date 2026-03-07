import 'package:ekdant/models/game_model..dart';
import 'package:flutter/material.dart';
import 'package:ekdant/services/game_rate_service.dart';

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

class GameRateScreen extends StatefulWidget {
  const GameRateScreen({super.key});

  @override
  State<GameRateScreen> createState() => _GameRateScreenState();
}

class _GameRateScreenState extends State<GameRateScreen> {
  final GameRateService _gameRateService = GameRateService();
  late Future<List<GameRate>> _gameRatesFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gameRatesFuture = _fetchGameRates();
  }

  Future<List<GameRate>> _fetchGameRates() async {
    setState(() => _isLoading = true);
    try {
      final gameRates = await _gameRateService.getAllGameRates();
      setState(() => _isLoading = false);
      return gameRates;
    } catch (e) {
      setState(() => _isLoading = false);
      throw Exception('Failed to load game rates: $e');
    }
  }

  Future<void> _refreshGameRates() async {
    setState(() {
      _gameRatesFuture = _fetchGameRates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_C.gold),
                strokeWidth: 3,
              ),
            )
          : RefreshIndicator(
              color: _C.gold,
              backgroundColor: _C.card,
              onRefresh: _refreshGameRates,
              child: FutureBuilder<List<GameRate>>(
                future: _gameRatesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_C.gold),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final gameRates = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    itemCount: gameRates.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final gameRate = gameRates[index];
                      return _buildGameRateCard(gameRate, index);
                    },
                  );
                },
              ),
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
      title: const Text(
        'Game Rates',
        style: TextStyle(
          color: _C.txt,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: _C.gold,
                size: 18,
              ),
            ),
            onPressed: _refreshGameRates,
            tooltip: 'Refresh',
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border.withOpacity(0.5)),
      ),
    );
  }

  // ─── Game Rate Card ────────────────────────────────────────
  Widget _buildGameRateCard(GameRate gameRate, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_C.card, _C.surface],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // Optional: Add navigation or action when card is tapped
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Index number with gold gradient
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_C.gold, _C.goldLt],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _C.gold.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _C.bg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Game details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gameRate.gameName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _C.txt,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _C.gold.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _C.gold.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                'Rate',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _C.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              gameRate.rate,
                              style: const TextStyle(
                                fontSize: 15,
                                color: _C.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chevron icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _C.gold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.border),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: _C.gold,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Error State ───────────────────────────────────────────
  Widget _buildErrorState(String error) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _C.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _C.red.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _C.red,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to load game rates',
              style: TextStyle(
                fontSize: 18,
                color: _C.txt,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: const TextStyle(color: _C.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshGameRates,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.gold,
                foregroundColor: _C.bg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _C.gold.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _C.gold.withOpacity(0.2)),
              ),
              child: const Icon(Icons.games_outlined, color: _C.gold, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'No game rates available',
              style: TextStyle(
                fontSize: 18,
                color: _C.txt,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh or try again later',
              style: TextStyle(color: _C.muted.withOpacity(0.7), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshGameRates,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.gold,
                foregroundColor: _C.bg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
