import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'time_log_controller.dart';
import 'models.dart';
import 'storage_service.dart';

class StudiesHistoryScreen extends ConsumerStatefulWidget {
  const StudiesHistoryScreen({super.key});
  @override
  ConsumerState<StudiesHistoryScreen> createState() => _StudiesHistoryScreenState();
}

class _StudiesHistoryScreenState extends ConsumerState<StudiesHistoryScreen> {
  final StorageService _storage = StorageService();
  List<StudyModel> _studies = [];
  bool _isLoading = true;

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
      ref.read(timeLogProvider).clearActiveStudyId();
    }
    
    await _storage.deleteStudyFromHistory(id);
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
                  ref.read(timeLogProvider).syncActiveStudyName(newName);
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
    ref.read(timeLogProvider).loadStudyFromHistory(study);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeStudyId = ref.watch(timeLogProvider).activeStudyId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Estudios'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
                    final modeStr = study.mode == StopwatchMode.continuo ? 'Continuo' : 'Regreso a Cero';
                    
                    final isActive = study.id == activeStudyId;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: isActive ? Colors.tealAccent.withValues(alpha: 0.05) : const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? Colors.tealAccent : Colors.white10,
                          width: isActive ? 1.5 : 1.0,
                        ),
                        boxShadow: isActive
                            ? [BoxShadow(color: Colors.tealAccent.withValues(alpha: 0.15), blurRadius: 10, spreadRadius: 1)]
                            : [],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                              
                              // NUEVO: Etiqueta Visual de "Plantilla"
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                              onPressed: () => _editStudyName(study),
                              tooltip: 'Renombrar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.folder_open, color: Colors.blueAccent),
                              onPressed: () => _loadStudyToActive(study),
                              tooltip: 'Cargar Estudio',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _confirmDelete(study),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}