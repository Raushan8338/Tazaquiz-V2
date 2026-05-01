import 'package:flutter/material.dart';
import 'package:tazaquiznew/constants/app_colors.dart';
import 'package:tazaquiznew/models/quizItem_modal.dart';

/// A reusable horizontal year filter widget for PYP quizzes.
///
/// Use it with your existing quiz list state by passing available years,
/// the currently selected year, and an onSelected callback.
class YearFilterChipList extends StatelessWidget {
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<int?> onYearSelected;
  final String label;

  const YearFilterChipList({
    Key? key,
    required this.years,
    required this.selectedYear,
    required this.onYearSelected,
    this.label = 'Filter by year',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = <_YearOption>[const _YearOption(year: null, title: 'All Years')]
      ..addAll(years.map((year) => _YearOption(year: year, title: year.toString())));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.greyS700,
                fontFamily: 'Poppins',
              )),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = items[index];
                final bool selected = option.year == selectedYear;
                return GestureDetector(
                  onTap: () => onYearSelected(option.year),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: selected ? AppColors.tealGreen : const Color(0xFFF0F2F8),
                      border: Border.all(
                        color: selected
                            ? AppColors.tealGreen
                            : AppColors.greyS400.withOpacity(0.4),
                      ),
                    ),
                    child: Center(
                      child: Text(option.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? Colors.white : AppColors.greyS700,
                            fontFamily: 'Poppins',
                          )),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static List<int> extractUniqueYears(List<QuizItem> quizzes) {
    final years = quizzes
        .where((quiz) => quiz.pyps_year != null && quiz.pyps_year! > 0)
        .map((quiz) => quiz.pyps_year!)
        .toSet()
        .toList();
    years.sort((b, a) => a.compareTo(b));
    return years;
  }
}

class _YearOption {
  final int? year;
  final String title;

  const _YearOption({required this.year, required this.title});
}
