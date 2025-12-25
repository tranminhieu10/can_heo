part of 'market_report_bloc.dart';

abstract class MarketReportEvent extends Equatable {
  const MarketReportEvent();

  @override
  List<Object> get props => [];
}

class MarketReportSubscriptionRequested extends MarketReportEvent {
  const MarketReportSubscriptionRequested();
}

class MarketReportDateRangeChanged extends MarketReportEvent {
  const MarketReportDateRangeChanged({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object> get props => [startDate, endDate];
}
