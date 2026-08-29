import 'package:equatable/equatable.dart';

abstract class ListingEvent extends Equatable {
  const ListingEvent();

  @override
  List<Object?> get props => [];
}

class LoadListings extends ListingEvent {
  final bool refresh;
  final String? categoryId;
  final String? categorySlug;
  final String? searchQuery;
  final String? country;
  final String? city;

  const LoadListings({
    this.refresh = false,
    this.categoryId,
    this.categorySlug,
    this.searchQuery,
    this.country,
    this.city,
  });

  @override
  List<Object?> get props => [refresh, categoryId, categorySlug, searchQuery, country, city];
}

class LoadListingDetail extends ListingEvent {
  final String id;

  const LoadListingDetail(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateListingRequested extends ListingEvent {
  final Map<String, dynamic> data;

  const CreateListingRequested(this.data);

  @override
  List<Object?> get props => [data];
}

class DeleteListingRequested extends ListingEvent {
  final String id;

  const DeleteListingRequested(this.id);

  @override
  List<Object?> get props => [id];
}
