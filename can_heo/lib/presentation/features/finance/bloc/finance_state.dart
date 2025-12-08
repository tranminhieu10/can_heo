import 'package:equatable/equatable.dart';
import '../../../../domain/entities/transaction.dart';

enum FinanceStatus { initial, loading, success, failure }

class FinanceState extends Equatable {
  final FinanceStatus status;
  final List<TransactionEntity> transactions;
  final String? errorMessage;
  
  // Tổng thu - chi trong danh sách hiện tại (để hiện dashboard nhỏ)
  final double totalIncome;
  final double totalExpense;

  const FinanceState({
    this.status = FinanceStatus.initial,
    this.transactions = const [],
    this.errorMessage,
    this.totalIncome = 0,
    this.totalExpense = 0,
  });

  FinanceState copyWith({
    FinanceStatus? status,
    List<TransactionEntity>? transactions,
    String? errorMessage,
    double? totalIncome,
    double? totalExpense,
  }) {
    return FinanceState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
    );
  }

  @override
  List<Object?> get props => [status, transactions, errorMessage, totalIncome, totalExpense];
}