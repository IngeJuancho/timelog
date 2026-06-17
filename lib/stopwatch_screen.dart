import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Agregado para SystemChannels
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'time_log_controller.dart';
import 'models.dart';
import 'settings_screen.dart';
import 'calculator_screen.dart';
import 'studies_history_screen.dart';

class StopwatchScreen extends ConsumerStatefulWidget {
  const StopwatchScreen({super.key});
  @override
  ConsumerState<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends ConsumerState<StopwatchScreen> with TickerProviderStateMixin {
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
  
  bool _showingAnalysis = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    
    _taskNameFocusNode.addListener(() {
      if (!_taskNameFocusNode.hasFocus) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });
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

  void _promptMerge(int index, TimeLogController state) {
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

  Future<void> _promptSaveStudy(BuildContext context, TimeLogController controller) async {
    if (controller.activeRecordedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para guardar.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (controller.activeStudyId != null) {
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

      if (!mounted) return; // Corrección async gap
      if (chooseUpdate == null) return; 

      if (chooseUpdate == true) {
        controller.updateCurrentStudy();
        return;
      }
    }

    final TextEditingController nameController = TextEditingController(
      text: controller.taskNameController.text.isNotEmpty ? controller.taskNameController.text : 'Estudio ${DateTime.now().day}/${DateTime.now().month}'
    );

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
              controller.saveCurrentStudyToHistory(nameController.text.trim());
            },
            child: const Text('GUARDAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset() async {
    final controller = ref.read(timeLogProvider);
    if (controller.activeRecordedTimes.isEmpty && !controller.isRunning && controller.elapsedMilliseconds == 0) {
      controller.resetAll();
      return;
    }

    bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        if (!controller.hasExported && controller.activeRecordedTimes.isNotEmpty) {
          return AlertDialog(
            backgroundColor: const Color(0xFF252525),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent), SizedBox(width: 10), Text('Datos no exportados', style: TextStyle(color: Colors.white, fontSize: 18))]),
            content: const Text('¿Desea borrar los datos registrados sin haberlos exportado?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCELAR', style: TextStyle(color: Colors.white54))),
              TextButton(onPressed: () { Navigator.of(context).pop(false); controller.exportData(); }, child: const Text('EXPORTAR', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold))),
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

    if (!mounted) return; // Corrección async gap
    if (shouldReset == true) controller.resetAll();
  }

  @override
  void dispose() {
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
        if (previous != null && next > previous && !_showingAnalysis) {
          _scrollToBottom();
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
    
    if (state.activeRecordedTimes.isNotEmpty && state.averageTime == 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => state.calculateStatistics());
    }

    return TapRegion(
      onTapOutside: (_) {
        if (_taskNameFocusNode.hasFocus) {
          _taskNameFocusNode.unfocus();
        }
      },
      child: Scaffold(
        drawer: _buildDrawer(state),
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
                  _buildTimerDisplay(state),
                  const SizedBox(height: 24),
                  _buildTaskNameField(state),
                  const SizedBox(height: 24),
                  _buildControlButtons(state),
                  const SizedBox(height: 16),
                  _buildSecondaryButtons(state),
                  const SizedBox(height: 24),
                  Expanded(child: _buildStatsCard(state)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(TimeLogController state) {
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.timer, color: Colors.white)),
                SizedBox(height: 12),
                Text('TimeLog', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 10), child: Text("MODO", style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          _buildDrawerOption('Regreso a Cero', 'Clásico. Reinicia al registrar.', Icons.replay, StopwatchMode.regresoACero, state),
          _buildDrawerOption('Continuo', 'Acumulativo. Calcula TO.', Icons.timeline, StopwatchMode.continuo, state),
          
          const Divider(color: Colors.white10, indent: 24, endIndent: 24, height: 40),
          const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 10), child: Text("DATOS", style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const Icon(Icons.save_outlined, color: Colors.white70), title: const Text('Guardar Estudio', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _promptSaveStudy(context, state); }),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const Icon(Icons.history, color: Colors.white70), title: const Text('Historial', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const StudiesHistoryScreen())); }),

          const Divider(color: Colors.white10, indent: 24, endIndent: 24, height: 40),
          const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 10), child: Text("UTILIDADES", style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const Icon(Icons.calculate_outlined, color: Colors.white70), title: const Text('Calculadora Muestra', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SampleCalculatorScreen())); }),
          ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 24), leading: const Icon(Icons.settings_outlined, color: Colors.white70), title: const Text('Configuración', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
        ],
      ),
    );
  }

  Widget _buildDrawerOption(String title, String subtitle, IconData icon, StopwatchMode mode, TimeLogController state) {
    bool isSelected = state.currentMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isSelected ? Colors.tealAccent : Colors.white70),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.tealAccent : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(subtitle, style: TextStyle(color: isSelected ? Colors.teal.withOpacity(0.7) : Colors.white38, fontSize: 12)),
        tileColor: isSelected ? Colors.teal.withValues(alpha: 0.15) : null,
        onTap: () { state.setMode(mode); Navigator.pop(context); },
      ),
    );
  }

  Widget _buildTimerDisplay(TimeLogController state) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: state.isRunning ? _pulseAnimation.value : 1.0,
          child: Column(
            children: [
              Text(state.currentMode == StopwatchMode.regresoACero ? "REGRESO A CERO" : "CONTINUO", style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white38, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  state.formatTime(state.elapsedMilliseconds.toDouble()), 
                  style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w300, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()], letterSpacing: -2.0)
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskNameField(TimeLogController state) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: state.taskNameController,
        focusNode: _taskNameFocusNode, 
        enableInteractiveSelection: true, 
        onTap: () {
          final text = state.taskNameController.text;
          if (text.isNotEmpty && state.taskNameController.selection.isCollapsed) {
            state.taskNameController.selection = TextSelection.fromPosition(
              TextPosition(offset: state.taskNameController.selection.baseOffset)
            );
          }
        },
        onSubmitted: (_) => _taskNameFocusNode.unfocus(),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Nombre de la tarea...',
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(Icons.edit, color: Colors.teal.shade200, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20), 
            onPressed: () => state.taskNameController.clear(),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          filled: true,
          fillColor: const Color(0xFF252525),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildControlButtons(TimeLogController state) {
    String primaryLabel; 
    IconData primaryIcon; 
    Color primaryColor;
    
    // Corrección: Encapsulamiento con llaves en sentencias if
    if (state.currentMode == StopwatchMode.regresoACero) {
      if (state.isRunning) { 
        primaryLabel = 'Parar'; 
        primaryIcon = Icons.pause_circle_filled; 
        primaryColor = Colors.redAccent; 
      } else { 
        primaryLabel = 'Iniciar'; 
        primaryIcon = Icons.play_circle_fill; 
        primaryColor = Colors.tealAccent; 
      }
    } else {
      if (state.isRunning) { 
        primaryLabel = 'Lap'; 
        primaryIcon = Icons.flag; 
        primaryColor = Colors.indigoAccent; 
      } else { 
        primaryLabel = 'Iniciar'; 
        primaryIcon = Icons.play_circle_fill; 
        primaryColor = Colors.tealAccent; 
      }
    }
    
    return AnimatedBuilder(
      animation: _startButtonAnimation,
      builder: (context, child) => Transform.scale(
        scale: _startButtonAnimation.value,
        child: SizedBox(
          width: double.infinity, height: 65,
          child: ElevatedButton.icon(
            onPressed: () {
              _animateButton(_startButtonController);
              if (state.isRunning) {
                // Corrección: Encapsulamiento con llaves
                if (state.currentMode == StopwatchMode.continuo) {
                  state.recordTime(resetStopwatch: false, keepRunning: true);
                } else { 
                  state.stopTimerLogic(); 
                  state.recordTime(resetStopwatch: true, keepRunning: false); 
                }
              } else {
                state.startTimerLogic();
              }
            },
            icon: Icon(primaryIcon, size: 28),
            label: Text(primaryLabel.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor.withValues(alpha: 0.2), 
              foregroundColor: primaryColor, 
              elevation: 0, 
              side: BorderSide(color: primaryColor.withValues(alpha: 0.5), width: 1.5), 
              shape: const StadiumBorder()
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButtons(TimeLogController state) {
    String secondaryLabel = state.currentMode == StopwatchMode.regresoACero ? 'Vuelta' : 'Finalizar';
    IconData secondaryIcon = state.currentMode == StopwatchMode.regresoACero ? Icons.replay : Icons.stop_circle_outlined;
    bool isEnabled = state.isRunning;

    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _secondaryButtonAnimation,
            builder: (_, __) => Transform.scale(
              scale: _secondaryButtonAnimation.value, 
              child: _buildSecondaryButton(
                icon: secondaryIcon, 
                label: secondaryLabel, 
                onPressed: isEnabled ? () {
                  _animateButton(_secondaryButtonController);
                  // Corrección: Encapsulamiento con llaves
                  if (state.currentMode == StopwatchMode.regresoACero) {
                    state.recordTime(resetStopwatch: true, keepRunning: true);
                  } else { 
                    state.stopTimerLogic(); 
                    state.recordTime(resetStopwatch: true, keepRunning: false); 
                  }
                } : null, 
                color: Colors.orangeAccent
              )
            ),
          )
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedBuilder(
            animation: _resetButtonAnimation,
            builder: (_, __) => Transform.scale(
              scale: _resetButtonAnimation.value, 
              child: _buildSecondaryButton(
                icon: Icons.refresh, 
                label: 'Reset', 
                onPressed: () { 
                  _animateButton(_resetButtonController); 
                  _confirmReset(); 
                }, 
                color: Colors.white70
              )
            ),
          )
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedBuilder(
            animation: _exportButtonAnimation,
            builder: (_, __) => Transform.scale(
              scale: _exportButtonAnimation.value, 
              child: _buildSecondaryButton(
                icon: Icons.import_export, 
                label: 'Archivos',         
                onPressed: () { 
                  _animateButton(_exportButtonController); 
                  _showExportImportOptions(context, state); 
                }, 
                color: Colors.blueAccent
              )
            ),
          )
        ),
      ],
    );
  }

  void _showExportImportOptions(BuildContext context, TimeLogController state) {
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
              title: const Text('Importar desde CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Cargar un estudio previo desde tus archivos.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                state.importCsv();
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.upload, color: Colors.white)),
              title: const Text('Exportar a CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Guardar el estudio actual en tus archivos.', style: TextStyle(color: Colors.white54, fontSize: 12)),
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

  Widget _buildSecondaryButton({required IconData icon, required String label, required VoidCallback? onPressed, required Color color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF252525), 
        foregroundColor: color, 
        elevation: 0, 
        padding: const EdgeInsets.symmetric(vertical: 16), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Icon(icon, size: 20), 
          const SizedBox(height: 4), 
          Text(label, style: const TextStyle(fontSize: 10))
        ]
      ),
    );
  }

  Widget _buildStatsCard(TimeLogController state) {
    return AnimatedBuilder(
      animation: _viewChangeAnimation,
      builder: (_, __) => Card(
        color: const Color(0xFF252525), elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), clipBehavior: Clip.antiAlias, margin: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), color: const Color(0xFF2A2A2A),
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
                child: _showingAnalysis ? _buildAnalysisView(state) : (state.currentMode == StopwatchMode.continuo ? _buildContinuousTable(state) : _buildSimpleRecordsList(state)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisView(TimeLogController state) {
    if (state.activeRecordedTimes.isEmpty) return _buildEmptyState();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(children: [Expanded(child: _buildStatBox('Promedio', state.averageTime, Colors.blueAccent, state)), const SizedBox(width: 12), Expanded(child: _buildStatBox('Desviación', state.stdDev, Colors.orangeAccent, state))]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _buildStatBox('Mínimo', state.minTime, Colors.greenAccent, state)), const SizedBox(width: 12), Expanded(child: _buildStatBox('Máximo', state.maxTime, Colors.redAccent, state))]),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, double value, Color color, TimeLogController state) {
    return Container(
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: color.withValues(alpha: 0.3))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)), 
          const SizedBox(height: 8), 
          Text(state.formatTime(value), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
        ]
      ),
    );
  }

  Widget _buildElementNameWidget(Map<String, dynamic> timeData, int index, TimeLogController state) {
    bool isOutlier = timeData['type'] == 'outlier';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(timeData['name'], style: TextStyle(fontWeight: FontWeight.w500, color: isOutlier ? Colors.white54 : Colors.white, decoration: isOutlier ? TextDecoration.lineThrough : null)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => state.toggleElementType(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isOutlier ? Colors.redAccent.withValues(alpha: 0.15) : Colors.tealAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.5) : Colors.tealAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  isOutlier ? 'ATÍPICO' : 'NORMAL',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isOutlier ? Colors.redAccent : Colors.tealAccent, decoration: TextDecoration.none),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContinuousTable(TimeLogController state) {
    if (state.recordedTimesContinuo.isEmpty) return _buildEmptyState();
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.white10),
          child: DataTable(
            columnSpacing: 20, 
            headingRowColor: WidgetStateProperty.all(const Color(0xFF252525)), 
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent, fontSize: 12), 
            dataTextStyle: const TextStyle(fontSize: 13, color: Colors.white70),
            columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('ELEMENTO')), DataColumn(label: Text('TC (Acum)')), DataColumn(label: Text('TO (Indiv)')), DataColumn(label: Text(''))],
            rows: state.recordedTimesContinuo.asMap().entries.map((e) {
              bool isOutlier = e.value['type'] == 'outlier';
              return DataRow(
                onLongPress: () => _promptMerge(e.key, state), 
                color: WidgetStateProperty.all(isOutlier ? Colors.redAccent.withValues(alpha: 0.05) : null),
                cells: [
                  DataCell(Text('${e.key + 1}', style: const TextStyle(color: Colors.white38))), 
                  DataCell(_buildElementNameWidget(e.value, e.key, state)), 
                  DataCell(Text(state.formatTime((e.value['cumulative_time'] ?? 0).toDouble()), style: TextStyle(color: isOutlier ? Colors.white54 : Colors.white70))), 
                  DataCell(Text(state.formatTime(e.value['time'].toDouble()), style: TextStyle(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.7) : Colors.white))), 
                  DataCell(IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => state.deleteItem(e.key)))
                ]
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleRecordsList(TimeLogController state) {
    if (state.recordedTimesRegresoACero.isEmpty) return _buildEmptyState();
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16), 
      itemCount: state.recordedTimesRegresoACero.length, 
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final timeData = state.recordedTimesRegresoACero[index];
        bool isOutlier = timeData['type'] == 'outlier';
        
        return Container(
          decoration: BoxDecoration(
            color: isOutlier ? Colors.redAccent.withValues(alpha: 0.05) : const Color(0xFF252525), 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.2) : Colors.transparent),
          ),
          child: ListTile(
            onLongPress: () => _promptMerge(index, state), 
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), 
            leading: Text('${index + 1}', style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 16)), 
            title: _buildElementNameWidget(timeData, index, state),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text(state.formatTime(timeData['time'].toDouble()), style: TextStyle(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.7) : Colors.white70, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace')), 
                const SizedBox(width: 10), 
                IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.redAccent), onPressed: () => state.deleteItem(index))
              ]
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.hourglass_empty, size: 48, color: Colors.white10), SizedBox(height: 16), Text('Sin datos registrados', style: TextStyle(color: Colors.white24))]));
}