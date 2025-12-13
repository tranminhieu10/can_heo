import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/scale_service.dart';
import '../../../../domain/entities/invoice.dart';
import '../../../../domain/repositories/i_invoice_repository.dart';
import 'weighing_event.dart';
import 'weighing_state.dart';

class WeighingBloc extends Bloc<WeighingEvent, WeighingState> {
  final IInvoiceRepository invoiceRepository;
  final IScaleService scaleService; // Inject ScaleService
  final _uuid = const Uuid();

  double _lastPricePerKg = 0;
  double _lastDeduction = 0;
  double _lastDiscount = 0;
  
  // Quản lý stream từ đầu cân
  StreamSubscription<double>? _scaleSubscription;

  WeighingBloc(this.invoiceRepository, this.scaleService) : super(WeighingState.initial()) {
    on<WeighingStarted>(_onStarted);
    on<WeighingItemAdded>(_onItemAdded);
    on<WeighingItemRemoved>(_onItemRemoved);
    on<WeighingInvoiceUpdated>(_onInvoiceUpdated);
    on<WeighingSaved>(_onSaved);
    
    // Handler cho sự kiện nội bộ từ Stream
    on<WeighingScaleDataReceived>(_onScaleDataReceived);
  }

  @override
  Future<void> close() {
    _scaleSubscription?.cancel();
    return super.close();
  }

  // --------- HANDLERS ----------

  Future<void> _onStarted(
    WeighingStarted event,
    Emitter<WeighingState> emit,
  ) async {
    // 1. Khởi tạo Invoice mới
    final invoice = InvoiceEntity(
      id: _uuid.v4(),
      type: event.invoiceType,
      createdDate: DateTime.now(),
      totalWeight: 0,
      totalQuantity: 0,
      finalAmount: 0,
      partnerId: null,
      partnerName: null,
      details: const [],
    );

    _lastPricePerKg = 0;
    _lastDeduction = 0;
    _lastDiscount = 0;

    // 2. Bắt đầu lắng nghe Stream từ ScaleService (nếu chưa nghe)
    _startListeningToScale();

    emit(
      WeighingState(
        status: WeighingStatus.editing,
        currentInvoice: invoice,
        items: const [],
        scaleWeight: 0.0,
        isScaleConnected: false,
      ),
    );
  }

  void _onScaleDataReceived(
    WeighingScaleDataReceived event,
    Emitter<WeighingState> emit,
  ) {
    // Chỉ cập nhật UI về số cân live, không ảnh hưởng logic tính tiền
    emit(state.copyWith(
      scaleWeight: event.weight,
      isScaleConnected: event.isConnected,
    ));
  }

  void _onItemAdded(
    WeighingItemAdded event,
    Emitter<WeighingState> emit,
  ) {
    final invoice = state.currentInvoice;
    if (invoice == null) return;

    final newItem = WeighingItemEntity(
      id: _uuid.v4(),
      sequence: state.items.length + 1,
      weight: event.weight,
      quantity: event.quantity,
      time: DateTime.now(),
      batchNumber: event.batchNumber,
      pigType: event.pigType,
    );

    final updatedItems = List<WeighingItemEntity>.from(state.items)
      ..add(newItem);

    final totalWeight =
        updatedItems.fold<double>(0, (sum, i) => sum + i.weight);
    final totalQty =
        updatedItems.fold<int>(0, (sum, i) => sum + i.quantity);

    final updatedInvoice = invoice.copyWith(
      totalWeight: totalWeight,
      totalQuantity: totalQty,
      finalAmount: _calculateFinalAmount(totalWeight),
    );

    emit(
      state.copyWith(
        status: WeighingStatus.editing,
        items: updatedItems,
        currentInvoice: updatedInvoice,
        clearError: true,
      ),
    );
  }

  void _onItemRemoved(
    WeighingItemRemoved event,
    Emitter<WeighingState> emit,
  ) {
    final invoice = state.currentInvoice;
    if (invoice == null) return;

    final filtered =
        state.items.where((i) => i.id != event.itemId).toList();

    // Đánh lại STT
    final reindexed = <WeighingItemEntity>[];
    for (var i = 0; i < filtered.length; i++) {
      reindexed.add(filtered[i].copyWith(sequence: i + 1));
    }

    final totalWeight =
        reindexed.fold<double>(0, (sum, i) => sum + i.weight);
    final totalQty =
        reindexed.fold<int>(0, (sum, i) => sum + i.quantity);

    final updatedInvoice = invoice.copyWith(
      totalWeight: totalWeight,
      totalQuantity: totalQty,
      finalAmount: _calculateFinalAmount(totalWeight),
    );

    emit(
      state.copyWith(
        status: WeighingStatus.editing,
        items: reindexed,
        currentInvoice: updatedInvoice,
        clearError: true,
      ),
    );
  }

  void _onInvoiceUpdated(
    WeighingInvoiceUpdated event,
    Emitter<WeighingState> emit,
  ) {
    final invoice = state.currentInvoice;
    if (invoice == null) return;

    if (event.pricePerKg != null) {
      _lastPricePerKg = (event.pricePerKg!.clamp(0, double.infinity)).toDouble();
    }
    if (event.deduction != null) {
      _lastDeduction = (event.deduction!.clamp(0, double.infinity)).toDouble();
    }
    if (event.discount != null) {
      _lastDiscount = (event.discount!.clamp(0, double.infinity)).toDouble();
    }

    // If finalAmount is explicitly provided (e.g., from import screen), use it
    // Otherwise calculate it (for export screen)
    final calculatedFinalAmount = event.finalAmount ?? _calculateFinalAmount(invoice.totalWeight);

    final updatedInvoice = invoice.copyWith(
      partnerId: event.partnerId ?? invoice.partnerId,
      partnerName: event.partnerName ?? invoice.partnerName,
      note: event.note ?? invoice.note,
      pricePerKg: _lastPricePerKg,
      deduction: _lastDeduction,
      discount: _lastDiscount,
      finalAmount: calculatedFinalAmount,
    );

    emit(
      state.copyWith(
        status: WeighingStatus.editing,
        currentInvoice: updatedInvoice,
        clearError: true,
      ),
    );
  }

  Future<void> _onSaved(
    WeighingSaved event,
    Emitter<WeighingState> emit,
  ) async {
    final invoice = state.currentInvoice;
    if (invoice == null || state.items.isEmpty) return;

    emit(state.copyWith(status: WeighingStatus.loading, clearError: true));

    try {
      // Generate invoice code
      final invoiceCode = await invoiceRepository.generateInvoiceCode(invoice.type);
      final invoiceWithCode = invoice.copyWith(invoiceCode: invoiceCode);
      
      await invoiceRepository.createInvoice(invoiceWithCode);
      for (final item in state.items) {
        await invoiceRepository.addWeighingItem(invoice.id, item);
      }

      emit(
        state.copyWith(status: WeighingStatus.success),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: WeighingStatus.failure,
          errorMessage: 'Lỗi lưu phiếu: $e',
        ),
      );
    }
  }

  // --------- HELPER ----------

  void _startListeningToScale() {
    _scaleSubscription?.cancel();
    _scaleSubscription = scaleService.watchWeight().listen(
      (weight) {
        if (!isClosed) {
          add(WeighingScaleDataReceived(weight: weight, isConnected: true));
        }
      },
      onError: (error) {
        if (!isClosed) {
          add(const WeighingScaleDataReceived(weight: 0.0, isConnected: false));
        }
      },
    );
  }

  double _calculateFinalAmount(double totalWeight) {
    final netWeight = (totalWeight - _lastDeduction).clamp(0, double.infinity);
    return (netWeight * _lastPricePerKg) - _lastDiscount;
  }
}