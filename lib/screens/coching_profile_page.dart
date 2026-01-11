import 'package:flutter/material.dart';

// ========== COACHING PROFILE CARD WIDGET (NEW DESIGN) ==========
class CoachingProfileCard extends StatelessWidget {
  final String name;
  final String? bannerImg;
  final String coachingId;

  const CoachingProfileCard({Key? key, required this.name, this.bannerImg, required this.coachingId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to detail page
      },
      child: Container(
        margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Section with Avatar
            Stack(
              children: [
                // Banner Image or Gradient
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    gradient:
                        bannerImg == null || bannerImg!.isEmpty
                            ? LinearGradient(
                              colors: [Color(0xFF0F4C75), Color(0xFF1B9AAA), Color(0xFF06D6A0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                    image:
                        bannerImg != null && bannerImg!.isNotEmpty
                            ? DecorationImage(image: NetworkImage(bannerImg!), fit: BoxFit.cover)
                            : null,
                  ),
                ),

                // Rating Badge (Top Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          '4.5',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Avatar (Bottom Left - Overlapping)
                Positioned(
                  bottom: -30,
                  left: 16,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 6),

                  // Description
                  // if (description != null && description!.isNotEmpty)
                  Text(
                    'description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), height: 1.4, fontFamily: 'Poppins'),
                  ),
                  SizedBox(height: 12),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatItem(icon: Icons.people_outline, label: '10 + Students', color: Color(0xFF6C63FF)),
                      SizedBox(width: 20),
                      _buildStatItem(icon: Icons.school_outlined, label: '10 Courses', color: Color(0xFF1B9AAA)),
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

  Widget _buildStatItem({required IconData icon, required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
        ),
      ],
    );
  }
}

// ========== EXAMPLE USAGE IN HOME PAGE ==========
class CoachingProfilesSection extends StatelessWidget {
  const CoachingProfilesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coaching Profiles',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                  fontFamily: 'Poppins',
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Learn from expert coaches',
            style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93), fontFamily: 'Poppins'),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
