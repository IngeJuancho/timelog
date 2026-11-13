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

    // 5. Verify Process Summary has static range instead of INDEX
    final summaryFormula = (sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 12)).value as FormulaCellValue).formula;
    expect(summaryFormula, 'SUMIF(\$D\$11:\$D\$12,"Hand",\$E\$11:\$E\$12)');
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
}
