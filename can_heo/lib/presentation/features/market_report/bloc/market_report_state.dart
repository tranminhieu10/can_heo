part of 'market_report_bloc.dart';

enum MarketReportStatus { initial, loading, success, failure }

/// Model cho chi phí
class CostSummary extends Equatable {
  final double otherCost;       // Chi phí khác
  final double transportFee;    // Cước xe
  final double rejectAmount;    // Thải loại
  final String? otherCostNote;
  final String? rejectNote;

  const CostSummary({
    this.otherCost = 0,
    this.transportFee = 0,
    this.rejectAmount = 0,
    this.otherCostNote,
    this.rejectNote,
  });

  double get total => otherCost + transportFee + rejectAmount;

  @override
  List<Object?> get props => [otherCost, transportFee, rejectAmount, otherCostNote, rejectNote];
}

/// Model cho công nợ từng đối tác (NCC hoặc Khách hàng)
class CustomerDebt extends Equatable {
  final String partnerId;
  final String partnerName;
  final int debtType;           // 0: Nợ NCC (ta nợ), 1: Nợ Khách (khách nợ ta)
  final double totalAmount;     // Tổng tiền giao dịch
  final double totalPaid;       // Đã thanh toán (lúc giao dịch)
  final double debtAmount;      // Nợ phát sinh
  final double debtPaid;        // Đã trả nợ
  final double remaining;       // Còn nợ
  final int invoiceCount;       // Số phiếu
  final DateTime? lastTransaction; // Giao dịch gần nhất

  const CustomerDebt({
    required this.partnerId,
    required this.partnerName,
    this.debtType = 0,
    this.totalAmount = 0,
    this.totalPaid = 0,
    this.debtAmount = 0,
    this.debtPaid = 0,
    this.remaining = 0,
    this.invoiceCount = 0,
    this.lastTransaction,
  });

  /// true nếu là NCC (ta nợ NCC)
  bool get isSupplierDebt => debtType == 0;
  
  /// true nếu là Khách hàng (khách nợ ta)
  bool get isCustomerDebt => debtType == 1;

  @override
  List<Object?> get props => [
    partnerId, partnerName, debtType, totalAmount, totalPaid,
    debtAmount, debtPaid, remaining, invoiceCount, lastTransaction
  ];
}

/// Model cho công nợ
class DebtSummary extends Equatable {
  // Công nợ NCC (ta nợ NCC)
  final double totalSupplierDebt;     // Tổng nợ NCC
  final double totalSupplierPaid;     // Đã trả NCC
  final double supplierRemaining;     // Còn nợ NCC
  
  // Công nợ Khách hàng (khách nợ ta)
  final double totalCustomerDebt;     // Tổng nợ khách
  final double totalCustomerPaid;     // Khách đã trả
  final double customerRemaining;     // Khách còn nợ
  
  // Legacy fields (giữ tương thích)
  final double totalDebt;       
  final double totalPaid;       
  final double totalDebtPaid;   
  final double remaining;       
  
  final List<CustomerDebt> supplierDebts;   // Chi tiết nợ NCC
  final List<CustomerDebt> customerDebts;   // Chi tiết nợ Khách hàng

  const DebtSummary({
    this.totalSupplierDebt = 0,
    this.totalSupplierPaid = 0,
    this.supplierRemaining = 0,
    this.totalCustomerDebt = 0,
    this.totalCustomerPaid = 0,
    this.customerRemaining = 0,
    this.totalDebt = 0,
    this.totalPaid = 0,
    this.totalDebtPaid = 0,
    this.remaining = 0,
    this.supplierDebts = const [],
    this.customerDebts = const [],
  });

  @override
  List<Object?> get props => [
    totalSupplierDebt, totalSupplierPaid, supplierRemaining,
    totalCustomerDebt, totalCustomerPaid, customerRemaining,
    totalDebt, totalPaid, totalDebtPaid, remaining,
    supplierDebts, customerDebts
  ];
}

/// Model cho tổng hợp
class OverviewSummary extends Equatable {
  // Nhập hàng
  final int importCount;
  final double importWeight;
  final double importAmount;
  
  // Bán hàng
  final int exportCount;
  final double exportWeight;
  final double exportAmount;
  
  // Còn lại (Nhập - Bán)
  final double remainingWeight;
  final double remainingAmount;
  
  // Lợi nhuận
  final double profit;

  const OverviewSummary({
    this.importCount = 0,
    this.importWeight = 0,
    this.importAmount = 0,
    this.exportCount = 0,
    this.exportWeight = 0,
    this.exportAmount = 0,
    this.remainingWeight = 0,
    this.remainingAmount = 0,
    this.profit = 0,
  });

  @override
  List<Object?> get props => [
    importCount, importWeight, importAmount,
    exportCount, exportWeight, exportAmount,
    remainingWeight, remainingAmount, profit
  ];
}

class MarketReportState extends Equatable {
  const MarketReportState({
    this.status = MarketReportStatus.initial,
    this.startDate,
    this.endDate,
    this.marketImports = const [],
    this.marketExports = const [],
    this.transactions = const [],
    this.overviewSummary = const OverviewSummary(),
    this.costSummary = const CostSummary(),
    this.debtSummary = const DebtSummary(),
    this.errorMessage,
  });

  final MarketReportStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<InvoiceEntity> marketImports;
  final List<InvoiceEntity> marketExports;
  final List<TransactionEntity> transactions;
  final OverviewSummary overviewSummary;
  final CostSummary costSummary;
  final DebtSummary debtSummary;
  final String? errorMessage;

  MarketReportState copyWith({
    MarketReportStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    List<InvoiceEntity>? marketImports,
    List<InvoiceEntity>? marketExports,
    List<TransactionEntity>? transactions,
    OverviewSummary? overviewSummary,
    CostSummary? costSummary,
    DebtSummary? debtSummary,
    String? errorMessage,
  }) {
    return MarketReportState(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      marketImports: marketImports ?? this.marketImports,
      marketExports: marketExports ?? this.marketExports,
      transactions: transactions ?? this.transactions,
      overviewSummary: overviewSummary ?? this.overviewSummary,
      costSummary: costSummary ?? this.costSummary,
      debtSummary: debtSummary ?? this.debtSummary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status, startDate, endDate, 
    marketImports, marketExports, transactions,
    overviewSummary, costSummary, debtSummary,
    errorMessage
  ];
}
