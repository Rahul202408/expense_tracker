import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/pro_provider.dart';
import '../../providers/currency_provider.dart';
import '../../services/in_app_purchase_service.dart';
import '../../services/firebase_analytics_service.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  // Default selected plan is Yearly (Most Popular)
  String _selectedPlanId = InAppPurchaseService.yearlyPlanId;
  bool _isRetryingStore = false;
  int _selectedTab = 0; // 0: VIP Benefits, 1: Free vs PRO
  int? _expandedFaqIndex;

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsService().logProPlanView();
    InAppPurchaseService().fetchProducts().then((_) {
      if (mounted) setState(() {});
    });
  }

  String _getPriceForPlan(String planId, bool isIndia) {
    final products = InAppPurchaseService().products;
    try {
      if (planId == InAppPurchaseService.lifetimePlanId ||
          planId == InAppPurchaseService.altLifetimePlanId) {
        final prod = products.firstWhere(
          (p) =>
              p.id == InAppPurchaseService.lifetimePlanId ||
              p.id == InAppPurchaseService.altLifetimePlanId,
        );
        if (prod.price.isNotEmpty) return prod.price;
      } else {
        final prod = products.firstWhere((p) => p.id == planId);
        if (prod.price.isNotEmpty) return prod.price;
      }
    } catch (_) {}

    if (isIndia) {
      if (planId == InAppPurchaseService.monthlyPlanId) return "₹59";
      if (planId == InAppPurchaseService.yearlyPlanId) return "₹399";
      return "₹899";
    } else {
      if (planId == InAppPurchaseService.monthlyPlanId) return "\$2.99";
      if (planId == InAppPurchaseService.yearlyPlanId) return "\$19.99";
      return "\$39.99";
    }
  }

  String _getCtaButtonText(bool isPro, String price) {
    if (isPro) return "YOU ARE ALREADY A VIP MEMBER ✨";
    if (_selectedPlanId == InAppPurchaseService.yearlyPlanId) {
      return "START ANNUAL VIP • $price 👑";
    } else if (_selectedPlanId == InAppPurchaseService.lifetimePlanId) {
      return "GET LIFETIME ACCESS • $price 👑";
    } else {
      return "START MONTHLY VIP • $price 👑";
    }
  }

  @override
  Widget build(BuildContext context) {
    final proProvider = Provider.of<ProProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final isIndia = currencyProvider.code == 'INR' || currencyProvider.countryCode == 'IN';
    final selectedPrice = _getPriceForPlan(_selectedPlanId, isIndia);

    return Scaffold(
      backgroundColor: const Color(0xff0B1329),
      body: SafeArea(
        child: Stack(
          children: [
            // Background ambient glows
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xffF59E0B).withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              top: 180,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff6366F1).withValues(alpha: 0.15),
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Navigation Bar (Close + Restore)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                          tooltip: "Close",
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await proProvider.restorePurchases();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  proProvider.isPro
                                      ? "Purchases successfully restored! 🎉"
                                      : "No active VIP purchase found to restore.",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: proProvider.isPro ? Colors.green : const Color(0xff1E293B),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.restore_rounded, size: 16, color: Color(0xff94A3B8)),
                        label: const Text(
                          "Restore",
                          style: TextStyle(
                            color: Color(0xff94A3B8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Crown Icon badge with luxury glow
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xffFBBF24), Color(0xffD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xffF59E0B).withValues(alpha: 0.45),
                          blurRadius: 28,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title & Subtitle
                  const Text(
                    "Unlock Expense Tracker PRO",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Get complete control over your finances with zero ads, deep insights, and unlimited VIP tools.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Interactive Segmented Tab Switcher (VIP Perks vs Free vs PRO)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xff141E33),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedTab = 0);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: _selectedTab == 0
                                    ? const LinearGradient(
                                        colors: [Color(0xffF59E0B), Color(0xffD97706)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 16,
                                    color: _selectedTab == 0 ? Colors.white : Colors.white60,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "VIP Benefits",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedTab == 0 ? Colors.white : Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedTab = 1);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: _selectedTab == 1
                                    ? const LinearGradient(
                                        colors: [Color(0xff6366F1), Color(0xff4F46E5)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.compare_arrows_rounded,
                                    size: 16,
                                    color: _selectedTab == 1 ? Colors.white : Colors.white60,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Free vs PRO",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedTab == 1 ? Colors.white : Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Tab Content: View 0 = Benefits Cards, View 1 = Comparison Table
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _selectedTab == 0
                        ? _buildBenefitsList()
                        : _buildComparisonTable(),
                  ),

                  const SizedBox(height: 24),

                  // Plan Selection Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "CHOOSE YOUR PLAN",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff94A3B8),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xff10B981).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xff10B981)),
                            SizedBox(width: 4),
                            Text(
                              "CANCEL ANYTIME",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xff10B981),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. Monthly Plan (₹59 / $2.99)
                  _buildPlanCard(
                    planId: InAppPurchaseService.monthlyPlanId,
                    title: "Monthly VIP",
                    price: _getPriceForPlan(InAppPurchaseService.monthlyPlanId, isIndia),
                    period: "/ month",
                    subtitle: "Billed monthly • Perfect for trying out PRO",
                    tag: "FLEXIBLE",
                    tagColor: const Color(0xff94A3B8),
                  ),
                  const SizedBox(height: 12),

                  // 2. Yearly Plan (₹399 / $19.99) - Most Popular
                  _buildPlanCard(
                    planId: InAppPurchaseService.yearlyPlanId,
                    title: "Annual VIP",
                    price: _getPriceForPlan(InAppPurchaseService.yearlyPlanId, isIndia),
                    period: "/ year",
                    subtitle: isIndia
                        ? "Only ₹33 / month • Billed ₹399 yearly"
                        : "Only ~\$1.66 / month • Save 44%",
                    tag: isIndia ? "MOST POPULAR • SAVE 43%" : "MOST POPULAR • SAVE 44%",
                    tagColor: const Color(0xff10B981),
                  ),
                  const SizedBox(height: 12),

                  // 3. Lifetime Plan (₹899 / $39.99) - Best Value
                  _buildPlanCard(
                    planId: InAppPurchaseService.lifetimePlanId,
                    title: "Lifetime VIP",
                    price: _getPriceForPlan(InAppPurchaseService.lifetimePlanId, isIndia),
                    period: "one-time",
                    subtitle: "Pay once, enjoy PRO forever • Zero recurring charges",
                    tag: "BEST VALUE • ONE-TIME",
                    tagColor: const Color(0xffF59E0B),
                  ),

                  const SizedBox(height: 24),

                  // Main Dynamic CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: proProvider.isLoading
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();
                              final result = await proProvider.purchasePlanWithResult(_selectedPlanId);
                              if (!result.success && context.mounted) {
                                _showPlayStoreTroubleshootingDialog(context, result);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        elevation: 8,
                        shadowColor: const Color(0xffF59E0B).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xffF59E0B), Color(0xffD97706)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: proProvider.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  _getCtaButtonText(proProvider.isPro, selectedPrice),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Trust Badges Row (Google Play Protected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xff141E33),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTrustBadge(Icons.shield_outlined, "Play Protect"),
                        Container(width: 1, height: 24, color: Colors.white12),
                        _buildTrustBadge(Icons.bolt_rounded, "Instant VIP"),
                        Container(width: 1, height: 24, color: Colors.white12),
                        _buildTrustBadge(Icons.autorenew_rounded, "Cancel Anytime"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Interactive FAQ Accordion
                  _buildFaqSection(),

                  const SizedBox(height: 16),

                  Text(
                    "Recurring billing through Google Play. You can manage or cancel your subscription anytime in Google Play Store settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // View 0: VIP Benefits List
  Widget _buildBenefitsList() {
    return Column(
      key: const ValueKey("benefits_list"),
      children: [
        _buildFeatureRow(
          icon: Icons.block_rounded,
          iconColor: const Color(0xffEF4444),
          title: "100% Ad-Free Experience",
          subtitle: "Zero banner, interstitial, or native ads anywhere in the app",
        ),
        _buildFeatureRow(
          icon: Icons.picture_as_pdf_rounded,
          iconColor: const Color(0xff3B82F6),
          title: "Unlimited PDF & Excel Statements",
          subtitle: "Export beautiful, categorized financial reports with custom date ranges",
        ),
        _buildFeatureRow(
          icon: Icons.category_rounded,
          iconColor: const Color(0xff10B981),
          title: "Unlimited Custom Categories & Icons",
          subtitle: "Create unlimited custom expense & income categories with unique icons",
        ),
        _buildFeatureRow(
          icon: Icons.fingerprint_rounded,
          iconColor: const Color(0xff8B5CF6),
          title: "Biometric & 4-Digit PIN App Lock",
          subtitle: "Keep your sensitive money records secure with Fingerprint, Face & PIN",
        ),
        _buildFeatureRow(
          icon: Icons.workspace_premium_rounded,
          iconColor: const Color(0xffF59E0B),
          title: "Exclusive Golden VIP Badge & Priority Sync",
          subtitle: "Golden VIP status on your profile and instant real-time cloud sync",
        ),
      ],
    );
  }

  // View 1: Free vs PRO Interactive Comparison Matrix
  Widget _buildComparisonTable() {
    return Container(
      key: const ValueKey("comparison_table"),
      decoration: BoxDecoration(
        color: const Color(0xff141E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    "FEATURE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    "FREE",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff94A3B8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "PRO VIP 👑",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xffFBBF24),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          // Comparison rows
          _buildComparisonRow("Ad Experience", "Banner Ads", "100% Ad-Free ✨", isPositivePro: true),
          _buildComparisonRow("Statements", "Basic PDF", "Unlimited PDF & Excel", isPositivePro: true),
          _buildComparisonRow("Categories", "Limited (5)", "Unlimited Custom", isPositivePro: true),
          _buildComparisonRow("App Security", "Locked", "PIN & Biometric 🛡️", isPositivePro: true),
          _buildComparisonRow("Cloud Sync", "Standard", "Real-time Sync", isPositivePro: true),
          _buildComparisonRow("VIP Badge", "—", "Golden VIP 👑", isPositivePro: true, isLast: true),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String feature,
    String freeValue,
    String proValue, {
    bool isPositivePro = true,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  feature,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  freeValue,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xffF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xffF59E0B).withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    proValue,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xffFBBF24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Colors.white10),
      ],
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xff10B981)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String planId,
    required String title,
    required String price,
    required String period,
    required String subtitle,
    String? tag,
    Color? tagColor,
  }) {
    final bool isSelected = _selectedPlanId == planId;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPlanId = planId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xff1E293B)
              : const Color(0xff141E33),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xffF59E0B)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xffF59E0B).withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xffF59E0B)
                              : Colors.white38,
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xffF59E0B)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.black)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  ],
                ),

                if (tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (tagColor ?? const Color(0xffF59E0B)).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: tagColor ?? const Color(0xffF59E0B),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: tagColor ?? const Color(0xffF59E0B),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Interactive FAQ Accordion
  Widget _buildFaqSection() {
    final faqs = [
      {
        "q": "Can I cancel my subscription anytime?",
        "a": "Yes! You can cancel anytime directly from the Google Play Store under Payments & Subscriptions. You will continue to enjoy PRO benefits until the end of your billing cycle."
      },
      {
        "q": "Will my PRO status work if I change phones?",
        "a": "Absolutely! As long as you are signed into the same Google Account on your new device, simply tap 'Restore' at the top right to restore all VIP perks instantly."
      },
      {
        "q": "What is Lifetime VIP Access?",
        "a": "Lifetime Access is a single one-time purchase. You get all current and future PRO features forever with zero renewals or recurring bills."
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff141E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.help_outline_rounded, size: 18, color: const Color(0xffF59E0B).withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                const Text(
                  "Frequently Asked Questions",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          ...faqs.asMap().entries.map((entry) {
            final index = entry.key;
            final faq = entry.value;
            final isExpanded = _expandedFaqIndex == index;

            return Column(
              children: [
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _expandedFaqIndex = isExpanded ? null : index;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            faq["q"]!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    child: Text(
                      faq["a"]!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ),
                if (index < faqs.length - 1)
                  const Divider(height: 1, color: Colors.white10),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Consumer-facing Google Play Troubleshooting & Connection Dialog
  void _showPlayStoreTroubleshootingDialog(BuildContext context, PurchaseResult result) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xff1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xffF59E0B).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xffF59E0B),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Google Play Store",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Billing & Purchase Assistance",
                                style: TextStyle(
                                  color: Color(0xff94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xffFBBF24), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              result.message,
                              style: const TextStyle(
                                color: Color(0xffFEF3C7),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Please verify the following:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTroubleshootStep(
                      number: "1",
                      title: "Google Play Account",
                      desc: "Ensure you are signed into Google Play Store with an active Google Account.",
                    ),
                    _buildTroubleshootStep(
                      number: "2",
                      title: "Payment Method",
                      desc: "Ensure a supported payment method (UPI, Debit/Credit Card, Net Banking) is linked in Play Store.",
                    ),
                    _buildTroubleshootStep(
                      number: "3",
                      title: "Internet Connection",
                      desc: "Check your Wi-Fi or cellular network connection and try again.",
                    ),
                    _buildTroubleshootStep(
                      number: "4",
                      title: "Google Play Services",
                      desc: "Ensure Google Play Services on your device is up to date.",
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xff94A3B8),
                            ),
                            child: const Text("Close"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffF59E0B),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isRetryingStore
                                ? null
                                : () async {
                                    setDialogState(() => _isRetryingStore = true);
                                    await InAppPurchaseService().fetchProducts();
                                    _isRetryingStore = false;
                                    if (context.mounted) {
                                      setState(() {});
                                    }
                                    if (dialogCtx.mounted) {
                                      Navigator.pop(dialogCtx);
                                    }
                                    if (context.mounted) {
                                      final isConnected = InAppPurchaseService().products.isNotEmpty;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(
                                                isConnected ? Icons.check_circle : Icons.warning_amber_rounded,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  isConnected
                                                      ? "Google Play Connected! (${InAppPurchaseService().products.length} plans ready)"
                                                      : "Connecting to Google Play Store...",
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: isConnected ? Colors.green : const Color(0xff1E293B),
                                        ),
                                      );
                                    }
                                  },
                            child: _isRetryingStore
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "Retry Connection",
                                      maxLines: 1,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTroubleshootStep({
    required String number,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xff334155),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xffFBBF24),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, height: 1.35),
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: desc,
                    style: const TextStyle(color: Color(0xff94A3B8)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
