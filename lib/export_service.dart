import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:csv/csv.dart';
import 'models.dart';

class ExportService {
  Future<String?> exportDataToCsv({
    required List<Map<String, dynamic>> data,
    required StopwatchMode mode,
    required String Function(double) timeFormatter,
  }) async {
    if (data.isEmpty) return null;

    try {
      List<List<dynamic>> csvData;
      List<String> headers;
      String modeName = mode == StopwatchMode.continuo ? "Continuo" : "RegresoACero";
      
      // Hemos integrado la columna "Tipo" para mantener la trazabilidad de los atípicos
      if (mode == StopwatchMode.continuo) {
        headers = ['#', 'Nombre', 'Tipo', 'TC (ms)', 'TC Formateado', 'TO (ms)', 'TO Formateado'];
        csvData = [headers, ...data.asMap().entries.map((entry) {
            int index = entry.key; 
            Map<String, dynamic> t = entry.value;
            String tipo = t['type'] == 'outlier' ? 'Atípico' : 'Normal';
            return [index + 1, t['name'], tipo, t['cumulative_time'] ?? 0, timeFormatter((t['cumulative_time'] ?? 0).toDouble()), t['time'], timeFormatter(t['time'].toDouble())];
          })];
      } else {
        headers = ['#', 'Nombre', 'Tipo', 'Tiempo (ms)', 'Tiempo Formateado'];
        csvData = [headers, ...data.asMap().entries.map((entry) {
            int index = entry.key; 
            Map<String, dynamic> t = entry.value;
            String tipo = t['type'] == 'outlier' ? 'Atípico' : 'Normal';
            return [index + 1, t['name'], tipo, t['time'], timeFormatter(t['time'].toDouble())];
          })];
      }
      
      final csv = const ListToCsvConverter().convert(csvData);
      final bytes = Uint8List.fromList(csv.codeUnits);
      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'Tiempos_IE_${modeName}_$timestamp';
      
      final result = await FileSaver.instance.saveAs(name: fileName, bytes: bytes, ext: 'csv', mimeType: MimeType.csv);
      return result != null ? '$fileName.csv' : null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}