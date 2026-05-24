// db_helper.dart
// Pure in-memory stub — replaces the old sqflite/ObjectBox DBHelper.
// All callers that did `await DBHelper.instance.warmUp()` compile fine.
// All data now lives in model in-memory caches backed by Firestore
// fire-and-forget writes — works fully offline.

class DBHelper {
  DBHelper._();
  static final DBHelper instance = DBHelper._();

  /// Called from main.dart: `await DBHelper.instance.warmUp()`
  /// Nothing to initialise — caches are populated lazily by the models.
  Future<void> warmUp() async {}

  /// Legacy accessor kept so any stray `.database` calls don't crash.
  Future<void> get database async {}
}