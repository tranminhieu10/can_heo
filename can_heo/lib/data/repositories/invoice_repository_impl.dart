import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/repositories/i_invoice_repository.dart';
import '../local/database.dart';

class InvoiceRepositoryImpl implements IInvoiceRepository {
  final AppDatabase _db;

  InvoiceRepositoryImpl(this._db);

  @override
  Stream<List<InvoiceEntity>> watchInvoices({
    required int type,
    String? keyword,
    int? daysAgo,
  }) {
    DateTime? fromDate;

    // Tính toán ngày bắt đầu dựa trên daysAgo
    if (daysAgo != null) {
      final now = DateTime.now();
      final start = daysAgo == 0
          ? DateTime(now.year, now.month, now.day)
          : now.subtract(Duration(days: daysAgo));
      fromDate = start;
    }

    // We need to include at least the first detail (batch/pigType) so UI can show
    // Số lô / Loại heo in the saved-invoices grid. Use asyncMap so we can
    // fetch the first weighing detail per invoice.
    return _db.invoicesDao
        .watchInvoicesFiltered(
          type: type,
          keyword: keyword,
          fromDate: fromDate,
        )
        .asyncMap((rows) async {
      final results = <InvoiceEntity>[];
      for (final row in rows) {
        // Try to read the first detail (sequence asc) for this invoice
        final firstDetail = await (_db.select(_db.weighingDetails)
              ..where((t) => t.invoiceId.equals(row.invoice.id))
              ..orderBy([(t) => OrderingTerm.asc(t.sequence)])
              ..limit(1))
            .getSingleOrNull();

        final details = <WeighingItemEntity>[];
        if (firstDetail != null) {
          details.add(WeighingItemEntity(
            id: firstDetail.id,
            sequence: firstDetail.sequence,
            weight: firstDetail.weight,
            quantity: firstDetail.quantity,
            time: firstDetail.weighingTime,
            batchNumber: firstDetail.batchNumber,
            pigType: firstDetail.pigType,
          ));
        }

        results.add(InvoiceEntity(
          id: row.invoice.id,
          invoiceCode: row.invoice.invoiceCode,
          partnerId: row.partner?.id,
          partnerName: row.partner?.name ?? 'Khách lẻ',
          type: row.invoice.type,
          createdDate: row.invoice.createdDate,
          totalWeight: row.invoice.totalWeight,
          totalQuantity: row.invoice.totalQuantity,
          pricePerKg: row.invoice.pricePerKg,
          deduction: row.invoice.truckCost, // Read deduction directly
          discount: row.invoice.discount,
          finalAmount: row.invoice.finalAmount,
          paidAmount: row.invoice.paidAmount,
          note: row.invoice.note,
          details: details,
        ));
      }

      return results;
    });
  }

  @override
  Future<InvoiceEntity?> getInvoiceDetail(String id) async {
    final invoiceRow = await (_db.select(_db.invoices)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();

    if (invoiceRow == null) return null;

    String? partnerName;
    if (invoiceRow.partnerId != null) {
      final partner =
          await _db.partnersDao.getPartnerById(invoiceRow.partnerId!);
      partnerName = partner?.name;
    }

    final detailQuery = _db.select(_db.weighingDetails)
      ..where((tbl) => tbl.invoiceId.equals(id))
      ..orderBy([(t) => OrderingTerm.asc(t.sequence)]);
    final detailRows = await detailQuery.get();

    final details = detailRows
        .map(
          (d) => WeighingItemEntity(
            id: d.id,
            sequence: d.sequence,
            weight: d.weight,
            quantity: d.quantity,
            time: d.weighingTime,
            batchNumber: d.batchNumber,
            pigType: d.pigType,
          ),
        )
        .toList();

    return InvoiceEntity(
      id: invoiceRow.id,
      invoiceCode: invoiceRow.invoiceCode,
      partnerId: invoiceRow.partnerId,
      partnerName: partnerName,
      type: invoiceRow.type,
      createdDate: invoiceRow.createdDate,
      totalWeight: invoiceRow.totalWeight,
      totalQuantity: invoiceRow.totalQuantity,
      pricePerKg: invoiceRow.pricePerKg,
      deduction: invoiceRow.truckCost, // Read deduction directly
      discount: invoiceRow.discount,
      finalAmount: invoiceRow.finalAmount,
      paidAmount: invoiceRow.paidAmount,
      note: invoiceRow.note,
      details: details,
    );
  }

  @override
  Future<void> createInvoice(InvoiceEntity invoice) async {
    await _db.invoicesDao.createInvoice(
      InvoicesCompanion(
        id: Value(invoice.id),
        invoiceCode: Value(invoice.invoiceCode),
        partnerId: Value(invoice.partnerId),
        type: Value(invoice.type),
        createdDate: Value(invoice.createdDate),
        totalWeight: Value(invoice.totalWeight),
        totalQuantity: Value(invoice.totalQuantity),
        pricePerKg: Value(invoice.pricePerKg),
        truckCost: Value(invoice.deduction), // Store deduction (farmWeight for import) directly
        discount: Value(invoice.discount),
        finalAmount: Value(invoice.finalAmount),
        paidAmount: Value(invoice.paidAmount),
        note: Value(invoice.note),
      ),
    );
  }

  @override
  Future<void> addWeighingItem(
    String invoiceId,
    WeighingItemEntity item,
  ) async {
    await _db.weighingDetailsDao.insertDetail(
      WeighingDetailsCompanion(
        id: Value(item.id),
        invoiceId: Value(invoiceId),
        sequence: Value(item.sequence),
        weight: Value(item.weight),
        quantity: Value(item.quantity),
        weighingTime: Value(item.time),
        batchNumber: Value(item.batchNumber),
        pigType: Value(item.pigType),
      ),
    );

    final totals = await _db.weighingDetailsDao.getInvoiceTotals(invoiceId);
    final totalWeight = totals['totalWeight'] ?? 0.0;
    final totalQty = totals['totalQuantity'] ?? 0.0;

    await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId)))
        .write(
      InvoicesCompanion(
        totalWeight: Value(totalWeight),
        totalQuantity: Value(totalQty.toInt()),
      ),
    );
  }

  @override
  Future<void> deleteInvoice(String id) async {
    await (_db.delete(_db.invoices)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> updateInvoice(InvoiceEntity invoice) async {
    debugPrint('=== REPOSITORY: updateInvoice ===');
    debugPrint('Updating invoice ID: ${invoice.id}');
    debugPrint('totalWeight: ${invoice.totalWeight}');
    debugPrint('pricePerKg: ${invoice.pricePerKg}');
    debugPrint('deduction: ${invoice.deduction}');
    debugPrint('discount: ${invoice.discount}');
    debugPrint('finalAmount: ${invoice.finalAmount}');
    
    final rowsAffected = await (_db.update(_db.invoices)..where((t) => t.id.equals(invoice.id))).write(
      InvoicesCompanion(
        partnerId: Value(invoice.partnerId),
        totalWeight: Value(invoice.totalWeight),
        totalQuantity: Value(invoice.totalQuantity),
        pricePerKg: Value(invoice.pricePerKg),
        truckCost: Value(invoice.deduction), // Store deduction (farmWeight) directly
        discount: Value(invoice.discount),
        finalAmount: Value(invoice.finalAmount),
        paidAmount: Value(invoice.paidAmount),
        note: Value(invoice.note),
      ),
    );
    debugPrint('Rows affected: $rowsAffected');
  }

  @override
  Future<void> updateWeighingItem(WeighingItemEntity item) async {
    debugPrint('=== REPOSITORY: updateWeighingItem ===');
    debugPrint('Updating item ID: ${item.id}');
    debugPrint('pigType: ${item.pigType}');
    debugPrint('weight: ${item.weight}');
    
    final rowsAffected = await (_db.update(_db.weighingDetails)..where((t) => t.id.equals(item.id))).write(
      WeighingDetailsCompanion(
        weight: Value(item.weight),
        quantity: Value(item.quantity),
        batchNumber: Value(item.batchNumber),
        pigType: Value(item.pigType),
      ),
    );
    debugPrint('WeighingItem rows affected: $rowsAffected');
  }

  @override
  Stream<int> watchPigTypeInventory(String pigType) {
    if (pigType.isEmpty) return Stream.value(0);

    final query = _db.select(_db.weighingDetails).join([
      innerJoin(
          _db.invoices, _db.invoices.id.equalsExp(_db.weighingDetails.invoiceId))
    ])
      ..where(_db.weighingDetails.pigType.equals(pigType));

    return query.watch().map((rows) {
      int imported = 0;
      int exported = 0;

      for (final row in rows) {
        final invoice = row.readTable(_db.invoices);
        final detail = row.readTable(_db.weighingDetails);
        if (invoice.type == 0) {
          imported += detail.quantity;
        } else if (invoice.type == 2) {
          exported += detail.quantity;
        }
      }
      return imported - exported;
    });
  }

  @override
  Future<String> generateInvoiceCode(int type) async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final prefix = type == 0 ? 'NK' : 'XC'; // NK = Nhập Kho, XC = Xuất Chợ
    
    // Đếm số phiếu cùng loại trong ngày (chỉ đếm phiếu gốc, không đếm chiết khấu/trả nợ)
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final query = _db.select(_db.invoices)
      ..where((tbl) => tbl.type.equals(type) & 
                       tbl.createdDate.isBiggerOrEqualValue(startOfDay) &
                       tbl.createdDate.isSmallerThanValue(endOfDay));
    
    final todayInvoices = await query.get();
    
    // Chỉ đếm phiếu có invoiceCode (phiếu gốc), không đếm phiếu chiết khấu/trả nợ
    final originalInvoices = todayInvoices.where((inv) {
      final note = inv.note ?? '';
      return !note.contains('[TRẢ NỢ]') && !note.contains('[CHIẾT KHẤU]');
    }).toList();
    
    final count = originalInvoices.length + 1;
    
    return '$dateStr-$prefix${count.toString().padLeft(2, '0')}';
  }
}
