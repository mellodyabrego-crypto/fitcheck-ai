class UserProfile {
  final String id;
  final String userId;
  final List<String> aesthetics;
  final String? bodyType;
  final List<String> colorPreferences;
  final String? gender;
  final bool onboardingComplete;
  final bool notificationsEnabled;
  final String? notificationTime;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  // New onboarding fields
  final List<String> goals;
  final String? ageRange;
  final List<String> brands;
  final String? topSize;
  final String? bottomSize;
  final String? shoeSize;
  final String? skinToneUndertone;

  const UserProfile({
    required this.id,
    required this.userId,
    this.aesthetics = const [],
    this.bodyType,
    this.colorPreferences = const [],
    this.gender,
    this.onboardingComplete = false,
    this.notificationsEnabled = false,
    this.notificationTime,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.goals = const [],
    this.ageRange,
    this.brands = const [],
    this.topSize,
    this.bottomSize,
    this.shoeSize,
    this.skinToneUndertone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      aesthetics: (json['aesthetics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bodyType: json['body_type'] as String?,
      colorPreferences: (json['color_preferences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      gender: json['gender'] as String?,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? false,
      notificationTime: json['notification_time'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      goals: (json['goals'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      ageRange: json['age_range'] as String?,
      brands: (json['brands'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      topSize: json['top_size'] as String?,
      bottomSize: json['bottom_size'] as String?,
      shoeSize: json['shoe_size'] as String?,
      skinToneUndertone: json['skin_tone_undertone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'aesthetics': aesthetics,
        'body_type': bodyType,
        'color_preferences': colorPreferences,
        'gender': gender,
        'onboarding_complete': onboardingComplete,
        'notifications_enabled': notificationsEnabled,
        'notification_time': notificationTime,
        'location': location,
        'goals': goals,
        'age_range': ageRange,
        'brands': brands,
        'top_size': topSize,
        'bottom_size': bottomSize,
        'shoe_size': shoeSize,
        'skin_tone_undertone': skinToneUndertone,
      };

  UserProfile copyWith({
    List<String>? aesthetics,
    String? bodyType,
    List<String>? colorPreferences,
    String? gender,
    bool? onboardingComplete,
    bool? notificationsEnabled,
    String? notificationTime,
    String? location,
    List<String>? goals,
    String? ageRange,
    List<String>? brands,
    String? topSize,
    String? bottomSize,
    String? shoeSize,
    String? skinToneUndertone,
  }) {
    return UserProfile(
      id: id,
      userId: userId,
      aesthetics: aesthetics ?? this.aesthetics,
      bodyType: bodyType ?? this.bodyType,
      colorPreferences: colorPreferences ?? this.colorPreferences,
      gender: gender ?? this.gender,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      location: location ?? this.location,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      goals: goals ?? this.goals,
      ageRange: ageRange ?? this.ageRange,
      brands: brands ?? this.brands,
      topSize: topSize ?? this.topSize,
      bottomSize: bottomSize ?? this.bottomSize,
      shoeSize: shoeSize ?? this.shoeSize,
      skinToneUndertone: skinToneUndertone ?? this.skinToneUndertone,
    );
  }
}
