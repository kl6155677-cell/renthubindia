import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/listing_repository.dart';
import '../../data/models/listing_model.dart';
import '../../data/services/local_cache_service.dart';
import 'package:renthubindia/core/utils/error_utils.dart';
import 'listing_event.dart';
import 'listing_state.dart';

class ListingBloc extends Bloc<ListingEvent, ListingState> {
  final ListingRepository listingRepository;
  final LocalCacheService _cache = LocalCacheService();

  ListingBloc({required this.listingRepository}) : super(const ListingState()) {
    on<LoadListings>(_onLoadListings);
    on<LoadListingDetail>(_onLoadListingDetail);
    on<CreateListingRequested>(_onCreateListingRequested);
    on<DeleteListingRequested>(_onDeleteListingRequested);
  }

  Future<void> _onLoadListings(LoadListings event, Emitter<ListingState> emit) async {
    try {
      final bool isFirstPage = event.refresh || state.status == ListingStatus.initial;

      if (event.refresh) {
        emit(state.copyWith(status: ListingStatus.loading, isPagination: false));
      } else if (state.status == ListingStatus.loaded) {
        if (state.hasReachedMax) return;
        emit(state.copyWith(isPagination: true));
      } else {
        emit(state.copyWith(status: ListingStatus.loading, isPagination: false));
      }

      int page = 1;
      List<ListingModel> currentListings = [];

      if (!event.refresh && state.status == ListingStatus.loaded) {
        page = state.currentPage + 1;
        currentListings = state.listings;
      }

      // ── Stale-while-revalidate: serve cache on first-page loads ──
      if (isFirstPage) {
        final cacheKey = LocalCacheService.listingsCacheKey(
          country: event.country,
          city: event.city,
          categorySlug: event.categorySlug,
          search: event.searchQuery,
        );
        final cached = await _cache.getCachedListings(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          emit(state.copyWith(
            status: ListingStatus.loaded,
            listings: cached,
            hasReachedMax: false,
            currentPage: 1,
          ));
        }

        // Fetch fresh from network
        final newListings = await listingRepository.getListings(
          page: 1,
          limit: 10,
          categorySlug: event.categorySlug,
          search: event.searchQuery,
          country: event.country,
          city: event.city,
        );

        emit(state.copyWith(
          status: ListingStatus.loaded,
          listings: newListings,
          hasReachedMax: newListings.length < 10,
          currentPage: 1,
          isPagination: false,
        ));

        // Persist page-1 to Hive for next launch
        await _cache.saveListings(cacheKey, newListings);
      } else {
        // Pagination: no cache, just fetch next page
        final newListings = await listingRepository.getListings(
          page: page,
          limit: 10,
          categorySlug: event.categorySlug,
          search: event.searchQuery,
          country: event.country,
          city: event.city,
        );

        emit(state.copyWith(
          status: ListingStatus.loaded,
          listings: currentListings + newListings,
          hasReachedMax: newListings.length < 10,
          currentPage: page,
          isPagination: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ListingStatus.error,
        errorMessage: ErrorUtils.formatError(e),
        isPagination: false,
      ));
    }
  }

  Future<void> _onLoadListingDetail(LoadListingDetail event, Emitter<ListingState> emit) async {
    // Note: We deliberately don't set status to loading globally if we already have listings,
    // but the detail screen expects a loading indicator for itself.
    // For now, we'll keep it simple and just emit.
    emit(state.copyWith(status: ListingStatus.loading, clearDetail: true));
    try {
      final listing = await listingRepository.getListing(event.id);
      emit(state.copyWith(
        status: ListingStatus.loaded,
        detailListing: listing,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ListingStatus.error,
        errorMessage: ErrorUtils.formatError(e),
      ));
    }
  }

  Future<void> _onCreateListingRequested(CreateListingRequested event, Emitter<ListingState> emit) async {
    emit(state.copyWith(status: ListingStatus.loading));
    try {
      await listingRepository.createListing(event.data);
      emit(state.copyWith(
        status: ListingStatus.success,
        actionMessage: "Listing created successfully!",
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ListingStatus.error,
        errorMessage: ErrorUtils.formatError(e),
      ));
    }
  }

  Future<void> _onDeleteListingRequested(DeleteListingRequested event, Emitter<ListingState> emit) async {
    emit(state.copyWith(status: ListingStatus.loading));
    try {
      await listingRepository.deleteListing(event.id);
      
      // Update local state to remove the listing without full refresh
      final updatedListings = state.listings.where((l) => l.id != event.id).toList();
      
      emit(state.copyWith(
        status: ListingStatus.success,
        listings: updatedListings,
        actionMessage: "Listing deleted successfully!",
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ListingStatus.error,
        errorMessage: ErrorUtils.formatError(e),
      ));
    }
  }
}
