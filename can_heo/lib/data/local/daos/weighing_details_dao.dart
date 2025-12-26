import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/weighing_details.dart';

part 'weighing_details_dao.g.dart';

@DriftAccessor(tables: [WeighingDetails])
class WeighingDetailsDao extends DatabaseAccessor<AppDatabase> with _$WeighingDetailsDaoMixin {
  WeighingDetailsDao(AppDatabase db) : super(db);

  // Lấy chi tiết cân của 1 phiếu
  Stream<List<WeighingDetail>> watchDetailsByInvoice(String invoiceId) {
    return (select(weighingDetails)
      ..where((tbl) => tbl.invoiceId.equals(invoiceId))
      ..orderBy([(t) => OrderingTerm.desc(t.sequence)]))
      .watch();
  }

  // Thêm 1 mã cân mới
  Future<int> insertDetail(WeighingDetailsCompanion entry) {
    return into(weighingDetails).insert(entry);
  }

  // Xóa 1 mã cân
  Future<int> deleteDetail(String id) {
    return (delete(weighingDetails)..where((tbl) => tbl.id.equals(id))).go();
  }
  
  // Xóa tất cả chi tiết của 1 phiếu
  Future<int> deleteByInvoiceId(String invoiceId) {
    return (delete(weighingDetails)..where((tbl) => tbl.invoiceId.equals(invoiceId))).go();
  }
  
  // Tính tổng
  Future<Map<String, double>> getInvoiceTotals(String invoiceId) async {
    final weightQuery = selectOnly(weighingDetails)
      ..addColumns([weighingDetails.weight.sum(), weighingDetails.quantity.sum()])
      ..where(weighingDetails.invoiceId.equals(invoiceId));
      
    final result = await weightQuery.getSingle();
    
    // Xử lý null safety khi chưa có dữ liệu
    final totalWeight = result.read(weighingDetails.weight.sum()) ?? 0.0;
    final totalQty = result.read(weighingDetails.quantity.sum()) ?? 0;

    return {
      'totalWeight': totalWeight,
      'totalQuantity': totalQty.toDouble(),
    };
  }
}