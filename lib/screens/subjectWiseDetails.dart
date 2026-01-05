import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/subjectWiseDetails.dart';
import 'package:tazaquiznew/utils/richText.dart';

class SubjectContentPage extends StatefulWidget {
  @override
  _SubjectContentPageState createState() => _SubjectContentPageState();
}

class _SubjectContentPageState extends State<SubjectContentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  final List<Map<String, dynamic>> _studyMaterials = [
    {
      'title': 'Advanced Calculus Guide',
      'subject': 'Mathematics',
      'type': 'PDF',
      'size': '12.5 MB',
      'pages': 245,
      'downloads': 5420,
      'rating': 4.8,
      'isPremium': false,
      'thumbnail': 'calculus',
      'author': 'Dr. Sarah Johnson',
      'lastUpdated': '2 days ago',
    },
    {
      'title': 'Organic Chemistry Basics',
      'subject': 'Chemistry',
      'type': 'PDF',
      'size': '8.3 MB',
      'pages': 180,
      'downloads': 3890,
      'rating': 4.6,
      'isPremium': true,
      'thumbnail': 'chemistry',
      'author': 'Prof. Mike Chen',
      'lastUpdated': '1 week ago',
    },
    {
      'title': 'Physics Formulas Cheat Sheet',
      'subject': 'Physics',
      'type': 'PDF',
      'size': '2.1 MB',
      'pages': 45,
      'downloads': 8920,
      'rating': 4.9,
      'isPremium': false,
      'thumbnail': 'physics',
      'author': 'Dr. Alex Kumar',
      'lastUpdated': '3 days ago',
    },
    {
      'title': 'English Grammar Complete',
      'subject': 'English',
      'type': 'PDF',
      'size': '15.7 MB',
      'pages': 320,
      'downloads': 6750,
      'rating': 4.7,
      'isPremium': false,
      'thumbnail': 'english',
      'author': 'Lisa Williams',
      'lastUpdated': '5 days ago',
    },
    {
      'title': 'Quantum Mechanics Introduction',
      'subject': 'Physics',
      'type': 'VIDEO',
      'size': '450 MB',
      'duration': '3h 45m',
      'downloads': 2340,
      'rating': 4.8,
      'isPremium': true,
      'thumbnail': 'quantum',
      'author': 'Dr. James Wilson',
      'lastUpdated': '1 day ago',
    },
    {
      'title': 'Biology Notes - Class 12',
      'subject': 'Science',
      'type': 'PDF',
      'size': '9.8 MB',
      'pages': 210,
      'downloads': 4560,
      'rating': 4.5,
      'isPremium': false,
      'thumbnail': 'biology',
      'author': 'Dr. Priya Sharma',
      'lastUpdated': '4 days ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchStudyLevels();
  }

  Future<void> fetchStudyLevels() async {
    Authrepository authRepository = Authrepository(Api_Client.dio);
    Response response = await authRepository.fetchStudyLevels();

    if (response.statusCode == 200) {
      final data = response.data;

      if (data['success'] == true && data['data'] != null) {
        List list = data['data'];

        setState(() {
          _categories = ['All']; // reset
          _categories.addAll(list.map<String>((e) => e['name'].toString()).toList());
          _isLoading = false;
        });

        print('Study Levels: $_categories');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredMaterials {
    if (_selectedCategory == 'All') return _studyMaterials;
    return _studyMaterials.where((material) => material['subject'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildCategoriesSection()),
          _buildMaterialsList(),
          SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkNavy, AppColors.tealGreen],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title in single line
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.arrow_back, color: AppColors.white, size: 18),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Study Materials',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.tealGreen, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search materials...',
                hintStyle: TextStyle(color: AppColors.greyS400, fontSize: 14, fontFamily: "Poppins"),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.tune, color: AppColors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      margin: EdgeInsets.only(top: 16, bottom: 16),
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategory == _categories[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = _categories[index];
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 10),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]) : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? AppColors.tealGreen.withOpacity(0.3) : AppColors.black.withOpacity(0.04),
                    blurRadius: isSelected ? 12 : 6,
                    offset: Offset(0, isSelected ? 4 : 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.greyS700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterialsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final material = _filteredMaterials[index];
        return _buildMaterialCard(material);
      }, childCount: _filteredMaterials.length),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SubjectContentPage()));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            // Header Image Section
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(material['subject']),
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
                    ),
                  ),
                  Center(
                    child: Icon(
                      material['type'] == 'PDF' ? Icons.picture_as_pdf : Icons.play_circle_filled,
                      size: 50,
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        if (material['isPremium'])
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.workspace_premium, size: 12, color: AppColors.tealGreen),
                                SizedBox(width: 4),
                                Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.tealGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.25), shape: BoxShape.circle),
                          child: Icon(Icons.bookmark_outline, color: AppColors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        material['type'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getSubjectColor(material['subject']),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material['title'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tealGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          material['subject'],
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tealGreen),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.person_outline, size: 13, color: AppColors.greyS500),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          material['author'],
                          style: TextStyle(fontSize: 11, color: AppColors.greyS600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.insert_drive_file,
                        material['type'] == 'PDF' ? '${material['pages']} pages' : material['duration'],
                      ),
                      SizedBox(width: 10),
                      _buildInfoChip(Icons.file_download, material['size']),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.amber[700]),
                            SizedBox(width: 3),
                            Text(
                              '${material['rating']}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkNavy),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Single Preview button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _previewMaterial(material),
                      icon: Icon(
                        material['isPremium'] ? Icons.lock_outline : Icons.visibility_outlined,
                        size: 16,
                        color: AppColors.white,
                      ),
                      label: Text(
                        material['isPremium'] ? 'Unlock to Preview' : 'Preview',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.transparent,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ).decorated(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              material['isPremium']
                                  ? [AppColors.darkNavy, AppColors.tealGreen]
                                  : [AppColors.tealGreen, AppColors.darkNavy],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${material['downloads']} downloads',
                        style: TextStyle(fontSize: 10, color: AppColors.greyS500),
                      ),
                      Text(
                        'Updated ${material['lastUpdated']}',
                        style: TextStyle(fontSize: 10, color: AppColors.greyS500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.tealGreen),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.greyS700)),
      ],
    );
  }

  List<Color> _getGradientColors(String subject) {
    switch (subject) {
      case 'Mathematics':
        return [AppColors.darkNavy, AppColors.tealGreen];
      case 'Science':
        return [AppColors.tealGreen, AppColors.greenS2];
      case 'Physics':
        return [AppColors.oxfordBlue, AppColors.darkNavy];
      case 'Chemistry':
        return [AppColors.tealGreen, AppColors.darkNavy];
      case 'English':
        return [AppColors.darkNavy, AppColors.oxfordBlue];
      default:
        return [AppColors.tealGreen, AppColors.darkNavy];
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return AppColors.darkNavy;
      case 'Science':
        return AppColors.tealGreen;
      case 'Physics':
        return AppColors.oxfordBlue;
      case 'Chemistry':
        return AppColors.tealGreen;
      case 'English':
        return AppColors.darkNavy;
      default:
        return AppColors.tealGreen;
    }
  }

  void _previewMaterial(Map<String, dynamic> material) {
    if (material['isPremium']) {
      _showPremiumDialog();
    } else {
      _showPreviewDialog(material);
    }
  }

  void _showPreviewDialog(Map<String, dynamic> material) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _getGradientColors(material['subject'])),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      material['type'] == 'PDF' ? Icons.picture_as_pdf : Icons.play_circle_filled,
                      size: 40,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    material['title'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Preview feature coming soon!',
                    style: TextStyle(fontSize: 13, color: AppColors.greyS600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.transparent,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: Text(
                          'Close',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.workspace_premium, size: 40, color: AppColors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Premium Content',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Upgrade to Pro to access this material',
                    style: TextStyle(fontSize: 13, color: AppColors.greyS600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.greyS300),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.greyS700),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.transparent,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              child: Text(
                                'Upgrade',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white),
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
          ),
    );
  }
}

extension WidgetExtension on Widget {
  Widget decorated({required BoxDecoration decoration}) {
    return DecoratedBox(decoration: decoration, child: this);
  }
}
