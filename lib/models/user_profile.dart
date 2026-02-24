import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  @HiveField(2)
  String gender;

  @HiveField(3)
  double? height;

  @HiveField(4)
  double? weight;

  @HiveField(5)
  String? phone;

  // --- Women's Health Fields ---
  @HiveField(6)
  int? menstrualCycleLength;

  @HiveField(7)
  String? cycleRegularity;

  @HiveField(8)
  int? periodPainScore;

  @HiveField(9)
  String? reproductiveHistory;

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    this.height,
    this.weight,
    this.phone,
    this.menstrualCycleLength,
    this.cycleRegularity,
    this.periodPainScore,
    this.reproductiveHistory,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      menstrualCycleLength: json['menstrualCycleLength'] as int?,
      cycleRegularity: json['cycleRegularity'] as String?,
      periodPainScore: json['periodPainScore'] as int?,
      reproductiveHistory: json['reproductiveHistory'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'phone': phone,
      'menstrualCycleLength': menstrualCycleLength,
      'cycleRegularity': cycleRegularity,
      'periodPainScore': periodPainScore,
      'reproductiveHistory': reproductiveHistory,
    };
  }
}
