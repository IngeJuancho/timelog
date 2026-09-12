import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'models.dart';
import 'services/export/excel_generator.dart';
import 'services/export/excel_importer.dart';

class ExportService {
  final ExcelGenerator _generator = ExcelGenerator();
  final ExcelImporter _importer = ExcelImporter();

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
      mimeType: MimeType.microsoftExcel,
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
  }) {
    return _generator.generateExcelBytes(
      data: data,
      mode: mode,
      activeTemplate: activeTemplate,
      studyName: studyName,
      globalRating: globalRating,
      cycleRatings: cycleRatings,
    );
  }

  Future<Map<String, dynamic>?> importDataFromExcel() {
    return _importer.importDataFromExcel();
  }
}