import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Import Tables
import 'tables/partners.dart';
import 'tables/invoices.dart';
import 'tables/weighing_details.dart';
import 'tables/transactions.dart';

// Import DAOs
import 'daos/partners_dao.dart';
import 'daos/invoices_dao.dart';
import 'daos/weighing_details_dao.dart';
import 'daos/transactions_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Partners, Invoices, WeighingDetails, Transactions],
  daos: [PartnersDao, InvoicesDao, WeighingDetailsDao, TransactionsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      // Kích hoạt Foreign Keys cho SQLite
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // SỬA LỖI QUAN TRỌNG: Thêm dấu cách giữa final và dbFolder
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pig_scale.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}