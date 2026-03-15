class AdHelper {
  // ================= SWITCH =================
  static bool isTest = true;

  // ================= APP ID =================
  static const String androidTestAppId = 'ca-app-pub-3940256099942544~3347511713';

  static const String androidLiveAppId = 'ca-app-pub-2864505635048283~9032729860';

  // ================= REWARDED =================
  static const String rewardedTestAdUnit = 'ca-app-pub-3940256099942544/5224354917';

  static const String rewardedLiveAdUnit = 'ca-app-pub-2864505635048283/5221329943';

  // ================= BANNER =================
  static const String bannerTestAdUnit = 'ca-app-pub-3940256099942544/6300978111';

  static const String bannerLiveAdUnit = 'ca-app-pub-2864505635048283/9996714710';

  // ================= GETTERS =================
  static String get rewardedAdUnitId => isTest ? rewardedTestAdUnit : rewardedLiveAdUnit;

  static String get bannerAdUnitId => isTest ? bannerTestAdUnit : bannerLiveAdUnit;
}
