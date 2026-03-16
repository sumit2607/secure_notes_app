/// Application entry point.
///
/// Initializes:
/// 1. SQLCipher native library loading for the current platform.
/// 2. Encryption key service (generates or retrieves DB key).
/// 3. Encrypted database connection.
/// 4. Repository and controller wiring via Provider.
///
/// SECURITY: Debug output is suppressed in release mode to prevent
/// accidental information leakage through console logs.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import 'app/app.dart';
import 'data/datasource/database_helper.dart';
import 'data/repositories/note_repository_impl.dart';
import 'presentation/controllers/note_controller.dart';
import 'services/encryption_key_service.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Configure SQLCipher library loading ────────────────────
  _configureSqlCipher();

  // SECURITY: Suppress debug prints in release builds to prevent
  // accidental information leakage via console output.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // ── Initialize services ────────────────────────────────────
  final secureStorage = SecureStorageService();
  final keyService = EncryptionKeyService(secureStorage);

  try {
    final dbHelper = await DatabaseHelper.initialize(keyService);
    final repository = NoteRepositoryImpl(dbHelper);

    runApp(
      ChangeNotifierProvider(
        create: (_) => NoteController(repository),
        child: const SecureNotesApp(),
      ),
    );
  } catch (e) {
    // SECURITY: Do not expose internal error details to the UI.
    // The error app shows a generic, safe message.
    debugPrint('[INIT] Application failed to start: ${e.runtimeType}');
    runApp(const _DatabaseErrorApp());
  }
}

void _configureSqlCipher() {
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  } else if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('sqlcipher.dll'));
  } else if (Platform.isMacOS) {
    open.overrideFor(OperatingSystem.macOS, () => DynamicLibrary.open('sqlcipher.dylib'));
  } else if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlcipher.so'));
  }
}

/// Fallback app displayed when database initialization fails.
class _DatabaseErrorApp extends StatelessWidget {
  const _DatabaseErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Database Initialization Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'The secure database could not be opened.\n'
                  'Please restart the application. If the problem '
                  'persists, the database file may be corrupted.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
