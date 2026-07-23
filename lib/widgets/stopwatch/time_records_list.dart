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

    // Auto-scroll logic
    ref.listen(timeLogProvider.select((s) => s.recordedTimesContinuo.length), (previous, next) {
      if (previous != null && next > previous) {
        Future.delayed(const Duration(milliseconds: 100), () {
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

    if (state.activeTemplate != null) {
      return _buildMatrixTable(context, state, notifier);
    } else {
      if (state.recordedTimesContinuo.isEmpty) return const EmptyStateWidget();
      return _buildLinearTable(context, state, notifier);
    }
  }

  Widget _buildLinearTable(BuildContext context, dynamic state, dynamic notifier) {
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

              return DataRow(
                onLongPress: isPending ? null : () => widget.onMergeRequest(e.key), 
                color: WidgetStateProperty.resolveWith((states) {
                  if (isActiveStep) return tealFill; 
                  if (isOutlier) return Colors.redAccent.withValues(alpha: 0.05);
                  return null;
                }),
                cells: [
                  DataCell(Text('${e.key + 1}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)))), 
                  DataCell(ElementNameWidget(timeData: e.value, index: e.key)), 
                  DataCell(Text(isPending ? '--:--.--' : notifier.formatTime((e.value['cumulative_time'] ?? 0).toDouble()), style: TextStyle(color: isOutlier ? Theme.of(context).textTheme.bodySmall?.color : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))))), 
                  DataCell(Text(isPending ? '--:--.--' : notifier.formatTime(e.value['time'].toDouble()), style: TextStyle(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.7) : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color)))), 
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
    if (numCycles == 0) numCycles = 1; // Mostrar al menos la columna C1 vacía
    
    final columns = <DataColumn>[
      const DataColumn(label: Text('ELEMENTO')),
    ];
    for (int i = 0; i < numCycles; i++) {
      final int cycleIndex = i;
      final int? assignedRating = cycleRatings[cycleIndex];
      columns.add(DataColumn(
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
    
    final rows = <DataRow>[];
    
    for (int elIndex = 0; elIndex < numElements; elIndex++) {
      final cells = <DataCell>[
        DataCell(Text(elements[elIndex], style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color))),
      ];
      
      for (int cycle = 0; cycle < numCycles; cycle++) {
        final recordIndex = cycle * numElements + elIndex;
        if (recordIndex < recordedTimes.length) {
          final record = recordedTimes[recordIndex];
          bool isOutlier = record['type'] == 'outlier';
          bool isPending = record['status'] == 'pending';
          
          cells.add(DataCell(
            GestureDetector(
              onLongPress: isPending ? null : () => widget.onMergeRequest(recordIndex),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    isPending ? '--:--.--' : notifier.formatTime(record['time'].toDouble()), 
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
          cells.add(const DataCell(Text('')));
        }
      }
      rows.add(DataRow(cells: cells));
    }
    
    // Add "Total Ciclo" row
    final totalCells = <DataCell>[
      DataCell(Text('TOTAL CICLO', style: TextStyle(fontWeight: FontWeight.bold, color: tealColor))),
    ];
    
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
            cycleTotal += record['time'].toDouble();
          }
        }
      }
      
      if (!hasValues && !hasPending) {
         totalCells.add(const DataCell(Text('')));
      } else {
         totalCells.add(DataCell(
           Text(
             hasPending ? '--:--.--' : notifier.formatTime(cycleTotal),
             style: TextStyle(fontWeight: FontWeight.bold, color: tealColor)
           )
         ));
      }
    }
    
    rows.add(DataRow(
       color: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest),
       cells: totalCells
    ));

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
            dataRowMaxHeight: 60,
            dataRowMinHeight: 45,
            headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHighest), 
            headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 12), 
            dataTextStyle: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
            columns: columns,
            rows: rows,
          ),
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

class SimpleRecordsListWidget extends ConsumerWidget {
  final ScrollController scrollController;
  final void Function(int) onMergeRequest;

  const SimpleRecordsListWidget({
    super.key, 
    required this.scrollController, 
    required this.onMergeRequest
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);
    final tealFill = AppTheme.getTealFill(context);

    if (state.recordedTimesRegresoACero.isEmpty) return const EmptyStateWidget();
    
    return SingleChildScrollView(
      controller: scrollController,
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

              return DataRow(
                onLongPress: isPending ? null : () => onMergeRequest(e.key),
                color: WidgetStateProperty.resolveWith((states) {
                  if (isActiveStep) return tealFill;
                  if (isOutlier) return Colors.redAccent.withValues(alpha: 0.05);
                  return null;
                }),
                cells: [
                  DataCell(Text('${e.key + 1}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5)))),
                  DataCell(ElementNameWidget(timeData: e.value, index: e.key)),
                  DataCell(Text(isPending ? '--:--.--' : notifier.formatTime(e.value['time'].toDouble()), style: TextStyle(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.7) : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color)))),
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
            Text(
              timeData['name'], 
              style: TextStyle(
                fontWeight: FontWeight.w500, 
                color: isOutlier ? Theme.of(context).textTheme.bodySmall?.color : (isPending ? Theme.of(context).disabledColor : Theme.of(context).textTheme.bodyMedium?.color), 
                decoration: isOutlier ? TextDecoration.lineThrough : null
              )
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
