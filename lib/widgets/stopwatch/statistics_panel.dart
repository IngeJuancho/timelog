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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final emerald = AppTheme.getTealAccent(context);

    final realData = state.activeRecordedTimes.where((e) => e['status'] != 'pending').toList();
    if (realData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats_rounded, size: 48, color: Theme.of(context).dividerColor),
            const SizedBox(height: 14),
            Text(
              'No hay registros para analizar aún',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final isCycle = state.isCycleStatistics;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con indicador de contexto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isCycle ? AppTheme.skyPrecision : emerald,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCycle ? 'ANÁLISIS POR CICLO COMPLETO' : 'MÉTRICAS GLOBALES DEL ESTUDIO',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: isCycle ? (isLight ? const Color(0xFF0284C7) : AppTheme.skyPrecision) : emerald,
                    ),
                  ),
                ],
              ),
              if (isCycle)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.skyPrecision.withValues(alpha: isLight ? 0.12 : 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.skyPrecision.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Text(
                    '${state.completedCycles} ciclos',
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w700, 
                      color: isLight ? const Color(0xFF0284C7) : AppTheme.skyPrecision,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Bento Grid: 4 KPIs Principales
          Row(
            children: [
              Expanded(
                child: _buildBentoCard(
                  context: context,
                  label: isCycle ? 'Promedio Ciclo' : 'Tiempo Promedio',
                  value: notifier.formatTime(state.averageTime),
                  color: isLight ? const Color(0xFF0284C7) : AppTheme.skyPrecision,
                  icon: Icons.speed_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBentoCard(
                  context: context,
                  label: isCycle ? 'Desv. Ciclo (σ)' : 'Desviación (σ)',
                  value: notifier.formatTime(state.stdDev),
                  color: AppTheme.amberIndustrial,
                  icon: Icons.stacked_line_chart_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildBentoCard(
                  context: context,
                  label: 'Tiempo Mínimo',
                  value: notifier.formatTime(state.minTime),
                  color: emerald,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBentoCard(
                  context: context,
                  label: 'Tiempo Máximo',
                  value: notifier.formatTime(state.maxTime),
                  color: AppTheme.crimsonOutlier,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),

          // Desglose analítico por elemento si hay plantilla activa
          if (isCycle && state.stepStatistics.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.view_timeline_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'DESGLOSE POR OPERACIÓN / ELEMENTO',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...state.stepStatistics.map((step) => _buildStepCard(context, step, notifier)),
          ],
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF14171E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isLight ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, StepStatistics step, TimeLogNotifier notifier) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: isLight ? 0.8 : 0.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF14171E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (isLight ? const Color(0xFF0284C7) : AppTheme.skyPrecision).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'n = ${step.sampleCount}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isLight ? const Color(0xFF0284C7) : AppTheme.skyPrecision,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepMiniMetric('Promedio', notifier.formatTime(step.averageTime), isLight ? const Color(0xFF0284C7) : AppTheme.skyPrecision),
              _buildStepMiniMetric('Desv.', notifier.formatTime(step.stdDev), AppTheme.amberIndustrial),
              _buildStepMiniMetric('Mín.', notifier.formatTime(step.minTime), AppTheme.getTealAccent(context)),
              _buildStepMiniMetric('Máx.', notifier.formatTime(step.maxTime), AppTheme.crimsonOutlier),
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
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w800, letterSpacing: 0.4),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
