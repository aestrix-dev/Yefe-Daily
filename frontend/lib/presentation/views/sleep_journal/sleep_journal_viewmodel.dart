import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../../../app/app_setup.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/api_result.dart';
import '../../../data/repositories/sleep_repository.dart';
import '../../shared/widgets/toast_overlay.dart';

class SleepJournalViewModel extends BaseViewModel {
  BuildContext? _context;
  final SleepRepository _sleepRepository = locator<SleepRepository>();
  final Logger _logger = Logger();

  // Form data
  DateTime _sleptDate = DateTime.now().subtract(const Duration(days: 1));
  TimeOfDay _sleptTime = const TimeOfDay(hour: 22, minute: 0);
  DateTime _wokeUpDate = DateTime.now();
  TimeOfDay _wokeUpTime = const TimeOfDay(hour: 6, minute: 30);
  
  String? _errorMessage;
  bool _isSubmitting = false;

  // Getters
  DateTime get sleptDate => _sleptDate;
  TimeOfDay get sleptTime => _sleptTime;
  DateTime get wokeUpDate => _wokeUpDate;
  TimeOfDay get wokeUpTime => _wokeUpTime;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _isSubmitting;

  // Formatted getters for display
  String get sleptDateFormatted => DateFormat('MMM dd, yyyy').format(_sleptDate);
  String get sleptTimeFormatted => _context != null 
      ? _sleptTime.format(_context!) 
      : '${_sleptTime.hour.toString().padLeft(2, '0')}:${_sleptTime.minute.toString().padLeft(2, '0')}';
  String get wokeUpDateFormatted => DateFormat('MMM dd, yyyy').format(_wokeUpDate);
  String get wokeUpTimeFormatted => _context != null 
      ? _wokeUpTime.format(_context!) 
      : '${_wokeUpTime.hour.toString().padLeft(2, '0')}:${_wokeUpTime.minute.toString().padLeft(2, '0')}';

  // Calculate sleep duration
  double get sleepDuration {
    final sleptDateTime = DateTime(
      _sleptDate.year, _sleptDate.month, _sleptDate.day,
      _sleptTime.hour, _sleptTime.minute,
    );
    final wokeUpDateTime = DateTime(
      _wokeUpDate.year, _wokeUpDate.month, _wokeUpDate.day,
      _wokeUpTime.hour, _wokeUpTime.minute,
    );
    
    final difference = wokeUpDateTime.difference(sleptDateTime);
    return difference.inMinutes / 60.0;
  }

  String get sleepDurationFormatted {
    final duration = sleepDuration;
    final hours = duration.floor();
    final minutes = ((duration - hours) * 60).round();
    
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void onModelReady() {
    // Set default times - yesterday 10 PM to today 6:30 AM
    _sleptDate = DateTime.now().subtract(const Duration(days: 1));
    _wokeUpDate = DateTime.now();
    notifyListeners();
  }

  // Date and time picker methods
  Future<void> selectSleptDate() async {
    if (_context == null) return;
    
    final picked = await showDatePicker(
      context: _context!,
      initialDate: _sleptDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      _sleptDate = picked;
      _validateDates();
      notifyListeners();
    }
  }

  Future<void> selectSleptTime() async {
    if (_context == null) return;
    
    final picked = await showTimePicker(
      context: _context!,
      initialTime: _sleptTime,
    );
    
    if (picked != null) {
      _sleptTime = picked;
      notifyListeners();
    }
  }

  Future<void> selectWokeUpDate() async {
    if (_context == null) return;
    
    final picked = await showDatePicker(
      context: _context!,
      initialDate: _wokeUpDate,
      firstDate: _sleptDate,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (picked != null) {
      _wokeUpDate = picked;
      _validateDates();
      notifyListeners();
    }
  }

  Future<void> selectWokeUpTime() async {
    if (_context == null) return;
    
    final picked = await showTimePicker(
      context: _context!,
      initialTime: _wokeUpTime,
    );
    
    if (picked != null) {
      _wokeUpTime = picked;
      notifyListeners();
    }
  }

  void _validateDates() {
    if (_wokeUpDate.isBefore(_sleptDate)) {
      _wokeUpDate = _sleptDate.add(const Duration(days: 1));
    }
  }

  // Form validation
  bool get isFormValid {
    final duration = sleepDuration;
    return duration > 0 && duration < 24; // Between 0 and 24 hours
  }

  String? get formValidationError {
    if (sleepDuration <= 0) {
      return 'Wake up time must be after sleep time';
    }
    if (sleepDuration > 24) {
      return 'Sleep duration cannot exceed 24 hours';
    }
    return null;
  }

  // Submit sleep journal
  Future<void> submitSleepJournal() async {
    if (!isFormValid) {
      _errorMessage = formValidationError;
      
      // Show validation error toast
      if (_context != null && formValidationError != null) {
        ToastOverlay.showError(
          context: _context!,
          message: formValidationError!,
        );
      }
      
      notifyListeners();
      return;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Format dates and times for API
      final sleptDateStr = DateFormat('yyyy-MM-dd').format(_sleptDate);
      final sleptTimeStr = '${_sleptTime.hour.toString().padLeft(2, '0')}:${_sleptTime.minute.toString().padLeft(2, '0')}:00';
      final wokeUpDateStr = DateFormat('yyyy-MM-dd').format(_wokeUpDate);
      final wokeUpTimeStr = '${_wokeUpTime.hour.toString().padLeft(2, '0')}:${_wokeUpTime.minute.toString().padLeft(2, '0')}:00';

      _logger.i('Submitting sleep journal: $sleptDateStr $sleptTimeStr to $wokeUpDateStr $wokeUpTimeStr');

      final result = await _sleepRepository.recordSleep(
        sleptDate: sleptDateStr,
        sleptTime: sleptTimeStr,
        wokeUpDate: wokeUpDateStr,
        wokeUpTime: wokeUpTimeStr,
      );

      result.when(
        success: (sleepEntry) {
          _logger.i('Sleep journal submitted successfully: Duration ${sleepEntry.duration}h');
          
          // Show success message
          if (_context != null) {
            ToastOverlay.showSuccess(
              context: _context!,
              message: 'Sleep journal saved! Duration: $sleepDurationFormatted',
            );
          }
          
          // Reset form for next entry
          _resetForm();
        },
        failure: (error) {
          _logger.e('Failed to submit sleep journal: $error');
          _errorMessage = error;
          
          // Show error toast
          if (_context != null) {
            ToastOverlay.showError(
              context: _context!,
              message: error,
            );
          }
        },
      );
    } catch (e) {
      _logger.e('Unexpected error submitting sleep journal: $e');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      
      // Show error toast
      if (_context != null) {
        ToastOverlay.showError(
          context: _context!,
          message: 'An unexpected error occurred. Please try again.',
        );
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    _sleptDate = DateTime.now().subtract(const Duration(days: 1));
    _sleptTime = const TimeOfDay(hour: 22, minute: 0);
    _wokeUpDate = DateTime.now();
    _wokeUpTime = const TimeOfDay(hour: 6, minute: 30);
    _errorMessage = null;
    notifyListeners();
  }

  // Navigation
  void navigateBack() {
    if (_context != null && _context!.canPop()) {
      _context!.pop();
    } else if (_context != null) {
      _context!.go('/profile');
    }
  }

  void navigateToAnalytics() {
    if (_context != null) {
      _context!.go(AppRoutes.moodAnalytics);
    }
  }

  // Quick preset buttons
  void setPreset8Hours() {
    _sleptTime = const TimeOfDay(hour: 22, minute: 0);
    _wokeUpTime = const TimeOfDay(hour: 6, minute: 0);
    notifyListeners();
  }

  void setPreset7Hours() {
    _sleptTime = const TimeOfDay(hour: 23, minute: 0);
    _wokeUpTime = const TimeOfDay(hour: 6, minute: 0);
    notifyListeners();
  }

  void setPreset9Hours() {
    _sleptTime = const TimeOfDay(hour: 21, minute: 0);
    _wokeUpTime = const TimeOfDay(hour: 6, minute: 0);
    notifyListeners();
  }
}