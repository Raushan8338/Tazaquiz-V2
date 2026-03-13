import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/API/api_endpoint.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/selected_courses_item.dart';
import 'package:tazaquiznew/screens/homeSceen.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

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
  final Set<int> _selectedIds = {};

  final TextEditingController _searchController = TextEditingController();

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
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchCourses() async {
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'user_id': _user!.id.toString()};
      final response = await authRepository.getUserSelected_non_Courses(data);
      print("Course fetch response: ${response.data}");

      if (response.statusCode == 200) {
        final List list = response.data['data'] ?? [];
        _coursesItem = list.map((e) => SelectedCourseItem.fromJson(e)).toList();

        _selectedIds.clear();
        for (var course in _coursesItem) {
          final sel = course.isSelected;
          if (sel == true || sel == 1 || sel == '1') {
            _selectedIds.add(course.categoryId);
          }
        }

        _filteredCourses = List.from(_coursesItem);
      }
    } catch (e) {
      debugPrint("Course fetch error: $e");
    }
  }

  void _filterCourses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCourses =
          query.isEmpty
              ? List.from(_coursesItem)
              : _coursesItem.where((c) => c.categoryName.toLowerCase().contains(query)).toList();
    });
  }

  void _onCourseToggle(int categoryId) {
    setState(() {
      if (_selectedIds.contains(categoryId)) {
        _selectedIds.remove(categoryId);
      } else {
        _selectedIds.add(categoryId);
      }
    });
  }

  Future<void> _updateCourses() async {
    setState(() => _isUpdating = true);
    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);

      // FormData manually banao array ke liye
      FormData formData = FormData();
      formData.fields.add(MapEntry('user_id', _user!.id.toString()));

      for (final id in _selectedIds) {
        formData.fields.add(MapEntry('category_ids[]', id.toString()));
      }

      final response = await Api_Client.dio.post(BaseUrl.save_update_user_courses, data: formData);
      print("RESPONSE: ${response.data}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Courses updated successfully!'),
            backgroundColor: primaryTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.pageId == 0
            ? Navigator.pop(context)
            : Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomeScreen()), (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedIds.length;

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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          '$selectedCount Course${selectedCount != 1 ? 's' : ''} Selected',
                          style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Grid
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
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _filteredCourses.length,
                              itemBuilder: (context, index) {
                                final course = _filteredCourses[index];
                                final isSelected = _selectedIds.contains(course.categoryId);
                                final hasImage = course.boardIcon != null && course.boardIcon!.isNotEmpty;

                                return GestureDetector(
                                  onTap: () => _onCourseToggle(course.categoryId),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? primaryTeal : Colors.grey.shade200,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              isSelected
                                                  ? primaryTeal.withOpacity(0.15)
                                                  : Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // ── TOP: Banner image ──────────
                                        Expanded(
                                          flex: 5,
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(13),
                                              topRight: Radius.circular(13),
                                            ),
                                            child:
                                                hasImage
                                                    ? CachedNetworkImage(
                                                      imageUrl: course.boardIcon!,
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (ctx, url) => Container(
                                                            color: accentOrange.withOpacity(0.07),
                                                            child: Center(
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: accentOrange,
                                                              ),
                                                            ),
                                                          ),
                                                      errorWidget: (ctx, url, err) => _fallbackBanner(isSelected),
                                                    )
                                                    : _fallbackBanner(isSelected),
                                          ),
                                        ),

                                        // ── BOTTOM: Name + Checkbox ────
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                // Course name
                                                Expanded(
                                                  child: Text(
                                                    course.categoryName,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                      height: 1.3,
                                                      color: isSelected ? primaryTeal : Colors.grey.shade800,
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(width: 6),

                                                // Checkbox
                                                AnimatedContainer(
                                                  duration: const Duration(milliseconds: 180),
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? primaryTeal : Colors.white,
                                                    borderRadius: BorderRadius.circular(5),
                                                    border: Border.all(
                                                      color: isSelected ? primaryTeal : Colors.grey.shade400,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child:
                                                      isSelected
                                                          ? const Icon(Icons.check, color: Colors.white, size: 13)
                                                          : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),

      // Bottom button
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

  Widget _fallbackBanner(bool isSelected) {
    return Container(
      color: isSelected ? primaryTeal.withOpacity(0.08) : accentOrange.withOpacity(0.08),
      child: Center(child: Icon(Icons.menu_book_rounded, size: 40, color: isSelected ? primaryTeal : accentOrange)),
    );
  }
}
