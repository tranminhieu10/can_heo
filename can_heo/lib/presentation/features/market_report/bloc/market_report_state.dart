part of 'market_report_bloc.dart';

enum MarketReportStatus { initial, loading, success, failure }

class MarketReportState extends Equatable {
  const MarketReportState({
    this.status = MarketReportStatus.initial,
    this.startDate,
    this.endDate,
    this.marketImports = const [],
    this.marketExports = const [],
    this.errorMessage,
  });

  final MarketReportStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<InvoiceEntity> marketImports;
  final List<InvoiceEntity> marketExports;
  final String? errorMessage;

  MarketReportState copyWith({
    MarketReportStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    List<InvoiceEntity>? marketImports,
    List<InvoiceEntity>? marketExports,
    String? errorMessage,
  }) {
    return MarketReportState(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      marketImports: marketImports ?? this.marketImports,
      marketExports: marketExports ?? this.marketExports,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, startDate, endDate, marketImports, marketExports, errorMessage];
}