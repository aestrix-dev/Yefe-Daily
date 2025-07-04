import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/puzzle_model.dart';

class PuzzleSection extends StatelessWidget {
  final PuzzleModel puzzle;
  final ValueChanged<String> onAnswerSelected;
  final VoidCallback onSubmit;

  const PuzzleSection({
    super.key,
    required this.puzzle,
    required this.onAnswerSelected,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Daily Puzzle',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          SizedBox(height: 8.h),

          // Question
          Text(
            puzzle.question,
            style: TextStyle(fontSize: 14.sp, color: Colors.black, height: 1.3),
          ),

          SizedBox(height: 16.h),

          // Answer options
          ...puzzle.options.map((option) => _buildAnswerOption(option)),

          SizedBox(height: 16.h),

          // Submit button or result
          _buildSubmitSection(),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(String option) {
    final isSelected = puzzle.selectedAnswer == option;
    final isAnswered = puzzle.isAnswered;
    final isCorrect = puzzle.options[puzzle.correctAnswerIndex] == option;

    Color backgroundColor;
    Color textColor = Colors.black;

    if (isAnswered) {
      if (isCorrect) {
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.red;
        textColor = Colors.white;
      } else {
        backgroundColor = Colors.grey[200]!;
      }
    } else {
      backgroundColor = isSelected ? AppColors.primary : Colors.grey[200]!;
      if (isSelected) textColor = Colors.white;
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      child: GestureDetector(
        onTap: isAnswered ? null : () => onAnswerSelected(option),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            option,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitSection() {
    if (puzzle.isAnswered) {
      final isCorrect = puzzle.isCorrect;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isCorrect ? Colors.green[50] : Colors.red[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isCorrect ? Colors.green : Colors.red),
        ),
        child: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                isCorrect
                    ? 'Correct! You earned 10 points! 🎉'
                    : 'Check-in Tomorrow',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: puzzle.selectedAnswer != null ? onSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          'Submit Answer',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
