// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stopwatch_screen.dart';
import 'time_log_controller.dart';
import 'theme.dart';
// Llave global para poder mostrar SnackBars desde la lógica de Riverpod
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
  // ProviderScope es necesario para inicializar Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAmoled = ref.watch(timeLogProvider.select((s) => s.isAmoledMode));

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isAmoled ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'TimeLog',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: isAmoled ? AppTheme.amoledTheme : AppTheme.lightTheme,
      home: const StopwatchScreen(),
    );
  }
}