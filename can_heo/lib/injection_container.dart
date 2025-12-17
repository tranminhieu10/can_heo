import 'package:get_it/get_it.dart';

import 'core/services/scale_service.dart';
import 'data/local/database.dart';
import 'data/repositories/invoice_repository_impl.dart';
import 'data/repositories/partner_repository_impl.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'data/repositories/pigtype_repository_impl.dart';
import 'data/repositories/farm_repository_impl.dart';

import 'domain/repositories/i_invoice_repository.dart';
import 'domain/repositories/i_partner_repository.dart';
import 'domain/repositories/i_transaction_repository.dart';
import 'domain/repositories/i_pigtype_repository.dart';
import 'domain/repositories/i_farm_repository.dart';

import 'presentation/features/weighing/bloc/weighing_bloc.dart';
import 'presentation/features/history/bloc/invoice_history_bloc.dart';
import 'presentation/features/history/bloc_detail/invoice_detail_cubit.dart';
import 'presentation/features/partners/bloc/partner_bloc.dart';
import 'presentation/features/finance/bloc/finance_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Database
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Services
  // TẠM THỜI dùng DummyScaleService
  // Khi có plugin native: sl.registerLazySingleton<IScaleService>(() => MethodChannelScaleService());
  sl.registerLazySingleton<IScaleService>(() => DummyScaleService());

  // Repositories
  sl.registerLazySingleton<IInvoiceRepository>(
    () => InvoiceRepositoryImpl(sl<AppDatabase>()),
  );

  sl.registerLazySingleton<IPartnerRepository>(
    () => PartnerRepositoryImpl(sl<AppDatabase>()),
  );

  sl.registerLazySingleton<ITransactionRepository>(
    () => TransactionRepositoryImpl(sl<AppDatabase>()),
  );

  sl.registerLazySingleton<IPigTypeRepository>(
    () => PigTypeRepositoryImpl(sl<AppDatabase>()),
  );

  sl.registerLazySingleton<IFarmRepository>(
    () => FarmRepositoryImpl(sl<AppDatabase>()),
  );

  // Blocs / Cubits
  // SỬA: Thêm ScaleService vào WeighingBloc
  sl.registerFactory(() => WeighingBloc(
        sl<IInvoiceRepository>(),
        sl<IScaleService>(),
      ));

  sl.registerFactory(
    () => InvoiceHistoryBloc(sl<IInvoiceRepository>()),
  );

  sl.registerFactory(
    () => InvoiceDetailCubit(sl<IInvoiceRepository>()),
  );

  sl.registerFactory(
    () => PartnerBloc(sl<IPartnerRepository>()),
  );

  sl.registerFactory(
    () => FinanceBloc(sl<ITransactionRepository>()),
  );
}