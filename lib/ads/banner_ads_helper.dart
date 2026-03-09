import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

class BannerAdService {
  BannerAd? _bannerAd;

  BannerAd? get bannerAd => _bannerAd;

  void loadAd(Function onLoaded) {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Banner Ad Loaded');
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner failed: ${error.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  void dispose() {
    _bannerAd?.dispose();
  }
}
