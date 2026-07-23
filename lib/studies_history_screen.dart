import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'time_log_controller.dart';
import 'models.dart';
import 'storage_service.dart';
import 'export_service.dart';
import 'theme.dart';

class StudiesHistoryScreen extends ConsumerStatefulWidget {
  const StudiesHistoryScreen({super.key});
  @override
  ConsumerState<StudiesHistoryScreen> createState() => _StudiesHistoryScreenState();
}

class _StudiesHistoryScreenState extends ConsumerState<StudiesHistoryScreen> {
  final StorageService _storage = StorageService();
  final ExportService _export = ExportService();
  List<StudyModel> _studies = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<int> _selectedStudyIds = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final studies = await _storage.getStudiesHistory();
    setState(() {
      studies.sort((a, b) => b.date.compareTo(a.date));
      _studies = studies;
      _isLoading = false;
    });
  }

  Future<void> _deleteStudy(int id) async { 
    if (ref.read(timeLogProvider).activeStudyId == id) {
      ref.read(timeLogProvider.notifier).clearActiveStudyId();
    }
    
    await _storage.deleteStudyFromHistory(id);
    setState(() {
      _selectedStudyIds.remove(id);
    });
    _loadHistory();
  }

  void _confirmDelete(StudyModel study) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text('Eliminar Estudio', style: TextStyle(color: Colors.white)),
        content: Text('¿Seguro que deseas eliminar "${study.name}" de forma permanente?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStudy(study.id);
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _editStudyName(StudyModel study) {
    final nameController = TextEditingController(text: study.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text('Renombrar Estudio', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != study.name) {
                await _storage.updateStudyName(study.id, newName); 
                
                // NUEVO: Sincronización en tiempo real si el estudio está abierto en el cronómetro
                if (ref.read(timeLogProvider).activeStudyId == study.id) {
                  ref.read(timeLogProvider.notifier).syncActiveStudyName(newName);
                }
                
                _loadHistory(); 
              }
            },
            child: const Text('GUARDAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _loadStudyToActive(StudyModel study) {
    ref.read(timeLogProvider.notifier).loadStudyFromHistory(study);
    Navigator.pop(context);
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedStudyIds.clear();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedStudyIds.contains(id)) {
        _selectedStudyIds.remove(id);
      } else {
        _selectedStudyIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedStudyIds.length == _studies.length) {
        _selectedStudyIds.clear();
      } else {
        _selectedStudyIds.addAll(_studies.map((s) => s.id));
      }
    });
  }

  Future<void> _exportSelectedStudies() async {
    if (_selectedStudyIds.isEmpty) return;
    
    setState(() => _isLoading = true);

    try {
      final selectedStudies = _studies.where((s) => _selectedStudyIds.contains(s.id)).toList();
      
      final tempDir = await getTemporaryDirectory();
      List<XFile> filesToShare = [];

      for (var study in selectedStudies) {
        final data = study.times.map((e) => {
          'name': e.name,
          'time': e.time,
          'cumulative_time': e.cumulativeTime,
          'type': e.type,
          'status': 'done',
          'step_index': e.stepIndex,
        }).toList();

        Map<int, int> cycleRatings = study.cycleRatingsMap;

        OperationTemplate? template;
        if (study.isTemplate) {
          final templates = await _storage.getTemplates();
          template = templates.where((t) => t.steps.length == study.templateSteps.length).firstOrNull;
        }

        final fileBytes = await _export.generateExcelBytes(
          data: data,
          mode: study.mode,
          activeTemplate: template,
          studyName: study.name,
          globalRating: 100,
          cycleRatings: cycleRatings,
        );

        final date = study.date;
        final baseName = study.name.replaceAll(' ', '_');
        final y = date.year;
        final m = date.month.toString().padLeft(2, '0');
        final d = date.day.toString().padLeft(2, '0');
        final hh = date.hour.toString().padLeft(2, '0');
        final mm = date.minute.toString().padLeft(2, '0');
        final fileName = "${baseName}_$y$m$d" "_$hh$mm.xlsx";
        
        final filePath = '${tempDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        
        filesToShare.add(XFile(filePath));
      }

      setState(() => _isLoading = false);

      if (filesToShare.isNotEmpty) {
        // ignore: deprecated_member_use
        final result = await Share.shareXFiles(filesToShare, text: 'Respaldo de Estudios de Tiempos');
        if (result.status == ShareResultStatus.success) {
          _toggleSelectionMode();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Archivos compartidos con éxito'), backgroundColor: Colors.teal),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStudyId = ref.watch(timeLogProvider).activeStudyId;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedStudyIds.length} Seleccionados')
            : const Text('Historial de Estudios'),
        centerTitle: !_isSelectionMode,
        backgroundColor: _isSelectionMode ? const Color(0xFF252525) : Colors.transparent,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(
                _selectedStudyIds.length == _studies.length ? Icons.deselect : Icons.select_all,
                color: Colors.white70,
              ),
              tooltip: _selectedStudyIds.length == _studies.length ? 'Deseleccionar todos' : 'Seleccionar todos',
              onPressed: _toggleSelectAll,
            ),
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blueAccent),
              onPressed: _selectedStudyIds.isNotEmpty ? _exportSelectedStudies : null,
              tooltip: 'Subir seleccionados',
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.cloud_outlined),
              onPressed: _studies.isNotEmpty ? _toggleSelectionMode : null,
              tooltip: 'Subir a la nube',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : _studies.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off_outlined, size: 48, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('No hay estudios guardados', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _studies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final study = _studies[index];
                    final dateStr = '${study.date.day}/${study.date.month}/${study.date.year}';
                    final modeStr = study.mode == StopwatchMode.continuo ? 'Por Elemento' : 'Por Ciclo';
                    
                    final isActive = study.id == activeStudyId;
                    
                    final isSelected = _selectedStudyIds.contains(study.id);
                    final isSelectionModeActive = _isSelectionMode;

                    return GestureDetector(
                      onLongPress: () {
                        if (!isSelectionModeActive) {
                          _toggleSelectionMode();
                          _toggleSelection(study.id);
                        }
                      },
                      onTap: () {
                        if (isSelectionModeActive) {
                          _toggleSelection(study.id);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.blueAccent.withValues(alpha: 0.15) 
                              : (isActive ? Colors.tealAccent.withValues(alpha: 0.05) : const Color(0xFF252525)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.blueAccent 
                                : (isActive ? Colors.tealAccent : Colors.white10),
                            width: isSelected ? 2.0 : (isActive ? 1.5 : 1.0),
                          ),
                          boxShadow: isActive && !isSelected
                              ? [BoxShadow(color: Colors.tealAccent.withValues(alpha: 0.15), blurRadius: 10, spreadRadius: 1)]
                              : [],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: isSelectionModeActive 
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(study.id),
                                activeColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              )
                            : null,
                          title: Text(study.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                const SizedBox(width: 16),
                                Icon(study.mode == StopwatchMode.continuo ? Icons.timeline : Icons.replay, size: 14, color: Colors.tealAccent),
                                const SizedBox(width: 4),
                                Text(modeStr, style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
                                
                                if (study.isTemplate) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.yellowAccent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.yellowAccent.withValues(alpha: 0.5)),
                                    ),
                                    child: const Text('PLANTILLA', style: TextStyle(color: Colors.yellowAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: isSelectionModeActive ? null : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                onPressed: () => _editStudyName(study),
                                tooltip: 'Renombrar',
                              ),
                              ElevatedButton.icon(
                                onPressed: isActive ? null : () => _loadStudyToActive(study),
                                icon: Icon(isActive ? Icons.check_circle_rounded : Icons.open_in_new_rounded, size: 14),
                                label: Text(isActive ? 'ABIERTO' : 'ABRIR', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isActive 
                                      ? Colors.tealAccent.withValues(alpha: 0.15) 
                                      : AppTheme.getTealAccent(context).withValues(alpha: 0.2),
                                  foregroundColor: isActive 
                                      ? Colors.tealAccent 
                                      : AppTheme.getTealAccent(context),
                                  disabledBackgroundColor: Colors.tealAccent.withValues(alpha: 0.15),
                                  disabledForegroundColor: Colors.tealAccent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(study),
                                tooltip: 'Eliminar',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
