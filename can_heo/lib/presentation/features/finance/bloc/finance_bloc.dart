import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final ITransactionRepository _repository;

  FinanceBloc(this._repository) : super(const FinanceState()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<CreateTransaction>(_onCreateTransaction);
  }

  Future<void> _onLoadTransactions(LoadTransactions event, Emitter<FinanceState> emit) async {
    emit(state.copyWith(status: FinanceStatus.loading));

    await emit.forEach(
      _repository.watchTransactions(),
      onData: (transactions) {
        // Tính tổng thu chi
        double income = 0;
        double expense = 0;
        for (var t in transactions) {
          if (t.type == 0) income += t.amount; // 0 = Thu
          if (t.type == 1) expense += t.amount; // 1 = Chi
        }

        return state.copyWith(
          status: FinanceStatus.success,
          transactions: transactions,
          totalIncome: income,
          totalExpense: expense,
        );
      },
      onError: (error, stackTrace) => state.copyWith(
        status: FinanceStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onCreateTransaction(CreateTransaction event, Emitter<FinanceState> emit) async {
    try {
      await _repository.createTransaction(event.transaction);
      // Không cần emit success vì Stream sẽ tự update
    } catch (e) {
      emit(state.copyWith(status: FinanceStatus.failure, errorMessage: e.toString()));
    }
  }
}