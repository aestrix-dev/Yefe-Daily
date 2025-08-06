import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';

import '../../../core/constants/app_colors.dart';
import 'history_viewmodel.dart';
import 'widgets/history_item_card.dart';

class HistoryView extends StackedView<HistoryViewModel> {
  const HistoryView({super.key});

  @override
  Widget builder(
    BuildContext context,
    HistoryViewModel viewModel,
    Widget? child,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Pass context safely once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.setContext(context);
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.accentDark(context),
        appBar: AppBar(
          backgroundColor: AppColors.accentDark(context),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppColors.textPrimary(context),
              size: 20.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Ledger History',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: viewModel.isBusy
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary(context),
                  ),
                )
              : viewModel.historyItems.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: viewModel.refreshHistory,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                    itemCount: viewModel.historyItems.length,
                    itemBuilder: (context, index) {
                      final item = viewModel.historyItems[index];
                      return HistoryItemCard(
                        entry: item,
                        onTap: () {
                          print('Tapped entry: ${item.id}');
                        },
                        onDelete: () {
                          viewModel.onDeleteEntry(item.id);
                        },
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your spiritual journey history will appear here',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  HistoryViewModel viewModelBuilder(BuildContext context) => HistoryViewModel();

  @override
  void onViewModelReady(HistoryViewModel viewModel) {
    super.onViewModelReady(viewModel);
    viewModel.onModelReady();
  }
}
