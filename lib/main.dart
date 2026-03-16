import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import 'app/app.dart';
import 'core/security/encryption_service.dart';
import 'core/security/secure_logger.dart';
import 'data/datasource/database_helper.dart';
import 'data/repositories/note_repository_impl.dart';
import 'presentation/controllers/note_controller.dart';
import 'presentation/pages/lock_page.dart';
import 'services/app_lock_service.dart';
import 'services/encryption_key_service.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Configure SQLCipher library loading ────────────────────
  _configureSqlCipher();

  // SECURITY: Suppress all debug prints in release builds.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // ── Initialize core security services ──────────────────────
  final secureStorage = SecureStorageService();
  final keyService = EncryptionKeyService(secureStorage);
  final lockService = AppLockService(secureStorage);
  
  await lockService.initialize();

  try {
    // 1. Get/Create the master database key
    final masterKey = await keyService.getOrCreateKey();
    
    // 2. Initialize the SQLCipher database
    final dbHelper = await DatabaseHelper.initialize(keyService);
    
    // 3. Initialize the Field Encryption Service (AES-GCM)
    final encryptionService = await EncryptionService.initialize(masterKey);
    
    // 4. Initialize Repository and run legacy migration
    final repository = NoteRepositoryImpl(dbHelper, encryptionService);
    
    // SECURITY: Potentially long-running migration of old plain-text notes.
    // Done in background to not block startup.
    repository.migrateLegacyNotes();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => lockService),
          ChangeNotifierProvider(create: (_) => NoteController(repository)),
        ],
        child: const SecureNotesApp(),
      ),
    );
  } catch (e) {
    SecureLogger.error('INIT', 'Critical initialization failure', e);
    runApp(_DatabaseErrorApp(errorMessage: e.toString()));
  }
}



void _configureSqlCipher() {
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  } else if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('sqlcipher.dll'));
  } else if (Platform.isMacOS) {
    open.overrideFor(OperatingSystem.macOS, () {
      try {
        return DynamicLibrary.open('../Frameworks/sqlcipher_flutter_libs.framework/Versions/A/sqlcipher_flutter_libs');
      } catch (_) {
        try {
          return DynamicLibrary.open('sqlcipher.dylib');
        } catch (_) {
          return DynamicLibrary.process();
        }
      }
    });
  } else if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlcipher.so'));
  }
}

class _DatabaseErrorApp extends StatelessWidget {
  final String? errorMessage;
  const _DatabaseErrorApp({this.errorMessage});

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
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.lock_outline, size: 48, color: Colors.red.shade400),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Security Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage ?? 'An internal security error occurred.',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
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
