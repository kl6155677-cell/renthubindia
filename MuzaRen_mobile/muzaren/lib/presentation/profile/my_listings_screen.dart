import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/listing_model.dart';
import '../../data/repositories/listing_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_state.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ListingModel> _allListings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);
    try {
      final listings = await ListingRepository().getMyListings();
      if (mounted) {
        setState(() {
          _allListings = listings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading listings: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text(
          'My Listings',
          style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Paused'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListingList('ACTIVE'),
                _buildListingList('PAUSED'),
                _buildListingList(null),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/listing/post'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildListingList(String? filterStatus) {
    final filtered = filterStatus == null 
        ? _allListings 
        : _allListings.where((l) => l.status.toUpperCase() == filterStatus).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No ${filterStatus?.toLowerCase() ?? ""} listings found',
              style: const TextStyle(fontFamily: 'PlusJakartaSans', color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final listing = filtered[index];
        return _buildListingCard(listing);
      },
    );
  }

  Widget _buildListingCard(ListingModel listing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/listing/${listing.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: listing.images.isNotEmpty
                      ? CachedNetworkImage(imageUrl: listing.images.first, fit: BoxFit.cover)
                      : Container(color: const Color(0xFFF3F4F6), child: const Icon(Icons.image_outlined, color: Color(0xFFD1D5DB))),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(listing.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            listing.status.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _getStatusColor(listing.status),
                            ),
                          ),
                        ),
                        BlocBuilder<LocationBloc, LocationState>(
                          builder: (context, locState) {
                            final symbol = locState is LocationDetected ? locState.currencySymbol : r'$';
                            return Text(
                              '$symbol${listing.pricePerDay.toStringAsFixed(0)}/day',
                              style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Sora', fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Posted on ${_formatDate(listing.createdAt)}',
                          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildActionButton(Icons.edit_outlined, 'Edit', () => context.push('/listing/edit', extra: listing)),
                        const SizedBox(width: 16),
                        _buildActionButton(
                          listing.status == 'PAUSED' ? Icons.play_arrow_outlined : Icons.pause_circle_outline,
                          listing.status == 'PAUSED' ? 'Resume' : 'Pause',
                          () => _toggleStatus(listing),
                        ),
                        const SizedBox(width: 16),
                        _buildActionButton(Icons.delete_outline, 'Delete', () => _confirmDelete(listing), color: AppColors.error),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {Color color = AppColors.primary}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontFamily: 'Sora', fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE': return AppColors.success;
      case 'PAUSED': return AppColors.accent;
      default: return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _toggleStatus(ListingModel listing) async {
    final newStatus = listing.status == 'PAUSED' ? 'ACTIVE' : 'PAUSED';
    try {
      await ListingRepository().updateListingStatus(listing.id, newStatus);
      _loadListings(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listing ${newStatus.toLowerCase()} success'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _confirmDelete(ListingModel listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing', style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this listing?', 
          style: TextStyle(fontFamily: 'PlusJakartaSans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteListing(listing.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteListing(String id) async {
    try {
      await ListingRepository().deleteListing(id);
      _loadListings(); // Refresh UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing deleted successfully'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
