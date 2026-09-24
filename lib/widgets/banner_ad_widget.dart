import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_service.dart';
import '../services/app_prompt_service.dart';
import '../providers/pro_provider.dart';

class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final EdgeInsetsGeometry margin;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.margin = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isPro = Provider.of<ProProvider>(context, listen: false).isPro;
      if (isPro) return;

      // First-time users (Launch 1): Keep experience completely ad-free
      try {
        final prefs = await SharedPreferences.getInstance();
        final launchCount = prefs.getInt(AppPromptService.keyLaunchCount) ?? 0;
        if (launchCount <= 1) {
          return;
        }
      } catch (_) {}

      if (mounted) {
        _loadBannerAd();
      }
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proProvider = Provider.of<ProProvider>(context);
    if (proProvider.isPro || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xff162032) : Colors.white;
    final cardBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      width: double.infinity,
      margin: widget.margin,
      alignment: Alignment.center,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          ),
        ),
      ),
    );
  }
}
