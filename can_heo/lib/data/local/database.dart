import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:equatable/equatable.dart';

// Import Tables
import 'tables/partners.dart';
import 'tables/invoices.dart';
import 'tables/weighing_details.dart';
import 'tables/transactions.dart';
import 'tables/pig_types.dart';

// Import DAOs
import 'daos/partners_dao.dart';
import 'daos/invoices_dao.dart';
import 'daos/weighing_details_dao.dart';
import 'daos/transactions_dao.dart';
import 'daos/pig_types_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Partners, Invoices, WeighingDetails, Transactions, PigTypes],
  daos: [
    PartnersDao,
    InvoicesDao,
    WeighingDetailsDao,
    TransactionsDao,
    PigTypesDao
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5; // added paymentMethod to transactions

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          // Tạo toàn bộ bảng lần đầu
          await m.createAll();
        },

        // Nâng cấp DB khi schemaVersion thay đổi
        onUpgrade: (Migrator m, int from, int to) async {
          // Từ version 1 -> 2: Thêm các cột cho Partners
          if (from < 2) {
            try {
              await m.addColumn(partners, partners.code);
            } catch (_) {}
            try {
              await m.addColumn(partners, partners.isSupplier);
            } catch (_) {}
            try {
              await m.addColumn(partners, partners.currentDebt);
            } catch (_) {}
          }

          // Từ version 2 -> 3: Thêm batchNumber & pigType cho WeighingDetails
          if (from < 3) {
            try {
              await m.addColumn(weighingDetails, weighingDetails.batchNumber);
            } catch (_) {}
            try {
              await m.addColumn(weighingDetails, weighingDetails.pigType);
            } catch (_) {}
          }

          // Từ version 3 -> 4: Tạo bảng PigTypes mới
          if (from < 4) {
            try {
              await m.createTable(pigTypes);
            } catch (_) {}
          }

          // Từ version 4 -> 5: Thêm cột paymentMethod cho Transactions
          if (from < 5) {
            try {
              await m.addColumn(transactions, transactions.paymentMethod);
            } catch (_) {}
          }
        },

        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Đảm bảo cột payment_method tồn tại
          try {
            await customStatement(
                'ALTER TABLE transactions ADD COLUMN payment_method INTEGER NOT NULL DEFAULT 0');
          } catch (_) {
            // Cột đã tồn tại, bỏ qua
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'pig_scale.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

abstract class WeighingEvent extends Equatable {
  const WeighingEvent();

  @override
  List<Object?> get props => [];
}

/// Bắt đầu 1 phiếu mới
/// [invoiceType] : 1 = Nhập kho, 2 = Xuất chợ...
class WeighingStarted extends WeighingEvent {
  final int invoiceType;

  const WeighingStarted(this.invoiceType);

  @override
  List<Object?> get props => [invoiceType];
}

/// Thêm 1 lần cân vào phiếu
class WeighingItemAdded extends WeighingEvent {
  final double weight;
  final int quantity;
  final String? batchNumber; // Mới: số lô
  final String? pigType; // Mới: loại heo

  const WeighingItemAdded({
    required this.weight,
    this.quantity = 1,
    this.batchNumber,
    this.pigType,
  });

  @override
  List<Object?> get props => [weight, quantity, batchNumber, pigType];
}

/// Xoá 1 lần cân
class WeighingItemRemoved extends WeighingEvent {
  final String itemId;

  const WeighingItemRemoved(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

/// Cập nhật thông tin phiếu (khách, giá, cước)
class WeighingInvoiceUpdated extends WeighingEvent {
  final String? partnerId;
  final String? partnerName;
  final double? pricePerKg;
  final double? truckCost;

  const WeighingInvoiceUpdated({
    this.partnerId,
    this.partnerName,
    this.pricePerKg,
    this.truckCost,
  });

  @override
  List<Object?> get props => [partnerId, partnerName, pricePerKg, truckCost];
}

/// Lưu phiếu xuống DB
class WeighingSaved extends WeighingEvent {
  const WeighingSaved();
}

/// [INTERNAL] Sự kiện nội bộ: Khi Bloc nhận được dữ liệu từ Stream của ScaleService
class WeighingScaleDataReceived extends WeighingEvent {
  final double weight;
  final bool isConnected;

  const WeighingScaleDataReceived({
    required this.weight,
    required this.isConnected,
  });

  @override
  List<Object?> get props => [weight, isConnected];
}
