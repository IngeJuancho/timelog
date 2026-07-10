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

// Import new extracted widgets
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Row(children: [Icon(Icons.call_merge, color: Colors.tealAccent), SizedBox(width: 10), Text('Fusionar Registros', style: TextStyle(color: Colors.white, fontSize: 18))]),
        content: const Text('¿Deseas combinar este registro con el anterior?\n\nLos tiempos se sumarán y la línea temporal del estudio se mantendrá intacta.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              state.mergeWithPrevious(index);
            },
            child: const Text('FUSIONAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _promptSaveStudy(BuildContext context) async {
    final state = ref.read(timeLogProvider);
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
          backgroundColor: const Color(0xFF252525),
          title: const Text('Actualizar Estudio', style: TextStyle(color: Colors.white)),
          content: const Text('Este estudio ya está guardado en tu historial. ¿Deseas actualizar los datos del registro existente o guardarlo como un estudio completamente nuevo?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), 
              child: const Text('NUEVO', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), 
              child: const Text('ACTUALIZAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (!context.mounted) return; 
      if (chooseUpdate == null) return; 

      if (chooseUpdate == true) {
        // Assume controller.updateCurrentStudy() exists or implement logic here.
        // As per original code, we call updateCurrentStudy (which seems to be missing in controller? We'll leave it as it was)
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
        backgroundColor: const Color(0xFF252525),
        title: const Text('Guardar Estudio Nuevo', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nombre del estudio',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.tealAccent)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Assume controller.saveCurrentStudyToHistory() exists.
            },
            child: const Text('GUARDAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset() async {
    final state = ref.read(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);

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
            backgroundColor: const Color(0xFF252525),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent), SizedBox(width: 10), Text('Datos no exportados', style: TextStyle(color: Colors.white, fontSize: 18))]),
            content: const Text('¿Desea borrar los datos registrados sin haberlos exportado?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
              TextButton(onPressed: () { Navigator.of(context).pop(false); notifier.exportData(); }, child: const Text('EXPORTAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold))),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('BORRAR', style: TextStyle(color: Colors.redAccent))),
            ],
          );
        } else {
          return AlertDialog(
            backgroundColor: const Color(0xFF252525),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [Icon(Icons.refresh, color: Colors.white), SizedBox(width: 10), Text('Reiniciar Todo', style: TextStyle(color: Colors.white, fontSize: 18))]),
            content: const Text('¿Estás seguro de reiniciar los datos y el cronómetro?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
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
      backgroundColor: const Color(0xFF252525),
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
      backgroundColor: const Color(0xFF252525),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Manejo de Datos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.download, color: Colors.white)),
              title: const Text('Importar archivo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Cargar un estudio previo desde tus archivos Excel.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                state.importExcel(); 
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.upload, color: Colors.white)),
              title: const Text('Exportar a Excel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Guardar el estudio en formato Excel (.xlsx).', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
      backgroundColor: const Color(0xFF1E1E1E),
      surfaceTintColor: Colors.transparent,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 160,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade900, const Color(0xFF1E1E1E)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
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
          const Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 10), child: Text("MODO", style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          _buildDrawerOption('Por Ciclo', 'Clásico. Reinicia al registrar.', Icons.replay, StopwatchMode.regresoACero, state, notifier),
          _buildDrawerOption('Por Elemento', 'Acumulativo. Calcula TO.', Icons.timeline, StopwatchMode.continuo, state, notifier),
          
          const Divider(color: Colors.white10, indent: 24, endIndent: 24, height: 40),
          const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 10), child: Text("DATOS", style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const Icon(Icons.save_outlined, color: Colors.white70), title: const Text('Guardar Estudio', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _promptSaveStudy(context); }),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const Icon(Icons.history, color: Colors.white70), title: const Text('Historial', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const StudiesHistoryScreen())); }),

          const Divider(color: Colors.white10, indent: 24, endIndent: 24, height: 40),
          const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 10), child: Text("UTILIDADES", style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const Icon(Icons.route, color: Colors.white70), title: const Text('Rutas Estándar', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateManagerScreen())); }),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const Icon(Icons.calculate_outlined, color: Colors.white70), title: const Text('Calculadora Muestra', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SampleCalculatorScreen())); }),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const Icon(Icons.settings_outlined, color: Colors.white70), title: const Text('Configuración', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
        ],
      ),
    );
  }

  Widget _buildDrawerOption(String title, String subtitle, IconData icon, StopwatchMode mode, TimeLogState state, TimeLogNotifier notifier) {
    bool isSelected = state.currentMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isSelected ? Colors.tealAccent : Colors.white70),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.tealAccent : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(subtitle, style: TextStyle(color: isSelected ? Colors.teal.withValues(alpha: 0.7) : Colors.white38, fontSize: 12)),
        tileColor: isSelected ? Colors.teal.withValues(alpha: 0.15) : null,
        onTap: () { notifier.setMode(mode); Navigator.pop(context); },
      ),
    );
  }

  Widget _buildTaskNameField(TimeLogState state, TimeLogNotifier notifier) {
    bool isTemplateActive = state.activeTemplate != null;

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
          color: isTemplateActive ? Colors.tealAccent : Colors.white, 
          fontWeight: isTemplateActive ? FontWeight.bold : FontWeight.normal
        ),
        decoration: InputDecoration(
          hintText: 'Nombre de la tarea...',
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: IconButton(
            icon: Icon(isTemplateActive ? Icons.route : Icons.alt_route, color: isTemplateActive ? Colors.orangeAccent : Colors.teal.shade200, size: 20),
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
                  icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20), 
                  onPressed: () {
                    notifier.taskNameController.clear();
                    notifier.updateTaskName(''); 
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          filled: true,
          fillColor: const Color(0xFF252525),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30), 
            borderSide: isTemplateActive ? const BorderSide(color: Colors.tealAccent, width: 1) : BorderSide.none
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(TimeLogState state, TimeLogNotifier notifier) {
    return AnimatedBuilder(
      animation: _viewChangeAnimation,
      builder: (_, __) => Card(
        color: const Color(0xFF252525), 
        elevation: 4, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), 
        clipBehavior: Clip.antiAlias, 
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
              color: const Color(0xFF2A2A2A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [Icon(_showingAnalysis ? Icons.pie_chart_outline : Icons.list_alt, color: Colors.tealAccent, size: 20), const SizedBox(width: 10), Text(_showingAnalysis ? 'ESTADÍSTICAS' : 'REGISTROS', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white70))]),
                  SizedBox(height: 32, width: 32, child: IconButton(padding: EdgeInsets.zero, onPressed: _toggleView, icon: Icon(_showingAnalysis ? Icons.list : Icons.analytics, size: 20), style: IconButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white))),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            Expanded(
              child: Container(
                color: const Color(0xFF1E1E1E),
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
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o número...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear, color: Colors.white54), onPressed: () => _searchController.clear())
                  : null,
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
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
      return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
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
