import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tazaquiznew/API/api_client.dart';
import 'package:tazaquiznew/authentication/AuthRepository.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/login_response_model.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';
import 'package:tazaquiznew/models/study_category_item.dart';
import 'package:tazaquiznew/screens/buyQuizes.dart';
import 'package:tazaquiznew/screens/seriesWiseQuizList.dart';
import 'package:tazaquiznew/utils/richText.dart';
import 'package:tazaquiznew/utils/session_manager.dart';

class Paid_QuizListScreen extends StatefulWidget {
  String pageId;
  Paid_QuizListScreen(this.pageId);

  @override
  _Paid_QuizListScreenState createState() => _Paid_QuizListScreenState();
}

class _Paid_QuizListScreenState extends State<Paid_QuizListScreen> with SingleTickerProviderStateMixin {
  bool _isGridView = true;
  String _selectedFilter = 'all'; // 'all', 'live', 'upcoming'

  late TabController _tabController;
  List<CategoryItem> _categories = [];
  int _selectedCategoryId = 0;

  bool _isLoading = true;
  bool _isFetchingQuizzes = false;
  List<QuizItem> _quizzes = [];

  // Colors for gradient cards
  final List<List<Color>> _gradientColors = [
    [Color(0xFF1A4D6D), Color(0xFF28A194)],
    [Color(0xFF28A194), Color(0xFF1A4D6D)],
    [Color(0xFF0C3756), Color(0xFF1A4D6D)],
    [Color(0xFF1A4D6D), Color(0xFF0C3756)],
    [Color(0xFF28A194), Color(0xFF0C3756)],
  ];
  UserModel? _user;
  @override
  void initState() {
    super.initState();
    _getUserData();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getUserData() async {
    _user = await SessionManager.getUser();
    setState(() {});
    fetchQuizData();
  }

  Future<void> fetchQuizData() async {
    setState(() {
      _isFetchingQuizzes = true;
    });

    try {
      Authrepository authRepository = Authrepository(Api_Client.dio);
      final data = {'subscription_id': widget.pageId, 'user_id': _user!.id.toString()};
      print(data);
      final responseFuture = await authRepository.get_paid_quizes_api(data);

      if (responseFuture.statusCode == 200) {
        final responseData = responseFuture.data;
        final List list = responseData['data'] ?? [];

        setState(() {
          _quizzes = list.map((e) => QuizItem.fromJson(e)).toList();
          _isFetchingQuizzes = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isFetchingQuizzes = false;
        _isLoading = false;
      });
      print('Error fetching quizzes: $e');
    }
  }

  List<QuizItem> get _filteredQuizzes {
    if (_selectedFilter == 'all') {
      return _quizzes;
    } else if (_selectedFilter == 'live') {
      return _quizzes.where((quiz) => quiz.isLive).toList();
    } else if (_selectedFilter == 'upcoming') {
      return _quizzes.where((quiz) => quiz.quizStatus == 'upcoming' && !quiz.isLive).toList();
    }
    return _quizzes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyS1,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Loading or Content
          if (_isFetchingQuizzes)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen)),
                ),
              ),
            )
          else if (_filteredQuizzes.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.quiz_outlined, size: 80, color: AppColors.greyS400),
                      SizedBox(height: 16),
                      Text(
                        'No quizzes found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.greyS600),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Try selecting a different category',
                        style: TextStyle(fontSize: 14, color: AppColors.greyS500),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            _isGridView ? _buildGridView() : _buildListView(),

          SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
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
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          (widget.pageId == '1')
                              ? IconButton(
                                icon: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
                                ),
                                onPressed: () => Navigator.pop(context),
                              )
                              : Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.quiz, color: AppColors.white, size: 22),
                              ),

                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Quizzes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  '${_filteredQuizzes.length} quiz${_filteredQuizzes.length != 1 ? 'zes' : ''} available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.white.withOpacity(0.8),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _isGridView ? Icons.view_list : Icons.grid_view,
                                color: AppColors.white,
                                size: 22,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _isGridView = !_isGridView;
                              });
                            },
                          ),
                          IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.filter_list, color: AppColors.white, size: 22),
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => _buildFilterBottomSheet(),
                              );
                            },
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

  Widget _buildCategoriesSection() {
    if (_isLoading) {
      return Container(
        margin: EdgeInsets.only(top: 16, bottom: 16),
        height: 42,
        child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.tealGreen))),
      );
    }

    return Container(
      margin: EdgeInsets.only(top: 16, bottom: 16),
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          bool isSelected = _selectedCategoryId == category.category_id;

          return GestureDetector(
            onTap: () async {
              setState(() {
                _selectedCategoryId = category.category_id;
              });
              await fetchQuizData();
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
                  category.name,
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

  Widget _buildGridView() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final quiz = _filteredQuizzes[index];
          final colors = _gradientColors[index % _gradientColors.length];
          return _buildGridCard(quiz, colors);
        }, childCount: _filteredQuizzes.length),
      ),
    );
  }

  Widget _buildListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final quiz = _filteredQuizzes[index];
        final colors = _gradientColors[index % _gradientColors.length];
        return _buildListCard(quiz, colors);
      }, childCount: _filteredQuizzes.length),
    );
  }

  Widget _buildGridCard(QuizItem quiz, List<Color> colors) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QuizDetailPage(quizId: quiz.quizId, is_subscribed: true)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: quiz.isLive ? Color(0xFFFF3B30) : Color(0xFFFFB800),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (quiz.isLive)
                              Container(
                                width: 6,
                                height: 6,
                                margin: EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                              ),
                            Text(
                              quiz.isLive ? 'LIVE' : 'UPCOMING',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.white),
                            ),
                          ],
                        ),
                      ),
                      if (quiz.isPaid && !quiz.isPurchased)
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.25), shape: BoxShape.circle),
                          child: Icon(Icons.workspace_premium, color: AppColors.white, size: 14),
                        ),
                    ],
                  ),
                  Spacer(),
                  Text(
                    quiz.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (quiz.difficultyLevel.isNotEmpty)
                    Text(
                      quiz.difficultyLevel,
                      style: TextStyle(fontSize: 11, color: AppColors.white.withOpacity(0.8), fontFamily: 'Poppins'),
                    ),
                  if (quiz.startsInText.isNotEmpty && !quiz.isLive)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Starts in ${quiz.startsInText}',
                        style: TextStyle(fontSize: 10, color: AppColors.white.withOpacity(0.9), fontFamily: 'Poppins'),
                      ),
                    ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          quiz.isAccessible ? (quiz.isLive ? Icons.play_arrow : Icons.schedule) : Icons.lock,
                          color: colors[0],
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _getButtonText(quiz),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors[0]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(QuizItem quiz, List<Color> colors) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QuizDetailPage(quizId: quiz.quizId, is_subscribed: true)),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 120,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
                    ),
                  ),
                  Center(child: Icon(Icons.quiz, size: 50, color: AppColors.white.withOpacity(0.9))),
                  if (quiz.isPaid && !quiz.isPurchased)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.white.withOpacity(0.25), shape: BoxShape.circle),
                        child: Icon(Icons.workspace_premium, color: AppColors.white, size: 14),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: quiz.isLive ? Color(0xFFFF3B30) : Color(0xFFFFB800),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (quiz.isLive)
                            Container(
                              width: 5,
                              height: 5,
                              margin: EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                            ),
                          Text(
                            quiz.isLive ? 'LIVE' : 'UPCOMING',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkNavy),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (quiz.description.isNotEmpty)
                      Text(
                        quiz.description,
                        style: TextStyle(fontSize: 12, color: AppColors.greyS600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (quiz.difficultyLevel.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.tealGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              quiz.difficultyLevel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.tealGreen),
                            ),
                          ),
                          SizedBox(width: 6),
                        ],
                        if (quiz.timeLimit.isNotEmpty) ...[
                          Icon(Icons.timer, size: 12, color: AppColors.greyS500),
                          SizedBox(width: 3),
                          Text(quiz.timeLimit, style: TextStyle(fontSize: 11, color: AppColors.greyS600)),
                        ],
                      ],
                    ),
                    if (quiz.startsInText.isNotEmpty && !quiz.isLive) ...[
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 12, color: AppColors.greyS500),
                          SizedBox(width: 4),
                          Text(
                            'Starts in ${quiz.startsInText}',
                            style: TextStyle(fontSize: 11, color: AppColors.greyS600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            quiz.isAccessible ? (quiz.isLive ? Icons.play_arrow : Icons.schedule) : Icons.lock,
                            color: AppColors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _getButtonText(quiz),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonText(QuizItem quiz) {
    if (!quiz.isAccessible) {
      if (quiz.isPaid && !quiz.isPurchased) {
        return 'Unlock - ₹${quiz.price.toStringAsFixed(0)}';
      }
      return 'Locked';
    }

    if (quiz.isLive) {
      return 'Join Now';
    }

    return 'View Details';
  }

  Widget _buildFilterBottomSheet() {
    String tempSelectedFilter = _selectedFilter;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: AppColors.greyS300, borderRadius: BorderRadius.circular(10)),
              ),

              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.filter_list, color: AppColors.white, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: AppRichText.setTextPoppinsStyle(
                        context,
                        'Filter Quizzes',
                        20,
                        AppColors.darkNavy,
                        FontWeight.w900,
                        1,
                        TextAlign.left,
                        0.0,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppColors.greyS600),
                    ),
                  ],
                ),
              ),

              Container(height: 1, color: AppColors.greyS200),

              // Filter options
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Select Quiz Type',
                      16,
                      AppColors.darkNavy,
                      FontWeight.w800,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    SizedBox(height: 8),
                    AppRichText.setTextPoppinsStyle(
                      context,
                      'Choose one option to filter quizzes',
                      13,
                      AppColors.greyS600,
                      FontWeight.w500,
                      1,
                      TextAlign.left,
                      0.0,
                    ),
                    SizedBox(height: 20),

                    // All Quizzes Option
                    _buildFilterOption(
                      context: context,
                      icon: Icons.view_list,
                      title: 'All Quizzes',
                      subtitle: 'Show all available quizzes',
                      isSelected: tempSelectedFilter == 'all',
                      activeColor: AppColors.darkNavy,
                      onTap: () {
                        setModalState(() {
                          tempSelectedFilter = 'all';
                        });
                      },
                    ),

                    SizedBox(height: 12),

                    // Live Quiz Option
                    _buildFilterOption(
                      context: context,
                      icon: Icons.radio_button_checked,
                      title: 'Live Quiz',
                      subtitle: 'Show quizzes that are currently live',
                      isSelected: tempSelectedFilter == 'live',
                      activeColor: Color(0xFFFF3B30),
                      onTap: () {
                        setModalState(() {
                          tempSelectedFilter = 'live';
                        });
                      },
                    ),

                    SizedBox(height: 12),

                    // Upcoming Quiz Option
                    _buildFilterOption(
                      context: context,
                      icon: Icons.schedule,
                      title: 'Upcoming Quiz',
                      subtitle: 'Show quizzes scheduled for later',
                      isSelected: tempSelectedFilter == 'upcoming',
                      activeColor: AppColors.tealGreen,
                      onTap: () {
                        setModalState(() {
                          tempSelectedFilter = 'upcoming';
                        });
                      },
                    ),

                    SizedBox(height: 24),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedFilter = tempSelectedFilter;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.transparent,
                          shadowColor: AppColors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.tealGreen, AppColors.darkNavy]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: AppColors.white, size: 22),
                                SizedBox(width: 10),
                                AppRichText.setTextPoppinsStyle(
                                  context,
                                  'Apply Filter',
                                  16,
                                  AppColors.white,
                                  FontWeight.w700,
                                  1,
                                  TextAlign.center,
                                  0.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(colors: [activeColor.withOpacity(0.15), activeColor.withOpacity(0.08)])
                  : null,
          color: isSelected ? null : AppColors.greyS1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? activeColor : AppColors.greyS300!, width: isSelected ? 2.5 : 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.2) : AppColors.greyS200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? activeColor : AppColors.greyS600, size: 26),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppRichText.setTextPoppinsStyle(
                    context,
                    title,
                    15,
                    AppColors.darkNavy,
                    FontWeight.w700,
                    1,
                    TextAlign.left,
                    0.0,
                  ),
                  SizedBox(height: 4),
                  AppRichText.setTextPoppinsStyle(
                    context,
                    subtitle,
                    12,
                    AppColors.greyS600,
                    FontWeight.w500,
                    2,
                    TextAlign.left,
                    0.0,
                  ),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? activeColor : AppColors.greyS400, width: 2.5),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: activeColor),
                        ),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
