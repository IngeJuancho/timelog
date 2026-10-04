class PfdCategory {
  final String id;
  final int code;
  final String name;
  final String description;
  final double rate;

  const PfdCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.rate,
  });

  String get percentageText => '${(rate * 100).toStringAsFixed(rate * 100 % 1 == 0 ? 0 : 1)}%';

  static const List<PfdCategory> jabilPresets = [
    PfdCategory(
      code: 1,
      id: 'manual_insertion',
      name: 'Inserción / Montaje Ligero',
      description: 'Inserción manual, montaje manual ligero o proceso similar',
      rate: 0.13,
    ),
    PfdCategory(
      code: 2,
      id: 'complex_assembly',
      name: 'Montaje Complejo',
      description: 'Montaje complejo o proceso similar',
      rate: 0.15,
    ),
    PfdCategory(
      code: 3,
      id: 'visual_inspection',
      name: 'Inspección Visual',
      description: 'Inspección visual, THI, FNI y OBA que requieren concentración visual o mental',
      rate: 0.14,
    ),
    PfdCategory(
      code: 4,
      id: 'manual_soldering',
      name: 'Soldado Manual',
      description: 'Soldado manual',
      rate: 0.15,
    ),
    PfdCategory(
      code: 6,
      id: 'test_processes',
      name: 'Pruebas (ICT / FVT / XRAY)',
      description: 'ICT, FVT, XRAY, o procesos de prueba similares',
      rate: 0.12,
    ),
    PfdCategory(
      code: 7,
      id: 'packaging',
      name: 'Empaque',
      description: 'Empaque',
      rate: 0.12,
    ),
  ];

  static PfdCategory get defaultCategory => jabilPresets[0];

  static PfdCategory custom(double rate) {
    return PfdCategory(
      code: 0,
      id: 'custom',
      name: 'Personalizado',
      description: 'Porcentaje de tolerancia PF&D personalizado',
      rate: rate,
    );
  }

  static PfdCategory fromId(String? id, {double? customRate}) {
    if (id == null || id.isEmpty) return defaultCategory;
    if (id == 'custom') {
      return custom(customRate ?? 0.13);
    }
    for (final preset in jabilPresets) {
      if (preset.id == id) return preset;
    }
    return defaultCategory;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'description': description,
    'rate': rate,
  };

  factory PfdCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? 'manual_insertion';
    final rate = (json['rate'] as num?)?.toDouble() ?? 0.13;
    if (id == 'custom') {
      return custom(rate);
    }
    return fromId(id, customRate: rate);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PfdCategory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          rate == other.rate;

  @override
  int get hashCode => id.hashCode ^ rate.hashCode;
}
