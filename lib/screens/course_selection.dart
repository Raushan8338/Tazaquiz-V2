import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiz/API/api_client.dart';
import 'package:tazaquiz/authentication/AuthRepository.dart';
import 'package:tazaquiz/models/login_response_model.dart';
import 'package:tazaquiz/models/selected_courses_item.dart';
import 'package:tazaquiz/screens/homeSceen.dart';
import 'package:tazaquiz/utils/session_manager.dart';

class MyCoursesSelection extends StatefulWidget {
  int pageId;
  MyCoursesSelection({super.key, required this.pageId});

  @override
  State<MyCoursesSelection> createState() => _MyCoursesSelectionState();
}

class _MyCoursesSelectionState extends State<MyCoursesSelection> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isUpdating = false;
  List<SelectedCourseItem> _coursesItem = [];
  List<SelectedCourseItem> _filteredCourses = [];

  final TextEditingController _searchController = TextEditingController();

  // Your app colors
  final Color primaryTeal = const Color(0xFF00695C);
  final Color accentOrange = const Color(0xFFFF9800);
  final Color lightBg = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _init();
    _searchController.addListener(_filterCourses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _user = await SessionManager.getUser();
    if (_user == null) return;

    await _fetchCourses();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCourses() async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'user_id': _user!.id.toString()};

      final response = await authRepository.getUserSelected_non_Courses(data);

      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];

        _coursesItem = list.map((e) => SelectedCourseItem.fromJson(e)).toList();

        // Debug: Check isSelected values
        for (var course in _coursesItem) {
          print("Course: ${course.categoryName}, isSelected: ${course.isSelected}");
        }

        // Sort: selected courses first
        _coursesItem.sort((a, b) => b.isSelected.toString().compareTo(a.isSelected.toString()));

        _filteredCourses = List.from(_coursesItem);
      }
    } catch (e) {
      debugPrint("Course fetch error: $e");
    }
  }

  void _filterCourses() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredCourses = List.from(_coursesItem);
      } else {
        _filteredCourses =
            _coursesItem.where((course) {
              return course.categoryName.toLowerCase().contains(query);
            }).toList();
      }
    });
  }

  void _onCourseToggle(SelectedCourseItem course) {
    setState(() {
      final originalIndex = _coursesItem.indexWhere((c) => c.categoryId == course.categoryId);

      if (originalIndex != -1) {
        _coursesItem[originalIndex].isSelected = !_coursesItem[originalIndex].isSelected;
      }

      // Re-sort both lists
      _coursesItem.sort((a, b) => b.isSelected.toString().compareTo(a.isSelected.toString()));
      _filterCourses();
    });
  }

  Future<void> _updateCourses() async {  
    setState(() => _isUpdating = true);

    try {
      final selectedIds = _coursesItem.where((c) => c.isSelected).map((c) => c.categoryId).toList();
      Authrepository authRepository = Authrepository(Api_Client.dio);
      List<int> categoryIds = selectedIds;
      for (var id in categoryIds) {
        final data = {'user_id': _user!.id.toString(), 'category_id': id.toString()};


        await authRepository.Saveupdate_user_courses(data);
     
      }

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Courses updated successfully!'),
            backgroundColor: primaryTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.pageId == 0 ?
        Navigator.pop(context):
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomeScreen()), (route) => false);


      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _coursesItem.where((c) => c.isSelected).length;

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryTeal,
        leading: IconButton(
          icon: Icon(widget.pageId == 0 ? Icons.arrow_back : Icons.check, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Courses",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Search bar
                  Container(
                    color: primaryTeal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search courses...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white, size: 20),
                                  onPressed: () => _searchController.clear(),
                                )
                                : null,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),

                  // Selected count
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.school, color: primaryTeal, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$selectedCount Courses Selected',
                          style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Grid view
                  Expanded(
                    child:
                        _filteredCourses.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isEmpty ? 'No courses found' : 'No matching courses',
                                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                            : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.50,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _filteredCourses.length,
                              itemBuilder: (context, index) {
                                final course = _filteredCourses[index];

                                return GestureDetector(
                                  onTap: () => _onCourseToggle(course),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: course.isSelected ? primaryTeal : Colors.grey.shade200,
                                        width: course.isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              course.isSelected
                                                  ? primaryTeal.withOpacity(0.15)
                                                  : Colors.grey.withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          // Icon
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  course.isSelected
                                                      ? primaryTeal.withOpacity(0.1)
                                                      : accentOrange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.book_outlined,
                                              color: course.isSelected ? primaryTeal : accentOrange,
                                              size: 28,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          // Course name
                                          Text(
                                            course.categoryName,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              height: 1.2,
                                              color: course.isSelected ? Colors.grey.shade900 : Colors.grey.shade700,
                                            ),
                                          ),

                                          const Spacer(),

                                          // Bottom row: Checkbox (left) + Description (right)
                                        Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    // Description - always center aligned
    Expanded(
      child: Center(
        child: course.description.isNotEmpty
            ? Text(
                course.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  height: 1.1,
                ),
              )
            : const SizedBox.shrink(),
      ),
    ),

    const SizedBox(width: 6),

    // Checkbox - always on right
    Container(
      decoration: BoxDecoration(
        color: course.isSelected ? primaryTeal : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: course.isSelected
              ? primaryTeal
              : Colors.grey.shade400,
          width: 2,
        ),
      ),
      width: 18,
      height: 18,
      child: course.isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    ),
  ],
)
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),

      // Bottom update button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isUpdating || selectedCount == 0 ? null : _updateCourses,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child:
                _isUpdating
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          selectedCount == 0
                              ? 'Select Courses to Update'
                              : 'Update $selectedCount Course${selectedCount > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
