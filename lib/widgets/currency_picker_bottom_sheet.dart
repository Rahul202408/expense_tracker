import 'package:flutter/material.dart';
import '../services/currency_service.dart';

/// Shows a high-end, modern frosted bottom sheet for selecting a Country & Currency
Future<CurrencyInfo?> showCurrencyPickerModal({
  required BuildContext context,
  required CurrencyInfo selectedCurrency,
}) {
  return showModalBottomSheet<CurrencyInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) => _CurrencyPickerModalSheet(
      initialSelected: selectedCurrency,
    ),
  );
}

class _CurrencyPickerModalSheet extends StatefulWidget {
  final CurrencyInfo initialSelected;

  const _CurrencyPickerModalSheet({
    required this.initialSelected,
  });

  @override
  State<_CurrencyPickerModalSheet> createState() => _CurrencyPickerModalSheetState();
}

class _CurrencyPickerModalSheetState extends State<_CurrencyPickerModalSheet> {
  final TextEditingController _searchController = TextEditingController();
  late CurrencyInfo _currentSelected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentSelected = widget.initialSelected;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CurrencyInfo> get _filteredList {
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

  static const List<String> _popularCodes = ['INR', 'USD', 'EUR', 'GBP', 'AED', 'SAR', 'CAD', 'SGD'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xff0F172A) : Colors.white;
    final cardBgColor = isDark ? const Color(0xff1E293B) : const Color(0xffF8FAFC);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final titleColor = isDark ? Colors.white : const Color(0xff0F172A);
    final subtitleColor = isDark ? const Color(0xff94A3B8) : const Color(0xff64748B);

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black12,
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff10B981), Color(0xff059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff10B981).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.public_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Country & Currency",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Choose default currency for all records",
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: subtitleColor, size: 22),
                  ),
                ],
              ),
            ),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: titleColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Search country, code or symbol (e.g. INR, USD)...",
                    hintStyle: TextStyle(
                      color: subtitleColor.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xff10B981),
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: subtitleColor, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Popular Currencies Quick Filter Chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _popularCodes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final code = _popularCodes[i];
                  final match = CurrencyService.supportedCurrencies.firstWhere(
                    (c) => c.code == code,
                    orElse: () => CurrencyService.defaultCurrency,
                  );
                  final isSelected = _currentSelected.code == code;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _currentSelected = match);
                      Navigator.pop(context, match);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xff10B981).withValues(alpha: 0.2)
                            : cardBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xff10B981)
                              : borderColor,
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(match.flagEmoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            match.code,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xff10B981) : titleColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "(${match.symbol})",
                            style: TextStyle(
                              fontSize: 11,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: borderColor),

            // Currency List View
            Flexible(
              child: _filteredList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: subtitleColor),
                          const SizedBox(height: 12),
                          Text(
                            "No country or currency found",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Try searching with another keyword like 'USD' or 'India'",
                            style: TextStyle(fontSize: 12, color: subtitleColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final curr = _filteredList[index];
                        final isSelected = curr.code == _currentSelected.code;

                        return Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() => _currentSelected = curr);
                              Navigator.pop(context, curr);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xff10B981).withValues(alpha: isDark ? 0.15 : 0.08)
                                    : cardBgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xff10B981)
                                      : borderColor,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Country Flag Circle
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xff0F172A)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xff10B981).withValues(alpha: 0.5)
                                            : borderColor,
                                        width: 1.2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      curr.flagEmoji,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Country & Currency Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          curr.country,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? const Color(0xff10B981)
                                                : titleColor,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${curr.name} • ${curr.code}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: subtitleColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Symbol Pill & Checkmark
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xff10B981).withValues(alpha: 0.2)
                                              : (isDark
                                                  ? Colors.white.withValues(alpha: 0.08)
                                                  : Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xff10B981).withValues(alpha: 0.5)
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Text(
                                          curr.symbol,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? const Color(0xff10B981)
                                                : titleColor,
                                          ),
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xff10B981),
                                          size: 20,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
}
