import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
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

  // Lógica inversa para leer e importar el CSV
  Future<Map<String, dynamic>?> importDataFromCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, 
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      // Obtener los bytes del archivo (manejo seguro para múltiples plataformas)
      Uint8List? fileBytes = result.files.first.bytes;
      if (fileBytes == null && result.files.first.path != null) {
        fileBytes = File(result.files.first.path!).readAsBytesSync();
      }

      if (fileBytes == null) throw Exception("No se pudo leer el contenido del archivo.");

      final String csvString = utf8.decode(fileBytes);
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

      if (csvTable.isEmpty) throw Exception("El archivo CSV está vacío o corrupto.");

      final headers = csvTable.first.map((e) => e.toString().toLowerCase()).toList();
      
      // Detección automática del modo por el encabezado
      bool isContinuo = headers.contains('tc (ms)');
      StopwatchMode mode = isContinuo ? StopwatchMode.continuo : StopwatchMode.regresoACero;

      List<Map<String, dynamic>> importedTimes = [];

      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.isEmpty || row.length < 4) continue; 
        
        String name = row[1].toString();
        String type = row[2].toString().toLowerCase() == 'atípico' ? 'outlier' : 'normal';
        
        if (isContinuo) {
          int tc = int.tryParse(row[3].toString()) ?? 0;
          int to = int.tryParse(row[5].toString()) ?? 0;
          importedTimes.add({'name': name, 'type': type, 'cumulative_time': tc, 'time': to});
        } else {
          int to = int.tryParse(row[3].toString()) ?? 0;
          importedTimes.add({'name': name, 'type': type, 'time': to});
        }
      }

      return {'mode': mode, 'times': importedTimes};
    } catch (e) {
      throw Exception("Error al leer el CSV: ${e.toString()}");
    }
  }
}