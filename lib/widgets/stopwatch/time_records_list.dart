import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../time_log_controller.dart';

class ContinuousTableWidget extends ConsumerWidget {
  final ScrollController scrollController;
  final void Function(int) onMergeRequest;

  const ContinuousTableWidget({
    super.key, 
    required this.scrollController, 
    required this.onMergeRequest
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);
    
    if (state.recordedTimesContinuo.isEmpty) return const EmptyStateWidget();
    return SingleChildScrollView(
      controller: scrollController,
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
            columns: const [
              DataColumn(label: Text('#')), 
              DataColumn(label: Text('ELEMENTO')), 
              DataColumn(label: Text('TC (Acum)')), 
              DataColumn(label: Text('TO (Indiv)')), 
              DataColumn(label: Text(''))
            ],
            rows: state.recordedTimesContinuo.asMap().entries.map((e) {
              bool isOutlier = e.value['type'] == 'outlier';
              bool isPending = e.value['status'] == 'pending';
              bool isActiveStep = state.activeTemplate != null && e.key == state.currentTemplateStepIndex;

              return DataRow(
                onLongPress: isPending ? null : () => onMergeRequest(e.key), 
                color: WidgetStateProperty.resolveWith((states) {
                  if (isActiveStep) return Colors.tealAccent.withValues(alpha: 0.15); 
                  if (isOutlier) return Colors.redAccent.withValues(alpha: 0.05);
                  return null;
                }),
                cells: [
                  DataCell(Text('${e.key + 1}', style: const TextStyle(color: Colors.white38))), 
                  DataCell(ElementNameWidget(timeData: e.value, index: e.key)), 
                  DataCell(Text(isPending ? '--:--.--' : notifier.formatTime((e.value['cumulative_time'] ?? 0).toDouble()), style: TextStyle(color: isOutlier ? Colors.white54 : (isPending ? Colors.white38 : Colors.white70)))), 
                  DataCell(Text(isPending ? '--:--.--' : notifier.formatTime(e.value['time'].toDouble()), style: TextStyle(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.7) : (isPending ? Colors.white38 : Colors.white)))), 
                  DataCell(isPending ? const SizedBox.shrink() : IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.redAccent), onPressed: () => notifier.deleteItem(e.key)))
                ]
              );
            }).toList(),
          ),
        ),
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
    
    if (state.recordedTimesRegresoACero.isEmpty) return const EmptyStateWidget();
    
    return SingleChildScrollView(
      controller: scrollController,
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
                  if (isActiveStep) return Colors.tealAccent.withValues(alpha: 0.15);
                  if (isOutlier) return Colors.redAccent.withValues(alpha: 0.05);
                  return null;
                }),
                cells: [
                  DataCell(Text('${e.key + 1}', style: const TextStyle(color: Colors.white38))),
                  DataCell(ElementNameWidget(timeData: e.value, index: e.key)),
                  DataCell(Text(isPending ? '--:--.--' : notifier.formatTime(e.value['time'].toDouble()), style: TextStyle(color: isOutlier ? Colors.redAccent.withValues(alpha: 0.7) : (isPending ? Colors.white38 : Colors.white)))),
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
                color: isOutlier ? Colors.white54 : (isPending ? Colors.white60 : Colors.white), 
                decoration: isOutlier ? TextDecoration.lineThrough : null
              )
            ),
            const SizedBox(width: 8),
            if (!isPending) GestureDetector(
              onTap: () => ref.read(timeLogProvider.notifier).toggleElementType(index),
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
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(Icons.hourglass_empty, size: 48, color: Colors.white10), 
          SizedBox(height: 16), 
          Text('Sin datos registrados', style: TextStyle(color: Colors.white24))
        ]
      )
    );
  }
}
