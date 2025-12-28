import 'package:flutter/material.dart';
import 'dart:async';

import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/utils/richText.dart';

class StudyMaterialScreen extends StatefulWidget {
  @override
  _StudyMaterialScreenState createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
 //hyggtt
  final List<String> _categories = ['All', 'Mathematics', 'Science', 'English', 'Physics', 'Chemistry'];

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
          SliverToBoxAdapter(
            child: Column(children: [_buildSearchBar(), _buildStatsSection(), _buildCategoriesSection()]),
          ),
          _buildMaterialsList(),
          SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.darkNavy,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.bookmark_outline, color: AppColors.white, size: 20),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.download, color: AppColors.white, size: 20),
          ),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkNavy, AppColors.tealGreen],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(color: AppColors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(color: AppColors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(left: 60, right: 60, top: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightGold,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.library_books, color: AppColors.darkNavy, size: 32),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppRichText.setTextPoppinsStyle(context, 'Study Materials', 24, AppColors.white, FontWeight.w900, 1, TextAlign.left, 0.0),
                            
                              AppRichText.setTextPoppinsStyle(context, 'Learn from the best resources', 13, AppColors.lightGold, FontWeight.normal, 1, TextAlign.left, 0.0),
                           
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 20),
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.tealGreen, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search materials...',
                hintStyle: TextStyle(color: AppColors.greyS400, fontSize: 15, fontFamily: "Poppins"),
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
            child: Icon(Icons.tune, color: AppColors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lightGold, AppColors.lightGoldS2],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.lightGold.withOpacity(0.4), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.description, '1,234', 'Materials'),
          Container(width: 1, height: 40, color: AppColors.darkNavy.withOpacity(0.2)),
          _buildStatItem(Icons.download, '45,678', 'Downloads'),
          Container(width: 1, height: 40, color: AppColors.darkNavy.withOpacity(0.2)),
          _buildStatItem(Icons.people, '8,920', 'Learners'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.darkNavy, size: 24),
        SizedBox(height: 8),
        AppRichText.setTextPoppinsStyle(context, value, 18, AppColors.darkNavy, FontWeight.w900, 1, TextAlign.left, 0.0),

      
        AppRichText.setTextPoppinsStyle(context, label, 11, AppColors.tealGreen, FontWeight.w900, 1, TextAlign.left, 0.0),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      margin: EdgeInsets.only(top: 20, bottom: 16),
      height: 45,
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
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]) : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? AppColors.tealGreen.withOpacity(0.3) : AppColors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 15 : 8,
                    offset: Offset(0, isSelected ? 5 : 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.08), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getGradientColors(material['subject']),
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
                  ),
                ),
                Center(
                  child: Icon(
                    material['type'] == 'PDF' ? Icons.picture_as_pdf : Icons.play_circle_filled,
                    size: 60,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (material['isPremium'])
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.workspace_premium, size: 12, color: AppColors.darkNavy),
                              SizedBox(width: 4),
                              AppRichText.setTextPoppinsStyle(context, 'PRO', 10, AppColors.darkNavy, FontWeight.w900, 1, TextAlign.left, 0.0),

                          
                            ],
                          ),
                        ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(Icons.bookmark_outline, color: AppColors.white, size: 18),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AppRichText.setTextPoppinsStyle(context,  material['type'], 11, _getSubjectColor(material['subject']), FontWeight.w900, 1, TextAlign.left, 0.0),

                    
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppRichText.setTextPoppinsStyle(context, material['title'], 18, AppColors.darkNavy, FontWeight.w800, 1, TextAlign.left, 0.0),

                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tealGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppRichText.setTextPoppinsStyle(context, material['subject'], 11, AppColors.tealGreen, FontWeight.w700, 1, TextAlign.left, 0.0),

                   
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.person_outline, size: 14, color: AppColors.greyS600),
                    SizedBox(width: 4),
                    AppRichText.setTextPoppinsStyle(context, material['author'], 12, AppColors.greyS600, FontWeight.normal, 1, TextAlign.left, 0.0),

                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.insert_drive_file,
                      material['type'] == 'PDF' ? '${material['pages']} pages' : material['duration'],
                    ),
                    SizedBox(width: 12),
                    _buildInfoChip(Icons.file_download, material['size']),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightGold.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 14, color: AppColors.lightGoldS2),
                          SizedBox(width: 4),
                           AppRichText.setTextPoppinsStyle(context, '${material['rating']}', 12, AppColors.darkNavy, FontWeight.w700, 1, TextAlign.left, 0.0),

                     
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPreviewDialog(material),
                        icon: Icon(Icons.visibility_outlined, size: 18, color: AppColors.darkNavy),
                        label:  AppRichText.setTextPoppinsStyle(context, 'Preview', 13, AppColors.darkNavy, FontWeight.w700, 1, TextAlign.left, 0.0),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.darkNavy, width: 2),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadMaterial(material),
                        icon: Icon(Icons.download, size: 18, color: AppColors.white),
                        label: AppRichText.setTextPoppinsStyle(context, 'Download', 13, AppColors.white, FontWeight.w700, 1, TextAlign.left, 0.0),
                   
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.transparent,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppRichText.setTextPoppinsStyle(context, '${material['downloads']} downloads', 11, AppColors.greyS600, FontWeight.normal, 1, TextAlign.left, 0.0),
                    AppRichText.setTextPoppinsStyle(context, 'Updated ${material['lastUpdated']}', 11, AppColors.greyS600, FontWeight.normal, 1, TextAlign.left, 0.0),
                ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.tealGreen),
        SizedBox(width: 4),
        AppRichText.setTextPoppinsStyle(context, text, 12, AppColors.greyS700, FontWeight.w500, 1, TextAlign.left, 0.0),

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

  void _showPreviewDialog(Map<String, dynamic> material) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _getGradientColors(material['subject'])),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  material['type'] == 'PDF' ? Icons.picture_as_pdf : Icons.play_circle_filled,
                  size: 48,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: 20),
              AppRichText.setTextPoppinsStyle(context, material['title'], 20, AppColors.darkNavy, FontWeight.w800, 1, TextAlign.left, 0.0),

              SizedBox(height: 12),
              AppRichText.setTextPoppinsStyle(context, 'Preview feature coming soon!', 14, AppColors.greyS600, FontWeight.normal, 1, TextAlign.center, 0.0),

            
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.transparent,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: AppRichText.setTextPoppinsStyle(context, 'Close', 15, AppColors.white, FontWeight.w700, 1, TextAlign.center, 0.0),
 
                   
                
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadMaterial(Map<String, dynamic> material) {
    if (material['isPremium']) {
      _showPremiumDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.download, color: AppColors.white),
              SizedBox(width: 12),
              AppRichText.setTextPoppinsStyle(context, 'Downloading ${material['title']}...', 13, AppColors.black, FontWeight.normal, 1, TextAlign.center, 0.0),
            ],
          ),
          backgroundColor: AppColors.tealGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.white, AppColors.greyS1],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.lightGoldS2]),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium, size: 48, color: AppColors.darkNavy),
              ),
              SizedBox(height: 20),
              AppRichText.setTextPoppinsStyle(context, 'Premium Content', 22, AppColors.darkNavy, FontWeight.w900, 1, TextAlign.left, 0.0),

             
              SizedBox(height: 12),
              AppRichText.setTextPoppinsStyle(context, 'Upgrade to Pro to access this material', 14, AppColors.greyS600, FontWeight.normal, 1, TextAlign.left, 0.0),

            
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.greyS300),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child:  AppRichText.setTextPoppinsStyle(context, 'Cancel', 15, AppColors.greyS700, FontWeight.w600, 1, TextAlign.left, 0.0),

                    
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: AppRichText.setTextPoppinsStyle(context, 'Upgrade', 15, AppColors.white, FontWeight.w700, 1, TextAlign.left, 0.0),
                       
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
