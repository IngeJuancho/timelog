import 'package:flutter/material.dart';
import '../../storage_service.dart';
import '../../theme.dart';
import '../../time_log_controller.dart';
import '../../time_log_state.dart';

class StopwatchDialogs {
  static void promptMerge(BuildContext context, int index, TimeLogNotifier notifier) {
    if (index == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede fusionar el primer registro.', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final tealColor = AppTheme.getTealAccent(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.call_merge, color: tealColor),
            const SizedBox(width: 10),
            const Text('Fusionar Registros', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          '¿Deseas combinar este registro con el anterior?\n\nLos tiempos se sumarán y la línea temporal del estudio se mantendrá intacta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.mergeWithPrevious(index);
            },
            child: Text('FUSIONAR', style: TextStyle(color: tealColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Future<void> promptSaveStudy(BuildContext context, TimeLogState state, TimeLogNotifier notifier) async {
    final tealColor = AppTheme.getTealAccent(context);
    final realData = state.activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (realData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tiempos tomados para guardar.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (state.activeStudyId != null) {
      bool? chooseUpdate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Actualizar Estudio'),
          content: const Text(
            'Este estudio ya está guardado en tu historial. ¿Deseas actualizar los datos del registro existente o guardarlo como un estudio completamente nuevo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('NUEVO'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('ACTUALIZAR', style: TextStyle(color: tealColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (!context.mounted) return;
      if (chooseUpdate == null) return;

      if (chooseUpdate == true) {
        await notifier.updateCurrentStudy();
        return;
      }
    }

    final String currentMasterName = state.masterStudyName;
    final TextEditingController nameController = TextEditingController(
      text: currentMasterName.isNotEmpty
          ? currentMasterName
          : 'Estudio ${DateTime.now().day}/${DateTime.now().month}',
    );

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar Estudio Nuevo'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Nombre del estudio',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: tealColor)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              final studyName = nameController.text.trim();
              Navigator.pop(ctx);
              if (studyName.isNotEmpty) {
                await notifier.saveCurrentStudyToHistory(studyName);
              }
            },
            child: Text('GUARDAR', style: TextStyle(color: tealColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static Future<void> confirmReset(BuildContext context, TimeLogState state, TimeLogNotifier notifier) async {
    final tealColor = AppTheme.getTealAccent(context);

    if (state.activeRecordedTimes.isEmpty && !state.isRunning && notifier.elapsedMilliseconds == 0) {
      notifier.resetAll();
      return;
    }

    bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final realData = state.activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
        if (!state.hasExported && realData.isNotEmpty) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                SizedBox(width: 10),
                Text('Datos no exportados', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: const Text('¿Desea borrar los datos registrados sin haberlos exportado?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCELAR')),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(false);
                  notifier.exportData();
                },
                child: Text('EXPORTAR', style: TextStyle(color: tealColor, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('BORRAR', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          );
        } else {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 10),
                Text('Reiniciar Todo', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: const Text('¿Estás seguro de reiniciar los datos y el cronómetro?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCELAR')),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('REINICIAR', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          );
        }
      },
    );

    if (!context.mounted) return;
    if (shouldReset == true) notifier.resetAll();
  }

  static void promptSaveCurrentTemplate(
    BuildContext context,
    TimeLogState state,
    TimeLogNotifier notifier,
  ) async {
    List<String> steps = [];
    if (state.activeTemplate != null) {
      steps = List<String>.from(state.activeTemplate!.steps);
    } else {
      final recorded = state.recordedTimesContinuo;
      for (final item in recorded) {
        if (item['status'] == 'pending') continue;
        final name = (item['name'] as String? ?? '').trim();
        if (name.isNotEmpty) {
          if (!steps.contains(name)) {
            steps.add(name);
          } else if (steps.isNotEmpty && name == steps.first) {
            break;
          }
        }
      }
    }

    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay elementos etiquetados o registrados para guardar como plantilla.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final initialName = (state.activeTemplate?.name.isNotEmpty == true)
        ? state.activeTemplate!.name
        : (state.savedTaskNameCont.isNotEmpty ? state.savedTaskNameCont : 'Nueva Ruta Estándar');
    final nameController = TextEditingController(text: initialName);

    final storage = StorageService();
    final folders = await storage.getFolders();
    int? selectedFolderId;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.bookmark_add, color: Colors.amber),
                  const SizedBox(width: 10),
                  Text(
                    'Guardar Ruta Estándar',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre de la Ruta',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      decoration: InputDecoration(
                        hintText: 'Ej. Ensamble de Motor',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Carpeta Destino',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedFolderId,
                      dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sin Carpeta (Raíz)', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                        ),
                        ...folders.map((f) => DropdownMenuItem<int?>(
                          value: f.id,
                          child: Text('📁 ${f.name}', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                        )),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedFolderId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pasos de la Ruta (${steps.length})',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: steps.length,
                        itemBuilder: (_, index) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppTheme.getTealAccent(context).withValues(alpha: 0.2),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(fontSize: 10, color: AppTheme.getTealAccent(context), fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  steps[index],
                                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('CANCELAR', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final savedTemplate = await storage.saveTemplate(name, steps, folderId: selectedFolderId);
                    notifier.attachLiveTemplate(savedTemplate);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '¡Ruta Estándar "$name" activada y guardada con éxito!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
