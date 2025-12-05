import 'package:get_it/get_it.dart';

// Import Database
import 'data/local/database.dart';

// Import Repositories Implementation (Data Layer)
import 'data/repositories/invoice_repository_impl.dart';
import 'data/repositories/partner_repository_impl.dart';

// Import Repositories Interface (Domain Layer)
import 'domain/repositories/i_invoice_repository.dart';
import 'domain/repositories/i_partner_repository.dart';

// Import Bloc
import 'presentation/features/weighing/bloc/weighing_bloc.dart';

// Biến toàn cục Service Locator
final sl = GetIt.instance;

Future<void> init() async {
  // ==========================
  // 1. External & Core (Database)
  // ==========================
  // Đăng ký AppDatabase là Singleton (chỉ khởi tạo 1 lần dùng mãi mãi)
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // ==========================
  // 2. Repositories
  // ==========================
  // Partner Repository
  sl.registerLazySingleton<IPartnerRepository>(
    () => PartnerRepositoryImpl(sl()), // sl() sẽ tự động lấy AppDatabase ở trên điền vào đây
  );

  // Invoice Repository
  sl.registerLazySingleton<IInvoiceRepository>(
    () => InvoiceRepositoryImpl(sl()),
  );

  // ==========================
  // 3. Blocs (State Management)
  // ==========================
  // WeighingBloc dùng Factory (tạo mới mỗi khi vào màn hình cân)
  sl.registerFactory(
    () => WeighingBloc(invoiceRepository: sl()),
  );
}