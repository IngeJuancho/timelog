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
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _selectedStudyIds.remove(id);
    });
    _loadHistory();
  }

  void _confirmDelete(StudyModel study) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Estudio'),
        content: Text('¿Seguro que deseas eliminar permanentemente el estudio "${study.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.crimsonOutlier,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteStudy(study.id);
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  void _editStudyName(StudyModel study) {
    final nameController = TextEditingController(text: study.name);
    final tealAccent = AppTheme.getTealAccent(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar Estudio'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nombre del estudio',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: tealAccent, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tealAccent,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != study.name) {
                await _storage.updateStudyName(study.id, newName); 
                
                // Sincronización en tiempo real si el estudio está abierto en el cronómetro
                if (mounted && ref.read(timeLogProvider).activeStudyId == study.id) {
                  ref.read(timeLogProvider.notifier).syncActiveStudyName(newName);
                }
                
                if (mounted) _loadHistory(); 
              }
            },
            child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold)),
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
        if (study.isTemplate && study.templateSteps.isNotEmpty) {
          final templates = await _storage.getTemplates();
          template = templates.where((t) => t.name == study.name && t.steps.length == study.templateSteps.length).firstOrNull;
          template ??= OperationTemplate()
            ..name = study.name
            ..steps = study.templateSteps;
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

      if (mounted) setState(() => _isLoading = false);

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
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeStudyId = ref.watch(timeLogProvider).activeStudyId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tealAccent = AppTheme.getTealAccent(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedStudyIds.length} Seleccionados')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Historial de Estudios'),
                  if (_studies.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tealAccent.withValues(alpha: isDark ? 0.16 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tealAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${_studies.length}',
                        style: TextStyle(
                          color: tealAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
        centerTitle: !_isSelectionMode,
        backgroundColor: _isSelectionMode
            ? (isDark ? AppTheme.amoledSurfaceContainerHighest : AppTheme.lightSurfaceContainerHighest)
            : Colors.transparent,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(
                _selectedStudyIds.length == _studies.length ? Icons.deselect_rounded : Icons.select_all_rounded,
              ),
              tooltip: _selectedStudyIds.length == _studies.length ? 'Deseleccionar todos' : 'Seleccionar todos',
              onPressed: _toggleSelectAll,
            ),
            IconButton(
              icon: const Icon(Icons.cloud_upload_rounded, color: AppTheme.skyPrecision),
              onPressed: _selectedStudyIds.isNotEmpty ? _exportSelectedStudies : null,
              tooltip: 'Exportar seleccionados',
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.cloud_outlined),
              onPressed: _studies.isNotEmpty ? _toggleSelectionMode : null,
              tooltip: 'Exportación masiva',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: tealAccent))
          : _studies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.amoledSurface : AppTheme.lightSurfaceContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Icon(
                          Icons.history_toggle_off_rounded,
                          size: 48,
                          color: theme.hintColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No hay estudios guardados',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Los estudios finalizados se registrarán aquí para consulta y exportación.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: _studies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final study = _studies[index];
                    final date = study.date;
                    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
                              ? AppTheme.skyPrecision.withValues(alpha: isDark ? 0.16 : 0.10) 
                              : (isActive 
                                  ? (isDark ? AppTheme.amoledSurfaceContainer : AppTheme.lightSurfaceContainer)
                                  : theme.cardColor),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? AppTheme.skyPrecision 
                                : (isActive ? tealAccent : theme.dividerColor),
                            width: isSelected ? 2.0 : (isActive ? 1.5 : 1.0),
                          ),
                          boxShadow: isActive && !isSelected
                              ? [
                                  BoxShadow(
                                    color: tealAccent.withValues(alpha: isDark ? 0.20 : 0.12),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isSelectionModeActive) ...[
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (_) => _toggleSelection(study.id),
                                      activeColor: AppTheme.skyPrecision,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      study.name, 
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: tealAccent.withValues(alpha: isDark ? 0.15 : 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: tealAccent.withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: tealAccent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'ACTIVO',
                                            style: TextStyle(
                                              color: tealAccent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _buildBadge(
                                    icon: Icons.calendar_today_rounded,
                                    text: '$dateStr $timeStr',
                                    color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                                  ),
                                  _buildBadge(
                                    icon: study.mode == StopwatchMode.continuo ? Icons.timeline_rounded : Icons.replay_rounded,
                                    text: modeStr,
                                    color: AppTheme.skyPrecision,
                                  ),
                                  if (study.isTemplate)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: AppTheme.amberIndustrial.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.amberIndustrial.withValues(alpha: 0.45)),
                                      ),
                                      child: const Text(
                                        'PLANTILLA',
                                        style: TextStyle(
                                          color: AppTheme.amberIndustrial,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  _buildBadge(
                                    icon: Icons.data_usage_rounded,
                                    text: '${study.times.length} tomas',
                                    color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                                  ),
                                ],
                              ),
                              if (!isSelectionModeActive) ...[
                                const SizedBox(height: 14),
                                Divider(height: 1, thickness: 0.8, color: theme.dividerColor),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.drive_file_rename_outline_rounded,
                                        size: 20,
                                        color: theme.iconTheme.color?.withValues(alpha: 0.8),
                                      ),
                                      onPressed: () => _editStudyName(study),
                                      tooltip: 'Renombrar estudio',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: AppTheme.crimsonOutlier,
                                      ),
                                      onPressed: () => _confirmDelete(study),
                                      tooltip: 'Eliminar estudio',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    const Spacer(),
                                    FilledButton.icon(
                                      onPressed: isActive ? null : () => _loadStudyToActive(study),
                                      icon: Icon(
                                        isActive ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        isActive ? 'EN CURSO' : 'ABRIR',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isActive 
                                            ? tealAccent.withValues(alpha: 0.15) 
                                            : tealAccent,
                                        foregroundColor: isActive 
                                            ? tealAccent 
                                            : (isDark ? Colors.black : Colors.white),
                                        disabledBackgroundColor: tealAccent.withValues(alpha: 0.12),
                                        disabledForegroundColor: tealAccent,
                                        elevation: isActive ? 0 : 2,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
