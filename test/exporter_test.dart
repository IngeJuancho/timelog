import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:timelog/models.dart';
import 'package:timelog/services/export/excel_generator.dart';
import 'package:timelog/services/export/excel_importer.dart';

void main() {
  test('Verify Excel generation and bug fixes', () async {
    final gen = ExcelGenerator();

    final testData = [
      {
        'name': 'Paso 1',
        'time': 10000,
        'status': 'done',
        'type': 'normal',
        'step_index': 0,
        'cycle_index': 0,
      },
      {
        'name': 'Paso 1',
        'time': 45000, // Outlier
        'status': 'done',
        'type': 'outlier',
        'step_index': 0,
        'cycle_index': 1,
      },
      {
        'name': 'Paso 1',
        'time': 11000,
        'status': 'done',
        'type': 'normal',
        'step_index': 0,
        'cycle_index': 2,
      },
    ];

    final template = OperationTemplate()
      ..name = 'Test Operation'
      ..steps = ['Paso 1'];

    final bytes = await gen.generateExcelBytes(
      data: testData,
      mode: StopwatchMode.regresoACero,
      activeTemplate: template,
      studyName: 'Test Operation',
    );

    expect(bytes.isNotEmpty, true);

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Sheet1'];

    // 1. Verify Study Mode metadata row 7
    final modeLabel = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 7)).value;
    final modeVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 7)).value;
    expect(modeLabel.toString(), 'Study Mode:');
    expect(modeVal.toString(), 'Regreso a Cero (RAC)');

    // 2. Verify Outlier in Cycle 2: exported as text with '*'
    final cycle1Val = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 10)).value;
    final cycle2Val = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 10)).value;
    final cycle3Val = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 10)).value;

    expect(cycle1Val.toString(), '10');
    expect(cycle2Val is TextCellValue, true);
    expect((cycle2Val as TextCellValue).value.text, '45.00*');
    expect(cycle3Val.toString(), '11');

    // 3. Verify Remarks has footnote
    const remarksCol = 4 + 10 + 6; // col 20
    final remarksVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: 10)).value;
    expect(remarksVal.toString(), '* Valores atípicos excluidos');

    // 4. Verify Standard Time formula uses '*' for frequency
    const stdTimeCol = 4 + 10 + 5; // col 19
    final stdTimeFormula = (sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: 10)).value as FormulaCellValue).formula;
    expect(stdTimeFormula.contains('*'), true);
    expect(stdTimeFormula.contains('/'), false); // No longer divides frequency!

    // 5. Verify Process Summary multiplies Observed Time by Rating (row 12)
    final summaryFormula = (sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 12)).value as FormulaCellValue).formula;
    expect(summaryFormula, 'SUM(IF(\$D\$11="Hand",IFERROR(E11*E12,0),0))');
    expect(summaryFormula.contains('E12'), true); // Explicitly references rating row!
    expect(summaryFormula.contains('INDEX'), false);

    // 6. Verify VAT and SMH use SUM(...) instead of '+'
    final vatFormula = (sheet.cell(CellIndex.indexByColumnRow(columnIndex: 22, rowIndex: 15)).value as FormulaCellValue).formula;
    expect(vatFormula, 'IFERROR(SUM(T13,T14),"")');

    final smhFormula = (sheet.cell(CellIndex.indexByColumnRow(columnIndex: 22, rowIndex: 16)).value as FormulaCellValue).formula;
    expect(smhFormula, 'IFERROR(((SUM(T13,T15)/3600)/T19),"")');
  });

  test('Verify Free Mode cycle spreading', () async {
    final gen = ExcelGenerator();

    final freeData = [
      {'name': 'Ciclo 1', 'time': 5000, 'status': 'done', 'type': 'normal'},
      {'name': 'Ciclo 2', 'time': 6000, 'status': 'done', 'type': 'normal'},
      {'name': 'Ciclo 3', 'time': 5500, 'status': 'done', 'type': 'normal'},
    ];

    final bytes = await gen.generateExcelBytes(
      data: freeData,
      mode: StopwatchMode.regresoACero,
      studyName: 'Inspección',
    );

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Sheet1'];

    // Only 1 step row (row 10), and 3 cycle columns (4, 5, 6)
    final stepNameVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10)).value;
    expect(stepNameVal.toString(), 'Inspección');

    final c1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 10)).value;
    final c2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 10)).value;
    final c3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 10)).value;

    expect(c1.toString(), '5');
    expect(c2.toString(), '6');
    expect(c3.toString(), '5.5');
  });

  test('Verify Excel Importer reads metadata mode and outliers', () async {
    final gen = ExcelGenerator();
    final importer = ExcelImporter();

    final testData = [
      {'name': 'Soldadura', 'time': 12000, 'status': 'done', 'type': 'normal', 'step_index': 0, 'cycle_index': 0},
      {'name': 'Soldadura', 'time': 80000, 'status': 'done', 'type': 'outlier', 'step_index': 0, 'cycle_index': 1},
    ];

    final template = OperationTemplate()
      ..name = 'Proceso Soldadura'
      ..steps = ['Soldadura'];

    final bytes = await gen.generateExcelBytes(
      data: testData,
      mode: StopwatchMode.regresoACero,
      activeTemplate: template,
      studyName: 'Proceso Soldadura',
    );

    final imported = importer.parseExcelBytes(Uint8List.fromList(bytes));
    expect(imported, isNotNull);
    expect(imported!['mode'], StopwatchMode.regresoACero);
    expect(imported['studyName'], 'Proceso Soldadura');
    final times = imported['times'] as List<Map<String, dynamic>>;
    expect(times.length, 2);
    expect(times[0]['type'], 'normal');
    expect(times[1]['type'], 'outlier');
    expect(times[1]['time'], 80000);
  });

  test('Verify 3 manual operations with 10 times each creates 3 rows x 10 columns', () async {
    final gen = ExcelGenerator();

    final List<Map<String, dynamic>> multiOpData = [];
    // 10 times of Operación 1
    for (int i = 0; i < 10; i++) {
      multiOpData.add({'name': 'Operación 1', 'time': 2000 + (i * 100), 'status': 'done', 'type': 'normal'});
    }
    // 10 times of Operación 2
    for (int i = 0; i < 10; i++) {
      multiOpData.add({'name': 'Operación 2', 'time': 50000 + (i * 100), 'status': 'done', 'type': 'normal'});
    }
    // 10 times of Operación 3
    for (int i = 0; i < 10; i++) {
      multiOpData.add({'name': 'Operación 3', 'time': 4000 + (i * 100), 'status': 'done', 'type': 'normal'});
    }

    // In Modo Continuo, without activeTemplate, studyName was "Operación 3" (the last element)
    final bytes = await gen.generateExcelBytes(
      data: multiOpData,
      mode: StopwatchMode.continuo,
      activeTemplate: null,
      studyName: 'Operación 3',
    );

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Sheet1'];

    // 1. Process description must NOT be "Operación 3", but "Estudio de Tiempos"
    final procDescVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 7)).value;
    expect(procDescVal.toString(), 'Estudio de Tiempos');

    // 2. Row 10 (Seq 1): Operación 1
    final seq1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10)).value;
    final name1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10)).value;
    expect(seq1.toString(), '1');
    expect(name1.toString(), 'Operación 1');
    // Cycle 1 to 10 for Op 1
    for (int c = 0; c < 10; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: 10)).value;
      expect(cell, isNotNull);
      expect(cell.toString(), isNotEmpty);
    }

    // 3. Row 12 (Seq 2): Operación 2
    final seq2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 12)).value;
    final name2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12)).value;
    expect(seq2.toString(), '2');
    expect(name2.toString(), 'Operación 2');
    // Cycle 1 to 10 for Op 2
    for (int c = 0; c < 10; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: 12)).value;
      expect(cell, isNotNull);
      expect(cell.toString(), isNotEmpty);
    }

    // 4. Row 14 (Seq 3): Operación 3
    final seq3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 14)).value;
    final name3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 14)).value;
    expect(seq3.toString(), '3');
    expect(name3.toString(), 'Operación 3');
    // Cycle 1 to 10 for Op 3
    for (int c = 0; c < 10; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: 14)).value;
      expect(cell, isNotNull);
      expect(cell.toString(), isNotEmpty);
    }

    // 5. Verify Process Summary in multi-operation manual mode incorporates ratings
    // Row 16 is Process Summary Hand for 3 steps (rows 10, 12, 14 -> excel rows 11, 13, 15)
    final psHandCycle1 = (sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 16)).value as FormulaCellValue).formula;
    expect(psHandCycle1, 'SUM(IF(\$D\$11="Hand",IFERROR(E11*E12,0),0),IF(\$D\$13="Hand",IFERROR(E13*E14,0),0),IF(\$D\$15="Hand",IFERROR(E15*E16,0),0))');
  });

  test('Verify Process Summary formula with custom operator ratings', () async {
    final gen = ExcelGenerator();

    final testData = [
      {'name': 'Corte', 'time': 10000, 'status': 'done', 'type': 'normal', 'step_index': 0, 'cycle_index': 0},
      {'name': 'Ensamble', 'time': 20000, 'status': 'done', 'type': 'normal', 'step_index': 1, 'cycle_index': 0},
    ];

    final template = OperationTemplate()
      ..name = 'Célula 1'
      ..steps = ['Corte', 'Ensamble'];

    final bytes = await gen.generateExcelBytes(
      data: testData,
      mode: StopwatchMode.continuo,
      activeTemplate: template,
      studyName: 'Célula 1',
      globalRating: 110, // 110% rating
    );

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Sheet1'];

    // Row 10 (Corte) rating is in row 11 (excel row 12)
    final ratingCorte = (sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 11)).value as DoubleCellValue).value;
    expect(ratingCorte, 1.10);

    // Row 12 (Ensamble) rating is in row 13 (excel row 14)
    final ratingEnsamble = (sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 13)).value as DoubleCellValue).value;
    expect(ratingEnsamble, 1.10);

    // Process Summary Hand is at rowIndex 14 (excel row 15)
    final psFormula = (sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 14)).value as FormulaCellValue).formula;
    expect(psFormula, 'SUM(IF(\$D\$11="Hand",IFERROR(E11*E12,0),0),IF(\$D\$13="Hand",IFERROR(E13*E14,0),0))');
  });

  test('Verify Free Mode normalizes unnamed Ciclo records and does not split into 1-cell rows', () async {
    final gen = ExcelGenerator();

    final List<Map<String, dynamic>> mixedData = [];
    // 10 unnamed records (default Ciclo 1 .. Ciclo 10)
    for (int i = 1; i <= 10; i++) {
      mixedData.add({'name': 'Ciclo $i', 'time': 8000, 'status': 'done', 'type': 'normal'});
    }
    // Followed by 5 records named "Soldadura"
    for (int i = 0; i < 5; i++) {
      mixedData.add({'name': 'Soldadura', 'time': 12000, 'status': 'done', 'type': 'normal'});
    }

    final bytes = await gen.generateExcelBytes(
      data: mixedData,
      mode: StopwatchMode.continuo,
      activeTemplate: null,
      studyName: 'Estudio_de_Tiempos',
    );

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Sheet1'];

    // Should create exactly 2 rows (Seq 1 and Seq 2), NOT 11 rows!
    final seq1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10)).value;
    final name1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10)).value;
    expect(seq1.toString(), '1');
    expect(name1.toString(), 'Operación 1');

    final seq2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 12)).value;
    final name2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12)).value;
    expect(seq2.toString(), '2');
    expect(name2.toString(), 'Soldadura');

    // Row 14 should NOT be Seq 3, it should be Process Summary
    final psLabel = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 14)).value;
    expect(psLabel.toString(), 'Process Summary');
  });
}
