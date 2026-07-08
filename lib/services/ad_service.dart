import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'payment_service.dart';
import 'remote_config_service.dart';
import 'usage_counter_service.dart';

/// Central gate for all ads. Respects the remote kill-switch and rewards paying
/// users with an ad-free experience.
class AdService {
  static InterstitialAd? _interstitial;
  static bool _loadingInterstitial = false;

  /// Ads are only shown on mobile, when remotely enabled, and only to users who
  /// have NOT paid (removeAds / any purchase makes them ad-free).
  static Future<bool> adsAreEnabledForUser() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return false;
    if (!RemoteConfigService.adsEnabled) return false;
    final adFree = await PaymentService.isAdFree();
    return !adFree;
  }

  // ── Interstitials ───────────────────────────────────────────────────────

  /// Preloads an interstitial so it can be shown instantly when due. Safe to
  /// call repeatedly; no-ops if one is already loaded/loading or ads are off.
  static Future<void> loadInterstitial() async {
    if (_interstitial != null || _loadingInterstitial) return;
    if (!await adsAreEnabledForUser()) return;

    _loadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: RemoteConfigService.admobInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          _loadingInterstitial = false;
        },
      ),
    );
  }

  /// Records a successful AI generation and, if this generation lands on an ad
  /// slot, shows a preloaded interstitial. Never blocks the result: if no ad is
  /// ready it silently skips and preloads for next time.
  static Future<void> onSuccessfulGenerationAndMaybeShow() async {
    await UsageCounterService.incrementGeneration();

    if (!await adsAreEnabledForUser()) return;

    final due = await UsageCounterService.shouldShowAd();
    if (!due) {
      // Warm the cache for the next slot.
      loadInterstitial();
      return;
    }

    if (_interstitial == null) {
      // Not ready this time — skip silently, start loading for next time.
      loadInterstitial();
      return;
    }

    final ad = _interstitial!;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        loadInterstitial();
      },
    );
    await ad.show();
  }

  // ── Banners ───────────────────────────────────────────────────────────

  /// Creates and loads a banner ad, or returns null if ads are disabled for the
  /// user. Caller owns disposal.
  static Future<BannerAd?> createBanner() async {
    if (!await adsAreEnabledForUser()) return null;
    final banner = BannerAd(
      adUnitId: RemoteConfigService.admobBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
    await banner.load();
    return banner;
  }

  static void dispose() {
    _interstitial?.dispose();
    _interstitial = null;
  }
}
