class ParkingSettings {
  final double hourPrice;
  final int targetSlots;

  ParkingSettings({
    required this.hourPrice,
    required this.targetSlots,
  });

  Map<String, dynamic> toMap({required String updatedBy}) => {
        'hourPrice': hourPrice,
        'targetSlots': targetSlots,
        'updatedAt': DateTime.now(),
        'updatedBy': updatedBy,
      };

  static ParkingSettings fromMap(Map<String, dynamic> data) {
    return ParkingSettings(
      hourPrice: (data['hourPrice'] ?? 0).toDouble(),
      targetSlots: (data['targetSlots'] ?? 0) as int,
    );
  }
}
