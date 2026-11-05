import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quotation/ads/ad_units.dart';
import 'package:quotation/theme/app_colors.dart';

/// Anchored banner below the bottom navigation for free users, held apart
/// from the tabs (see [build]) so taps meant for a tab never hit the ad.
class BottomBannerAd extends StatefulWidget {
  const BottomBannerAd({super.key});

  @override
  State<BottomBannerAd> createState() => _BottomBannerAdState();
}

class _BottomBannerAdState extends State<BottomBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ad = BannerAd(
      adUnitId: AdUnits.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted) {
            loaded.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (failed, error) {
          debugPrint('BottomBannerAd: $error');
          failed.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    // A banner that failed gives its space back. Nothing then sits under a
    // finger, since the tabs only move down, away from the ad.
    if (ad == null) return const SizedBox.shrink();
    // AdMob accidental-click rules:
    // - The space is held from the start, so the tabs do not jump up when
    //   the ad arrives and a tap meant for a tab cannot land on it.
    // - A gap, a divider and a different background set it apart from the
    //   tab bar above, so the two never touch.
    final height = AdSize.banner.height.toDouble();
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFFE3E7EF), width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: _gap, bottom: 4),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: _loaded
              ? Center(
                  child: SizedBox(
                    width: ad.size.width.toDouble(),
                    height: ad.size.height.toDouble(),
                    child: AdWidget(ad: ad),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  /// Space between the tab bar and the ad.
  static const _gap = 10.0;
}
