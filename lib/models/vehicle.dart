import 'package:flutter/material.dart';

enum VehicleKind {
  motor('Motor'),
  mobil('Mobil');

  const VehicleKind(this.label);
  final String label;

  static VehicleKind parse(Object? raw) =>
      raw == 'mobil' ? VehicleKind.mobil : VehicleKind.motor;
}

class Vehicle {
  const Vehicle({
    this.id = 'veh-1',
    this.kind = VehicleKind.motor,
    required this.brand,
    required this.model,
    required this.plate,
    required this.type,
    required this.year,
    required this.mileage,
    int? baselineMileage,
  }) : baselineMileage = baselineMileage ?? mileage;

  final String id;
  final VehicleKind kind;
  final String brand, model, plate, type;
  final int year, mileage;

  /// Odometer reading when the vehicle was added. Maintenance estimates are
  /// counted from here until a task is marked done.
  final int baselineMileage;

  String get name => '$brand $model $year';

  Vehicle copyWith({
    VehicleKind? kind,
    String? brand,
    String? model,
    String? plate,
    String? type,
    int? year,
    int? mileage,
  }) => Vehicle(
    id: id,
    kind: kind ?? this.kind,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    plate: plate ?? this.plate,
    type: type ?? this.type,
    year: year ?? this.year,
    mileage: mileage ?? this.mileage,
    baselineMileage: baselineMileage,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'brand': brand,
    'model': model,
    'plate': plate,
    'type': type,
    'year': year,
    'mileage': mileage,
    'baselineMileage': baselineMileage,
  };

  factory Vehicle.fromJson(Map<String, dynamic> json, {Vehicle? fallback}) {
    final mileage = json['mileage'];
    final base = json['baselineMileage'];
    final safeMileage = mileage is int && mileage >= 0
        ? mileage
        : (fallback?.mileage ?? 0);
    return Vehicle(
      id: json['id'] as String? ?? fallback?.id ?? 'veh-1',
      kind: json['kind'] == null
          ? (fallback?.kind ?? VehicleKind.motor)
          : VehicleKind.parse(json['kind']),
      brand: json['brand'] as String? ?? fallback?.brand ?? '',
      model: json['model'] as String? ?? fallback?.model ?? '',
      plate: json['plate'] as String? ?? fallback?.plate ?? '',
      type: json['type'] as String? ?? fallback?.type ?? '',
      year: json['year'] as int? ?? fallback?.year ?? DateTime.now().year,
      mileage: safeMileage,
      baselineMileage: base is int && base >= 0 ? base : safeMileage,
    );
  }

  static const demo = Vehicle(
    brand: 'Honda',
    model: 'Beat',
    plate: 'B 1234 XYZ',
    type: 'CBS',
    year: 2021,
    mileage: 12450,
  );
}

class MaintenanceTask {
  const MaintenanceTask(this.title, this.intervalKm, this.icon);
  final String title;
  final int intervalKm;
  final IconData icon;

  static const motorTasks = [
    MaintenanceTask('Ganti Oli Mesin', 2000, Icons.oil_barrel_outlined),
    MaintenanceTask('Cek Kampas Rem', 5000, Icons.disc_full),
    MaintenanceTask('Cek Filter Udara', 5000, Icons.filter_alt_outlined),
    MaintenanceTask('Cek Busi', 8000, Icons.electrical_services),
    MaintenanceTask('Ganti Oli Gear (CVT)', 8000, Icons.settings_outlined),
  ];

  static const carTasks = [
    MaintenanceTask('Ganti Oli Mesin', 5000, Icons.oil_barrel_outlined),
    MaintenanceTask('Cek Kampas Rem', 20000, Icons.disc_full),
    MaintenanceTask('Cek Filter Udara', 10000, Icons.filter_alt_outlined),
    MaintenanceTask('Cek Busi', 20000, Icons.electrical_services),
    MaintenanceTask('Ganti Oli Transmisi', 40000, Icons.settings_outlined),
  ];

  static List<MaintenanceTask> forKind(VehicleKind kind) =>
      kind == VehicleKind.mobil ? carTasks : motorTasks;
}

enum DueLevel { ok, soon, overdue }

class MaintenanceRecord {
  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.task,
    required this.mileage,
    required this.date,
  });
  final String id, vehicleId, task;
  final int mileage;
  final DateTime date;

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'task': task,
    'mileage': mileage,
    'date': date.toIso8601String(),
  };

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) =>
      MaintenanceRecord(
        id: json['id'] as String,
        vehicleId: json['vehicleId'] as String,
        task: json['task'] as String,
        mileage: (json['mileage'] as num).toInt(),
        date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      );
}

/// Computed due information for one [MaintenanceTask] on one [Vehicle].
class MaintenanceStatus {
  const MaintenanceStatus({
    required this.task,
    required this.dueAt,
    required this.remaining,
    required this.level,
    this.lastDone,
  });

  final MaintenanceTask task;
  final int dueAt;

  /// Kilometres until due; negative when overdue.
  final int remaining;
  final DueLevel level;
  final MaintenanceRecord? lastDone;

  static const soonThresholdKm = 1000;

  /// Next due odometer = last completion + interval, or, if never completed,
  /// the first interval boundary after the odometer when the vehicle was added.
  static MaintenanceStatus compute(
    Vehicle vehicle,
    MaintenanceTask task,
    Iterable<MaintenanceRecord> records,
  ) {
    final done =
        records
            .where((r) => r.vehicleId == vehicle.id && r.task == task.title)
            .toList()
          ..sort((a, b) => b.mileage.compareTo(a.mileage));
    final last = done.isEmpty ? null : done.first;
    final dueAt = last != null
        ? last.mileage + task.intervalKm
        : (vehicle.baselineMileage ~/ task.intervalKm + 1) * task.intervalKm;
    final remaining = dueAt - vehicle.mileage;
    return MaintenanceStatus(
      task: task,
      dueAt: dueAt,
      remaining: remaining,
      lastDone: last,
      level: remaining < 0
          ? DueLevel.overdue
          : remaining <= soonThresholdKm
          ? DueLevel.soon
          : DueLevel.ok,
    );
  }

  bool get needsAttention => level != DueLevel.ok;
}
