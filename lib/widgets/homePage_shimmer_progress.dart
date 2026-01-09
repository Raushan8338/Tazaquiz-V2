import 'package:flutter/material.dart';

class QuizShimmerUI extends StatelessWidget {
  const QuizShimmerUI({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const QuizShimmerLoading(),
      bottomNavigationBar: const ShimmerBottomNav(),
    );
  }
}

class QuizShimmerLoading extends StatefulWidget {
  const QuizShimmerLoading({Key? key}) : super(key: key);

  @override
  State<QuizShimmerLoading> createState() => _QuizShimmerLoadingState();
}

class _QuizShimmerLoadingState extends State<QuizShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return SafeArea(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Shimmer
                  _buildHeaderShimmer(),
                  const SizedBox(height: 20),

                  // Quiz Banner Shimmer
                  _buildQuizBannerShimmer(),
                  const SizedBox(height: 24),

                  // Weekly Progress Shimmer
                  _buildWeeklyProgressShimmer(),
                  const SizedBox(height: 24),

                  // Live Tests Section Shimmer
                  _buildLiveTestsShimmer(),
                  const SizedBox(height: 24),

                  // Popular Courses Shimmer
                  _buildPopularCoursesShimmer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderShimmer() {
    return Row(
      children: [
        // Profile Image Shimmer
        ShimmerBox(width: 45, height: 45, borderRadius: 22.5, shimmerController: _shimmerController),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Shimmer
              ShimmerBox(width: 150, height: 16, borderRadius: 4, shimmerController: _shimmerController),
              const SizedBox(height: 6),
              // Subtitle Shimmer
              ShimmerBox(width: 120, height: 12, borderRadius: 4, shimmerController: _shimmerController),
            ],
          ),
        ),
        // Notification Icon Shimmer
        ShimmerBox(width: 40, height: 40, borderRadius: 20, shimmerController: _shimmerController),
      ],
    );
  }

  Widget _buildQuizBannerShimmer() {
    return ShimmerBox(
      width: double.infinity,
      height: 160,
      borderRadius: 20,
      shimmerController: _shimmerController,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFF003161).withOpacity(0.3), const Color(0xFF016A67).withOpacity(0.3)],
      ),
    );
  }

  Widget _buildWeeklyProgressShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title Shimmer
              ShimmerBox(width: 130, height: 18, borderRadius: 4, shimmerController: _shimmerController),
              // Percentage Badge Shimmer
              ShimmerBox(width: 50, height: 28, borderRadius: 14, shimmerController: _shimmerController),
            ],
          ),
          const SizedBox(height: 20),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [_buildStatShimmer(), _buildStatShimmer(), _buildStatShimmer()],
          ),
        ],
      ),
    );
  }

  Widget _buildStatShimmer() {
    return Column(
      children: [
        ShimmerBox(width: 60, height: 12, borderRadius: 4, shimmerController: _shimmerController),
        const SizedBox(height: 8),
        ShimmerBox(width: 40, height: 24, borderRadius: 4, shimmerController: _shimmerController),
      ],
    );
  }

  Widget _buildLiveTestsShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Tests Title
                ShimmerBox(width: 100, height: 18, borderRadius: 4, shimmerController: _shimmerController),
                const SizedBox(height: 6),
                // Subtitle
                ShimmerBox(width: 200, height: 12, borderRadius: 4, shimmerController: _shimmerController),
              ],
            ),
            // View All Button
            ShimmerBox(width: 80, height: 32, borderRadius: 16, shimmerController: _shimmerController),
          ],
        ),
        const SizedBox(height: 16),
        // Test Cards
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 16, left: index == 0 ? 0 : 0),
                child: _buildTestCardShimmer(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTestCardShimmer() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF016A67).withOpacity(0.2), const Color(0xFF003161).withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upcoming Badge
          ShimmerBox(width: 80, height: 24, borderRadius: 12, shimmerController: _shimmerController),
          const SizedBox(height: 16),
          // Title
          ShimmerBox(width: 160, height: 16, borderRadius: 4, shimmerController: _shimmerController),
          const SizedBox(height: 8),
          // Subtitle
          ShimmerBox(width: 100, height: 12, borderRadius: 4, shimmerController: _shimmerController),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Join Now Button
              ShimmerBox(width: 90, height: 36, borderRadius: 18, shimmerController: _shimmerController),
              // Icon
              ShimmerBox(width: 36, height: 36, borderRadius: 18, shimmerController: _shimmerController),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCoursesShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title
            ShimmerBox(width: 140, height: 18, borderRadius: 4, shimmerController: _shimmerController),
            // View All Button
            ShimmerBox(width: 80, height: 32, borderRadius: 16, shimmerController: _shimmerController),
          ],
        ),
        const SizedBox(height: 16),
        // Course Cards
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: 16, left: index == 0 ? 0 : 0),
                child: _buildCourseCardShimmer(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCardShimmer() {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF016A67).withOpacity(0.2), const Color(0xFF003161).withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Badge
          ShimmerBox(width: 70, height: 24, borderRadius: 12, shimmerController: _shimmerController),
          const SizedBox(height: 16),
          // Icon
          ShimmerBox(width: 50, height: 50, borderRadius: 25, shimmerController: _shimmerController),
        ],
      ),
    );
  }
}

class ShimmerBottomNav extends StatefulWidget {
  const ShimmerBottomNav({Key? key}) : super(key: key);

  @override
  State<ShimmerBottomNav> createState() => _ShimmerBottomNavState();
}

class _ShimmerBottomNavState extends State<ShimmerBottomNav> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerBox(width: 24, height: 24, borderRadius: 4, shimmerController: _shimmerController),
                  const SizedBox(height: 6),
                  ShimmerBox(width: 40, height: 10, borderRadius: 4, shimmerController: _shimmerController),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final AnimationController shimmerController;
  final Gradient? gradient;

  const ShimmerBox({
    Key? key,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.shimmerController,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment(-1.0 - shimmerController.value * 2, 0),
              end: Alignment(1.0 - shimmerController.value * 2, 0),
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: const [0.0, 0.5, 1.0],
            ),
      ),
    );
  }
}
