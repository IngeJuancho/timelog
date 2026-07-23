import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'time_log_controller.dart';
import 'models.dart';
import 'time_log_state.dart';
import 'settings_screen.dart';
import 'calculator_screen.dart';
import 'studies_history_screen.dart';
import 'template_manager_screen.dart';
import 'storage_service.dart';
import 'update_service.dart';

import 'theme.dart';
import 'widgets/stopwatch/timer_display.dart';
import 'widgets/stopwatch/control_buttons.dart';
import 'widgets/stopwatch/time_records_list.dart';
import 'widgets/stopwatch/statistics_panel.dart';

class StopwatchScreen extends ConsumerStatefulWidget {
  const StopwatchScreen({super.key});
  @override
  ConsumerState<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends ConsumerState<StopwatchScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  late AnimationController _viewChangeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _viewChangeAnimation;
  
  late AnimationController _startButtonController;
  late AnimationController _resetButtonController;
  late AnimationController _secondaryButtonController;
  late AnimationController _exportButtonController;
  
  late Animation<double> _startButtonAnimation;
  late Animation<double> _resetButtonAnimation;
  late Animation<double> _secondaryButtonAnimation;
  late Animation<double> _exportButtonAnimation;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _taskNameFocusNode = FocusNode();
  double _previousBottomInset = 0.0;
  bool _showingAnalysis = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
    _initAnimations();
    
    _taskNameFocusNode.addListener(() {
      if (!_taskNameFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null) {
      final bottomInset = view.viewInsets.bottom;
      if (_previousBottomInset > 0.0 && bottomInset == 0.0 && _taskNameFocusNode.hasFocus) {
        _taskNameFocusNode.unfocus();
      }
      _previousBottomInset = bottomInset;
    }
  }

  void _initAnimations() {
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _viewChangeController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    const buttonDuration = Duration(milliseconds: 100);
    _startButtonController = AnimationController(duration: buttonDuration, vsync: this);
    _resetButtonController = AnimationController(duration: buttonDuration, vsync: this);
    _secondaryButtonController = AnimationController(duration: buttonDuration, vsync: this);
    _exportButtonController = AnimationController(duration: buttonDuration, vsync: this);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _viewChangeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _viewChangeController, curve: Curves.easeOutCubic));
    _startButtonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _startButtonController, curve: Curves.easeOutQuad));
    _resetButtonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _resetButtonController, curve: Curves.easeOutQuad));
    _secondaryButtonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _secondaryButtonController, curve: Curves.easeOutQuad));
    _exportButtonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _exportButtonController, curve: Curves.easeOutQuad));
  }

  void _animateButton(AnimationController controller) {
    controller.forward().then((_) => controller.reverse());
  }

  void _toggleView() {
    setState(() => _showingAnalysis = !_showingAnalysis);
    _viewChangeController.forward().then((_) => _viewChangeController.reverse());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToIndex(int index, bool isContinuous) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        double estimatedItemHeight = isContinuous ? 48.0 : 72.0;
        double headerOffset = isContinuous ? 56.0 : 0.0; 
        
        double targetItemOffset = (index * estimatedItemHeight) + headerOffset;
        double currentOffset = _scrollController.offset;
        double viewportHeight = _scrollController.position.viewportDimension;

        if (targetItemOffset < currentOffset || targetItemOffset > currentOffset + viewportHeight - estimatedItemHeight) {
          double targetScroll = targetItemOffset - (viewportHeight / 2) + (estimatedItemHeight / 2);
          
          if (targetScroll < 0) targetScroll = 0;
          if (targetScroll > _scrollController.position.maxScrollExtent) {
            targetScroll = _scrollController.position.maxScrollExtent;
          }

          _scrollController.animateTo(
            targetScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _promptMerge(int index, TimeLogNotifier state) {
    if (index == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede fusionar el primer registro.', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final tealColor = AppTheme.getTealAccent(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Icon(Icons.call_merge, color: tealColor), const SizedBox(width: 10), const Text('Fusionar Registros', style: TextStyle(fontSize: 18))]),
        content: const Text('¿Deseas combinar este registro con el anterior?\n\nLos tiempos se sumarán y la línea temporal del estudio se mantendrá intacta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              state.mergeWithPrevious(index);
            },
            child: Text('FUSIONAR', style: TextStyle(color: tealColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _promptSaveStudy(BuildContext context) async {
    final state = ref.read(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);
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
        builder: (context) => AlertDialog(
          title: const Text('Actualizar Estudio'),
          content: const Text('Este estudio ya está guardado en tu historial. ¿Deseas actualizar los datos del registro existente o guardarlo como un estudio completamente nuevo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), 
              child: const Text('NUEVO'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), 
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
          : 'Estudio ${DateTime.now().day}/${DateTime.now().month}'
    );

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              final studyName = nameController.text.trim();
              Navigator.pop(context);
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

  Future<void> _confirmReset() async {
    final state = ref.read(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);
    final tealColor = AppTheme.getTealAccent(context);

    if (state.activeRecordedTimes.isEmpty && !state.isRunning && notifier.elapsedMilliseconds == 0) {
      notifier.resetAll();
      return;
    }

    bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        final realData = state.activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
        if (!state.hasExported && realData.isNotEmpty) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent), SizedBox(width: 10), Text('Datos no exportados', style: TextStyle(fontSize: 18))]),
            content: const Text('¿Desea borrar los datos registrados sin haberlos exportado?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCELAR')),
              TextButton(onPressed: () { Navigator.of(context).pop(false); notifier.exportData(); }, child: Text('EXPORTAR', style: TextStyle(color: tealColor, fontWeight: FontWeight.bold))),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('BORRAR', style: TextStyle(color: Colors.redAccent))),
            ],
          );
        } else {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [Icon(Icons.refresh), SizedBox(width: 10), Text('Reiniciar Todo', style: TextStyle(fontSize: 18))]),
            content: const Text('¿Estás seguro de reiniciar los datos y el cronómetro?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCELAR')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('REINICIAR', style: TextStyle(color: Colors.redAccent))),
            ],
          );
        }
      }
    );

    if (!context.mounted) return; 
    if (shouldReset == true) notifier.resetAll();
  }

  Future<void> _showTemplateSelector(TimeLogNotifier state) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85, 
          ),
          child: _TemplateSelectorSheet(state: state),
        ),
      ),
    );
  }

  void _showExportImportOptions(BuildContext context, TimeLogNotifier state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Manejo de Datos', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.download, color: Colors.white)),
              title: Text('Importar archivo', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
              subtitle: Text('Cargar un estudio previo desde tus archivos Excel.', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                state.importExcel(); 
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.upload, color: Colors.white)),
              title: Text('Exportar a Excel', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
              subtitle: Text('Guardar el estudio en formato Excel (.xlsx).', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                state.exportData();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    _pulseController.dispose();
    _viewChangeController.dispose();
    _startButtonController.dispose();
    _resetButtonController.dispose();
    _secondaryButtonController.dispose();
    _exportButtonController.dispose();
    _scrollController.dispose();
    _taskNameFocusNode.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(timeLogProvider.select((s) => s.animateStartTrigger), (_, __) => _animateButton(_startButtonController));
    ref.listen(timeLogProvider.select((s) => s.animateSecondaryTrigger), (_, __) => _animateButton(_secondaryButtonController));
    ref.listen(timeLogProvider.select((s) => s.animateResetTrigger), (_, __) => _animateButton(_resetButtonController));
    ref.listen(timeLogProvider.select((s) => s.animateExportTrigger), (_, __) => _animateButton(_exportButtonController));
    ref.listen(timeLogProvider.select((s) => s.showResetDialogTrigger), (_, __) => _confirmReset());
    
    ref.listen<int>(
      timeLogProvider.select((s) => s.activeRecordedTimes.length),
      (previous, next) {
        final state = ref.read(timeLogProvider);
        if (previous != null && next > previous && !_showingAnalysis) {
          if (state.activeTemplate == null) {
            _scrollToBottom();
          } else {
            _scrollToIndex(state.currentTemplateStepIndex, state.currentMode == StopwatchMode.continuo);
          }
        }
      },
    );

    ref.listen<int>(
      timeLogProvider.select((s) => s.currentTemplateStepIndex),
      (previous, next) {
        final state = ref.read(timeLogProvider);
        if (previous != null && next != previous && !_showingAnalysis && state.activeTemplate != null) {
          _scrollToIndex(next, state.currentMode == StopwatchMode.continuo);
        }
      },
    );

    ref.listen(timeLogProvider.select((s) => s.isRunning), (_, isRunning) {
      if (isRunning && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      } else if (!isRunning && _pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    final state = ref.watch(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);

    return TapRegion(
      onTapOutside: (_) {
        if (_taskNameFocusNode.hasFocus) {
          _taskNameFocusNode.unfocus();
        }
      },
      child: Scaffold(
        drawer: _buildDrawer(state, notifier),
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              const Text('TimeLog', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                children: [
                  TimerDisplay(pulseAnimation: _pulseAnimation),
                  const SizedBox(height: 24),
                  _buildTaskNameField(state, notifier),
                  const SizedBox(height: 24),
                  ControlButtons(
                    startButtonAnimation: _startButtonAnimation,
                    secondaryButtonAnimation: _secondaryButtonAnimation,
                    resetButtonAnimation: _resetButtonAnimation,
                    exportButtonAnimation: _exportButtonAnimation,
                    onStartPressed: () {
                      _animateButton(_startButtonController);
                      if (state.isRunning) {
                        if (state.currentMode == StopwatchMode.continuo) {
                          notifier.recordTime(resetStopwatch: false, keepRunning: true);
                        } else { 
                          notifier.stopTimerLogic(); 
                          notifier.recordTime(resetStopwatch: true, keepRunning: false); 
                        }
                      } else {
                        notifier.startTimerLogic();
                      }
                    },
                    onSecondaryPressed: () {
                      _animateButton(_secondaryButtonController);
                      if (state.currentMode == StopwatchMode.regresoACero) {
                        notifier.recordTime(resetStopwatch: true, keepRunning: true);
                      } else { 
                        notifier.stopTimerLogic(); 
                        notifier.recordTime(resetStopwatch: true, keepRunning: false); 
                      }
                    },
                    onResetPressed: () {
                      _animateButton(_resetButtonController); 
                      _confirmReset();
                    },
                    onExportPressed: () {
                      _animateButton(_exportButtonController); 
                      _showExportImportOptions(context, notifier);
                    },
                  ),
                  const SizedBox(height: 24),
                  Expanded(child: _buildStatsCard(state, notifier)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(TimeLogState state, TimeLogNotifier notifier) {
    final updateInfo = ref.watch(updateProvider).value;

    return Drawer(
      backgroundColor: Theme.of(context).drawerTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 160,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade800, Theme.of(context).colorScheme.surface], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.timer, color: Colors.white)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('TimeLog', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    if (updateInfo != null && updateInfo.isUpdateAvailable) ...[
                      const Spacer(), // Empuja el botón hasta la derecha
                      GestureDetector(
                        onTap: () {
                          launchUrl(Uri.parse(updateInfo.releaseUrl), mode: LaunchMode.externalApplication);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.orangeAccent, width: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.system_update_alt, color: Colors.orangeAccent, size: 12),
                              const SizedBox(width: 4),
                              Text('¡Actualización ${updateInfo.latestVersion}!', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(24, 24, 24, 10), child: Text("MODO", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          _buildDrawerOption('Por Ciclo', 'Clásico. Reinicia al registrar.', Icons.replay, StopwatchMode.regresoACero, state, notifier),
          _buildDrawerOption('Por Elemento', 'Acumulativo. Calcula TO.', Icons.timeline, StopwatchMode.continuo, state, notifier),
          
          Divider(color: Theme.of(context).dividerColor, indent: 24, endIndent: 24, height: 40),
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 10), child: Text("DATOS", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: Icon(Icons.save_outlined, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)), title: Text('Guardar Estudio', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)), onTap: () { Navigator.pop(context); _promptSaveStudy(context); }),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: Icon(Icons.history, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)), title: Text('Historial', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const StudiesHistoryScreen())); }),

          Divider(color: Theme.of(context).dividerColor, indent: 24, endIndent: 24, height: 40),
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 10), child: Text("UTILIDADES", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: Icon(Icons.route, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)), title: Text('Rutas Estándar', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateManagerScreen())); }),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: Icon(Icons.calculate_outlined, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)), title: Text('Calculadora Muestra', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SampleCalculatorScreen())); }),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: Icon(Icons.settings_outlined, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)), title: Text('Configuración', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
        ],
      ),
    );
  }

  Widget _buildDrawerOption(String title, String subtitle, IconData icon, StopwatchMode mode, TimeLogState state, TimeLogNotifier notifier) {
    bool isSelected = state.currentMode == mode;
    final tealColor = AppTheme.getTealAccent(context);
    final tealFill = AppTheme.getTealFill(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isSelected ? tealColor : Theme.of(context).iconTheme.color?.withValues(alpha: 0.7)),
        title: Text(title, style: TextStyle(color: isSelected ? tealColor : Theme.of(context).textTheme.bodyMedium?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(subtitle, style: TextStyle(color: isSelected ? tealColor.withValues(alpha: 0.7) : Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
        tileColor: isSelected ? tealFill : null,
        onTap: () { notifier.setMode(mode); Navigator.pop(context); },
      ),
    );
  }

  Widget _buildTaskNameField(TimeLogState state, TimeLogNotifier notifier) {
    bool isTemplateActive = state.activeTemplate != null;
    final tealColor = AppTheme.getTealAccent(context);

    return SizedBox(
      height: 50,
      child: TextField(
        controller: notifier.taskNameController,
        focusNode: _taskNameFocusNode, 
        enableInteractiveSelection: true, 
        onChanged: (value) => notifier.updateTaskName(value),
        onTap: () {
          final text = notifier.taskNameController.text;
          if (text.isNotEmpty && notifier.taskNameController.selection.isCollapsed) {
            notifier.taskNameController.selection = TextSelection.fromPosition(
              TextPosition(offset: notifier.taskNameController.selection.baseOffset)
            );
          }
        },
        onSubmitted: (_) => _taskNameFocusNode.unfocus(),
        style: TextStyle(
          color: isTemplateActive ? tealColor : Theme.of(context).textTheme.bodyMedium?.color, 
          fontWeight: isTemplateActive ? FontWeight.bold : FontWeight.normal
        ),
        decoration: InputDecoration(
          hintText: 'Nombre de la tarea...',
          hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
          prefixIcon: IconButton(
            icon: Icon(isTemplateActive ? Icons.route : Icons.alt_route, color: isTemplateActive ? Colors.orangeAccent : tealColor, size: 20),
            tooltip: 'Cargar Ruta Estándar',
            onPressed: () => _showTemplateSelector(notifier),
          ),
          suffixIcon: isTemplateActive
              ? IconButton(
                  icon: const Icon(Icons.cancel_presentation, color: Colors.orangeAccent, size: 20),
                  tooltip: 'Desvincular Ruta',
                  onPressed: () => notifier.clearTemplate(),
                )
              : IconButton(
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5), size: 20), 
                  onPressed: () {
                    notifier.taskNameController.clear();
                    notifier.updateTaskName(''); 
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), 
            borderSide: isTemplateActive ? BorderSide(color: tealColor, width: 1.5) : BorderSide.none
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(TimeLogState state, TimeLogNotifier notifier) {
    final tealColor = AppTheme.getTealAccent(context);
    return AnimatedBuilder(
      animation: _viewChangeAnimation,
      builder: (_, __) => Card(
        color: Theme.of(context).cardColor, 
        elevation: 4, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
        clipBehavior: Clip.antiAlias, 
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [Icon(_showingAnalysis ? Icons.pie_chart_outline : Icons.list_alt, color: tealColor, size: 20), const SizedBox(width: 10), Text(_showingAnalysis ? 'ESTADÍSTICAS' : 'REGISTROS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Theme.of(context).textTheme.bodyMedium?.color))]),
                  SizedBox(height: 32, width: 32, child: IconButton(padding: EdgeInsets.zero, onPressed: _toggleView, icon: Icon(_showingAnalysis ? Icons.list : Icons.analytics, size: 20), style: IconButton.styleFrom(backgroundColor: Theme.of(context).dividerColor, foregroundColor: Theme.of(context).textTheme.bodyMedium?.color))),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: _showingAnalysis 
                    ? const AnalysisViewWidget() 
                    : (state.currentMode == StopwatchMode.continuo 
                        ? ContinuousTableWidget(scrollController: _scrollController, onMergeRequest: (i) => _promptMerge(i, notifier)) 
                        : SimpleRecordsListWidget(scrollController: _scrollController, onMergeRequest: (i) => _promptMerge(i, notifier))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateSelectorSheet extends StatefulWidget {
  final TimeLogNotifier state;
  const _TemplateSelectorSheet({required this.state});

  @override
  State<_TemplateSelectorSheet> createState() => _TemplateSelectorSheetState();
}

class _TemplateSelectorSheetState extends State<_TemplateSelectorSheet> {
  final StorageService _storage = StorageService();
  TemplateFolder? _currentFolder;
  List<TemplateFolder> _folders = [];
  List<OperationTemplate> _templates = [];
  List<OperationTemplate> _allTemplates = []; 
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); 
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _allTemplates = await _storage.getAllTemplates(); 
    
    if (_currentFolder == null) {
      _folders = await _storage.getFolders();
      _templates = await _storage.getTemplates(folderId: null);
    } else {
      _folders = [];
      _templates = await _storage.getTemplates(folderId: _currentFolder!.id);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _navigateIntoFolder(TemplateFolder folder) {
    setState(() => _currentFolder = folder);
    _loadData();
  }

  void _navigateBack() {
    setState(() => _currentFolder = null);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentFolder != null && _searchQuery.isEmpty)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _navigateBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (_currentFolder != null && _searchQuery.isEmpty) const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _searchQuery.isNotEmpty 
                      ? 'Resultados de Búsqueda' 
                      : (_currentFolder == null ? 'Seleccionar Ruta Estándar' : _currentFolder!.name),
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: _currentFolder == null && _searchQuery.isEmpty ? TextAlign.center : TextAlign.left,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onTap: () {
              if (!_searchFocusNode.hasFocus) {
                FocusScope.of(context).requestFocus(_searchFocusNode);
              }
            },
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o número...',
              hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.search, color: AppTheme.getTealAccent(context)),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5)), onPressed: () => _searchController.clear())
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.getTealAccent(context)));
    }

    if (_searchQuery.isNotEmpty) {
      final filtered = _allTemplates.where((t) => t.name.toLowerCase().contains(_searchQuery)).toList();
      if (filtered.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No se encontraron coincidencias', style: TextStyle(color: Colors.white54))));
      }
      return ListView(
        shrinkWrap: true,
        children: filtered.map((template) => ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.route, color: Colors.white, size: 20)),
          title: Text(template.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text('${template.steps.length} pasos programados', style: const TextStyle(color: Colors.white54)),
          onTap: () {
            widget.state.loadTemplate(template);
            Navigator.pop(context);
          },
        )).toList(),
      );
    }

    if (_folders.isEmpty && _templates.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('Carpeta vacía', style: TextStyle(color: Colors.white54))));
    }

    return ListView(
      shrinkWrap: true,
      children: [
        ..._folders.map((folder) => ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.folder, color: Colors.white, size: 20)),
          title: Text(folder.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
          onTap: () => _navigateIntoFolder(folder),
        )),
        ..._templates.map((template) => ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.route, color: Colors.white, size: 20)),
          title: Text(template.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text('${template.steps.length} pasos programados', style: const TextStyle(color: Colors.white54)),
          onTap: () {
            widget.state.loadTemplate(template);
            Navigator.pop(context);
          },
        )),
      ],
    );
  }
}
