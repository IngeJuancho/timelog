import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'models.dart';

class ExportService {
  
  Future<String?> exportDataToCsv({
    required List<Map<String, dynamic>> data,
    required StopwatchMode mode,
    required String Function(double) timeFormatter,
    OperationTemplate? activeTemplate,
  }) async {
    if (activeTemplate != null) {
      return await _exportJabilTemplateToExcel(data, activeTemplate);
    }

    // --- EXPORTACIÓN NORMAL (.CSV Libre) ---
    StringBuffer csv = StringBuffer();
    csv.writeln('\uFEFFElemento,Tiempo(OT),TiempoAcumulado(TC),Tipo'); 
    
    for (var item in data) {
      csv.writeln("${item['name']},${timeFormatter(item['time'].toDouble())},${timeFormatter((item['cumulative_time'] ?? 0).toDouble())},${item['type']}");
    }

    return await _saveFile(csv.toString(), 'TimeLog', 'csv', MimeType.csv);
  }

  // --- MOTOR DE EXPORTACIÓN EXCEL (.XLSX) - TABLA EXACTA ---
  Future<String?> _exportJabilTemplateToExcel(List<Map<String, dynamic>> data, OperationTemplate template) async {
    int numSteps = template.steps.length;
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

    // 1. Agrupar los tiempos
    List<List<double>> stepTimes = List.generate(numSteps, (_) => []);
    for (var record in data) {
      int sIndex = record['step_index'] ?? 0;
      if (sIndex >= 0 && sIndex < numSteps && record['type'] != 'outlier') {
        stepTimes[sIndex].add(record['time'] / 1000.0);
      }
    }

    int maxCycles = 10;
    for (var times in stepTimes) {
      if (times.length > maxCycles) maxCycles = times.length;
    }

    // =========================================================================
    // ENCABEZADOS DE LA TABLA (EMPIEZA EXACTAMENTE EN LA FILA 1)
    // =========================================================================
    
    // Seq.
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue("Seq.");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = headerStyle;
    
    // Work Element Description
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue("Work Element Description");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).cellStyle = headerStyle;
    
    // Type
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue("Type");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).cellStyle = headerStyle;
    
    // Observed Time (OT)
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles - 1, rowIndex: 0));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = TextCellValue("Observed Time (OT)");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).cellStyle = headerStyle;

    // NC
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 0)).value = TextCellValue("NC");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles, rowIndex: 0)).cellStyle = headerStyle;

    // Números de ciclos debajo de "OT"
    for (int i = 0; i < maxCycles; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: 1)).value = IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: 1)).cellStyle = headerStyle;
    }

    // =========================================================================
    // CONSTRUCCIÓN DE LOS DATOS
    // =========================================================================
    int currentRow = 2; // Fila 3
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
    
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), 
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow + 2)
    );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue("Process Summary");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = headerStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue("Hand");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = headerStyle;
    for(int c = 0; c < maxCycles; c++) {
        String col = _getColumnLetter(4 + c);
        String formula = 'SUMIF(\$D\$$firstDataRowExcel:\$D\$$endDataRowExcel,"Hand",${col}\$$firstDataRowExcel:$col\$$endDataRowExcel)';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).value = FormulaCellValue(formula);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).cellStyle = centerStyle;
    }
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue("Mach");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = headerStyle;
    for(int c = 0; c < maxCycles; c++) {
        String col = _getColumnLetter(4 + c);
        String formula = 'SUMIF(\$D\$$firstDataRowExcel:\$D\$$endDataRowExcel,"Mach",${col}\$$firstDataRowExcel:$col\$$endDataRowExcel)';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).value = FormulaCellValue(formula);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).cellStyle = centerStyle;
    }
    currentRow++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue("IMT");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = headerStyle;
    for(int c = 0; c < maxCycles; c++) {
        String col = _getColumnLetter(4 + c);
        String formula = 'SUMIF(\$D\$$firstDataRowExcel:\$D\$$endDataRowExcel,"IMT",${col}\$$firstDataRowExcel:$col\$$endDataRowExcel)';
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).value = FormulaCellValue(formula);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: currentRow)).cellStyle = centerStyle;
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

    // REQUISITO CUMPLIDO: Jabil eliminado del nombre del archivo
    final date = DateTime.now();
    final baseName = 'Study_${template.name.replaceAll(' ', '_')}';
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

  Future<String?> _saveFile(String content, String baseName, String extension, MimeType mimeType) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    final date = DateTime.now();
    final name = "${baseName}_${date.year}${date.month}${date.day}_${date.hour}${date.minute}";

    final result = await FileSaver.instance.saveAs(name: name, bytes: bytes, ext: extension, mimeType: mimeType);
    return result != null ? '$name.$extension' : null;
  }

  Future<Map<String, dynamic>?> importDataFromCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'], 
      );
      if (result == null || result.files.isEmpty) return null;

      Uint8List? bytes = result.files.first.bytes;
      if (bytes == null && result.files.first.path != null) {
        bytes = File(result.files.first.path!).readAsBytesSync();
      }
      if (bytes == null) return null;

      String csvString = utf8.decode(bytes);
      List<String> rows = csvString.split('\n');
      if (rows.length <= 1) return null;

      List<Map<String, dynamic>> times = [];
      StopwatchMode mode = StopwatchMode.regresoACero;

      for (int i = 1; i < rows.length; i++) {
        if (rows[i].trim().isEmpty) continue;
        List<String> cols = rows[i].split(',');
        if (cols.length >= 4) {
          double time = double.tryParse(cols[1].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          double cumTime = double.tryParse(cols[2].replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          if (cumTime > 0) mode = StopwatchMode.continuo;
          
          times.add({
            'name': cols[0],
            'time': (time * 1000).toInt(),
            'cumulative_time': (cumTime * 1000).toInt(),
            'type': cols[3].trim(),
            'status': 'done'
          });
        }
      }
      return {'mode': mode, 'times': times};
    } catch (e) {
      throw Exception("Error al leer el archivo. Asegúrate de que el formato sea correcto.");
    }
  }
}