import 'package:get_it/get_it.dart';

import 'core/services/scale_service.dart';
import 'data/local/database.dart';
import 'data/repositories/invoice_repository_impl.dart';
import 'data/repositories/partner_repository_impl.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'data/repositories/pigtype_repository_impl.dart';
import 'data/repositories/farm_repository_impl.dart';
import 'data/repositories/cage_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';

import 'domain/repositories/i_invoice_repository.dart';
import 'domain/repositories/i_partner_repository.dart';
import 'domain/repositories/i_transaction_repository.dart';
import 'domain/repositories/i_pigtype_repository.dart';
import 'domain/repositories/i_farm_repository.dart';
import 'domain/repositories/i_cage_repository.dart';
import 'domain/repositories/i_user_repository.dart';

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
  // Sử dụng ASIScaleService cho đầu hiển thị ASI 2025
  final asiScale = ASIScaleService();
  await asiScale.connect(); // Tự động tìm và kết nối với cổng COM
  sl.registerLazySingleton<IScaleService>(() => asiScale);
  
  // Hoặc nếu muốn dùng dummy (test không có cân):
  // sl.registerLazySingleton<IScaleService>(() => DummyScaleService());

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

  sl.registerLazySingleton<ICageRepository>(
    () => CageRepositoryImpl(sl<AppDatabase>()),
  );

  sl.registerLazySingleton<IUserRepository>(
    () => UserRepositoryImpl(sl<AppDatabase>()),
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