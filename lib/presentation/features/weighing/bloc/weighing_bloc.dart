import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import 'weighing_event.dart';
import 'weighing_state.dart';

class WeighingBloc extends Bloc<WeighingEvent, WeighingState> {
  final IInvoiceRepository invoiceRepository;
  final _uuid = const Uuid();

  WeighingBloc({required this.invoiceRepository}) : super(const WeighingState()) {
    on<WeighingStarted>(_onStarted);
    on<WeighingItemAdded>(_onItemAdded);
    on<WeighingInvoiceUpdated>(_onInvoiceUpdated);
    on<WeighingSaved>(_onSaved);
  }

  void _onStarted(WeighingStarted event, Emitter<WeighingState> emit) {
    // Tạo một phiếu nháp rỗng
    final newInvoice = InvoiceEntity(
      id: _uuid.v4(),
      type: event.invoiceType,
      createdDate: DateTime.now(),
      totalWeight: 0,
      totalQuantity: 0,
      finalAmount: 0,
      details: [],
    );
    emit(state.copyWith(
      status: WeighingStatus.success,
      currentInvoice: newInvoice,
      items: [],
    ));
  }

  void _onItemAdded(WeighingItemAdded event, Emitter<WeighingState> emit) {
    if (state.currentInvoice == null) return;

    // 1. Tạo mã cân mới
    final newItem = WeighingItemEntity(
      id: _uuid.v4(),
      sequence: state.items.length + 1, // Tự tăng STT
      weight: event.weight,
      quantity: event.quantity,
      time: DateTime.now(),
    );

    // 2. Thêm vào danh sách
    final updatedItems = [newItem, ...state.items]; // Thêm vào đầu danh sách để hiện lên trên cùng

    // 3. Tính lại tổng trọng lượng
    double totalWeight = 0;
    int totalQty = 0;
    for (var item in updatedItems) {
      totalWeight += item.weight;
      totalQty += item.quantity;
    }

    // 4. Update Invoice ảo
    final updatedInvoice = _updateInvoiceTotals(state.currentInvoice!, totalWeight, totalQty);

    emit(state.copyWith(items: updatedItems, currentInvoice: updatedInvoice));
  }

  void _onInvoiceUpdated(WeighingInvoiceUpdated event, Emitter<WeighingState> emit) {
    if (state.currentInvoice == null) return;
    
    // Logic tính tiền tạm thời (sẽ mở rộng sau)
    // Hiện tại chỉ update partnerId...
    // TODO: Thêm logic tính thành tiền = weight * price
  }

  Future<void> _onSaved(WeighingSaved event, Emitter<WeighingState> emit) async {
    if (state.currentInvoice == null) return;
    emit(state.copyWith(status: WeighingStatus.loading));

    try {
      // 1. Lưu Header phiếu
      await invoiceRepository.createInvoice(state.currentInvoice!);
      
      // 2. Lưu từng chi tiết (Có thể tối ưu bằng batch insert sau này)
      for (var item in state.items) {
        await invoiceRepository.addWeighingItem(state.currentInvoice!.id, item);
      }

      emit(state.copyWith(status: WeighingStatus.success));
    } catch (e) {
      emit(state.copyWith(status: WeighingStatus.failure, errorMessage: e.toString()));
    }
  }

  InvoiceEntity _updateInvoiceTotals(InvoiceEntity old, double newWeight, int newQty) {
    return InvoiceEntity(
      id: old.id,
      type: old.type,
      createdDate: old.createdDate,
      totalWeight: newWeight,
      totalQuantity: newQty,
      finalAmount: old.finalAmount, // Chưa tính tiền vội
      partnerId: old.partnerId,
      partnerName: old.partnerName,
      details: old.details,
    );
  }
}