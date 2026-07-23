// lib/calculator_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'time_log_controller.dart';
import 'theme.dart';

class SampleCalculatorScreen extends ConsumerStatefulWidget {
  const SampleCalculatorScreen({super.key});
  @override
  ConsumerState<SampleCalculatorScreen> createState() => _SampleCalculatorScreenState();
}

class _SampleCalculatorScreenState extends ConsumerState<SampleCalculatorScreen> {
  double _confidenceLevel = 0.95; 
  double _errorMargin = 0.05;

  @override
  Widget build(BuildContext context) {
    final currentMean = ref.watch(timeLogProvider.select((s) => s.averageTime));
    final currentStdDev = ref.watch(timeLogProvider.select((s) => s.stdDev));
    final currentCount = ref.watch(timeLogProvider.select((s) => s.activeRecordedTimes.where((e) => (e['type'] ?? 'normal') != 'outlier' && (e['time'] as int) > 0 && e['status'] != 'pending').length));
    
    final controller = ref.read(timeLogProvider.notifier);
    final tealColor = AppTheme.getTealAccent(context);
    final cardBg = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;
    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    bool hasData = currentCount >= 2;
    int nCalculated = 0; 
    int nAdditional = 0;
    
    if (hasData && currentMean > 0) {
      double tValue = _getTValue(currentCount - 1, _confidenceLevel);
      double nResult = pow((tValue * currentStdDev) / (_errorMargin * currentMean), 2).toDouble();
      nCalculated = nResult.ceil(); 
      nAdditional = max(0, nCalculated - currentCount);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora Muestra'), backgroundColor: Colors.transparent, centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildCard(context, cardBg, tealColor, "Datos Actuales", [
            _row(context, "Muestra válida (n')", "$currentCount", textColor, subtitleColor),
            _row(context, "Promedio", controller.formatTime(currentMean), textColor, subtitleColor), 
            _row(context, "Desviación Estándar", currentStdDev.toStringAsFixed(2), textColor, subtitleColor),
          ]),
          const SizedBox(height: 20),
          _buildCard(context, cardBg, tealColor, "Parámetros", [
            Text("Nivel de Confianza", style: TextStyle(color: subtitleColor, fontSize: 12)),
            DropdownButton<double>(
              isExpanded: true, 
              value: _confidenceLevel, 
              dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest, 
              underline: Container(height: 1, color: Theme.of(context).dividerColor), 
              items: [
                DropdownMenuItem(value: 0.90, child: Text("90%", style: TextStyle(color: textColor))), 
                DropdownMenuItem(value: 0.95, child: Text("95% (Estándar)", style: TextStyle(color: textColor))), 
                DropdownMenuItem(value: 0.99, child: Text("99%", style: TextStyle(color: textColor))),
              ], 
              onChanged: (v) {
                if (v != null) {
                  setState(() => _confidenceLevel = v);
                }
              }
            ),
            const SizedBox(height: 10),
            Text("Margen de Error", style: TextStyle(color: subtitleColor, fontSize: 12)),
            DropdownButton<double>(
              isExpanded: true, 
              value: _errorMargin, 
              dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest, 
              underline: Container(height: 1, color: Theme.of(context).dividerColor), 
              items: [
                DropdownMenuItem(value: 0.01, child: Text("1%", style: TextStyle(color: textColor))), 
                DropdownMenuItem(value: 0.03, child: Text("3%", style: TextStyle(color: textColor))), 
                DropdownMenuItem(value: 0.05, child: Text("5% (Estándar)", style: TextStyle(color: textColor))), 
                DropdownMenuItem(value: 0.10, child: Text("10%", style: TextStyle(color: textColor))),
              ], 
              onChanged: (v) {
                if (v != null) {
                  setState(() => _errorMargin = v);
                }
              }
            ),
          ]),
          const SizedBox(height: 30),
          if (hasData) Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.teal.shade800, Colors.teal.shade600]), 
              borderRadius: BorderRadius.circular(24), 
              boxShadow: [
                BoxShadow(color: Colors.tealAccent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: Column(children: [
              const Text("MUESTRA TOTAL REQUERIDA (N)", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("$nCalculated", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              const Divider(color: Colors.white24, height: 30),
              Text(nAdditional > 0 ? "FALTAN: $nAdditional CICLOS" : "¡MUESTRA COMPLETA!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Color bg, Color accent, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2))), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title.toUpperCase(), style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)), 
          const SizedBox(height: 15), 
          ...children
        ]
      )
    );
  }
  
  Widget _row(BuildContext context, String l, String v, Color textColor, Color subtitleColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6), 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Text(l, style: TextStyle(color: subtitleColor)), 
        Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))
      ]
    )
  );
  
  double _getTValue(int df, double confidence) {
    if (df < 1) return 0;
    if (df >= 30) {
      return confidence == 0.90 ? 1.645 : (confidence == 0.95 ? 1.960 : 2.576);
    }
    
    // Tabla t de Student exacta para grados de libertad de 1 a 30 [90%, 95%, 99%]
    const tTable = {
      1: [6.314, 12.706, 63.657],
      2: [2.920, 4.303, 9.925],
      3: [2.353, 3.182, 5.841],
      4: [2.132, 2.776, 4.604],
      5: [2.015, 2.571, 4.032],
      6: [1.943, 2.447, 3.707],
      7: [1.895, 2.365, 3.499],
      8: [1.860, 2.306, 3.355],
      9: [1.833, 2.262, 3.250],
      10: [1.812, 2.228, 3.169],
      11: [1.796, 2.201, 3.106],
      12: [1.782, 2.179, 3.055],
      13: [1.771, 2.160, 3.012],
      14: [1.761, 2.145, 2.977],
      15: [1.753, 2.131, 2.947],
      16: [1.746, 2.120, 2.921],
      17: [1.740, 2.110, 2.898],
      18: [1.734, 2.101, 2.878],
      19: [1.729, 2.093, 2.861],
      20: [1.725, 2.086, 2.845],
      21: [1.721, 2.080, 2.831],
      22: [1.717, 2.074, 2.819],
      23: [1.714, 2.069, 2.807],
      24: [1.711, 2.064, 2.797],
      25: [1.708, 2.060, 2.787],
      26: [1.706, 2.056, 2.779],
      27: [1.703, 2.052, 2.771],
      28: [1.701, 2.048, 2.763],
      29: [1.699, 2.045, 2.756],
      30: [1.697, 2.042, 2.750],
    };
    
    final values = tTable[df] ?? const [1.96, 1.96, 1.96]; 

    if (confidence == 0.90) return values[0];
    if (confidence == 0.95) return values[1];
    return values[2];
  }
}
