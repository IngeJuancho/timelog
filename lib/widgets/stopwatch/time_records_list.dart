import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../time_log_controller.dart';
import '../../theme.dart';

class ContinuousTableWidget extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final void Function(int) onMergeRequest;

  const ContinuousTableWidget({
    super.key, 
    required this.scrollController, 
    required this.onMergeRequest
  });

  @override
  ConsumerState<ContinuousTableWidget> createState() => _ContinuousTableWidgetState();
}

class _ContinuousTableWidgetState extends ConsumerState<ContinuousTableWidget> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);

    // Auto-scroll logic inteligente para Modo Continuo
    ref.listen(timeLogProvider.select((s) => s.recordAddedTrigger), (previous, next) {
      if (previous != null && next > previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final currentState = ref.read(timeLogProvider);
          if (currentState.activeTemplate != null) {
            // Matriz por ciclo/elemento: scroll horizontal a la columna y vertical al elemento
            final numElements = currentState.activeTemplate!.steps.length;
            if (numElements > 0) {
              final lastIdx = currentState.lastRecordedIndex ?? (currentState.currentTemplateStepIndex - 1);
              if (lastIdx >= 0) {
                final cycleIndex = lastIdx ~/ numElements;
                final stepIndex = lastIdx % numElements;

                // 1. Desplazamiento horizontal para que la columna del ciclo sea 100% visible
                if (_horizontalController.hasClients) {
                  const colWidth = 88.0;
                  final colStart = cycleIndex * colWidth;
                  final colEnd = (cycleIndex + 1) * colWidth;
                  final currentX = _horizontalController.offset;
                  final viewportW = _horizontalController.position.viewportDimension;
                  final maxScroll = _horizontalController.position.maxScrollExtent;

                  if (colEnd > currentX + viewportW) {
                    final targetX = (colEnd - viewportW + 16.0).clamp(0.0, maxScroll);
                    _horizontalController.animateTo(
                      targetX,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  } else if (colStart < currentX) {
                    final targetX = colStart.clamp(0.0, maxScroll);
                    _horizontalController.animateTo(
                      targetX,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                }

                // 2. Desplazamiento vertical para enfocar la fila del elemento
                if (widget.scrollController.hasClients) {
                  const rowH = 56.0;
                  final rowY = 44.0 + (stepIndex * rowH);
                  final currentY = widget.scrollController.offset;
                  final viewportH = widget.scrollController.position.viewportDimension;
                  final maxScroll = widget.scrollController.position.maxScrollExtent;

                  if (rowY + rowH > currentY + viewportH || rowY < currentY) {
                    final targetY = (rowY - (viewportH / 2) + (rowH / 2)).clamp(0.0, maxScroll);
                    widget.scrollController.animateTo(
                      targetY,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                }
              }
            }
          } else {
            // Modo continuo lineal: autoscroll al último registro registrado
            if (widget.scrollController.hasClients) {
              widget.scrollController.animateTo(
                widget.scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            }
          }
        });
      }
    });

    if (state.activeTemplate != null) {
      return _buildMatrixTable(context, state, notifier);
    } else {
      if (state.recordedTimesContinuo.isEmpty) return const EmptyStateWidget();
      return _buildLinearTable(context, state, notifier);
    }
  }

  Widget _buildLinearTable(BuildContext context, dynamic state, dynamic notifier) {
    final tealColor = AppTheme.getTealAccent(context);
    final tealFill = AppTheme.getTealFill(context);

    return SingleChildScrollView(
      controller: widget.scrollController,
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Theme.of(context).dividerColor),
          child: DataTable(
            columnSpacing: 20, 
            headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest), 
            headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12), 
            dataTextStyle: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
            columns: const [
              DataColumn(label: Text('#')), 
              DataColumn(label: Text('ELEMENTO')), 
              DataColumn(label: Text('TC (Acum)')), 
              DataColumn(label: Text('TO (Indiv)')), 
              DataColumn(label: Text(''))
            ],
            rows: state.recordedTimesContinuo.asMap().entries.map<DataRow>((e) {
              bool isOutlier = e.value['type'] == 'outlier';
              bool isPending = e.value['status'] == 'pending';
              bool isActiveStep = state.activeTemplate != null && e.key == state.currentTemplateStepIndex;
              bool isJustRecorded = e.key == state.lastRecordedIndex;

              return DataRow(
                onLongPress: isPending ? null : () => widget.onMergeRequest(e.key), 
                color: WidgetStateProperty.resolveWith((states) {
                  if (isJustRecorded) return tealFill.withValues(alpha: 0.35);
                  if (isActiveStep) return tealFill; 
                  if (isOutlier) return Colors.redAccent.withValues(alpha: 0.05);
                  return null;
                }),
                cells: [
                  DataCell(Text(
                    '${e.key + 1}', 
                    style: TextStyle(
                      fontWeight: isJustRecorded ? FontWeight.bold : FontWeight.normal,
                      color: isJustRecorded 
                          ? tealColor 
                          : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  )), 
                  DataCell(ElementNameWidget(timeData: e.value, index: e.key)), 
                  DataCell(Text(
                    isPending ? '--:--.--' : notifier.formatTime((e.value['cumulative_time'] ?? 0).toDouble()), 
                    style: TextStyle(
                      fontWeight: isJustRecorded ? FontWeight.w600 : FontWeight.normal,
                      color: isOutlier ? Theme.of(context).textTheme.bodySmall?.color : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                    ),
                  )), 
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPending ? '--:--.--' : notifier.formatTime(e.value['time'].toDouble()), 
                        style: TextStyle(
                          fontWeight: isJustRecorded ? FontWeight.bold : FontWeight.normal,
                          color: isJustRecorded 
                              ? tealColor 
                              : (isOutlier ? Colors.redAccent.withValues(alpha: 0.7) : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color)),
                        ),
                      ),
                      if (isJustRecorded) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: tealColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: tealColor, width: 0.8),
                          ),
                          child: Text(
                            'NUEVO',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: tealColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )), 
                  DataCell(isPending ? const SizedBox.shrink() : IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => notifier.deleteItem(e.key)))
                ]
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixTable(BuildContext context, dynamic state, dynamic notifier) {
    final elements = state.activeTemplate!.steps;
    final int numElements = elements.length;
    final List<Map<String, dynamic>> recordedTimes = state.recordedTimesContinuo;
    final Map<int, int> cycleRatings = state.cycleRatingsCont as Map<int, int>;
    final tealColor = AppTheme.getTealAccent(context);
    final tealFill = AppTheme.getTealFill(context);
    final tealBorder = AppTheme.getTealBorder(context);

    int numCycles = (recordedTimes.length / numElements).ceil();
    if (numCycles == 0) numCycles = 1;

    final int? activeCycleIndex = state.lastRecordedIndex != null
        ? (state.lastRecordedIndex! ~/ numElements)
        : (state.currentTemplateStepIndex ~/ numElements);

    const double colHeaderHeight = 44.0;
    const double rowHeight = 56.0;
    const double totalRowHeight = 46.0;
    const double elementColWidth = 150.0;
    const double cycleColWidth = 88.0;

    return SingleChildScrollView(
      controller: widget.scrollController,
      scrollDirection: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================
          // 1. COLUMNA FIJA IZQUIERDA: NOMBRES DE ELEMENTOS
          // ============================================
          SizedBox(
            width: elementColWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabecera: ELEMENTO
                Container(
                  height: colHeaderHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    'ELEMENTO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
                // Filas de cada paso del template
                for (int elIndex = 0; elIndex < numElements; elIndex++) ...[
                  Container(
                    height: rowHeight,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (state.activeTemplate != null &&
                              (state.currentTemplateStepIndex % numElements) == elIndex &&
                              state.isRunning)
                          ? tealFill.withValues(alpha: 0.15)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${elIndex + 1}. ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            elements[elIndex],
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Fila Total Ciclo
                Container(
                  height: totalRowHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  child: Text(
                    'TOTAL CICLO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tealColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Borde divisor vertical entre columna fija y columnas de ciclos
          Container(
            width: 1,
            height: colHeaderHeight + 1 + (numElements * rowHeight) + totalRowHeight,
            color: Theme.of(context).dividerColor,
          ),
          // ============================================
          // 2. COLUMNAS SCROLLABLES DERECHA: CICLOS (C1, C2...)
          // ============================================
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int cycle = 0; cycle < numCycles; cycle++) ...[
                    _buildCycleColumn(
                      context: context,
                      cycle: cycle,
                      numElements: numElements,
                      recordedTimes: recordedTimes,
                      cycleRatings: cycleRatings,
                      notifier: notifier,
                      isCurrentCycle: cycle == activeCycleIndex,
                      tealColor: tealColor,
                      tealFill: tealFill,
                      tealBorder: tealBorder,
                      colHeaderHeight: colHeaderHeight,
                      rowHeight: rowHeight,
                      totalRowHeight: totalRowHeight,
                      cycleColWidth: cycleColWidth,
                      lastRecordedIndex: state.lastRecordedIndex,
                      currentTemplateStepIndex: state.currentTemplateStepIndex,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleColumn({
    required BuildContext context,
    required int cycle,
    required int numElements,
    required List<Map<String, dynamic>> recordedTimes,
    required Map<int, int> cycleRatings,
    required dynamic notifier,
    required bool isCurrentCycle,
    required Color tealColor,
    required Color tealFill,
    required Color tealBorder,
    required double colHeaderHeight,
    required double rowHeight,
    required double totalRowHeight,
    required double cycleColWidth,
    required int? lastRecordedIndex,
    required int currentTemplateStepIndex,
  }) {
    final int? assignedRating = cycleRatings[cycle];

    // Calcular total del ciclo
    double cycleTotal = 0;
    bool hasPending = false;
    bool hasValues = false;

    for (int elIndex = 0; elIndex < numElements; elIndex++) {
      final recordIndex = cycle * numElements + elIndex;
      if (recordIndex < recordedTimes.length) {
        final record = recordedTimes[recordIndex];
        if (record['status'] == 'pending') {
          hasPending = true;
        } else {
          hasValues = true;
          cycleTotal += (record['time'] as num).toDouble();
        }
      }
    }

    return Container(
      width: cycleColWidth,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Cabecera: C1, C2, etc. con calificación
          GestureDetector(
            onTap: () => _showCycleRatingDialog(context, notifier, cycle, assignedRating),
            child: Container(
              height: colHeaderHeight,
              alignment: Alignment.center,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'C${cycle + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isCurrentCycle ? tealColor : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (assignedRating != null)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: tealFill,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$assignedRating%',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: tealColor),
                      ),
                    )
                  else
                    Text('•', style: TextStyle(fontSize: 8, color: isCurrentCycle ? tealColor : Colors.grey)),
                ],
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
          // Celdas de cada elemento para este ciclo
          for (int elIndex = 0; elIndex < numElements; elIndex++) ...[
            _buildMatrixCell(
              context: context,
              cycle: cycle,
              elIndex: elIndex,
              numElements: numElements,
              recordedTimes: recordedTimes,
              notifier: notifier,
              rowHeight: rowHeight,
              tealColor: tealColor,
              tealFill: tealFill,
              tealBorder: tealBorder,
              lastRecordedIndex: lastRecordedIndex,
              currentTemplateStepIndex: currentTemplateStepIndex,
            ),
          ],
          // Celda Total Ciclo
          Container(
            height: totalRowHeight,
            alignment: Alignment.center,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            child: Text(
              (!hasValues && !hasPending)
                  ? ''
                  : (hasPending ? '--:--.--' : notifier.formatTime(cycleTotal)),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: tealColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixCell({
    required BuildContext context,
    required int cycle,
    required int elIndex,
    required int numElements,
    required List<Map<String, dynamic>> recordedTimes,
    required dynamic notifier,
    required double rowHeight,
    required Color tealColor,
    required Color tealFill,
    required Color tealBorder,
    required int? lastRecordedIndex,
    required int currentTemplateStepIndex,
  }) {
    final recordIndex = cycle * numElements + elIndex;
    if (recordIndex >= recordedTimes.length) {
      return Container(
        height: rowHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
      );
    }

    final record = recordedTimes[recordIndex];
    final bool isOutlier = record['type'] == 'outlier';
    final bool isPending = record['status'] == 'pending';
    final bool isJustRecorded = recordIndex == lastRecordedIndex;
    final bool isCurrentTiming = recordIndex == currentTemplateStepIndex && isPending;

    return GestureDetector(
      onLongPress: isPending ? null : () => widget.onMergeRequest(recordIndex),
      child: Container(
        height: rowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: isJustRecorded
              ? tealFill.withValues(alpha: 0.35)
              : (isCurrentTiming ? tealFill.withValues(alpha: 0.12) : Colors.transparent),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: 0.5,
            ),
            left: isJustRecorded ? BorderSide(color: tealColor, width: 2) : BorderSide.none,
            right: isJustRecorded ? BorderSide(color: tealColor, width: 2) : BorderSide.none,
            top: isJustRecorded ? BorderSide(color: tealColor, width: 2) : BorderSide.none,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPending ? '--:--.--' : notifier.formatTime((record['time'] as num).toDouble()),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isJustRecorded ? FontWeight.bold : FontWeight.w600,
                    color: isJustRecorded
                        ? tealColor
                        : (isOutlier
                            ? Colors.redAccent.withValues(alpha: 0.7)
                            : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color)),
                    decoration: isOutlier ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isJustRecorded) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.check_circle, size: 10, color: tealColor),
                ],
              ],
            ),
            if (!isPending) ...[
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => notifier.toggleElementType(recordIndex),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isOutlier ? Colors.redAccent.withValues(alpha: 0.15) : tealFill,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isOutlier ? Colors.redAccent.withValues(alpha: 0.5) : tealBorder,
                    ),
                  ),
                  child: Text(
                    isOutlier ? 'ATÍPICO' : 'NORMAL',
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      color: isOutlier ? Colors.redAccent : tealColor,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCycleRatingDialog(BuildContext context, dynamic notifier, int cycleIndex, int? currentRating) {
    final TextEditingController ctrl = TextEditingController(text: '${currentRating ?? 100}');
    final tealColor = AppTheme.getTealAccent(context);
    final tealFill = AppTheme.getTealFill(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star_rate_rounded, color: tealColor, size: 22),
            const SizedBox(width: 8),
            Text('Calificación — Ciclo ${cycleIndex + 1}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el porcentaje de calificación del operario para este ciclo:',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: tealColor),
              decoration: InputDecoration(
                suffixText: '%',
                suffixStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tealColor, width: 2)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tealFill,
              foregroundColor: tealColor,
              elevation: 0,
              side: BorderSide(color: tealColor, width: 1),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              int parsed = int.tryParse(ctrl.text) ?? 100;
              if (parsed < 1) parsed = 1;
              if (parsed > 200) parsed = 200;
              notifier.applyRatingToCycle(cycleIndex, parsed);
            },
            child: const Text('APLICAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class SimpleRecordsListWidget extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final void Function(int) onMergeRequest;

  const SimpleRecordsListWidget({
    super.key, 
    required this.scrollController, 
    required this.onMergeRequest
  });

  @override
  ConsumerState<SimpleRecordsListWidget> createState() => _SimpleRecordsListWidgetState();
}

class _SimpleRecordsListWidgetState extends ConsumerState<SimpleRecordsListWidget> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);
    final tealColor = AppTheme.getTealAccent(context);
    final tealFill = AppTheme.getTealFill(context);

    // Auto-scroll logic inteligente para Modo Regreso a Cero / Por Ciclo
    ref.listen(timeLogProvider.select((s) => s.recordAddedTrigger), (previous, next) {
      if (previous != null && next > previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !widget.scrollController.hasClients) return;
          widget.scrollController.animateTo(
            widget.scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        });
      }
    });

    if (state.recordedTimesRegresoACero.isEmpty) return const EmptyStateWidget();
    
    return SingleChildScrollView(
      controller: widget.scrollController,
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Theme.of(context).dividerColor),
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
            headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12),
            dataTextStyle: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('ELEMENTO')),
              DataColumn(label: Text('TIEMPO (TO)')), 
              DataColumn(label: Text('')),
            ],
            rows: state.recordedTimesRegresoACero.asMap().entries.map((e) {
              bool isOutlier = e.value['type'] == 'outlier';
              bool isPending = e.value['status'] == 'pending';
              bool isActiveStep = state.activeTemplate != null && e.key == state.currentTemplateStepIndex;
              bool isJustRecorded = e.key == state.lastRecordedIndex;

              return DataRow(
                onLongPress: isPending ? null : () => widget.onMergeRequest(e.key),
                color: WidgetStateProperty.resolveWith((states) {
                  if (isJustRecorded) return tealFill.withValues(alpha: 0.35);
                  if (isActiveStep) return tealFill;
                  if (isOutlier) return Colors.redAccent.withValues(alpha: 0.05);
                  return null;
                }),
                cells: [
                  DataCell(Text(
                    '${e.key + 1}', 
                    style: TextStyle(
                      fontWeight: isJustRecorded ? FontWeight.bold : FontWeight.normal,
                      color: isJustRecorded 
                          ? tealColor 
                          : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  )),
                  DataCell(ElementNameWidget(timeData: e.value, index: e.key)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPending ? '--:--.--' : notifier.formatTime(e.value['time'].toDouble()), 
                        style: TextStyle(
                          fontWeight: isJustRecorded ? FontWeight.bold : FontWeight.normal,
                          color: isJustRecorded 
                              ? tealColor 
                              : (isOutlier 
                                  ? Colors.redAccent.withValues(alpha: 0.7) 
                                  : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color)),
                        ),
                      ),
                      if (isJustRecorded) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: tealColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: tealColor, width: 0.8),
                          ),
                          child: Text(
                            'NUEVO',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: tealColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )),
                  DataCell(isPending ? const SizedBox.shrink() : IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => notifier.deleteItem(e.key)))
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class ElementNameWidget extends ConsumerWidget {
  final Map<String, dynamic> timeData;
  final int index;

  const ElementNameWidget({super.key, required this.timeData, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isOutlier = timeData['type'] == 'outlier';
    bool isPending = timeData['status'] == 'pending';
    final tealColor = AppTheme.getTealAccent(context);
    final tealFill = AppTheme.getTealFill(context);
    final tealBorder = AppTheme.getTealBorder(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                timeData['name'], 
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w500, 
                  color: isOutlier ? Theme.of(context).textTheme.bodySmall?.color : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color), 
                  decoration: isOutlier ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!isPending) GestureDetector(
              onTap: () => ref.read(timeLogProvider.notifier).toggleElementType(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isOutlier ? Colors.redAccent.withValues(alpha: 0.15) : tealFill,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.5) : tealBorder),
                ),
                child: Text(
                  isOutlier ? 'ATÍPICO' : 'NORMAL',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isOutlier ? Colors.redAccent : tealColor, decoration: TextDecoration.none),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(Icons.hourglass_empty, size: 48, color: Theme.of(context).dividerColor), 
          const SizedBox(height: 16), 
          Text('Sin datos registrados', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)))
        ]
      )
    );
  }
}
