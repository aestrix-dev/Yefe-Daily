class UserModel {
  final String id;
  final String email;
  final String name;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final String role;
  final String planType;
  final String planName;
  final DateTime planStartDate;
  final DateTime? planEndDate;
  final bool planAutoRenew;
  final String planStatus;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.isEmailVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    required this.role,
    required this.planType,
    required this.planName,
    required this.planStartDate,
    this.planEndDate,
    required this.planAutoRenew,
    required this.planStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['Name'] ?? json['name'] ?? '',
      isEmailVerified: json['is_email_verified'] ?? false,
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
      role: json['role'] ?? '',
      planType: json['plan_type'] ?? 'free',
      planName: json['plan_name'] ?? 'Free',
      planStartDate: DateTime.parse(
        json['plan_start_date'] ?? DateTime.now().toIso8601String(),
      ),
      planEndDate: json['plan_end_date'] != null
          ? DateTime.parse(json['plan_end_date'])
          : null,
      planAutoRenew: json['plan_auto_renew'] ?? false,
      planStatus: json['plan_status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'is_email_verified': isEmailVerified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'role': role,
      'plan_type': planType,
      'plan_name': planName,
      'plan_start_date': planStartDate.toIso8601String(),
      'plan_end_date': planEndDate?.toIso8601String(),
      'plan_auto_renew': planAutoRenew,
      'plan_status': planStatus,
    };
  }
}
