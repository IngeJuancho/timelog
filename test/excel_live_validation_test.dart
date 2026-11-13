import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelog/models.dart';
import 'package:timelog/services/export/excel_generator.dart';

void main() {
  test('Generate physical Excel file for COM validation', () async {
    final gen = ExcelGenerator();

    // Escenario 1: Modo Libre sin plantilla, 3 operaciones con 10 tiempos cada una,
    // calificación del 110% en ciclo 1, valor atípico en ciclo 2 de Op 2.
    final List<Map<String, dynamic>> multiOpData = [];
    for (int i = 0; i < 10; i++) {
      multiOpData.add({
        'name': 'Operación 1',
        'time': 10000 + (i * 500),
        'status': 'done',
        'type': 'normal',
      });
    }
    for (int i = 0; i < 10; i++) {
      multiOpData.add({
        'name': 'Operación 2',
        'time': (i == 1) ? 50000 : 20000 + (i * 200),
        'status': 'done',
        'type': (i == 1) ? 'outlier' : 'normal',
      });
    }
    for (int i = 0; i < 10; i++) {
      multiOpData.add({
        'name': 'Operación 3',
        'time': 15000 + (i * 300),
        'status': 'done',
        'type': 'normal',
      });
    }

    final bytes = await gen.generateExcelBytes(
      data: multiOpData,
      mode: StopwatchMode.continuo,
      activeTemplate: null,
      studyName: 'Operación 3', // Reproduciendo el bug original del usuario
      globalRating: 110,         // Calificación asignada 110%
      cycleRatings: {
        0: 110, // Ciclo 1 = 110%
        1: 100, // Ciclo 2 = 100%
      },
      pfdRate: 0.13,
    );

    final outDir = Directory('build/test_output');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }

    final outFile = File('build/test_output/estudio_validado.xlsx');
    outFile.writeAsBytesSync(bytes);
    expect(outFile.existsSync(), true);
    expect(outFile.lengthSync() > 1000, true);
  });
}
