import 'package:flutter/material.dart';
import 'package:ekdant/models/market_model.dart';
import 'package:ekdant/models/result_model.dart';
import 'package:ekdant/services/market_service.dart';
import 'package:ekdant/services/result_service.dart';
import 'package:intl/intl.dart';

class MarketListComponent extends StatefulWidget {
  final MarketService marketService;
  final ResultService resultService;
  final Function(MarketResponse) onMarketTap;

  const MarketListComponent({
    super.key,
    required this.marketService,
    required this.resultService,
    required this.onMarketTap,
  });

  @override
  State<MarketListComponent> createState() => _MarketListComponentState();
}

class _MarketListComponentState extends State<MarketListComponent> {
  late Future<MarketListResponse> _marketsFuture;
  late Future<List<Result>> _resultsFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _marketsFuture = widget.marketService.getAllMarkets();
      _resultsFuture = widget.resultService.getAllResults();
      _isRefreshing = true;
    });
  }

  List<MarketResponse> _sortMarketsByCloseTimeOpen(
    List<MarketResponse> markets,
  ) {
    // Filter markets where status is true
    final activeMarkets = markets
        .where((market) => market.status == true)
        .toList();

    activeMarkets.sort((a, b) {
      int parseTimeToMinutes(String time) {
        try {
          final parts = time.split(':');
          if (parts.length >= 2) {
            return int.parse(parts[0]) * 60 + int.parse(parts[1]);
          }
          return 0;
        } catch (e) {
          debugPrint("Time parsing error: $e");
          return 0;
        }
      }

      final aTime = parseTimeToMinutes(a.closeTimeOpen);
      final bTime = parseTimeToMinutes(b.closeTimeOpen);
      return aTime.compareTo(bTime);
    });

    return activeMarkets;
  }

  String _formatResult(MarketResponse market, List<Result> results) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final marketResult = results.firstWhere((result) {
        final resultDate = result.date != null
            ? DateFormat('yyyy-MM-dd').format(result.date!)
            : null;

        final marketMatches =
            result.marketName == market.name ||
            (result.marketName == null && result.marketId == market.id);
        final dateMatches = resultDate == today;

        return marketMatches && dateMatches;
      });

      final openPart =
          marketResult.openPana.isNotEmpty && marketResult.openResult.isNotEmpty
          ? '${marketResult.openPana}-${marketResult.openResult}'
          : 'XXX-XX';

      final closePart =
          marketResult.closePana.isNotEmpty &&
              marketResult.closeResult.isNotEmpty
          ? '${marketResult.closeResult}-${marketResult.closePana}'
          : 'XX-XXX';

      return '$openPart$closePart';
    } catch (e) {
      return 'XXX-XX-XXX';
    }
  }

  Color _getMarketColor(int index) {
    final colors = [
      const Color.fromARGB(255, 93, 224, 99),
      const Color(0xFF2196F3),
    ];
    return colors[index % colors.length];
  }

  bool _isMarketOpenNow(MarketResponse market) {
    try {
      final now = DateTime.now();
      final openParts = market.openTime.split(':');
      final closeParts = market.closeTimeClose.split(':');

      if (openParts.length < 2 || closeParts.length < 2) return false;

      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);

      final nowInMinutes = now.hour * 60 + now.minute;
      final openInMinutes = openHour * 60 + openMinute;
      final closeInMinutes = closeHour * 60 + closeMinute;

      if (closeInMinutes < openInMinutes) {
        return nowInMinutes >= openInMinutes || nowInMinutes <= closeInMinutes;
      } else {
        return nowInMinutes >= openInMinutes && nowInMinutes <= closeInMinutes;
      }
    } catch (e) {
      debugPrint("Time parse error: $e");
      return false;
    }
  }

  String _format24HourTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return time;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
        setState(() => _isRefreshing = false);
      },
      child: FutureBuilder(
        future: Future.wait([_marketsFuture, _resultsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C3E50)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3E50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData ||
              (snapshot.data![0] as MarketListResponse).markets.isEmpty) {
            return const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: Color(0xFF2C3E50),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No markets available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF2C3E50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final markets = _sortMarketsByCloseTimeOpen(
            (snapshot.data![0] as MarketListResponse).markets,
          );
          final results = snapshot.data![1] as List<Result>;

          if (markets.isEmpty) {
            return const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: Color(0xFF2C3E50),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No active markets available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF2C3E50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: markets.asMap().entries.map((entry) {
              final index = entry.key;
              final market = entry.value;
              final color = _getMarketColor(index);
              final isOpen = _isMarketOpenNow(market);
              final result = _formatResult(market, results);

              return _buildMarketCard(market, color, isOpen, result);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMarketCard(
    MarketResponse market,
    Color color,
    bool isOpen,
    String result,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    market.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOpen ? 'OPEN NOW' : 'CLOSED',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOpen ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTimeInfo(
                    'Open Time',
                    _format24HourTime(market.closeTimeOpen),
                    color,
                  ),
                  const SizedBox(width: 20),
                  _buildTimeInfo(
                    'Close Time',
                    _format24HourTime(market.closeTimeClose),
                    color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Text(
                  'Result: $result',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 254, 254, 254),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOpen ? color : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 4,
                    shadowColor: color.withOpacity(0.5),
                  ),
                  onPressed: isOpen ? () => widget.onMarketTap(market) : null,
                  child: Text(
                    isOpen ? 'Play Now' : 'Market Closed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
