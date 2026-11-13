import 'package:excel/excel.dart';
import '../../models.dart';
import 'excel_styles.dart';

class ExcelGenerator {
  Future<List<int>> generateExcelBytes({
    required List<Map<String, dynamic>> data,
    required StopwatchMode mode,
    OperationTemplate? activeTemplate,
    required String studyName,
    int globalRating = 100,
    Map<int, int> cycleRatings = const {},
    double pfdRate = 0.13,
  }) async {
    // 1. Deep-copy de los registros para evitar mutar el estado reactivo de la app
    final cleanData = data.map((m) => Map<String, dynamic>.from(m)).toList();

    // 2. Normalización de nombres en modo manual sin plantilla
    final cicloRegex = RegExp(r'^Ciclo\s+\d+$', caseSensitive: false);
    final isAllCiclos = cleanData.isNotEmpty &&
        cleanData.every((r) => cicloRegex.hasMatch(r['name']?.toString().trim() ?? ''));

    if (activeTemplate == null) {
      if (isAllCiclos) {
        String defaultOpName = (studyName.isNotEmpty &&
                studyName != 'Operación' &&
                studyName != 'Estudio_General' &&
                studyName != 'Estudio_de_Tiempos' &&
                studyName != 'Estudio de Tiempos')
            ? studyName
            : "Operación 1";
        for (var record in cleanData) {
          record['name'] = defaultOpName;
        }
      } else {
        // Si hay mezcla de nombres personalizados y registros vacíos / automáticos ("Ciclo X"),
        // agrupamos los registros sin nombre o con "Ciclo X" bajo "Operación 1".
        for (var record in cleanData) {
          String rawName = record['name']?.toString().trim() ?? '';
          if (rawName.isEmpty || cicloRegex.hasMatch(rawName)) {
            record['name'] = "Operación 1";
          }
        }
      }
    }

    // 3. Extraer los nombres únicos de elementos en orden de aparición
    List<String> uniqueSteps = [];
    for (var record in cleanData) {
      String name = record['name']?.toString().trim() ?? '';
      if (name.isNotEmpty && !uniqueSteps.contains(name)) {
        uniqueSteps.add(name);
      }
    }

    final isAllSameName = uniqueSteps.length <= 1;

    OperationTemplate templateToUse;

    if (activeTemplate != null && activeTemplate.steps.isNotEmpty) {
      templateToUse = activeTemplate;
    } else if (isAllCiclos) {
      String stepName = (studyName.isNotEmpty &&
              studyName != 'Operación' &&
              studyName != 'Estudio_General' &&
              studyName != 'Estudio_de_Tiempos' &&
              studyName != 'Estudio de Tiempos')
          ? studyName
          : "Operación 1";
      templateToUse = OperationTemplate()
        ..name = studyName
        ..steps = [stepName];
    } else if (isAllSameName) {
      String stepName = uniqueSteps.isNotEmpty
          ? uniqueSteps.first
          : (studyName.isNotEmpty &&
                  studyName != 'Operación' &&
                  studyName != 'Estudio_General' &&
                  studyName != 'Estudio_de_Tiempos' &&
                  studyName != 'Estudio de Tiempos'
              ? studyName
              : "Operación 1");
      templateToUse = OperationTemplate()
        ..name = studyName
        ..steps = [stepName];
    } else {
      // Múltiples operaciones/elementos sin plantilla (manual)
      // Cada nombre único se convierte en una fila independiente de paso
      templateToUse = OperationTemplate()
        ..name = studyName
        ..steps = uniqueSteps;
    }

    int numSteps = templateToUse.steps.length;
    if (numSteps == 0) {
      numSteps = 1;
      templateToUse = OperationTemplate()
        ..name = studyName
        ..steps = [studyName.isNotEmpty ? studyName : "Operación 1"];
    }

    // 4. Resolver el nombre general del estudio / Process Description
    // Si hay múltiples pasos y studyName coincide con uno de los pasos individuales
    // (o es genérico/vacío), NO usar el nombre del paso individual como nombre del proceso.
    String resolvedProcessDescription = studyName;
    if (activeTemplate == null && uniqueSteps.length > 1) {
      if (uniqueSteps.contains(studyName) || studyName.isEmpty || studyName == 'Estudio_General' || studyName == 'Estudio_de_Tiempos') {
        resolvedProcessDescription = "Estudio de Tiempos";
      }
    } else if (resolvedProcessDescription.isEmpty || resolvedProcessDescription == 'Estudio_General' || resolvedProcessDescription == 'Estudio_de_Tiempos') {
      resolvedProcessDescription = templateToUse.name.isNotEmpty && templateToUse.name != 'Estudio_General' && templateToUse.name != 'Estudio_de_Tiempos'
          ? templateToUse.name
          : "Estudio de Tiempos";
    }
    resolvedProcessDescription = resolvedProcessDescription.replaceAll('_', ' ');

    // 5. Asignación robusta de step_index y cycle_index para cada registro
    final Map<int, int> stepCycleCounts = {};
    int maxCycleFound = 0;
    int currentCycle = 0;
    int lastStepIndex = -1;

    for (int i = 0; i < cleanData.length; i++) {
      final record = cleanData[i];
      int sIndex = -1;

      if (activeTemplate != null && record['step_index'] != null && (record['step_index'] as int) < numSteps) {
        sIndex = record['step_index'] as int;
      } else {
        String recordName = record['name']?.toString().trim() ?? '';
        sIndex = templateToUse.steps.indexOf(recordName);
        if (sIndex < 0) sIndex = 0;
      }

      int cIndex;
      if (activeTemplate != null) {
        if (lastStepIndex >= 0 && sIndex <= lastStepIndex) {
          currentCycle++;
        }
        lastStepIndex = sIndex;
        cIndex = currentCycle;
      } else {
        // Modo manual sin plantilla:
        // Cada registro de un paso sIndex corresponde a su observación consecutiva (Ciclo 1, 2, ...)
        cIndex = stepCycleCounts[sIndex] ?? 0;
        stepCycleCounts[sIndex] = cIndex + 1;
      }

      if (cIndex > maxCycleFound) {
        maxCycleFound = cIndex;
      }

      record['step_index'] = sIndex;
      record['cycle_index'] = cIndex;
      record['applied_rating'] = record['applied_rating'] ?? (cycleRatings[cIndex] ?? globalRating);
    }

    return await _exportJabilTemplateToExcel(
      cleanData,
      templateToUse,
      resolvedProcessDescription,
      pfdRate,
      mode: mode,
      globalRating: globalRating,
      cycleRatings: cycleRatings,
      totalCycles: maxCycleFound + 1,
    );
  }

  Future<List<int>> _exportJabilTemplateToExcel(
    List<Map<String, dynamic>> data,
    OperationTemplate template,
    String studyName,
    double pfdRate, {
    StopwatchMode mode = StopwatchMode.continuo,
    int globalRating = 100,
    Map<int, int> cycleRatings = const {},
    int totalCycles = 1,
  }) async {
    int numSteps = template.steps.length;
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // Mapeo bidimensional seguro: paso -> ciclo -> registro
    final Map<int, Map<int, Map<String, dynamic>>> grid = {};
    for (var record in data) {
      int sIndex = record['step_index'] ?? 0;
      int cIndex = record['cycle_index'] ?? 0;
      if (sIndex >= 0 && sIndex < numSteps) {
        grid.putIfAbsent(sIndex, () => {})[cIndex] = record;
      }
    }

    int maxCycles = totalCycles > 10 ? totalCycles : 10;

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
    for (int r = 0; r <= 3; r++) {
      for (int c = 0; c < totalCols; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).cellStyle = ExcelStyles.grayHeaderStyle;
      }
    }

    // Logo Box A1:C4 (Merged col 0..2, row 0..3)
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue("J A B I L");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = ExcelStyles.jabilLogoStyle;

    // Title Box D1:P4 (Merged col 3..15, row 0..3)
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: 3));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue("Formato para toma de tiempos");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).cellStyle = ExcelStyles.greenTitleStyle;

    // Document Control Block Q1:W4 (col 16..totalCols-1)
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 0), CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: 0));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 0)).value = TextCellValue("Document Number");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 0)).cellStyle = ExcelStyles.docControlHeaderStyle;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 1), CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: 1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 1)).value = TextCellValue("06-IE80-IE-ALLPLANT-00026");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 1)).cellStyle = ExcelStyles.docControlValueStyle;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 2), CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: 2));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 2)).value = TextCellValue("Revision");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 2)).cellStyle = ExcelStyles.docControlHeaderStyle;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 3), CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: 3));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 3)).value = TextCellValue("D");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 3)).cellStyle = ExcelStyles.docControlValueStyle;

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
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(label1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = ExcelStyles.formLabelStyle;

      int endVal1Col = (label2 == null) ? 15 : 6;
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: endVal1Col, rowIndex: rowIndex));
      if (val1 != null) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(val1.toString());
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).cellStyle = ExcelStyles.formInputStyle;

      if (label2 != null) {
        sheet.merge(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = TextCellValue(label2);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).cellStyle = ExcelStyles.formLabelStyle;

        sheet.merge(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex));
        if (val2 != null) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).value = TextCellValue(val2.toString());
        }
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex)).cellStyle = ExcelStyles.formInputStyle;
      }

      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex)).value = TextCellValue(label3);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex)).cellStyle = ExcelStyles.formLabelStyle;

      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: totalCols - 1, rowIndex: rowIndex));
      if (val3 != null) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex)).value = TextCellValue(val3.toString());
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex)).cellStyle = ExcelStyles.formInputStyle;
    }

    buildFormRow(rowIndex: 4, label1: "Workcell/Customer:", val1: null, label2: "Workcenter:", val2: null, label3: "Study Date:", val3: dateFormatted);
    buildFormRow(rowIndex: 5, label1: "Product Family:", val1: null, label2: "Sub Workcenter:", val2: null, label3: "IE Name:", val3: null);
    buildFormRow(rowIndex: 6, label1: "Assembly / Rev:", val1: null, label2: "WI No./Rev:", val2: null, label3: "Approving Mgr:", val3: null);
    buildFormRow(
      rowIndex: 7,
      label1: "Process Description:",
      val1: studyName,
      label2: "Study Mode:",
      val2: mode == StopwatchMode.regresoACero ? "Regreso a Cero (RAC)" : "Continuo",
      label3: "Approved Date:",
      val3: null,
    );

    // ==========================================
    // 4. ENCABEZADOS PRINCIPALES DE LA TABLA (Filas 9 y 10 en Excel -> rowIndex 8 y 9)
    // ==========================================
    int headerRow0 = 8;
    int headerRow1 = 9;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow0)).value = TextCellValue("Seq.");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow0)).cellStyle = ExcelStyles.blueHeaderStyleTable;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: headerRow1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow0)).value = TextCellValue("Work Element Description");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow0)).cellStyle = ExcelStyles.blueHeaderStyleTable;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow0)).value = TextCellValue("Type");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow0)).cellStyle = ExcelStyles.blueHeaderStyleTable;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: 4 + maxCycles - 1, rowIndex: headerRow0));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: headerRow0)).value = TextCellValue("Observed Time (OT)");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: headerRow0)).cellStyle = ExcelStyles.blueHeaderStyleTable;

    for (int i = 0; i < maxCycles; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: headerRow1)).value = IntCellValue(i + 1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4 + i, rowIndex: headerRow1)).cellStyle = ExcelStyles.blueHeaderStyleTable;
    }

    void addHeader(int col, String text, [CellStyle? customStyle]) {
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow1));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow0)).value = TextCellValue(text);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow0)).cellStyle = customStyle ?? ExcelStyles.blueHeaderStyleTable;
    }

    addHeader(ncCol, "NC", ExcelStyles.ncHeaderStyleTable);
    addHeader(avgOtCol, "Avg. OT", ExcelStyles.grayHeaderStyleTable);
    addHeader(avgNtCol, "Avg. NT", ExcelStyles.grayHeaderStyleTable);
    addHeader(freqCol, "NC\nFreq.", ExcelStyles.blueHeaderStyleTable);
    addHeader(pfdCol, "App.\nPF&D", ExcelStyles.blueHeaderStyleTable);
    addHeader(stdTimeCol, "Std. Time", ExcelStyles.stdTimeHeaderStyleTable);

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: headerRow0), CellIndex.indexByColumnRow(columnIndex: remarksCol + 2, rowIndex: headerRow1));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: headerRow0)).value = TextCellValue("Remarks");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: headerRow0)).cellStyle = ExcelStyles.blueHeaderStyleTable;

    // ==========================================
    // 5. DATOS Y FÓRMULAS ESTRUCTURADAS (Fila 11+ de Excel -> rowIndex 10+)
    // ==========================================
    int currentRow = 10;
    int firstDataRowExcel = currentRow + 1; // 11 en Excel

    for (int i = 0; i < numSteps; i++) {
      int excelRow = currentRow + 1;
      bool stepHasOutliers = false;

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
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = ExcelStyles.lightBlueDataStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).value = TextCellValue(template.steps[i]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow)).cellStyle = ExcelStyles.lightBlueDataStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue("Hand");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = ExcelStyles.lightBlueDataStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: ncCol, rowIndex: currentRow)).value = TextCellValue("N/A");
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: ncCol, rowIndex: currentRow)).cellStyle = ExcelStyles.ncDataStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: currentRow)).cellStyle = ExcelStyles.lightBlueDataStyle;

      // Inyección de Tiempos y Calificación de Operario sin desfase de columnas
      for (int c = 0; c < maxCycles; c++) {
        final cellCol = 4 + c;
        final record = grid[i]?[c];

        if (record != null && record['status'] != 'pending') {
          double timeSec = ((record['time'] as num?)?.toDouble() ?? 0.0) / 1000.0;
          final isOutlier = record['type'] == 'outlier';

          if (isOutlier) {
            stepHasOutliers = true;
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: cellCol, rowIndex: currentRow)).value =
                TextCellValue("${timeSec.toStringAsFixed(2)}*");
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: cellCol, rowIndex: currentRow)).cellStyle =
                ExcelStyles.outlierDataStyle;
          } else {
            if (timeSec > 0) {
              sheet.cell(CellIndex.indexByColumnRow(columnIndex: cellCol, rowIndex: currentRow)).value =
                  DoubleCellValue(timeSec);
            }
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: cellCol, rowIndex: currentRow)).cellStyle =
                ExcelStyles.twoDecimalsWhiteStyle;
          }

          int currentRating = (record['applied_rating'] as num?)?.toInt() ?? (cycleRatings[c] ?? globalRating);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: cellCol, rowIndex: currentRow + 1)).value =
              DoubleCellValue(currentRating / 100.0);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: cellCol, rowIndex: currentRow + 1)).cellStyle =
              ExcelStyles.percentStyle;
        } else {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: cellCol, rowIndex: currentRow)).cellStyle =
              ExcelStyles.twoDecimalsWhiteStyle;

          // Si el ciclo fue ejecutado en el estudio, mostrar el rating correspondiente
          if (c < totalCycles) {
            int currentRating = cycleRatings[c] ?? globalRating;
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: cellCol, rowIndex: currentRow + 1)).value =
                DoubleCellValue(currentRating / 100.0);
          }
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: cellCol, rowIndex: currentRow + 1)).cellStyle =
              ExcelStyles.percentStyle;
        }
      }

      if (stepHasOutliers) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: currentRow)).value =
            TextCellValue("* Valores atípicos excluidos");
      }

      // FÓRMULAS ESTRUCTURALES DEL ESTUDIO
      String startCycleCol = _getColumnLetter(4);
      String endCycleCol = _getColumnLetter(4 + maxCycles - 1);

      String avgOtFormula = 'IFERROR(AVERAGE($startCycleCol$excelRow:$endCycleCol$excelRow),"")';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: currentRow)).value = FormulaCellValue(avgOtFormula);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: currentRow)).cellStyle = ExcelStyles.grayDataTwoDecimalsStyle;

      String avgNtFormula = 'IFERROR((SUMPRODUCT($startCycleCol$excelRow:$endCycleCol$excelRow,$startCycleCol${excelRow+1}:$endCycleCol${excelRow+1})/COUNTIF($startCycleCol$excelRow:$endCycleCol$excelRow,">0")),"")';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgNtCol, rowIndex: currentRow)).value = FormulaCellValue(avgNtFormula);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgNtCol, rowIndex: currentRow)).cellStyle = ExcelStyles.grayDataTwoDecimalsStyle;

      // Frecuencia
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: freqCol, rowIndex: currentRow)).value = const IntCellValue(1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: freqCol, rowIndex: currentRow)).cellStyle = ExcelStyles.lightBlueDataStyle;

      // PF&D
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: currentRow)).value = DoubleCellValue(pfdRate);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: currentRow)).cellStyle = ExcelStyles.lightBluePercentStyle;

      String avgNtColStr = _getColumnLetter(avgNtCol);
      String freqColStr = _getColumnLetter(freqCol);
      String pfdColStr = _getColumnLetter(pfdCol);
      String stdTimeFormula = 'IFERROR(($avgNtColStr$excelRow*$freqColStr$excelRow*(1+$pfdColStr$excelRow)),"")';

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: currentRow)).value = FormulaCellValue(stdTimeFormula);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: currentRow)).cellStyle = ExcelStyles.greenDataTwoDecimalsStyle;

      currentRow += 2;
    }

    // ==========================================
    // 6. PROCESS SUMMARY (Consolidado Inteligente)
    // ==========================================
    int summaryStartRow = currentRow;
    int lastDataRowExcel = firstDataRowExcel + (numSteps * 2) - 1;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow), CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow + 2));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = TextCellValue("Process Summary");
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).cellStyle = ExcelStyles.processSummaryGrayStyle;

    String stdColStr = _getColumnLetter(stdTimeCol);
    List<String> types = ["Hand", "Mach", "IMT"];

    for (int t = 0; t < types.length; t++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).value = TextCellValue(types[t]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow)).cellStyle = ExcelStyles.whiteDataStyle;

      for (int colIndex = 4; colIndex <= avgNtCol; colIndex++) {
        if (colIndex == ncCol) continue;

        String col = _getColumnLetter(colIndex);
        String formula;
        if (colIndex < ncCol) {
          // Columnas de ciclo (Ciclo 1..maxCycles):
          // En cada ciclo se calcula el Tiempo Normal considerando la calificación (rating / 100) asignada:
          // Σ (Tiempo Observado * Calificación) para los elementos que correspondan al tipo (Hand, Mach, IMT).
          List<String> terms = [];
          for (int i = 0; i < numSteps; i++) {
            int timeRow = firstDataRowExcel + (i * 2);
            int ratingRow = timeRow + 1;
            terms.add('IF(\$D\$$timeRow="${types[t]}",IFERROR($col$timeRow*$col$ratingRow,0),0)');
          }
          formula = 'SUM(${terms.join(",")})';
        } else {
          // Columnas consolidadas: Avg. OT y Avg. NT
          // Se suma el valor consolidado de cada elemento del tipo correspondiente
          formula = 'SUMIF(\$D\$$firstDataRowExcel:\$D\$$lastDataRowExcel,"${types[t]}",\$$col\$$firstDataRowExcel:\$$col\$$lastDataRowExcel)';
        }

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: currentRow)).value = FormulaCellValue(formula);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: currentRow)).cellStyle = ExcelStyles.twoDecimalsWhiteStyle;
      }

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: currentRow)).value = TextCellValue(types[t]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: currentRow)).cellStyle = ExcelStyles.greenSummaryHeaderStyle;

      // Sumatoria de Std. Time
      String formulaStdTotal = 'SUMIF(\$D\$$firstDataRowExcel:\$D\$$lastDataRowExcel,"${types[t]}",\$$stdColStr\$$firstDataRowExcel:\$$stdColStr\$$lastDataRowExcel)';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: currentRow)).value = FormulaCellValue(formulaStdTotal);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: currentRow)).cellStyle = ExcelStyles.greenDataTwoDecimalsStyle;

      currentRow++;
    }

    // ==========================================
    // 7. CÁLCULOS FINALES ESTRUCTURADOS (VAT, SMH, UPH)
    // ==========================================
    int statsRow1 = summaryStartRow + 3;
    int statsRow2 = summaryStartRow + 4;
    int statsRow3 = summaryStartRow + 5;
    int statsRow4 = summaryStartRow + 6;

    void addStatRow(int rowIndex, String label1, dynamic value1, String label2, String formula2) {
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: pfdCol, rowIndex: rowIndex));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: rowIndex)).value = TextCellValue(label1);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: avgOtCol, rowIndex: rowIndex)).cellStyle = ExcelStyles.greenKpiLabelStyle;

      if (value1 is int) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: rowIndex)).value = IntCellValue(value1);
      } else if (value1 is String && value1.startsWith('=')) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: rowIndex)).value = FormulaCellValue(value1.substring(1));
      } else {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: rowIndex)).value = TextCellValue(value1.toString());
      }
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: stdTimeCol, rowIndex: rowIndex)).cellStyle = ExcelStyles.greenKpiValueStyle;

      sheet.merge(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: rowIndex), CellIndex.indexByColumnRow(columnIndex: remarksCol + 1, rowIndex: rowIndex));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: rowIndex)).value = TextCellValue(label2);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol, rowIndex: rowIndex)).cellStyle = ExcelStyles.greenKpiLabelStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol + 2, rowIndex: rowIndex)).value = FormulaCellValue(formula2);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: remarksCol + 2, rowIndex: rowIndex)).cellStyle = ExcelStyles.greenKpiValueStyle;
    }

    int handStdRow = summaryStartRow + 1;
    int machStdRow = summaryStartRow + 2;
    int imtStdRow = summaryStartRow + 3;

    int row2Excel = statsRow2 + 1;
    int row3Excel = statsRow3 + 1;
    int row4Excel = statsRow4 + 1;
    String rightValueColStr = _getColumnLetter(remarksCol + 2);

    addStatRow(statsRow1, "# of Mach/Stations", '=$stdColStr$row2Excel*$stdColStr$row3Excel',
               "VAT", 'IFERROR(SUM($stdColStr$handStdRow,$stdColStr$machStdRow),"")');
    addStatRow(statsRow2, "Headcount HC", 1,
               "SMH", 'IFERROR(((SUM($stdColStr$handStdRow,$stdColStr$imtStdRow)/3600)/$stdColStr$row4Excel),"")');
    addStatRow(statsRow3, "# of Mach/Stations per HC", 1,
               "Standard Time for 1 Unit", 'IFERROR(SUM($stdColStr$handStdRow,$stdColStr$machStdRow)/$stdColStr$row4Excel,"")');
    addStatRow(statsRow4, "Units Produced per Mach", 1,
               "UPH", 'IFERROR(3600/$rightValueColStr$row3Excel,"")');

    // ==========================================
    // 8. AUTO-AJUSTE VISUAL
    // ==========================================
    sheet.setColumnWidth(0, 8.0);
    sheet.setColumnWidth(1, 40.0);
    sheet.setColumnWidth(2, 5.0);
    sheet.setColumnWidth(3, 10.0);
    for (int i = 0; i < maxCycles; i++) {
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
}
