import 'package:equatable/equatable.dart';
import '../../../../domain/entities/invoice.dart';

enum HistoryStatus { initial, loading, success, failure }

class InvoiceHistoryState extends Equatable {
  final HistoryStatus status;
  final List<InvoiceEntity> invoices;
  final String? errorMessage;

  const InvoiceHistoryState({
    this.status = HistoryStatus.initial,
    this.invoices = const [],
    this.errorMessage,
  });

  InvoiceHistoryState copyWith({
    HistoryStatus? status,
    List<InvoiceEntity>? invoices,
    String? errorMessage,
  }) {
    return InvoiceHistoryState(
      status: status ?? this.status,
      invoices: invoices ?? this.invoices,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, invoices, errorMessage];
}