// lib/calculator_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'time_log_controller.dart';

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
    // Uso de '.select' para evitar que la calculadora se redibuje 60 veces por segundo.
    // Solo se reconstruirá si el analista registra o borra un tiempo nuevo y cambian los promedios.
    final currentMean = ref.watch(timeLogProvider.select((s) => s.averageTime));
    final currentStdDev = ref.watch(timeLogProvider.select((s) => s.stdDev));
    final currentCount = ref.watch(timeLogProvider.select((s) => s.activeRecordedTimes.length));
    
    // Necesitamos el provider solo para llamar al método formatTime visualmente
    final controller = ref.read(timeLogProvider);

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
          _buildCard("Datos Actuales", [
            _row("Muestra (n')", "$currentCount"),
            _row("Promedio", controller.formatTime(currentMean)), 
            _row("Desviación", currentStdDev.toStringAsFixed(2)),
          ]),
          const SizedBox(height: 20),
          _buildCard("Parámetros", [
            const Text("Nivel de Confianza", style: TextStyle(color: Colors.white54, fontSize: 12)),
            DropdownButton<double>(
              isExpanded: true, 
              value: _confidenceLevel, 
              dropdownColor: const Color(0xFF333333), 
              underline: Container(height: 1, color: Colors.white24), 
              items: const [
                DropdownMenuItem(value: 0.90, child: Text("90%")), 
                DropdownMenuItem(value: 0.95, child: Text("95% (Estándar)")), 
                DropdownMenuItem(value: 0.99, child: Text("99%"))
              ], 
              onChanged: (v) {
                if (v != null) {
                  setState(() => _confidenceLevel = v);
                }
              }
            ),
            const SizedBox(height: 10),
            const Text("Margen de Error", style: TextStyle(color: Colors.white54, fontSize: 12)),
            DropdownButton<double>(
              isExpanded: true, 
              value: _errorMargin, 
              dropdownColor: const Color(0xFF333333), 
              underline: Container(height: 1, color: Colors.white24), 
              items: const [
                DropdownMenuItem(value: 0.01, child: Text("1%")), 
                DropdownMenuItem(value: 0.03, child: Text("3%")), 
                DropdownMenuItem(value: 0.05, child: Text("5% (Estándar)")), 
                DropdownMenuItem(value: 0.10, child: Text("10%"))
              ], 
              onChanged: (v) {
                if (v != null) {
                  setState(() => _errorMargin = v);
                }
              }
            ),
          ]),
          const SizedBox(height: 30),
          if(hasData) Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.teal.shade800, Colors.teal.shade600]), 
              borderRadius: BorderRadius.circular(24), 
              boxShadow: [
                BoxShadow(color: Colors.tealAccent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ),
            child: Column(children: [
              const Text("MUESTRA TOTAL (N)", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
              Text("$nCalculated", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              const Divider(color: Colors.white24, height: 30),
              Text(nAdditional > 0 ? "FALTAN: $nAdditional" : "¡COMPLETO!", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20), 
      decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(16)), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold)), 
          const SizedBox(height: 15), 
          ...children
        ]
      )
    );
  }
  
  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4), 
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Text(l, style: const TextStyle(color: Colors.white70)), 
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold))
      ]
    )
  );
  
  double _getTValue(int df, double confidence) {
    if (df < 1) {
      return 0;
    }
    if (df >= 30) {
      return confidence == 0.90 ? 1.645 : (confidence == 0.95 ? 1.960 : 2.576);
    }
    
    const tTable = {
      1: [6.314, 12.706, 63.657], 5: [2.015, 2.571, 4.032], 10: [1.812, 2.228, 3.169], 20: [1.725, 2.086, 2.845]
    };
    
    List<double>? values;
    if (tTable.containsKey(df)) {
      values = tTable[df];
    } else {
      for (int i = df; i >= 1; i--) {
        if (tTable.containsKey(i)) {
          values = tTable[i];
          break;
        }
      }
    }
    
    values ??= const [1.96, 1.96, 1.96]; 

    if (confidence == 0.90) {
      return values[0];
    }
    if (confidence == 0.95) {
      return values[1];
    }
    return values[2];
  }
}