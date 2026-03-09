import 'dart:ui';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;

  void loadAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          print('✅ Rewarded Ad Loaded');
        },
        onAdFailedToLoad: (error) {
          print('❌ Failed to load: ${error.message}');
        },
      ),
    );
  }

  void showAd(VoidCallback onReward) {
    if (_rewardedAd == null) {
      print('⚠️ Ad not ready');
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        onReward();
      },
    );

    _rewardedAd = null;
    loadAd();
  }
}
