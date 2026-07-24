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
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    final name = "${baseName}_$y$m$d" "_$hh$mm";

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
    int totalCols = remarksCol + 3;

    // ==========================================
    // 2. ENCABEZADO OFICIAL JABIL (Filas 1 a 4 en Excel -> rowIndex 0..3)
    // ==========================================
    CellStyle grayHeaderStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString("#C0C0C0"),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    CellStyle greenTitleStyle = CellStyle(
      fontFamily: "Arial",
      fontSize: 22,
      bold: true,
      fontColorHex: ExcelColor.fromHexString("#00B050"),
      backgroundColorHex: ExcelColor.fromHexString("#C0C0C0"),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle docControlHeaderStyle = CellStyle(
      fontFamily: "Arial",
      fontSize: 12,
      bold: false,
      backgroundColorHex: ExcelColor.fromHexString("#C0C0C0"),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle docControlValueStyle = CellStyle(
      fontFamily: "Arial",
      fontSize: 18,
      bold: true,
      fontColorHex: ExcelColor.fromHexString("#00B050"),
      backgroundColorHex: ExcelColor.fromHexString("#C0C0C0"),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle formLabelStyle = CellStyle(
      fontFamily: "Calibri",
      fontSize: 11,
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString("#F2F2F2"),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle formInputStyle = CellStyle(
      fontFamily: "Calibri",
      fontSize: 11,
      bold: false,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    CellStyle ncHeaderStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString("#FCE4D6"),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    CellStyle stdTimeHeaderStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString("#E2EFDA"),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    // Fondo gris del bloque A1:W4
    for (int r = 0; r <= 3; r++) {
      for (int c = 0; c < totalCols; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).cellStyle = grayHeaderStyle;
      }
    }

    // Logo Box A1:C4 (Merged col 0..2, row 0..3)
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue("J A B I L");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString("#C0C0C0"),
      bold: true,
      fontSize: 22,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Title Box D1:P4 (Merged col 3..15, row 0..3)
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: 3));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue("Formato para toma de tiempos");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).cellStyle = greenTitleStyle;

    // Document Control Block Q1:W4 (col 16..totalCols-1)
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: 0));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 0)).value = TextCellValue("Document Number");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 0)).cellStyle = docControlHeaderStyle;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 1), CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 1)).value = TextCellValue("06-IE80-IE-ALLPLANT-00026");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 1)).cellStyle = docControlValueStyle;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 2), CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: 2));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 2)).value = TextCellValue("Revision");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 2)).cellStyle = docControlHeaderStyle;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 3), CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: 3));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 3)).value = TextCellValue("D");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 3)).cellStyle = docControlValueStyle;

    // ==========================================
    // 3. FORMULARIO DE METADATOS (Filas 5 a 8 en Excel -> rowIndex 4..7)
    // ==========================================
    final now = DateTime.now();
    final dateFormatted = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    void buildFormRow({
      required int rowIndex,
      required String label1, dynamic val1,
      String? label2, dynamic val2,
      required String label3, dynamic val3,
    }) {
      // 1. Campo Izquierdo: Etiqueta A:B (col 0..1), Input C:G (col 2..6) ó C:P (col 2..15) si no hay campo medio
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(label1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = formLabelStyle;
      
      int endVal1Col = (label2 == null) ? 15 : 6;
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: endVal1Col, rowIndex: rowIndex));
      if (val1 != null) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(val1.toString());
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).cellStyle = formInputStyle;

      // 2. Campo Medio: Etiqueta H:J (col 7..9), Input K:P (col 10..15)
      if (label2 != null) {
        sheet.merge(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = TextCellValue(label2);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).cellStyle = formLabelStyle;

        sheet.merge(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex));
        if (val2 != null) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).value = TextCellValue(val2.toString());
        }
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).cellStyle = formInputStyle;
      }

      // 3. Campo Derecho: Etiqueta Q:R (col 16..17), Input S:W (col 18..totalCols-1)
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex)).value = TextCellValue(label3);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex)).cellStyle = formLabelStyle;

      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: rowIndex));
      if (val3 != null) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex)).value = TextCellValue(val3.toString());
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex)).cellStyle = formInputStyle;
    }

    buildFormRow(rowIndex: 4, label1: "Workcell/Customer:", val1: null, label2: "Workcenter:", val2: null, label3: "Study Date:", val3: dateFormatted);
    buildFormRow(rowIndex: 5, label1: "Product Family:", val1: null, label2: "Sub Workcenter:", val2: null, label3: "IE Name:", val3: null);
    buildFormRow(rowIndex: 6, label1: "Assembly / Rev:", val1: null, label2: "WI No./Rev:", val2: null, label3: "Approving Mgr:", val3: null);
    buildFormRow(rowIndex: 7, label1: "Process Description:", val1: studyName, label2: null, val2: null, label3: "Approved Date:", val3: null);

    // ==========================================
    // 4. ENCABEZADOS PRINCIPALES DE LA TABLA (Filas 9 y 10 en Excel -> rowIndex 8 y 9)
    // ==========================================
    int headerRow0 = 8;
    int headerRow1 = 9;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow0)).value = TextCellValue("Seq.");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow0)).cellStyle = headerStyle;
    
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: headerRow1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow0)).value = TextCellValue("Work Element Description");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow0)).cellStyle = headerStyle;
    
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow0)).value = TextCellValue("Type");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow0)).cellStyle = headerStyle;
    
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles - 1, rowIndex: headerRow0));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: headerRow0)).value = TextCellValue("Observed Time (OT)");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: headerRow0)).cellStyle = headerStyle;

    for (int i = 0; i < maxCycles; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: headerRow1)).value = IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: headerRow1)).cellStyle = headerStyle;
    }

    void addHeader(int col, String text, [CellStyle? customStyle]) {
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow1));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow0)).value = TextCellValue(text);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow0)).cellStyle = customStyle ?? headerStyle;
    }

    addHeader(ncCol, "NC", ncHeaderStyle);
    addHeader(avgOtCol, "Avg. OT");
    addHeader(avgNtCol, "Avg. NT");
    addHeader(freqCol, "NC\nFreq.");
    addHeader(pfdCol, "App.\nPF&D");
    addHeader(stdTimeCol, "Std. Time", stdTimeHeaderStyle);
    
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: remarksCol + 2, rowIndex: headerRow1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: headerRow0)).value = TextCellValue("Remarks");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: headerRow0)).cellStyle = headerStyle;

    // ==========================================
    // 5. DATOS Y FÓRMULAS ESTRUCTURADAS (Fila 11+ de Excel -> rowIndex 10+)
    // ==========================================
    int currentRow = 10; 
    int firstDataRowExcel = currentRow + 1; // 11 en Excel
    
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
        
        String seqStr = seqCell.value?.toString().toLowerCase() ?? '';
        String descStr = nameCell.value?.toString().toLowerCase() ?? '';

        if (seqStr.contains("process") || descStr.contains("process") || 
            seqStr.contains("summary") || descStr.contains("summary")) {
          break;
        }
        if (seqCell.value == null && nameCell.value == null) {
          break;
        }

        String stepName = 'Paso ${numSteps + 1}';
        var nv = nameCell.value;
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
}