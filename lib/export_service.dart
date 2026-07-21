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
    int globalRating = 100,
    Map<int, int> cycleRatings = const {},
  }) async {
    final fileBytes = await generateExcelBytes(
      data: data,
      mode: mode,
      activeTemplate: activeTemplate,
      studyName: studyName,
      globalRating: globalRating,
      cycleRatings: cycleRatings,
    );

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

  Future<List<int>> generateExcelBytes({
    required List<Map<String, dynamic>> data,
    required StopwatchMode mode,
    OperationTemplate? activeTemplate,
    required String studyName, 
    int globalRating = 100,
    Map<int, int> cycleRatings = const {},
  }) async {
    
    // Precalculamos el rating de cada record
    int getOriginalCycleIndex(int recordIndex, OperationTemplate? template) {
      if (template != null && template.steps.isNotEmpty) {
        return recordIndex ~/ template.steps.length;
      }
      return recordIndex;
    }

    for (int i = 0; i < data.length; i++) {
       int cIndex = getOriginalCycleIndex(i, activeTemplate);
       data[i]['applied_rating'] = cycleRatings[cIndex] ?? globalRating;
    }

    OperationTemplate templateToUse;
    
    if (mode == StopwatchMode.regresoACero) {
      if (activeTemplate != null) {
        templateToUse = activeTemplate;
      } else {
        List<String> uniqueSteps = [];
        for (var record in data) {
          String name = record['name'].toString();
          if (!uniqueSteps.contains(name)) {
            uniqueSteps.add(name);
          }
        }
        templateToUse = OperationTemplate()
          ..name = studyName
          ..steps = uniqueSteps;
          
        for (var record in data) {
          record['step_index'] = uniqueSteps.indexOf(record['name'].toString());
        }
      }
    } else {
      // Modo Por Elemento (continuo): detectar cuántos pasos tiene un ciclo
      // analizando los nombres en orden hasta que se repita el primero.
      int detectedStepCount = data.length;
      if (data.isNotEmpty) {
        String firstName = data[0]['name'].toString();
        for (int i = 1; i < data.length; i++) {
          if (data[i]['name'].toString() == firstName) {
            detectedStepCount = i;
            break;
          }
        }
      }

      // Si hay plantilla activa, su longitud es la fuente de verdad
      if (activeTemplate != null && activeTemplate.steps.isNotEmpty) {
        detectedStepCount = activeTemplate.steps.length;
      }

      // Construir la plantilla con los nombres del PRIMER ciclo
      List<String> stepNames = [];
      for (int i = 0; i < detectedStepCount && i < data.length; i++) {
        stepNames.add(data[i]['name'].toString());
      }

      templateToUse = OperationTemplate()
        ..name = studyName
        ..steps = stepNames;

      // Asignar step_index como posición dentro del ciclo
      for (int i = 0; i < data.length; i++) {
        data[i]['step_index'] = i % detectedStepCount;
      }
    }

    return await _exportJabilTemplateToExcel(data, templateToUse, studyName);
  }

  Future<List<int>> _exportJabilTemplateToExcel(List<Map<String, dynamic>> data, OperationTemplate template, String studyName) async {
    int numSteps = template.steps.length;
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // Estilos base
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
    
    CellStyle centerBold = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle percentStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      numberFormat: NumFormat.standard_9 // Da formato de % nativo en Excel
    );

    List<List<Map<String, dynamic>>> stepData = List.generate(numSteps, (_) => []);
    for (var record in data) {
      int sIndex = record['step_index'] ?? 0;
      if (sIndex >= 0 && sIndex < numSteps && record['type'] != 'outlier') {
        stepData[sIndex].add(record);
      }
    }

    int maxCycles = 10;
    for (var times in stepData) {
      if (times.length > maxCycles) {
        maxCycles = times.length;
      }
    }

    // ==========================================
    // 1. ÍNDICES DE COLUMNAS DINÁMICAS
    // ==========================================
    int ncCol = 4 + maxCycles;
    int avgOtCol = ncCol + 1;
    int avgNtCol = avgOtCol + 1;
    int freqCol = avgNtCol + 1;
    int pfdCol = freqCol + 1;
    int stdTimeCol = pfdCol + 1;
    int remarksCol = stdTimeCol + 1;

    // ==========================================
    // 2. ENCABEZADOS PRINCIPALES
    // ==========================================
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

    for (int i = 0; i < maxCycles; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: 1)).value = IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: 1)).cellStyle = headerStyle;
    }

    void addHeader(int col, String text) {
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).value = TextCellValue(text);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = headerStyle;
    }

    addHeader(ncCol, "NC");
    addHeader(avgOtCol, "Avg. OT");
    addHeader(avgNtCol, "Avg. NT");
    addHeader(freqCol, "NC\nFreq.");
    addHeader(pfdCol, "App.\nPF&D");
    addHeader(stdTimeCol, "Std. Time");
    
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: remarksCol + 2, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: 0)).value = TextCellValue("Remarks");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: 0)).cellStyle = headerStyle;

    // ==========================================
    // 3. DATOS Y FÓRMULAS ESTRUCTURADAS
    // ==========================================
    int currentRow = 2; 
    int firstDataRowExcel = currentRow + 1; 
    
    for (int i = 0; i < numSteps; i++) {
      int excelRow = currentRow + 1; // Fila en el software Excel (inicia en 1)

      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow + 1)); 
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow + 1)); 
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow + 1)); 
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: ncCol, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: ncCol, rowIndex: currentRow + 1)); 
      
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: currentRow + 1));
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: avgNtCol, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: avgNtCol, rowIndex: currentRow + 1));
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: freqCol, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: freqCol, rowIndex: currentRow + 1));
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: currentRow + 1));
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: currentRow + 1));
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: remarksCol + 2, rowIndex: currentRow + 1));

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = IntCellValue(i + 1); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = centerStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(template.steps[i]); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).cellStyle = centerStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue("Hand"); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = centerStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: ncCol, rowIndex: currentRow)).value = TextCellValue("N/A"); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: ncCol, rowIndex: currentRow)).cellStyle = centerStyle;

      // Inyección de Tiempos y Calificación de Operario
      for (int c = 0; c < maxCycles; c++) {
        if (c < stepData[i].length) {
          var record = stepData[i][c];
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).value = DoubleCellValue((record['time'] as num) / 1000.0);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).cellStyle = centerStyle;
          
          int currentRating = record['applied_rating'] as int? ?? 100;
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow + 1)).value = DoubleCellValue(currentRating / 100.0); 
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow + 1)).cellStyle = percentStyle;
        }
      }

      // ==========================================
      // FÓRMULAS ESTRUCTURALES DEL ESTUDIO
      // ==========================================
      String startCycleCol = _getColumnLetter(4);
      String endCycleCol = _getColumnLetter(4 + maxCycles - 1);
      
      String avgOtFormula = 'IFERROR(AVERAGE($startCycleCol$excelRow:$endCycleCol$excelRow),"")';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: currentRow)).value = FormulaCellValue(avgOtFormula);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: currentRow)).cellStyle = centerStyle;

      String avgNtFormula = 'IFERROR((SUMPRODUCT($startCycleCol$excelRow:$endCycleCol$excelRow,$startCycleCol${excelRow+1}:$endCycleCol${excelRow+1})/COUNTIF($startCycleCol$excelRow:$endCycleCol$excelRow,">0")),"")';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgNtCol, rowIndex: currentRow)).value = FormulaCellValue(avgNtFormula);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgNtCol, rowIndex: currentRow)).cellStyle = centerStyle;

      // Frecuencia
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: freqCol, rowIndex: currentRow)).value = const IntCellValue(1); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: freqCol, rowIndex: currentRow)).cellStyle = centerStyle;

      // PF&D (8%)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: currentRow)).value = const DoubleCellValue(0.08); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: currentRow)).cellStyle = percentStyle;

      String avgNtColStr = _getColumnLetter(avgNtCol);
      String freqColStr = _getColumnLetter(freqCol);
      String pfdColStr = _getColumnLetter(pfdCol);
      String stdTimeFormula = 'IFERROR(($avgNtColStr$excelRow*(1/$freqColStr$excelRow)*(1+$pfdColStr$excelRow)),"")';
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: currentRow)).value = FormulaCellValue(stdTimeFormula);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: currentRow)).cellStyle = centerStyle;

      currentRow += 2; 
    }

    // ==========================================
    // 4. PROCESS SUMMARY (Consolidado Inteligente)
    // ==========================================
    int summaryStartRow = currentRow;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow + 2));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue("Process Summary"); 
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = centerBold; 
    
    String stdColStr = _getColumnLetter(stdTimeCol);
    List<String> types = ["Hand", "Mach", "IMT"];
    
    for (int t = 0; t < types.length; t++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue(types[t]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = centerBold;
      
      // LÓGICA DE RANGO DINÁMICO E INDESTRUCTIBLE
      for (int colIndex = 4; colIndex <= avgNtCol; colIndex++) {
        if (colIndex == ncCol) continue; 
        
        String col = _getColumnLetter(colIndex);
        String formula = 'SUMIF(\$D$firstDataRowExcel:INDEX(\$D:\$D,ROW()-1),"${types[t]}",\$$col$firstDataRowExcel:INDEX(\$$col:\$$col,ROW()-1))';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: currentRow)).value = FormulaCellValue(formula);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: currentRow)).cellStyle = centerStyle;
      }

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: currentRow)).value = TextCellValue(types[t]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: currentRow)).cellStyle = centerBold;

      // Sumatoria de Std. Time
      String formulaStdTotal = 'SUMIF(\$D$firstDataRowExcel:INDEX(\$D:\$D,ROW()-1),"${types[t]}",\$$stdColStr$firstDataRowExcel:INDEX(\$$stdColStr:\$$stdColStr,ROW()-1))';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: currentRow)).value = FormulaCellValue(formulaStdTotal);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: currentRow)).cellStyle = centerStyle;

      currentRow++;
    }

    // ==========================================
    // 5. CÁLCULOS FINALES ESTRUCTURADOS (VAT, SMH, UPH)
    // ==========================================
    int statsRow1 = summaryStartRow + 3;
    int statsRow2 = summaryStartRow + 4;
    int statsRow3 = summaryStartRow + 5;
    int statsRow4 = summaryStartRow + 6;
    
    CellStyle rightAlignBold = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right, verticalAlign: VerticalAlign.Center);
    
    void addStatRow(int rowIndex, String label1, dynamic value1, String label2, String formula2) {
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: rowIndex));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: rowIndex)).value = TextCellValue(label1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: rowIndex)).cellStyle = rightAlignBold;
      
      if (value1 is int) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: rowIndex)).value = IntCellValue(value1);
      } else if (value1 is String && value1.startsWith('=')) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: rowIndex)).value = FormulaCellValue(value1.substring(1));
      } else {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: rowIndex)).value = TextCellValue(value1.toString());
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: rowIndex)).cellStyle = centerStyle;
      
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: remarksCol + 1, rowIndex: rowIndex));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: rowIndex)).value = TextCellValue(label2);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: rowIndex)).cellStyle = centerBold;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol + 2, rowIndex: rowIndex)).value = FormulaCellValue(formula2);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol + 2, rowIndex: rowIndex)).cellStyle = centerStyle;
    }
    
    // Referencias relativas
    int handStdRow = summaryStartRow + 1;
    int machStdRow = summaryStartRow + 2;
    int imtStdRow = summaryStartRow + 3;
    
    int row2Excel = statsRow2 + 1;
    int row3Excel = statsRow3 + 1;
    int row4Excel = statsRow4 + 1;
    String rightValueColStr = _getColumnLetter(remarksCol + 2);

    addStatRow(statsRow1, "# of Mach/Stations", '=$stdColStr$row2Excel*$stdColStr$row3Excel', 
               "VAT", 'IFERROR($stdColStr$handStdRow+$stdColStr$machStdRow,"")');
    addStatRow(statsRow2, "Headcount HC", 1, 
               "SMH", 'IFERROR((($stdColStr$handStdRow+$stdColStr$imtStdRow)/3600)/$stdColStr$row4Excel,"")');
    addStatRow(statsRow3, "# of Mach/Stations per HC", 1, 
               "Standard Time for 1 Unit", 'IFERROR(SUM($stdColStr$handStdRow,$stdColStr$machStdRow)/$stdColStr$row4Excel,"")');
    addStatRow(statsRow4, "Units Produced per Mach", 1, 
               "UPH", 'IFERROR(3600/$rightValueColStr$row3Excel,"")');

    // ==========================================
    // 6. AUTO-AJUSTE VISUAL
    // ==========================================
    sheet.setColumnWidth(0, 8.0);  
    sheet.setColumnWidth(1, 40.0); 
    sheet.setColumnWidth(2, 5.0);  
    sheet.setColumnWidth(3, 10.0); 
    for(int i = 0; i < maxCycles; i++){
      sheet.setColumnWidth(4 + i, 8.0); 
    }
    sheet.setColumnWidth(ncCol, 6.0);
    sheet.setColumnWidth(avgOtCol, 10.0); 
    sheet.setColumnWidth(avgNtCol, 10.0); 
    sheet.setColumnWidth(freqCol, 8.0);   
    sheet.setColumnWidth(pfdCol, 10.0);   
    
    sheet.setColumnWidth(stdTimeCol, 12.0); 
    sheet.setColumnWidth(remarksCol, 12.0); 
    sheet.setColumnWidth(remarksCol + 1, 12.0); 
    sheet.setColumnWidth(remarksCol + 2, 12.0); 

    var fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception("Error al codificar el libro de Excel");
    }

    return fileBytes;
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

      int maxCycles = 0;
      while (true) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 1));
        if (cell.value == null || cell.value.toString().isEmpty) {
          break;
        }
        maxCycles++;
      }

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
      
      for (int c = 0; c < maxCycles; c++) {
        for (int r = 0; r < numSteps; r++) {
          int row = 2 + (r * 2);
          var timeCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: row));
          
          if (timeCell.value != null) {
            double? timeSec;
            var cv = timeCell.value;
            
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