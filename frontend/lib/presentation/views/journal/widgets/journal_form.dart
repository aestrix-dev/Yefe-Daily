import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class JournalForm extends StatefulWidget {
  final String content;
  final List<String> selectedTags;
  final List<String> availableTags;
  final ValueChanged<String> onContentChanged;
  final ValueChanged<String> onTagToggle;
  final VoidCallback onSave;
  final bool isSaving;

  const JournalForm({
    super.key,
    required this.content,
    required this.selectedTags,
    required this.availableTags,
    required this.onContentChanged,
    required this.onTagToggle,
    required this.onSave,
    required this.isSaving,
  });

  @override
  State<JournalForm> createState() => _JournalFormState();
}

class _JournalFormState extends State<JournalForm> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.content);
  }

  @override
  void didUpdateWidget(JournalForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller when content changes (like when form is cleared)
    if (widget.content != oldWidget.content &&
        widget.content != _textController.text) {
      _textController.text = widget.content;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Grey container wrapper
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.accentLight(context),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Text(
                  'What will you bring to the world today?',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(context),
                  ),
                ),

                SizedBox(height: 16.h),

                // Text input with accent dark background
                Container(
                  width: double.infinity,
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: AppColors.accentDark(context),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.primary(context)),
                  ),
                  child: TextField(
                    controller: _textController,
                    onChanged: widget.onContentChanged,
                    enabled: !widget.isSaving, // Disable while saving
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12.w),
                      hintText: 'Type here...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14.sp,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Tags section
                Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary(context),
                  ),
                ),

                SizedBox(height: 12.h),

                // Tags
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: widget.availableTags.map((tag) {
                    final isSelected = widget.selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: widget.isSaving
                          ? null
                          : () => widget.onTagToggle(tag),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight(context)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary(context)
                                : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Save button outside the grey box
          SizedBox(
            width: double.infinity,
            height: 38.h,
            child: ElevatedButton(
              onPressed: (widget.content.trim().isNotEmpty && !widget.isSaving)
                  ? widget.onSave
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                disabledBackgroundColor: AppColors.accentLight(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26.r),
                ),
              ),
              child: widget.isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14.w,
                          height: 14.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Saving...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
