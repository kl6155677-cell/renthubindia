import 'package:equatable/equatable.dart';
import '../../data/models/listing_model.dart';

enum ListingStatus { initial, loading, loaded, success, error }

class ListingState extends Equatable {
  final ListingStatus status;
  final List<ListingModel> listings;
  final ListingModel? detailListing;
  final bool hasReachedMax;
  final int currentPage;
  final bool isPagination;
  final String? errorMessage;
  final String? actionMessage;

  const ListingState({
    this.status = ListingStatus.initial,
    this.listings = const [],
    this.detailListing,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.isPagination = false,
    this.errorMessage,
    this.actionMessage,
  });

  ListingState copyWith({
    ListingStatus? status,
    List<ListingModel>? listings,
    ListingModel? detailListing,
    bool? hasReachedMax,
    int? currentPage,
    bool? isPagination,
    String? errorMessage,
    String? actionMessage,
    bool clearDetail = false,
    bool clearAction = false,
  }) {
    return ListingState(
      status: status ?? this.status,
      listings: listings ?? this.listings,
      detailListing: clearDetail ? null : (detailListing ?? this.detailListing),
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      isPagination: isPagination ?? this.isPagination,
      errorMessage: errorMessage, // Usually we want error to be cleared unless explicitly set
      actionMessage: clearAction ? null : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        listings,
        detailListing,
        hasReachedMax,
        currentPage,
        isPagination,
        errorMessage,
        actionMessage,
      ];
}
