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

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    this.height,
    this.weight,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
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
    };
  }
}
