import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/currency_provider.dart';
import '../../services/currency_service.dart';
import '../main_screen.dart';

class InitialCurrencyScreen extends StatefulWidget {
  const InitialCurrencyScreen({super.key});

  @override
  State<InitialCurrencyScreen> createState() => _InitialCurrencyScreenState();
}

class _InitialCurrencyScreenState extends State<InitialCurrencyScreen> {
  final TextEditingController _searchController = TextEditingController();
  late CurrencyInfo _selectedCurrency;
  String _searchQuery = '';
  bool _isSaving = false;

  static const List<String> _quickCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'INR',
    'AED',
    'CAD',
    'AUD',
    'SGD',
  ];

  @override
  void initState() {
    super.initState();
    // Default to the first currency in supportedCurrencies (USD) or current provider currency
    final current = Provider.of<CurrencyProvider>(context, listen: false).currentCurrency;
    _selectedCurrency = current.code == 'INR'
        ? CurrencyService.defaultCurrency // Default to USD for new selection
        : current;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CurrencyInfo> get _filteredCurrencies {
    if (_searchQuery.trim().isEmpty) {
      return CurrencyService.supportedCurrencies;
    }
    final q = _searchQuery.trim().toLowerCase();
    return CurrencyService.supportedCurrencies.where((curr) {
      return curr.country.toLowerCase().contains(q) ||
          curr.code.toLowerCase().contains(q) ||
          curr.name.toLowerCase().contains(q) ||
          curr.symbol.toLowerCase().contains(q) ||
          curr.countryCode.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _handleConfirm() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      await currencyProvider.setCurrency(_selectedCurrency);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Error saving initial currency: $e");
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xff0B1329) : const Color(0xffF4F6FB);
    final cardBg = isDark ? const Color(0xff141E33) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final textPrimary = isDark ? Colors.white : const Color(0xff0F172A);
    final textSecondary = isDark ? const Color(0xff94A3B8) : const Color(0xff64748B);
    final searchBg = isDark ? const Color(0xff0F172A) : const Color(0xffF1F5F9);
    final chipInactiveBg = isDark ? const Color(0xff1E293B) : const Color(0xffE2E8F0);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Glow / Icon Badge
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xff10B981), Color(0xff059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff10B981).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.currency_exchange_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Main Heading
                Text(
                  "Choose Your Currency",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Select the currency for your expense tracking. You can easily change this anytime in Settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Main Interactive Card
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Search Input Field
                      Container(
                        decoration: BoxDecoration(
                          color: searchBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Search country or currency (e.g. USD, \$)...",
                            hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear_rounded, color: textSecondary, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Quick Selection Chips Header
                      Text(
                        "POPULAR CURRENCIES",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Horizontal Quick-Picks Wrap
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickCurrencies.map((code) {
                          final match = CurrencyService.supportedCurrencies.firstWhere(
                            (c) => c.code == code,
                            orElse: () => CurrencyService.defaultCurrency,
                          );
                          final isSelected = _selectedCurrency.code == match.code;

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedCurrency = match);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xff10B981) : chipInactiveBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xff10B981)
                                      : borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(match.flagEmoji, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${match.symbol} ${match.code}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Currencies List Container
                      Container(
                        height: 240,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xff0B1329) : const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: _filteredCurrencies.isEmpty
                            ? Center(
                                child: Text(
                                  "No currencies found",
                                  style: TextStyle(color: textSecondary, fontSize: 13),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(8),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _filteredCurrencies.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final item = _filteredCurrencies[index];
                                  final isSelected = _selectedCurrency.code == item.code;

                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selectedCurrency = item);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isDark
                                                ? const Color(0xff10B981).withValues(alpha: 0.18)
                                                : const Color(0xffECFDF5))
                                            : (isDark
                                                ? const Color(0xff141E33)
                                                : Colors.white),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xff10B981)
                                              : borderColor,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            item.flagEmoji,
                                            style: const TextStyle(fontSize: 22),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                    color: isSelected
                                                        ? (isDark
                                                            ? const Color(0xff34D399)
                                                            : const Color(0xff047857))
                                                        : textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.country,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xff10B981)
                                                  : (isDark
                                                      ? const Color(0xff1E293B)
                                                      : const Color(0xffE2E8F0)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "${item.symbol} ${item.code}",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isSelected
                                                    ? Colors.white
                                                    : textPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            isSelected
                                                ? Icons.radio_button_checked_rounded
                                                : Icons.radio_button_off_rounded,
                                            color: isSelected
                                                ? const Color(0xff10B981)
                                                : textSecondary.withValues(alpha: 0.5),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 18),

                      // Continue CTA Button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: const Color(0xff10B981).withValues(alpha: 0.4),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Continue with ${_selectedCurrency.symbol} ${_selectedCurrency.code}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
