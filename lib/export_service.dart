import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'models.dart';

class ExportService {
  
  // --- MOTOR ÚNICO DE EXPORTACIÓN EXCEL (.XLSX) ---
  Future<String?> exportDataToExcel({
    required List<Map<String, dynamic>> data,
    required StopwatchMode mode,
    OperationTemplate? activeTemplate,
    required String studyName, 
  }) async {
    
    // 1. Deducir los pasos: Si hay plantilla, los usamos. Si no, extraemos los únicos del estudio.
    List<String> steps = [];
    if (activeTemplate != null) {
      steps = activeTemplate.steps;
    } else {
      for (var record in data) {
        String name = record['name'] ?? 'Elemento';
        if (!steps.contains(name)) steps.add(name);
      }
    }

    int numSteps = steps.length;
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // Estilos para el Excel
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

    // 2. Agrupar los tiempos usando el índice o buscando su posición
    List<List<double>> stepTimes = List.generate(numSteps, (_) => []);
    for (var record in data) {
      int sIndex = record['step_index'] ?? -1;
      String name = record['name'] ?? '';

      // Si no hay plantilla, buscamos el índice dinámicamente
      if (activeTemplate == null) {
        sIndex = steps.indexOf(name);
      }

      if (sIndex >= 0 && sIndex < numSteps && record['type'] != 'outlier') {
        stepTimes[sIndex].add((record['time'] as int) / 1000.0);
      }
    }

    int maxCycles = 1;
    for (var times in stepTimes) {
      if (times.length > maxCycles) maxCycles = times.length;
    }

    // =========================================================================
    // ENCABEZADOS DE LA TABLA (EMPIEZA EXACTAMENTE EN LA FILA 1)
    // =========================================================================
    
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
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = TextCellValue("Observed Time (OT) Secs");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).cellStyle = headerStyle;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 0)).value = TextCellValue("NC");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 0)).cellStyle = headerStyle;

    for (int i = 0; i < maxCycles; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: 1)).value = IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: 1)).cellStyle = headerStyle;
    }

    // =========================================================================
    // CONSTRUCCIÓN DE LOS DATOS 
    // =========================================================================
    int currentRow = 2; // Fila 3 en Excel
    int firstDataRowExcel = currentRow + 1; 
    
    for (int i = 0; i < numSteps; i++) {
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow + 1)); 
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow + 1)); 
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow + 1)); 
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: currentRow + 1)); 

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = IntCellValue(i + 1); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = centerStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(steps[i]); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).cellStyle = centerStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue("Hand"); 
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = centerStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: currentRow)).value = TextCellValue("N/A");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: currentRow)).cellStyle = centerStyle;

      for (int c = 0; c < maxCycles; c++) {
        if (c < stepTimes[i].length) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).value = DoubleCellValue(stepTimes[i][c]);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).cellStyle = centerStyle;
          
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow + 1)).value = IntCellValue(1);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow + 1)).cellStyle = centerStyle;
        }
      }
      currentRow += 2; 
    }

    // =========================================================================
    // PROCESS SUMMARY Y FÓRMULAS
    // =========================================================================
    int endDataRowExcel = currentRow; 
    
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow + 2));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue("Process Summary");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = headerStyle;

    List<String> types = ["Hand", "Mach", "IMT"];
    for(int t = 0; t < types.length; t++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow + t)).value = TextCellValue(types[t]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow + t)).cellStyle = boldStyle;
      for(int c = 0; c < maxCycles; c++) {
          String col = _getColumnLetter(4 + c);
          String formula = 'SUMIF(\$D\$$firstDataRowExcel:\$D\$$endDataRowExcel,"${types[t]}",${col}\$$firstDataRowExcel:$col\$$endDataRowExcel)';
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow + t)).value = FormulaCellValue(formula);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow + t)).cellStyle = centerStyle;
      }
    }

    // Ajustes estéticos
    sheet.setColumnWidth(0, 8.0);  
    sheet.setColumnWidth(1, 40.0); 
    sheet.setColumnWidth(2, 5.0);  
    sheet.setColumnWidth(3, 10.0); 
    for(int i = 0; i <= maxCycles; i++){
      sheet.setColumnWidth(4 + i, 8.0); 
    }

    var fileBytes = excel.encode();
    if (fileBytes == null) throw Exception("Error al codificar el libro de Excel");

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

  // --- MOTOR NATIVO DE IMPORTACIÓN DESDE EXCEL ---
  Future<Map<String, dynamic>?> importDataFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'], 
      );
      if (result == null || result.files.isEmpty) return null;

      Uint8List? bytes = result.files.first.bytes;
      if (bytes == null && result.files.first.path != null) {
        bytes = File(result.files.first.path!).readAsBytesSync();
      }
      if (bytes == null) return null;

      var excel = Excel.decodeBytes(bytes);
      Sheet sheet = excel.tables[excel.tables.keys.first]!;
      
      List<Map<String, dynamic>> times = [];
      // Se importa como Regreso a Cero ya que Excel solo almacena TO (Tiempos Observados), no Acumulados.
      StopwatchMode mode = StopwatchMode.regresoACero; 

      int maxCols = sheet.maxColumns;
      
      // Reconstruimos la lista en orden cronológico leyendo Columna por Columna (Ciclo por Ciclo)
      for (int cycle = 0; cycle < (maxCols - 4); cycle++) {
         for (int r = 2; r < sheet.maxRows; r += 2) {
            var nameCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value;
            if (nameCell == null || nameCell.toString().contains("Process Summary")) break;
            
            String name = nameCell.toString();
            var timeCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + cycle, rowIndex: r)).value;
            
            if (timeCell != null) {
               double timeSec = 0.0;
               if (timeCell is DoubleCellValue) timeSec = timeCell.value;
               else if (timeCell is IntCellValue) timeSec = timeCell.value.toDouble();
               else timeSec = double.tryParse(timeCell.toString()) ?? 0.0;

               if (timeSec > 0) {
                  times.add({
                    'name': name,
                    'time': (timeSec * 1000).toInt(),
                    'cumulative_time': 0,
                    'type': 'normal',
                    'status': 'done',
                    'step_index': (r - 2) ~/ 2
                  });
               }
            }
         }
      }
      return {'mode': mode, 'times': times};
    } catch (e) {
      throw Exception("Error al leer el archivo. Asegúrate de que sea un Excel generado por TimeLog.");
    }
  }
}