class DietPlanPackage {
  final String planId;
  final String title;
  final String description;
  final String targetIssue;
  final int price;
  final String duration;
  final List<DietMealPlan> mealPlans;
  final List<String> foodsToEat;
  final List<String> foodsToAvoid;
  final List<String> lifestyleTips;
  final String thumbnailUrl;
  final bool isPopular;

  DietPlanPackage({
    required this.planId,
    required this.title,
    required this.description,
    required this.targetIssue,
    this.price = 299,
    this.duration = '4 Weeks',
    this.mealPlans = const [],
    this.foodsToEat = const [],
    this.foodsToAvoid = const [],
    this.lifestyleTips = const [],
    this.thumbnailUrl = '',
    this.isPopular = false,
  });

  factory DietPlanPackage.fromJson(Map<String, dynamic> json) {
    return DietPlanPackage(
      planId: json['planId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetIssue: json['targetIssue'] as String,
      price: json['price'] as int? ?? 299,
      duration: json['duration'] as String? ?? '4 Weeks',
      mealPlans: (json['mealPlans'] as List<dynamic>?)
              ?.map((e) => DietMealPlan.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      foodsToEat: (json['foodsToEat'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      foodsToAvoid: (json['foodsToAvoid'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lifestyleTips: (json['lifestyleTips'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'title': title,
      'description': description,
      'targetIssue': targetIssue,
      'price': price,
      'duration': duration,
      'mealPlans': mealPlans.map((e) => e.toJson()).toList(),
      'foodsToEat': foodsToEat,
      'foodsToAvoid': foodsToAvoid,
      'lifestyleTips': lifestyleTips,
      'thumbnailUrl': thumbnailUrl,
      'isPopular': isPopular,
    };
  }
}

class DietMealPlan {
  final String day;
  final String breakfast;
  final String midMorning;
  final String lunch;
  final String eveningSnack;
  final String dinner;

  const DietMealPlan({
    required this.day,
    this.breakfast = '',
    this.midMorning = '',
    this.lunch = '',
    this.eveningSnack = '',
    this.dinner = '',
  });

  factory DietMealPlan.fromJson(Map<String, dynamic> json) {
    return DietMealPlan(
      day: json['day'] as String,
      breakfast: json['breakfast'] as String? ?? '',
      midMorning: json['midMorning'] as String? ?? '',
      lunch: json['lunch'] as String? ?? '',
      eveningSnack: json['eveningSnack'] as String? ?? '',
      dinner: json['dinner'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'breakfast': breakfast,
      'midMorning': midMorning,
      'lunch': lunch,
      'eveningSnack': eveningSnack,
      'dinner': dinner,
    };
  }
}
