import 'package:flutter/material.dart';
import 'dart:async';

class StudyMaterialScreen extends StatefulWidget {
  @override
  _StudyMaterialScreenState createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

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
      backgroundColor: Color(0xFFF8F9FD),
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
      backgroundColor: Color(0xFF003161),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.bookmark_outline, color: Colors.white, size: 20),
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.download, color: Colors.white, size: 20),
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
              colors: [Color(0xFF003161), Color(0xFF016A67)],
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
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
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
                              color: Color(0xFFFDEB9E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.library_books, color: Color(0xFF003161), size: 32),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Study Materials',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              Text(
                                'Learn from the best resources',
                                style: TextStyle(fontSize: 13, color: Color(0xFFFDEB9E)),
                              ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Color(0xFF016A67), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search materials...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.tune, color: Colors.white, size: 20),
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
          colors: [Color(0xFFFDEB9E), Color(0xFFFDD835)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Color(0xFFFDEB9E).withOpacity(0.4), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.description, '1,234', 'Materials'),
          Container(width: 1, height: 40, color: Color(0xFF003161).withOpacity(0.2)),
          _buildStatItem(Icons.download, '45,678', 'Downloads'),
          Container(width: 1, height: 40, color: Color(0xFF003161).withOpacity(0.2)),
          _buildStatItem(Icons.people, '8,920', 'Learners'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF003161), size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Color(0xFF016A67), fontWeight: FontWeight.w600),
        ),
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
                gradient: isSelected ? LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]) : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? Color(0xFF016A67).withOpacity(0.3) : Colors.black.withOpacity(0.05),
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
                    color: isSelected ? Colors.white : Colors.grey[700],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Top Section with Thumbnail
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
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                  ),
                ),
                Center(
                  child: Icon(
                    material['type'] == 'PDF' ? Icons.picture_as_pdf : Icons.play_circle_filled,
                    size: 60,
                    color: Colors.white.withOpacity(0.9),
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
                            gradient: LinearGradient(colors: [Color(0xFFFDEB9E), Color(0xFFFDD835)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.workspace_premium, size: 12, color: Color(0xFF003161)),
                              SizedBox(width: 4),
                              Text(
                                'PRO',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: Icon(Icons.bookmark_outline, color: Colors.white, size: 18),
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
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      material['type'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
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
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material['title'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF003161)),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF016A67).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        material['subject'],
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF016A67)),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(material['author'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
                        color: Color(0xFFFDEB9E).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Color(0xFFFDD835)),
                          SizedBox(width: 4),
                          Text(
                            '${material['rating']}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
                          ),
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
                        icon: Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF003161)),
                        label: Text(
                          'Preview',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF003161)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFF003161), width: 2),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadMaterial(material),
                        icon: Icon(Icons.download, size: 18, color: Colors.white),
                        label: Text(
                          'Download',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      // .apply(
                      //   decoration: BoxDecoration(
                      //     gradient: LinearGradient(
                      //       colors: [Color(0xFF016A67), Color(0xFF003161)],
                      //     ),
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      // ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${material['downloads']} downloads', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    Text('Updated ${material['lastUpdated']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
        Icon(icon, size: 14, color: Color(0xFF016A67)),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  List<Color> _getGradientColors(String subject) {
    switch (subject) {
      case 'Mathematics':
        return [Color(0xFF003161), Color(0xFF016A67)];
      case 'Science':
        return [Color(0xFF016A67), Color(0xFF00A896)];
      case 'Physics':
        return [Color(0xFF000B58), Color(0xFF003161)];
      case 'Chemistry':
        return [Color(0xFF016A67), Color(0xFF003161)];
      case 'English':
        return [Color(0xFF003161), Color(0xFF000B58)];
      default:
        return [Color(0xFF016A67), Color(0xFF003161)];
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return Color(0xFF003161);
      case 'Science':
        return Color(0xFF016A67);
      case 'Physics':
        return Color(0xFF000B58);
      case 'Chemistry':
        return Color(0xFF016A67);
      case 'English':
        return Color(0xFF003161);
      default:
        return Color(0xFF016A67);
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
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Text(
                material['title'],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF003161)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Preview feature coming soon!',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      'Close',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
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

  void _downloadMaterial(Map<String, dynamic> material) {
    if (material['isPremium']) {
      _showPremiumDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.download, color: Colors.white),
              SizedBox(width: 12),
              Text('Downloading ${material['title']}...'),
            ],
          ),
          backgroundColor: Color(0xFF016A67),
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
              colors: [Colors.white, Color(0xFFF8F9FD)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFDEB9E), Color(0xFFFDD835)]),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.workspace_premium, size: 48, color: Color(0xFF003161)),
              ),
              SizedBox(height: 20),
              Text(
                'Premium Content',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF003161)),
              ),
              SizedBox(height: 12),
              Text(
                'Upgrade to Pro to access this material',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700]),
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
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF016A67), Color(0xFF003161)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: Text(
                            'Upgrade',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
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
