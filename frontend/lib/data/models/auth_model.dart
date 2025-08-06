import 'package:yefa/data/models/user_model.dart';

class TokenData {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const TokenData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenData.fromJson(Map<String, dynamic> json) {
    return TokenData(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      expiresIn: json['expires_in'] ?? 86400,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
    };
  }
}

class UserPreferences {
  final bool morningPrompt;
  final bool eveningReflection;
  final bool challenge;
  final String language;
  final ReminderSettings reminders;

  const UserPreferences({
    required this.morningPrompt,
    required this.eveningReflection,
    required this.challenge,
    required this.language,
    required this.reminders,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      morningPrompt: json['morning_prompt'] ?? true,
      eveningReflection: json['evening_reflection'] ?? true,
      challenge: json['challenge'] ?? true,
      language: json['language'] ?? 'English',
      reminders: ReminderSettings.fromJson(json['reminders'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morning_prompt': morningPrompt,
      'evening_reflection': eveningReflection,
      'challenge': challenge,
      'language': language,
      'reminders': reminders.toJson(),
    };
  }
}

class ReminderSettings {
  final String morningReminder;
  final String eveningReminder;

  const ReminderSettings({
    required this.morningReminder,
    required this.eveningReminder,
  });

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      morningReminder: json['morning_reminder'] ?? '08:00',
      eveningReminder: json['evening_reminder'] ?? '20:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'morning_reminder': morningReminder,
      'evening_reminder': eveningReminder,
    };
  }
}

class RegisterRequest {
  final String email;
  final String name;
  final String password;
  final String confirmPassword;
  final UserPreferences userPrefs;

  const RegisterRequest({
    required this.email,
    required this.name,
    required this.password,
    required this.confirmPassword,
    required this.userPrefs,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'password': password,
      'confirm_password': confirmPassword,
      'user_prefs': userPrefs.toJson(),
    };
  }
}

class RegisterResponse {
  final bool success;
  final String message;
  final RegisterData data;
  final DateTime timestamp;

  const RegisterResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: RegisterData.fromJson(json['data'] ?? {}),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class RegisterData {
  final TokenData token;
  final UserModel user;

  const RegisterData({required this.token, required this.user});

  factory RegisterData.fromJson(Map<String, dynamic> json) {
    return RegisterData(
      token: TokenData.fromJson(json['token'] ?? {}),
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}
