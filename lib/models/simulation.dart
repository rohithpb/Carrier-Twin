class SimulationResult {
  final double currentGpa;
  final double predictedGpa;
  final double gpaDelta;
  final int workloadScore;
  final bool isBurnoutRisk;
  final String burnoutWarningMessage;
  final DateTime timestamp;

  SimulationResult({
    required this.currentGpa,
    required this.predictedGpa,
    required this.gpaDelta,
    required this.workloadScore,
    required this.isBurnoutRisk,
    required this.burnoutWarningMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SimulationResult.fromMap(Map<String, dynamic> map) {
    return SimulationResult(
      currentGpa: (map['currentGpa'] ?? 3.4).toDouble(),
      predictedGpa: (map['predictedGpa'] ?? 3.5).toDouble(),
      gpaDelta: (map['gpaDelta'] ?? 0.1).toDouble(),
      workloadScore: (map['workloadScore'] ?? 45).toInt(),
      isBurnoutRisk: map['isBurnoutRisk'] ?? false,
      burnoutWarningMessage: map['burnoutWarningMessage'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
