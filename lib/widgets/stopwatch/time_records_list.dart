import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models.dart';
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

    // Auto-scroll logic
    ref.listen(timeLogProvider.select((s) => s.activeRecordedTimes.where((e) => e['status'] != 'pending').length), (previous, next) {
      if (previous != null && next > previous) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          if (_horizontalController.hasClients) {
            _horizontalController.animateTo(
              _horizontalController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
          if (widget.scrollController.hasClients) {
            double targetY = widget.scrollController.position.maxScrollExtent;
            if (state.activeTemplate != null && state.activeTemplate!.steps.isNotEmpty) {
               int activeRow = state.currentTemplateStepIndex % state.activeTemplate!.steps.length;
               targetY = (activeRow * 52.0).clamp(0.0, widget.scrollController.position.maxScrollExtent);
            }
            widget.scrollController.animateTo(
              targetY,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    if (state.activeTemplate != null) {
      return _buildMatrixTable(context, state, notifier);
    } else {
      if (state.activeRecordedTimes.isEmpty) return const EmptyStateWidget();
      return _buildLinearTable(context, state, notifier);
    }
  }

  Widget _buildLinearTable(BuildContext context, dynamic state, dynamic notifier) {
    final tealFill = AppTheme.getTealFill(context);

    const fixedColumns = [
      DataColumn(label: Text('#')), 
      DataColumn(label: Text('ELEMENTO')), 
    ];

    const scrollableColumns = [
      DataColumn(label: Text('TC (Acum)')), 
      DataColumn(label: Text('TO (Indiv)')), 
      DataColumn(label: Text(''))
    ];

    final fixedRows = <DataRow>[];
    final scrollableRows = <DataRow>[];

    for (int i = 0; i < state.recordedTimesContinuo.length; i++) {
      final e = state.recordedTimesContinuo[i];
      bool isOutlier = e['type'] == 'outlier';
      bool isPending = e['status'] == 'pending';
      bool isActiveStep = state.activeTemplate != null && i == state.currentTemplateStepIndex;

      final color = WidgetStateProperty.resolveWith((states) {
        if (isActiveStep) return tealFill; 
        if (isOutlier) return Colors.redAccent.withValues(alpha: 0.05);
        return null;
      });

      fixedRows.add(DataRow(
        onLongPress: isPending ? null : () => widget.onMergeRequest(i), 
        color: color,
        cells: [
          DataCell(Text('${i + 1}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)))), 
          DataCell(ElementNameWidget(timeData: e, index: i)), 
        ],
      ));

      scrollableRows.add(DataRow(
        onLongPress: isPending ? null : () => widget.onMergeRequest(i), 
        color: color,
        cells: [
          DataCell(Text(isPending ? '--:--.--' : notifier.formatTime(((e['cumulative_time'] as num?)?.toDouble() ?? 0.0)), style: TextStyle(color: isOutlier ? Theme.of(context).textTheme.bodySmall?.color : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))))), 
          DataCell(Text(isPending ? '--:--.--' : notifier.formatTime(((e['time'] as num?)?.toDouble() ?? 0.0)), style: TextStyle(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.7) : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color)))), 
          DataCell(isPending ? const SizedBox.shrink() : IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => notifier.deleteItem(i)))
        ],
      ));
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      scrollDirection: Axis.vertical,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Theme.of(context).dividerColor),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 2.0)),
              ),
              child: DataTable(
                columnSpacing: 20, 
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                headingRowHeight: 48,
                headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest), 
                headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12), 
                dataTextStyle: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                columns: fixedColumns,
                rows: fixedRows,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20, 
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 60,
                  headingRowHeight: 48,
                  headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest), 
                  headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12), 
                  dataTextStyle: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                  columns: scrollableColumns,
                  rows: scrollableRows,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixTable(BuildContext context, dynamic state, dynamic notifier) {
    final elements = state.activeTemplate!.steps;
    final int numElements = elements.isNotEmpty ? elements.length : 1;
    final List<Map<String, dynamic>> recordedTimes = state.activeRecordedTimes;
    final Map<int, int> cycleRatings = (state.currentMode == StopwatchMode.regresoACero
        ? state.cycleRatingsRAC
        : state.cycleRatingsCont) as Map<int, int>;
    final tealColor = AppTheme.getTealAccent(context);
    final tealFill = AppTheme.getTealFill(context);
    final tealBorder = AppTheme.getTealBorder(context);
    
    int numCycles = (recordedTimes.length / numElements).ceil();
    if (numCycles == 0) numCycles = 1; // Mostrar al menos la columna C1 vacía
    
    final fixedColumns = <DataColumn>[
      const DataColumn(
        label: SizedBox(
          width: 140,
          child: Text('ELEMENTO', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ];
    
    final scrollableColumns = <DataColumn>[];
    for (int i = 0; i < numCycles; i++) {
      final int cycleIndex = i;
      final int? assignedRating = cycleRatings[cycleIndex];
      scrollableColumns.add(DataColumn(
        label: GestureDetector(
          onTap: () => _showCycleRatingDialog(context, notifier, cycleIndex, assignedRating),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('C${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              if (assignedRating != null)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
                Text('•', style: TextStyle(fontSize: 8, color: tealColor)),
            ],
          ),
        ),
      ));
    }
    
    final fixedRows = <DataRow>[];
    final scrollableRows = <DataRow>[];
    
    for (int elIndex = 0; elIndex < numElements; elIndex++) {
      final fixedCells = <DataCell>[
        DataCell(
          SizedBox(
            width: 140,
            child: Text(
              elements[elIndex],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ),
        ),
      ];
      
      final scrollableCells = <DataCell>[];
      for (int cycle = 0; cycle < numCycles; cycle++) {
        final recordIndex = cycle * numElements + elIndex;
        if (recordIndex < recordedTimes.length) {
          final record = recordedTimes[recordIndex];
          bool isOutlier = record['type'] == 'outlier';
          bool isPending = record['status'] == 'pending';
          
          scrollableCells.add(DataCell(
            GestureDetector(
              onLongPress: isPending ? null : () => widget.onMergeRequest(recordIndex),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    isPending ? '--:--.--' : notifier.formatTime(((record['time'] as num?)?.toDouble() ?? 0.0)), 
                    style: TextStyle(
                      color: isOutlier ? Colors.redAccent.withValues(alpha: 0.7) : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color),
                      decoration: isOutlier ? TextDecoration.lineThrough : null,
                    )
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
                            border: Border.all(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.5) : tealBorder),
                          ),
                          child: Text(
                            isOutlier ? 'ATÍPICO' : 'NORMAL',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isOutlier ? Colors.redAccent : tealColor, decoration: TextDecoration.none),
                          ),
                        ),
                      ),
                  ]
                ]
              )
            )
          ));
        } else {
          scrollableCells.add(const DataCell(Text('')));
        }
      }
      fixedRows.add(DataRow(cells: fixedCells));
      scrollableRows.add(DataRow(cells: scrollableCells));
    }
    
    // Add "Total Ciclo" row
    final fixedTotalCells = <DataCell>[
      DataCell(
        SizedBox(
          width: 140,
          child: Text('TOTAL CICLO', style: TextStyle(fontWeight: FontWeight.bold, color: tealColor)),
        ),
      ),
    ];
    
    final scrollableTotalCells = <DataCell>[];
    for (int cycle = 0; cycle < numCycles; cycle++) {
      double cycleTotal = 0;
      bool hasPending = false;
      bool hasValues = false;

      for (int elIndex = 0; elIndex < numElements; elIndex++) {
        final recordIndex = cycle * numElements + elIndex;
        if (recordIndex < recordedTimes.length) {
          final record = recordedTimes[recordIndex];
          bool isPending = record['status'] == 'pending';
          
          if (isPending) {
            hasPending = true;
          } else {
            hasValues = true;
            cycleTotal += ((record['time'] as num?)?.toDouble() ?? 0.0);
          }
        }
      }
      
      if (!hasValues && !hasPending) {
         scrollableTotalCells.add(const DataCell(Text('')));
      } else {
         scrollableTotalCells.add(DataCell(
           Text(
             hasPending ? '--:--.--' : notifier.formatTime(cycleTotal),
             style: TextStyle(fontWeight: FontWeight.bold, color: tealColor)
           )
         ));
      }
    }
    
    fixedRows.add(DataRow(
       color: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
       cells: fixedTotalCells
    ));
    scrollableRows.add(DataRow(
       color: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
       cells: scrollableTotalCells
    ));

    return SingleChildScrollView(
      controller: widget.scrollController,
      scrollDirection: Axis.vertical,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Theme.of(context).dividerColor),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 2.0)),
              ),
              child: DataTable(
                columnSpacing: 20, 
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                headingRowHeight: 48,
                headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest), 
                headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12), 
                dataTextStyle: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                columns: fixedColumns,
                rows: fixedRows,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20, 
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 52,
                  headingRowHeight: 48,
                  headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest), 
                  headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12), 
                  dataTextStyle: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                  columns: scrollableColumns,
                  rows: scrollableRows,
                ),
              ),
            ),
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
    final tealFill = AppTheme.getTealFill(context);

    // Si hay plantilla activa, delegamos a ContinuousTableWidget que maneja la matriz y 2D scroll
    if (state.activeTemplate != null) {
      return ContinuousTableWidget(
        scrollController: widget.scrollController,
        onMergeRequest: widget.onMergeRequest,
      );
    }

    // Auto-scroll logic en 2D (horizontal y vertical) para Regreso a Cero
    ref.listen(timeLogProvider.select((s) => s.recordedTimesRegresoACero.length), (previous, next) {
      if (previous != null && next > previous) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          if (_horizontalController.hasClients) {
            _horizontalController.animateTo(
              _horizontalController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
          if (widget.scrollController.hasClients) {
            widget.scrollController.animateTo(
              widget.scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    if (state.recordedTimesRegresoACero.isEmpty) return const EmptyStateWidget();
    
    const fixedColumns = [
      DataColumn(label: Text('#')),
      DataColumn(label: Text('ELEMENTO')),
    ];

    const scrollableColumns = [
      DataColumn(label: Text('TIEMPO (TO)')), 
      DataColumn(label: Text('')),
    ];

    final fixedRows = <DataRow>[];
    final scrollableRows = <DataRow>[];

    for (int i = 0; i < state.recordedTimesRegresoACero.length; i++) {
      final e = state.recordedTimesRegresoACero[i];
      bool isOutlier = e['type'] == 'outlier';
      bool isPending = e['status'] == 'pending';
      bool isActiveStep = state.activeTemplate != null && i == state.currentTemplateStepIndex;

      final color = WidgetStateProperty.resolveWith((states) {
        if (isActiveStep) return tealFill;
        if (isOutlier) return Colors.redAccent.withValues(alpha: 0.05);
        return null;
      });

      fixedRows.add(DataRow(
        onLongPress: isPending ? null : () => widget.onMergeRequest(i),
        color: color,
        cells: [
          DataCell(Text('${i + 1}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)))),
          DataCell(ElementNameWidget(timeData: e, index: i)),
        ],
      ));

      scrollableRows.add(DataRow(
        onLongPress: isPending ? null : () => widget.onMergeRequest(i),
        color: color,
        cells: [
          DataCell(Text(isPending ? '--:--.--' : notifier.formatTime(((e['time'] as num?)?.toDouble() ?? 0.0)), style: TextStyle(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.7) : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color)))),
          DataCell(isPending ? const SizedBox.shrink() : IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => notifier.deleteItem(i)))
        ],
      ));
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      scrollDirection: Axis.vertical,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Theme.of(context).dividerColor),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 2.0)),
              ),
              child: DataTable(
                columnSpacing: 20,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                headingRowHeight: 48,
                headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
                headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12),
                dataTextStyle: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                columns: fixedColumns,
                rows: fixedRows,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 60,
                  headingRowHeight: 48,
                  headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
                  headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12),
                  dataTextStyle: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                  columns: scrollableColumns,
                  rows: scrollableRows,
                ),
              ),
            ),
          ],
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
            SizedBox(
              width: 140,
              child: Text(
                timeData['name'], 
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w500, 
                  color: isOutlier ? Theme.of(context).textTheme.bodySmall?.color : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color), 
                  decoration: isOutlier ? TextDecoration.lineThrough : null
                )
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
