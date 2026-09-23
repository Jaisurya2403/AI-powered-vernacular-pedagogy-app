import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

void initDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
