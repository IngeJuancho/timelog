import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import '../../models.dart';

class ExcelImporter {
  Future<Map<String, dynamic>?> importDataFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      String studyName = 'Estudio Importado';
      if (result.files.first.name.isNotEmpty) {
        String fname = result.files.first.name;
        if (fname.toLowerCase().endsWith('.xlsx')) {
          fname = fname.substring(0, fname.length - 5);
        }
        fname = fname.replaceAll('_', ' ').trim();
        if (fname.isNotEmpty) {
          studyName = fname;
        }
      }

      Uint8List? bytes = result.files.first.bytes;
      if (bytes == null && result.files.first.path != null) {
        bytes = File(result.files.first.path!).readAsBytesSync();
      }

      if (bytes == null) {
        return null;
      }

      var excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) return null;

      var sheetName = excel.tables.keys.first;
      var sheet = excel.tables[sheetName];

      if (sheet == null) {
        return null;
      }

      // Escanear dinámicamente la fila donde comienza la tabla principal (Seq. / Work Element)
      int tableHeaderRow0Index = 0;
      for (int r = 0; r < 20; r++) {
        var val0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value?.toString().trim().toLowerCase() ?? '';
        var val1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value?.toString().trim().toLowerCase() ?? '';
        if (val0.contains("seq") || val1.contains("work element")) {
          tableHeaderRow0Index = r;
          break;
        }
      }
      int tableHeaderRow1Index = tableHeaderRow0Index + 1;
      int dataStartRowIndex = tableHeaderRow0Index + 2;

      // Intentar extraer el nombre del estudio desde los metadatos 'Process Description:'
      for (int r = 0; r < tableHeaderRow0Index; r++) {
        var labelVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value?.toString().trim().toLowerCase() ?? '';
        if (labelVal.contains("process description")) {
          var procVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value;
          if (procVal != null && procVal.toString().trim().isNotEmpty) {
            String pName = procVal.toString().trim();
            if (pName.isNotEmpty) {
              studyName = pName;
            }
          }
          break;
        }
      }

      // Detección de la cantidad exacta de ciclos de tiempo observados (OT)
      int maxCycles = 0;
      while (true) {
        int col = 4 + maxCycles;
        var headerRow0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: tableHeaderRow0Index)).value?.toString().trim().toLowerCase() ?? '';
        var headerRow1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: tableHeaderRow1Index)).value?.toString().trim().toLowerCase() ?? '';

        // Detenerse inmediatamente al llegar a las columnas de resumen de la plantilla Jabil
        if (headerRow0.startsWith("nc") || headerRow0.contains("avg") || headerRow0.contains("freq") ||
            headerRow0.contains("pf&d") || headerRow0.contains("std") || headerRow0.contains("remark") ||
            headerRow1.startsWith("nc") || headerRow1.contains("avg") || headerRow1.contains("freq") ||
            headerRow1.contains("pf&d") || headerRow1.contains("std") || headerRow1.contains("remark")) {
          break;
        }

        // Comprobar si el encabezado de fila 1 es un número de ciclo (1, 2, 3...)
        var cycleNumVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: tableHeaderRow1Index)).value;
        int? cycleNum;
        if (cycleNumVal is IntCellValue) {
          cycleNum = cycleNumVal.value;
        } else if (cycleNumVal != null) {
          cycleNum = int.tryParse(cycleNumVal.toString().trim());
        }

        if (cycleNum != null && cycleNum == maxCycles + 1) {
          maxCycles++;
          continue;
        }

        // Si no hay encabezado numérico, verificar si la celda de tiempo tiene un valor válido
        var dataCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: dataStartRowIndex)).value;
        if (dataCell == null || dataCell.toString().trim().isEmpty) {
          break;
        }

        maxCycles++;
        if (maxCycles > 100) break;
      }

      // Detección robusta de numSteps
      int numSteps = 0;
      List<String> stepNames = [];

      while (true) {
        int row = dataStartRowIndex + (numSteps * 2);
        var seqCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
        var nameCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
        var nameCellCol2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));

        String seqStr = seqCell.value?.toString().toLowerCase() ?? '';
        String descStr = (nameCell.value ?? nameCellCol2.value)?.toString().toLowerCase() ?? '';

        if (seqStr.contains("process") || descStr.contains("process") ||
            seqStr.contains("summary") || descStr.contains("summary")) {
          break;
        }
        if (seqCell.value == null && nameCell.value == null && nameCellCol2.value == null) {
          break;
        }

        String stepName = 'Paso ${numSteps + 1}';
        var nv = nameCell.value ?? nameCellCol2.value;
        if (nv is TextCellValue) {
          stepName = nv.value.text?.trim() ?? stepName;
        } else if (nv != null) {
          stepName = nv.toString().trim();
        }
        stepNames.add(stepName);

        numSteps++;
        if (numSteps > 200) break;
      }

      List<Map<String, dynamic>> times = [];
      Map<int, int> cycleRatings = {};
      double cumulativeMs = 0;

      for (int c = 0; c < maxCycles; c++) {
        // Extraer calificación asignada al ciclo si existe en la fila inferior
        int? detectedRating;

        for (int r = 0; r < numSteps; r++) {
          int row = dataStartRowIndex + (r * 2);
          int ratingRow = row + 1;

          var ratingCellVal = _parseCellValue(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: ratingRow)).value);
          if (ratingCellVal != null && ratingCellVal > 0) {
            int pctVal = (ratingCellVal <= 2.5) ? (ratingCellVal * 100).round() : ratingCellVal.round();
            if (pctVal >= 10 && pctVal <= 300) {
              detectedRating = pctVal;
              break;
            }
          }
        }

        if (detectedRating != null) {
          cycleRatings[c] = detectedRating;
        }

        for (int r = 0; r < numSteps; r++) {
          int row = dataStartRowIndex + (r * 2);
          var cellVal = _parseCellValue(sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + c, rowIndex: row)).value);

          if (cellVal != null && cellVal > 0) {
            double seconds = cellVal;
            int timeMs = (seconds * 1000).round();
            cumulativeMs += timeMs;

            times.add({
              'name': stepNames[r],
              'time': timeMs,
              'cumulative_time': cumulativeMs.round(),
              'type': 'normal',
              'status': 'done',
              'step_index': r,
              'applied_rating': detectedRating ?? 100,
            });
          }
        }
      }

      if (times.isEmpty) {
        return null;
      }

      return {
        'mode': StopwatchMode.continuo,
        'times': times,
        'stepNames': stepNames,
        'cycleRatings': cycleRatings,
        'studyName': studyName,
      };
    } catch (e) {
      throw Exception("Error al leer Excel. Asegúrate de que tenga el formato Jabil de la App.");
    }
  }

  double? _parseCellValue(CellValue? cv) {
    if (cv == null) return null;
    if (cv is DoubleCellValue) return cv.value;
    if (cv is IntCellValue) return cv.value.toDouble();
    if (cv is TextCellValue) {
      String raw = cv.value.text?.replaceAll(',', '.').trim() ?? '';
      return double.tryParse(raw);
    }
    if (cv is FormulaCellValue) {
      String raw = cv.formula.replaceAll(',', '.').trim();
      return double.tryParse(raw);
    }
    String str = cv.toString().replaceAll(',', '.').trim();
    return double.tryParse(str);
  }
}
