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

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    this.height,
    this.weight,
  });
}
