class Trip {
  const Trip({
    required this.id,
    required this.vehicleId,
    required this.startedAt,
    required this.endedAt,
    required this.distanceMeters,
    required this.durationSeconds,
    this.addedToMileage = false,
  });

  final String id, vehicleId;
  final DateTime startedAt, endedAt;
  final double distanceMeters;
  final int durationSeconds;
  final bool addedToMileage;

  /// Whole kilometres to offer for the mileage log.
  int get roundedKm => (distanceMeters / 1000).round();
  double get km => distanceMeters / 1000;

  Trip copyWith({bool? addedToMileage}) => Trip(
    id: id,
    vehicleId: vehicleId,
    startedAt: startedAt,
    endedAt: endedAt,
    distanceMeters: distanceMeters,
    durationSeconds: durationSeconds,
    addedToMileage: addedToMileage ?? this.addedToMileage,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'distanceMeters': distanceMeters,
    'durationSeconds': durationSeconds,
    'addedToMileage': addedToMileage,
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    vehicleId: json['vehicleId'] as String,
    startedAt: DateTime.tryParse('${json['startedAt']}') ?? DateTime.now(),
    endedAt: DateTime.tryParse('${json['endedAt']}') ?? DateTime.now(),
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
    durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
    addedToMileage: json['addedToMileage'] == true,
  );
}
