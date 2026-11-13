import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/time_log_calculator.dart';
import '../../time_log_controller.dart';
import '../../theme.dart';

class AnalysisViewWidget extends ConsumerWidget {
  const AnalysisViewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timeLogProvider);
    final notifier = ref.read(timeLogProvider.notifier);
    final minColor = AppTheme.getGreenAccent(context);
    final tealColor = AppTheme.getTealAccent(context);

    final realData = state.activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (realData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: Theme.of(context).dividerColor),
            const SizedBox(height: 16),
            Text(
              'Sin datos registrados',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.24)),
            ),
          ],
        ),
      );
    }

    final isCycle = state.isCycleStatistics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con indicador de contexto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCycle ? 'TIEMPO DE CICLO' : 'ESTADÍSTICAS DEL ESTUDIO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isCycle ? tealColor : Colors.blueAccent,
                ),
              ),
              if (isCycle)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tealColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tealColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${state.completedCycles} ciclos completos',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tealColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 KPIs principales de nivel superior
          Row(
            children: [
              Expanded(child: _buildStatBox(isCycle ? 'Promedio Ciclo' : 'Promedio', state.averageTime, Colors.blueAccent, notifier)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox(isCycle ? 'Desviación Ciclo' : 'Desviación', state.stdDev, Colors.orangeAccent, notifier)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatBox(isCycle ? 'Mínimo Ciclo' : 'Mínimo', state.minTime, minColor, notifier)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatBox(isCycle ? 'Máximo Ciclo' : 'Máximo', state.maxTime, Colors.redAccent, notifier)),
            ],
          ),

          // Desglose analítico por elemento si hay plantilla activa
          if (isCycle && state.stepStatistics.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Icon(Icons.format_list_bulleted_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'DESGLOSE POR ELEMENTO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...state.stepStatistics.map((step) => _buildStepCard(context, step, notifier)),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, StepStatistics step, TimeLogNotifier notifier) {
    final cardBg = Theme.of(context).cardColor;
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${step.stepIndex + 1}. ${step.stepName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'n = ${step.sampleCount}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepMiniMetric('Promedio', notifier.formatTime(step.averageTime), Colors.blueAccent),
              _buildStepMiniMetric('Desv.', notifier.formatTime(step.stdDev), Colors.orangeAccent),
              _buildStepMiniMetric('Mín.', notifier.formatTime(step.minTime), AppTheme.getGreenAccent(context)),
              _buildStepMiniMetric('Máx.', notifier.formatTime(step.maxTime), Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepMiniMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatBox(String label, double value, Color color, TimeLogNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(notifier.formatTime(value), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
