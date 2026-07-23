import 'remote_config_service.dart';

class HealthTip {
  final String category;
  final String text;
  const HealthTip(this.category, this.text);
}

/// Supplies a fresh women's-health "Tip of the Day".
///
/// Tips rotate deterministically by calendar day (same tip all day, a new one
/// tomorrow), work fully offline, and are medically general/safe. Dr. Deepika
/// can override the day's tip by setting `daily_tip` in the Firestore
/// `config/api_keys` document.
class DailyTipService {
  DailyTipService._();

  static const List<HealthTip> tips = [
    HealthTip('Nutrition',
        'Pair iron-rich foods (spinach, dates, jaggery) with vitamin C like lemon or amla to absorb up to 3x more iron.'),
    HealthTip('Nutrition',
        'Add protein to breakfast (eggs, paneer, sprouts) to curb cravings and keep blood sugar steady all day.'),
    HealthTip('Nutrition',
        'Ground flaxseed (1 tsp/day) adds omega-3 and fibre that may help ease PMS and support regular cycles.'),
    HealthTip('Cycle',
        'Track your period every month — even a quick note helps you spot changes early and plan around your cycle.'),
    HealthTip('Cycle',
        'For mild cramps, a warm compress and a gentle walk often work as well as painkillers for many women.'),
    HealthTip('Cycle',
        'Irregular periods for 3+ months deserve a check-up — it can be an early sign of PCOS or a thyroid issue.'),
    HealthTip('PCOS',
        'Walking 30 minutes daily improves insulin sensitivity — one of the most effective natural steps for PCOS.'),
    HealthTip('PCOS',
        'Swap refined carbs (maida, white rice) for whole grains (oats, millet, brown rice) to help steady hormones in PCOS.'),
    HealthTip('PCOS',
        'Good sleep matters for PCOS: 7–8 hours helps regulate the hormones that control your cycle and weight.'),
    HealthTip('Pregnancy',
        'Planning a baby? Start folic acid before conceiving — it protects your baby\'s brain and spine in the first weeks.'),
    HealthTip('Fertility',
        'Fertility is a team effort — a healthy diet, no smoking and limited alcohol improve chances for both partners.'),
    HealthTip('Screening',
        'A Pap smear every 3 years can catch cervical changes early, when they are almost always treatable.'),
    HealthTip('Screening',
        'Learn a monthly breast self-exam — knowing what is normal for you makes it easier to notice changes early.'),
    HealthTip('Screening',
        'After 40, ask your doctor about a mammogram — early detection saves lives.'),
    HealthTip('Screening',
        'The HPV vaccine prevents most cervical cancers and works best before exposure — ask if it suits you or your daughter.'),
    HealthTip('Bone Health',
        'Women lose bone faster after menopause — weight-bearing exercise plus calcium and vitamin D keep bones strong.'),
    HealthTip('Menopause',
        'Hot flashes? Light cotton clothing, cool water and less caffeine or spicy food can ease them naturally.'),
    HealthTip('Bone Health',
        '15 minutes of morning sunlight most days helps your body make the vitamin D your bones need.'),
    HealthTip('Mental Health',
        'Feeling low before your period is real — gentle exercise, sunlight and rest can lift PMS mood dips.'),
    HealthTip('Mental Health',
        'Try 5 slow, deep breaths when stressed — it calms your nervous system in under a minute.'),
    HealthTip('Mental Health',
        'Sadness after childbirth lasting more than 2 weeks is not weakness — please talk to your doctor, help works.'),
    HealthTip('Hydration',
        'Start your day with a glass of water — even mild dehydration can cause fatigue, headaches and cravings.'),
    HealthTip('Fitness',
        'Strength training twice a week isn\'t just for men — it boosts metabolism, bone strength and mood for women.'),
    HealthTip('Sleep',
        'Keep phones away 30 minutes before bed — better sleep improves hormones, skin and cycle regularity.'),
    HealthTip('Myth-buster',
        'Myth: You can\'t get pregnant during your period. Truth: It\'s less likely but still possible — use protection if avoiding pregnancy.'),
    HealthTip('Myth-buster',
        'Myth: PCOS means you can\'t have children. Truth: Many women with PCOS conceive, often with simple lifestyle and medical help.'),
    HealthTip('Myth-buster',
        'Myth: A missed period always means pregnancy. Truth: Stress, weight change, thyroid and PCOS can also delay periods.'),
    HealthTip('Myth-buster',
        'Myth: White discharge is always an infection. Truth: Clear/white discharge is usually normal — see a doctor only if it itches, smells or changes colour.'),
    HealthTip('Myth-buster',
        'Myth: You shouldn\'t exercise on your period. Truth: Light exercise often reduces cramps and lifts your mood.'),
    HealthTip('Myth-buster',
        'Myth: Emergency pills work as regular birth control. Truth: They\'re only for emergencies — regular methods are safer and more effective.'),
    HealthTip('Anemia',
        'Tired, breathless or pale? Ask for a simple hemoglobin test — iron deficiency is very common and easily treated.'),
    HealthTip('Hygiene',
        'Drink enough water and don\'t hold urine for long — one of the simplest ways to prevent UTIs.'),
    HealthTip('Hygiene',
        'Wipe front to back and skip harsh intimate washes — plain water is enough; the vagina cleans itself.'),
    HealthTip('Heart Health',
        'Heart disease is a top killer of women too — know your blood pressure and cholesterol numbers.'),
    HealthTip('Nutrition',
        'Cutting sugary drinks is one of the fastest ways to lower diabetes and weight risk — try nimbu paani without sugar.'),
    HealthTip('Thyroid',
        'Unexplained weight change, fatigue or hair fall? A simple TSH blood test can check your thyroid.'),
    HealthTip('Awareness',
        'Keep your health reports in one place — trends over time tell your doctor far more than a single test.'),
    HealthTip('Awareness',
        'Never ignore bleeding after menopause or between periods — get it checked promptly; it is usually treatable.'),
    HealthTip('Self-care',
        'Book that check-up you\'ve been postponing — preventive visits catch problems before they grow.'),
    HealthTip('Nutrition',
        'A bowl of curd/yogurt daily supports gut and vaginal health with natural good bacteria (probiotics).'),
    HealthTip('Fitness',
        'Pelvic floor (Kegel) exercises help prevent leaks and aid recovery after childbirth — a few minutes a day is enough.'),
    HealthTip('Nutrition',
        'Colour your plate: aim for 3 different vegetable colours a day for a natural mix of vitamins and antioxidants.'),
    HealthTip('Cycle',
        'Craving sweets before your period is normal — reach for fruit or a little dark chocolate instead of refined sugar.'),
    HealthTip('Lifestyle',
        'If you sit a lot, stand and stretch every hour — it protects your back, circulation and energy.'),
    HealthTip('Awareness',
        'Know your family history of breast, ovarian or cervical cancer — it helps your doctor plan the right screening for you.'),
  ];

  /// Index of today's tip (advances by one each calendar day, then cycles).
  static int todayIndex() {
    final days = DateTime.now()
        .difference(DateTime(2020, 1, 1))
        .inDays;
    final i = days % tips.length;
    return i < 0 ? i + tips.length : i;
  }

  /// A doctor-pushed override tip, if configured in Firestore.
  static HealthTip? overrideTip() {
    final t = RemoteConfigService.getString('daily_tip');
    if (t != null && t.trim().isNotEmpty) {
      return HealthTip('From Dr. Deepika', t.trim());
    }
    return null;
  }

  static HealthTip todayTip() => overrideTip() ?? tips[todayIndex()];

  static HealthTip tipAt(int index) {
    final i = index % tips.length;
    return tips[i < 0 ? i + tips.length : i];
  }
}
