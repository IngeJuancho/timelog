// lib/models.dart

enum StopwatchMode { regresoACero, continuo }

enum PhysicalButtonAction {
  none,
  startStop,      // Iniciar / Pausar
  lapSnapback,    // Vuelta (Regreso a Cero) o Lap (Continuo)
  stopAndRecord,  // Parar y Registrar
  reset           // Reiniciar Todo
}

enum HapticLevel { light, medium, heavy }

// Nuevo enum para el formato de visualización del tiempo
enum TimeFormat { standard, seconds, minutes }