import 'package:flutter/material.dart';

enum DtcSeverity {
  low('Rendah', Color(0xFF008438)),
  medium('Sedang', Color(0xFFF59E0B)),
  high('Tinggi', Color(0xFFE21B23));

  const DtcSeverity(this.label, this.color);
  final String label;
  final Color color;
}

/// Plain-language description of a diagnostic trouble code. A DTC is an
/// indication that needs inspection, never a definitive diagnosis.
class DtcInfo {
  const DtcInfo({
    required this.code,
    required this.title,
    required this.severity,
    required this.explanation,
    required this.checks,
    this.partCategory = 'Sparepart',
    this.bengkelService = 'Pemeriksaan Kode OBD',
  });

  final String code, title, explanation, partCategory, bengkelService;
  final DtcSeverity severity;
  final List<String> checks;

  static const catalog = <String, DtcInfo>{
    'P0301': DtcInfo(
      code: 'P0301',
      title: 'Misfire silinder 1',
      severity: DtcSeverity.medium,
      explanation: 'ECU mendeteksi pembakaran tidak sempurna pada silinder 1. Ini indikasi, bukan kepastian komponen rusak.',
      checks: [
        'Kondisi dan celah busi',
        'Kabel/koil busi',
        'Injektor dan kompresi',
      ],
      partCategory: 'Sparepart',
    ),
    'P0171': DtcInfo(
      code: 'P0171',
      title: 'Campuran bahan bakar terlalu kurus',
      severity: DtcSeverity.medium,
      explanation: 'Sensor membaca udara berlebih dibanding bahan bakar. Penyebabnya bisa beragam sehingga perlu diperiksa.',
      checks: ['Filter udara', 'Kebocoran saluran isap', 'Tekanan bahan bakar'],
      partCategory: 'Filter',
    ),
    'P0562': DtcInfo(
      code: 'P0562',
      title: 'Tegangan sistem rendah',
      severity: DtcSeverity.high,
      explanation: 'Tegangan sistem kelistrikan terbaca di bawah normal. Periksa aki dan sistem pengisian sebelum perjalanan jauh.',
      checks: [
        'Tegangan dan kondisi aki',
        'Kiprok / regulator',
        'Kabel dan terminal',
      ],
      partCategory: 'Aki',
    ),
  };

  static DtcInfo lookup(String code) =>
      catalog[code] ??
      DtcInfo(
        code: code,
        title: 'Kode tidak dikenal',
        severity: DtcSeverity.low,
        explanation: 'Kode ini belum ada di data simulasi. Konsultasikan dengan bengkel.',
        checks: const ['Pemeriksaan oleh bengkel'],
      );
}

/// A pretend OBD adapter shown during the simulated scan.
class SimulatedAdapter {
  const SimulatedAdapter(this.id, this.name, this.signal);
  final String id, name;
  final int signal; // 1..3 bars

  static const found = [
    SimulatedAdapter('elm327-demo', 'ELM327 Mini (simulasi)', 3),
    SimulatedAdapter('obdlink-demo', 'OBD Link Demo (simulasi)', 2),
  ];
}
