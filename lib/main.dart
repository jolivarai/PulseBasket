import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'services/lock_screen_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fechas en español ("lun 3 nov") sin depender de la red.
  await initializeDateFormatting('es');

  // Registra los MethodChannel de la pantalla de bloqueo una sola vez.
  LockScreenService.init();

  // Abre (y siembra) la base de datos antes del primer frame: evita
  // parpadeos de "plan vacío" en la pantalla de inicio.
  await AppDatabase.instance.database;

  runApp(const ProviderScope(child: PulsoApp()));
}
