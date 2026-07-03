import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'models.dart';

class ExportService {
  
  Future<String?> exportDataToExcel({
    required List<Map<String, dynamic>> data,
    required StopwatchMode mode,
    OperationTemplate? activeTemplate,
    required String studyName, 
  }) async {
    
    OperationTemplate templateToUse;
    
    if (activeTemplate != null) {
      templateToUse = activeTemplate;
    } else {
      templateToUse = OperationTemplate()
        ..name = studyName
        ..steps = data.map((e) => e['name'].toString()).toList();
        
      for (int i = 0; i < data.length; i++) {
        data[i]['step_index'] = i;
      }
    }

    return await _exportJabilTemplateToExcel(data, templateToUse, studyName);
  }

  Future<String?> _exportJabilTemplateToExcel(List<Map<String, dynamic>> data, OperationTemplate template, String studyName) async {
    int numSteps = template.steps.length;
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    CellStyle headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText
    );

    CellStyle centerStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText
    );
    
    CellStyle boldStyle = CellStyle(bold: true);

    CellStyle percentStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      numberFormat: NumFormat.standard_9 
    );

    List<List<double>> stepTimes = List.generate(numSteps, (_) => []);
    for (var record in data) {
      int sIndex = record['step_index'] ?? 0;
      if (sIndex >= 0 && sIndex < numSteps && record['type'] != 'outlier') {
        stepTimes[sIndex].add(record['time'] / 1000.0);
      }
    }

    int maxCycles = 10;
    for (var times in stepTimes) {
      if (times.length > maxCycles) {
        maxCycles = times.length;
      }
    }

    // Encabezados
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue("Seq.");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = headerStyle;
    
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue("Work Element Description");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).cellStyle = headerStyle;
    
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue("Type");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).cellStyle = headerStyle;
    
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles - 1, rowIndex: 0));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = TextCellValue("Observed Time (OT)");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).cellStyle = headerStyle;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 0)).value = TextCellValue("NC");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 0)).cellStyle = headerStyle;

    for (int i = 0; i < maxCycles; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: 1)).value = IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: 1)).cellStyle = headerStyle;
    }

    // Datos
    int currentRow = 2; 
    int firstDataRowExcel = currentRow + 1; 
    
    for (int i = 0; i < numSteps; i++) {
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow + 1)); 
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow + 1)); 
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow + 1)); 
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: currentRow + 1)); 

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = IntCellValue(i + 1); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = centerStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(template.steps[i]); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).cellStyle = centerStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue("Hand"); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = centerStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: currentRow)).value = TextCellValue("N/A");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: currentRow)).cellStyle = centerStyle;

      for (int c = 0; c < maxCycles; c++) {
        if (c < stepTimes[i].length) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).value = DoubleCellValue(stepTimes[i][c]);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).cellStyle = centerStyle;
          
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow + 1)).value = DoubleCellValue(1.0);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow + 1)).cellStyle = percentStyle;
        }
      }
      currentRow += 2; 
    }

    int endDataRowExcel = currentRow; 
    
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow + 2));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue("Process Summary");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = headerStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue("Hand");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = boldStyle;
    for(int c = 0; c < maxCycles; c++) {
        String col = _getColumnLetter(4 + c);
        String formula = 'SUMIF(\$D\$$firstDataRowExcel:\$D\$$endDataRowExcel,"Hand",$col\$$firstDataRowExcel:$col\$$endDataRowExcel)';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).value = FormulaCellValue(formula);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).cellStyle = centerStyle;
    }
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue("Mach");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = boldStyle;
    for(int c = 0; c < maxCycles; c++) {
        String col = _getColumnLetter(4 + c);
        String formula = 'SUMIF(\$D\$$firstDataRowExcel:\$D\$$endDataRowExcel,"Mach",$col\$$firstDataRowExcel:$col\$$endDataRowExcel)';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).value = FormulaCellValue(formula);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).cellStyle = centerStyle;
    }
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue("IMT");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = boldStyle;
    for(int c = 0; c < maxCycles; c++) {
        String col = _getColumnLetter(4 + c);
        String formula = 'SUMIF(\$D\$$firstDataRowExcel:\$D\$$endDataRowExcel,"IMT",$col\$$firstDataRowExcel:$col\$$endDataRowExcel)';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).value = FormulaCellValue(formula);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).cellStyle = centerStyle;
    }

    sheet.setColumnWidth(0, 8.0);  
    sheet.setColumnWidth(1, 40.0); 
    sheet.setColumnWidth(2, 5.0);  
    sheet.setColumnWidth(3, 10.0); 
    for(int i = 0; i <= maxCycles; i++){
      sheet.setColumnWidth(4 + i, 8.0); 
    }

    var fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception("Error al codificar el libro de Excel");
    }

    final date = DateTime.now();
    final baseName = studyName.replaceAll(' ', '_');
    final name = "${baseName}_${date.year}${date.month}${date.day}_${date.hour}${date.minute}";

    final result = await FileSaver.instance.saveAs(
      name: name, 
      bytes: Uint8List.fromList(fileBytes), 
      ext: 'xlsx', 
      mimeType: MimeType.microsoftExcel
    );
    return result != null ? '$name.xlsx' : null;
  }

  String _getColumnLetter(int colIndex) {
    String letter = '';
    while (colIndex >= 0) {
      letter = String.fromCharCode((colIndex % 26) + 65) + letter;
      colIndex = (colIndex ~/ 26) - 1;
    }
    return letter;
  }

  Future<Map<String, dynamic>?> importDataFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'], 
      );
      
      if (result == null || result.files.isEmpty) {
        return null;
      }

      Uint8List? bytes = result.files.first.bytes;
      if (bytes == null && result.files.first.path != null) {
        bytes = File(result.files.first.path!).readAsBytesSync();
      }
      
      if (bytes == null) {
        return null;
      }

      var excel = Excel.decodeBytes(bytes);
      var sheetName = excel.tables.keys.first;
      var sheet = excel.tables[sheetName];
      
      if (sheet == null) {
        return null;
      }

      // 1. Calcular cuántos ciclos tiene el archivo
      int maxCycles = 0;
      while (true) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 1));
        if (cell.value == null || cell.value.toString().isEmpty) {
          break;
        }
        maxCycles++;
      }

      // 2. Calcular cuántos pasos (filas) tiene el archivo
      int numSteps = 0;
      while (true) {
        int row = 2 + (numSteps * 2);
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        if (cell.value == null || cell.value.toString().contains("Process")) {
          break;
        }
        numSteps++;
      }

      List<Map<String, dynamic>> times = [];
      double cumulativeMs = 0;
      
      // 3. Reconstrucción Cronológica
      for (int c = 0; c < maxCycles; c++) {
        for (int r = 0; r < numSteps; r++) {
          int row = 2 + (r * 2);
          var timeCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: row));
          
          if (timeCell.value != null) {
            double? timeSec;
            var cv = timeCell.value;
            
            // Extracción segura del valor numérico
            if (cv is DoubleCellValue) {
              timeSec = cv.value;
            } else if (cv is IntCellValue) {
              timeSec = cv.value.toDouble();
            } else if (cv is TextCellValue) {
              timeSec = double.tryParse(cv.value.text ?? '');
            }

            if (timeSec != null && timeSec > 0) {
              int timeMs = (timeSec * 1000).toInt();
              cumulativeMs += timeMs;
              
              // Extraer nombre del paso de forma segura
              String stepName = 'Paso ${r + 1}';
              var nameCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value;
              
              if (nameCell is TextCellValue) {
                stepName = nameCell.value.text ?? '';
              } else if (nameCell != null) {
                stepName = nameCell.toString();
              }

              times.add({
                'name': stepName,
                'time': timeMs,
                'cumulative_time': cumulativeMs.toInt(),
                'type': 'normal',
                'status': 'done',
                'step_index': r
              });
            }
          }
        }
      }
      
      if (times.isEmpty) {
        return null;
      }
      return {'mode': StopwatchMode.continuo, 'times': times};
    } catch (e) {
      throw Exception("Error al leer Excel. Asegúrate de que tenga el formato Jabil de la App.");
    }
  }
}