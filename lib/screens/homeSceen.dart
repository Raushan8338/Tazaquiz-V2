import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/screens/home.dart';
import 'package:tazaquiznew/screens/profileScreen.dart';
import 'package:tazaquiznew/screens/quizListDetailsPage.dart';
import 'package:tazaquiznew/screens/studyMaterial.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //hyggtt
  int _selectedNavIndex = 0;

  final List<Widget> _pages = [HomePage(), StudyMaterialScreen('0'), QuizListScreen('0'), StudentProfilePage()];

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedNavIndex != 0) {
          setState(() {
            _selectedNavIndex = 0;
          });
          return false;
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return _buildExitDialog(context);
            },
          );
          return shouldExit ?? false;
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedNavIndex, children: _pages),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // Widget _buildBottomNav() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
  //       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: Offset(0, -10))],
  //     ),
  //     child: SafeArea(
  //       child: Padding(
  //         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
  //           children: [
  //             _buildNavItem(Icons.home_rounded, 'Home', 0),
  //             _buildNavItem(Icons.book, 'Courses', 1),
  //             _buildNavItem(Icons.quiz_rounded, 'Quiz', 2),
  //             _buildNavItem(Icons.person_rounded, 'Profile', 3),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: Offset(0, -10))],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem('assets/icons/home.png', 'Home', 0),
              _buildNavItem('assets/icons/learning.png', 'Courses', 1),
              // _buildNavItem('assets/icons/graduation.png', 'My Courses', 1),
              _buildNavItem('assets/icons/ideas.png', 'Quiz', 2),
              _buildNavItem('assets/icons/user.png', 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, int index) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [AppColors.tealGreen, AppColors.tealGreen.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                  : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow:
              isSelected
                  ? [BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))]
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon with Scale
            AnimatedScale(
              scale: 1.0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(isSelected ? Colors.white : AppColors.greyS600, BlendMode.srcIn),
                child: Image.asset(iconPath, width: 24, height: 24),
              ),
            ),
            SizedBox(height: 2),
            // Animated Label
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.greyS600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildNavItem(IconData icon, String label, int index) {
  //   final isSelected = _selectedNavIndex == index;

  //   return GestureDetector(
  //     onTap: () {
  //       setState(() {
  //         _selectedNavIndex = index;
  //       });
  //       // Navigate based on index
  //     },
  //     behavior: HitTestBehavior.opaque,
  //     child: AnimatedContainer(
  //       duration: Duration(milliseconds: 300),
  //       curve: Curves.easeInOut,
  //       padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: 8),
  //       decoration: BoxDecoration(
  //         gradient:
  //             isSelected
  //                 ? LinearGradient(
  //                   colors: [AppColors.tealGreen, AppColors.tealGreen.withOpacity(0.7)],
  //                   begin: Alignment.topLeft,
  //                   end: Alignment.bottomRight,
  //                 )
  //                 : null,
  //         borderRadius: BorderRadius.circular(16),
  //         boxShadow:
  //             isSelected
  //                 ? [BoxShadow(color: AppColors.tealGreen.withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))]
  //                 : null,
  //       ),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(icon, color: isSelected ? Colors.white : AppColors.greyS600, size: isSelected ? 26 : 24),
  //           if (isSelected) ...[
  //             SizedBox(width: 8),
  //             Text(
  //               label,
  //               style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
  //             ),
  //           ],
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildExitDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFe74c3c).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.exit_to_app_rounded, size: 48, color: Color(0xFFe74c3c)),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Exit App',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF003161)),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              'Are you sure you want to exit TazaQuiz?',
              style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFe74c3c),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Exit',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
