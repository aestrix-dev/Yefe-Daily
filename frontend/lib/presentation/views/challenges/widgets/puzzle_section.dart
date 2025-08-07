// File: ui/views/challenge/widgets/puzzle_section.dart (updated)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/puzzle_model.dart';

class PuzzleSection extends StatelessWidget {
  final PuzzleState puzzleState;
  final bool isSubmitting;
  final Function(int) onAnswerSelected;
  final VoidCallback onSubmit;

  const PuzzleSection({
    super.key,
    required this.puzzleState,
    required this.isSubmitting,
    required this.onAnswerSelected,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    // Show countdown if on cooldown but no puzzle loaded
    if (puzzleState.isOnCooldown && puzzleState.puzzle == null) {
      return _buildCountdownCard(context);
    }

    // Show puzzle if available
    if (puzzleState.puzzle == null) {
      return _buildEmptyState(context);
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(20.r),
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
            puzzleState.puzzle!.question,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary(context),
              height: 1.3,
            ),
          ),

          SizedBox(height: 16.h),

          // Answer options
          ...puzzleState.puzzle!.options.entries.map(
            (entry) => _buildAnswerOption(context, entry.key, entry.value),
          ),

          SizedBox(height: 16.h),

          // Submit button
          _buildSubmitButton(context),

          // Show result after submission
          if (puzzleState.hasSubmitted &&
              puzzleState.submissionResult != null) ...[
            SizedBox(height: 12.h),
            _buildResultAlert(context),
            SizedBox(height: 12.h),
            _buildExplanation(context),
          ],

          // Show countdown after submission
          if (puzzleState.hasSubmitted && puzzleState.isOnCooldown) ...[
            SizedBox(height: 12.h),
            _buildCountdownTimer(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerOption(BuildContext context, String key, String value) {
    // Convert key to actual array index (key "1" = index 0, key "2" = index 1, etc.)
    final optionNumber = int.tryParse(key) ?? 1;
    
    final isSelected = puzzleState.selectedAnswer == optionNumber;
    final canSelect = puzzleState.canSelectAnswer;

    // Show correct/incorrect colors after submission
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (puzzleState.hasSubmitted) {
      final isCorrectAnswer =
          optionNumber == puzzleState.submissionResult?.correctAnswer;
      final isUserAnswer = optionNumber == puzzleState.selectedAnswer;

      if (isCorrectAnswer) {
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green.shade700;
        borderColor = Colors.green;
      } else if (isUserAnswer && !isCorrectAnswer) {
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red.shade700;
        borderColor = Colors.red;
      } else {
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = AppColors.textSecondary(context);
        borderColor = Colors.grey.withOpacity(0.5);
      }
    } else if (isSelected) {
      backgroundColor = AppColors.primaryLight(context);
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
        onTap: canSelect
            ? () => onAnswerSelected(optionNumber)
            : null, 
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(13.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25.r),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              // Option letter/number
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Option text
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),

              // Show check/cross after submission
              if (puzzleState.hasSubmitted) ...[
                SizedBox(width: 8.w),
                Icon(
                  optionNumber == puzzleState.submissionResult?.correctAnswer
                      ? Icons.check_circle
                      : (optionNumber == puzzleState.selectedAnswer &&
                            optionNumber !=
                                puzzleState.submissionResult?.correctAnswer)
                      ? Icons.cancel
                      : null,
                  color:
                      optionNumber == puzzleState.submissionResult?.correctAnswer
                      ? Colors.green
                      : Colors.red,
                  size: 20.sp,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final canSubmit = puzzleState.canSubmit && !isSubmitting;
    final hasSubmitted = puzzleState.hasSubmitted;

    String buttonText;
    if (isSubmitting) {
      buttonText = 'Submitting...';
    } else if (hasSubmitted) {
      buttonText = 'Check-in Tomorrow';
    } else {
      buttonText = 'Submit Answer';
    }

    return SizedBox(
      width: double.infinity,
      height: 42.h,
      child: ElevatedButton(
        onPressed: canSubmit ? onSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasSubmitted
              ? Colors.grey[400]
              : AppColors.primary(context),
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
        ),
        child: isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                buttonText,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildResultAlert(BuildContext context) {
    final isCorrect = puzzleState.submissionResult!.isCorrect;
    final pointsEarned = puzzleState.submissionResult!.pointsEarned;

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
                  ? 'Correct! You earned $pointsEarned points! 🎉'
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

  Widget _buildExplanation(BuildContext context) {
    final explanation = puzzleState.submissionResult!.explanation;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: AppColors.primary(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary(context).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary(context),
                size: 16.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'Explanation',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textSecondary(context),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(13.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.orange.shade700, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next puzzle available in:',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  puzzleState.timeUntilNextPuzzle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildCountdownCard(BuildContext context) {
    return SizedBox(
      width: double.infinity, // 💡 Ensures full width
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.accentLight(context),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // 💡 Center contents
          children: [
            Icon(
              Icons.access_time,
              size: 48.sp,
              color: AppColors.primary(context),
            ),
            SizedBox(height: 16.h),
            Text(
              'Daily Puzzle',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Come back for your next puzzle in:',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.primary(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(
                  color: AppColors.primary(context).withOpacity(0.3),
                ),
              ),
              child: Text(
                puzzleState.timeUntilNextPuzzle,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary(context),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.accentLight(context),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 48.sp,
            color: AppColors.primary(context),
          ),
          SizedBox(height: 16.h),
          Text(
            'Daily Puzzle',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Loading your daily challenge...',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
