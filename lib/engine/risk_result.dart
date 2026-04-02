class RiskResult {
  final String disease;
  final String icdCode;
  final int riskScore;
  final String riskLevel;
  final List<String> findings;
  final String guideline;

  const RiskResult({
    required this.disease,
    required this.icdCode,
    required this.riskScore,
    required this.riskLevel,
    required this.findings,
    required this.guideline,
  });

  factory RiskResult.build({
    required String disease,
    required String icdCode,
    required double score,
    required List<String> findings,
    required String guideline,
  }) {
    final clamped = score.clamp(0, 100).toInt();
    String riskLevel;
    if (clamped >= 70) {
      riskLevel = 'high';
    } else if (clamped >= 30) {
      riskLevel = 'moderate';
    } else {
      riskLevel = 'low';
    }
    return RiskResult(
      disease: disease,
      icdCode: icdCode,
      riskScore: clamped,
      riskLevel: riskLevel,
      findings: findings,
      guideline: guideline,
    );
  }

  Map<String, dynamic> toMap() => {
        'disease': disease,
        'icdCode': icdCode,
        'riskScore': riskScore,
        'riskLevel': riskLevel,
        'findings': findings,
        'guideline': guideline,
      };
}
