// Coaching Item Model
class CoachingItem {
  final String id;
  final String coachingName;
  final String? bioInfo;
  final String? bannerImg;
  final String? profileIcon;

  CoachingItem({required this.id, required this.coachingName, this.bioInfo, this.bannerImg, this.profileIcon});

  factory CoachingItem.fromJson(Map<String, dynamic> json) {
    return CoachingItem(
      id: json['id']?.toString() ?? '',
      coachingName: json['coaching_name'] ?? '',
      bioInfo: json['bio_info'],
      bannerImg: json['banner_img'],
      profileIcon: json['profile_icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coaching_name': coachingName,
      'bio_info': bioInfo,
      'banner_img': bannerImg,
      'profile_icon': profileIcon,
    };
  }
}
