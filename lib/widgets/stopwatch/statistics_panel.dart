import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../time_log_controller.dart';

class AnalysisViewWidget extends ConsumerWidget {
  const AnalysisViewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);

    final realData = state.activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (realData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: Theme.of(context).dividerColor), 
            const SizedBox(height: 16), 
            Text('Sin datos registrados', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.24)))
          ]
        )
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _buildStatBox('Promedio', state.averageTime, Colors.blueAccent, notifier)), 
            const SizedBox(width: 12), 
            Expanded(child: _buildStatBox('Desviación', state.stdDev, Colors.orangeAccent, notifier))
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildStatBox('Mínimo', state.minTime, Colors.greenAccent, notifier)), 
            const SizedBox(width: 12), 
            Expanded(child: _buildStatBox('Máximo', state.maxTime, Colors.redAccent, notifier))
          ]),
        ]));
  }

  Widget _buildStatBox(String label, double value, Color color, TimeLogNotifier notifier) {
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
          Text(notifier.formatTime(value), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
        ]
      ));
  }
}
