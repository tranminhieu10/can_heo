import 'package:equatable/equatable.dart';
import '../../../../domain/entities/transaction.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();
  @override
  List<Object> get props => [];
}

class LoadTransactions extends FinanceEvent {}

class CreateTransaction extends FinanceEvent {
  final TransactionEntity transaction;
  const CreateTransaction(this.transaction);
}