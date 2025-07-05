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
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(20.r), // Full rounded border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Daily Puzzle',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),

          SizedBox(height: 8.h),

          // Question
          Text(
            puzzle.question,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary(context), height: 1.3),
          ),

          SizedBox(height: 16.h),

          // Answer options
          ...puzzle.options.map((option) => _buildAnswerOption(context, option)),

          SizedBox(height: 16.h),

          // Submit button
          _buildSubmitButton(context),

      
          if (puzzle.isAnswered) ...[
            SizedBox(height: 12.h),
            _buildResultAlert(),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerOption(BuildContext context, String option) {
    final isSelected = puzzle.selectedAnswer == option;
    final isAnswered = puzzle.isAnswered;

    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isSelected) {
     
      backgroundColor =
          AppColors.primaryLight(context);
      textColor = AppColors.primary(context);
      borderColor = AppColors.primary(context);
    } else {
      
      backgroundColor = Colors.transparent;
      textColor = AppColors.textPrimary(context);
      borderColor = AppColors.primary(context).withOpacity(0.6);
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      child: GestureDetector(
        onTap: isAnswered ? null : () => onAnswerSelected(option),
        child: Container(
          padding: EdgeInsets.all(13.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25.r),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Text(
            option,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final hasSelectedAnswer = puzzle.selectedAnswer != null;
    final isAnswered = puzzle.isAnswered;

    return SizedBox(
      width: double.infinity,
      height: 42.h,
      child: ElevatedButton(
        onPressed: isAnswered ? null : (hasSelectedAnswer ? onSubmit : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: isAnswered ? Colors.grey[400] : AppColors.primary(context),
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
        ),
        child: Text(
          isAnswered ? 'Check-in Tomorrow' : 'Submit Answer',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildResultAlert() {
    final isCorrect = puzzle.isCorrect;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(26.r),
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
                  : 'Incorrect. Better luck tomorrow!',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
