import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/listing_model.dart';
import '../../core/theme/app_colors.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_state.dart';
import '../../core/utils/location_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback? onTap;
  final String? heroSuffix;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.heroSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'listing_image_${listing.id}${heroSuffix ?? ''}',
                      child: listing.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: listing.images.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Center(
                                  child: Icon(Icons.image_outlined, color: Color(0xFFD1D5DB), size: 36),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined, color: Color(0xFFD1D5DB), size: 36),
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFF3F4F6),
                              child: const Center(
                                child: Icon(Icons.image_outlined, color: Color(0xFFD1D5DB), size: 36),
                              ),
                            ),
                    ),
                    // Status badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(listing.status).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          listing.status,
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Distance badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: BlocBuilder<LocationBloc, LocationState>(
                        builder: (context, state) {
                          double? userLat;
                          double? userLng;

                          if (state is LocationDetected) {
                            userLat = state.latitude;
                            userLng = state.longitude;
                          }

                          if (userLat == null || userLng == null) return const SizedBox.shrink();
                            
                          final distanceInMeters = LocationUtils.calculateDistance(
                            startLat: userLat,
                            startLng: userLng,
                            endLat: listing.latitude,
                            endLng: listing.longitude,
                          );
                          
                          final distanceText = LocationUtils.formatDistance(distanceInMeters);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  distanceText,
                                  style: const TextStyle(
                                    fontFamily: 'Sora',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (listing.rating != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFACC15)),
                        const SizedBox(width: 2),
                        Text(
                          listing.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${listing.reviewCount})',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${listing.city}, ${listing.country}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  BlocBuilder<LocationBloc, LocationState>(
                    buildWhen: (p, n) => (p is LocationDetected && n is LocationDetected)
                        ? p.currencySymbol != n.currencySymbol
                        : p.runtimeType != n.runtimeType,
                    builder: (context, locState) {
                      final symbol = locState is LocationDetected ? locState.currencySymbol : r'$';
                      return Row(
                        children: [
                          Text(
                            '$symbol${listing.pricePerDay.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                          const Text(
                            ' / day',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return AppColors.success;
      case 'PAUSED':
        return AppColors.accent;
      case 'RENTED':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }
}
