import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/listing_repository.dart';
import '../../data/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../widgets/listing_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_state.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategoryId;

  const SearchScreen({super.key, this.initialCategoryId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  String? _selectedCountry;
  double? _priceMin;
  double? _priceMax;
  String _sortBy = 'newest';

  List<ListingModel> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _listView = false;

  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    
    // Default country from location bloc
    final locState = context.read<LocationBloc>().state;
    if (locState is LocationDetected) {
      _selectedCountry = locState.country;
    }
    
    _initSearch();
  }

  Future<void> _initSearch() async {
    await _loadCategories();
    _search(); // auto-search on load after categories are ready
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiService.dio.get(ApiConstants.categories);
      final List<dynamic> data = response.data['data'] ?? [];
      if (mounted) {
        setState(() {
          _categories = data.map((j) => CategoryModel.fromJson(j)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _search() async {
    _focusNode.unfocus();
    setState(() { _isLoading = true; _hasSearched = true; });
    try {
      String? categorySlug;
      if (_selectedCategoryId != null) {
        final matches = _categories.where((c) => c.id == _selectedCategoryId);
        if (matches.isNotEmpty) {
          categorySlug = matches.first.slug;
        }
      }
      final results = await ListingRepository().getListings(
        search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        categorySlug: categorySlug,
        country: _selectedCountry,
        priceMin: _priceMin,
        priceMax: _priceMax,
        sortBy: _sortBy,
      );
      if (mounted) setState(() { _results = results; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Search Bar ──
            _buildTopBar(),
            // ── Filter Chips ──
            _buildFilterChips(),
            // ── Results Count + View Toggle ──
            _buildResultsHeader(),
            // ── Results List ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: _search,
                color: AppColors.primary,
                child: _buildResults(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
            onPressed: () => context.go('/home'),
          ),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                  prefixIconConstraints: BoxConstraints(minWidth: 40),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _showFilterBottomSheet(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, size: 20, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: [
          // Country chip
          if (_selectedCountry != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _selectedCountry!,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Category chips from API
          ..._categories.map((cat) {
            final isSelected = _selectedCategoryId == cat.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedCategoryId = isSelected ? null : cat.id);
                  _search();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.close, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_results.length} spaces found',
            style: const TextStyle(fontFamily: 'Sora', fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _listView = true),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _listView ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.view_list, size: 20, color: _listView ? AppColors.primary : const Color(0xFF9CA3AF)),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _listView = false),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: !_listView ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.map_outlined, size: 20, color: !_listView ? AppColors.primary : const Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_results.isEmpty && _hasSearched) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No results found', style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 6),
                const Text('Try a different search term or category', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFFD1D5DB))),
              ],
            ),
          ),
        ),
      );
    }

    if (_listView) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => ListingCard(
          listing: _results[index],
          onTap: () => context.push('/listing/${_results[index].id}'),
        ),
      );
    } else {
      return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        itemCount: _results.length,
        itemBuilder: (context, index) => ListingCard(
          listing: _results[index],
          onTap: () => context.push('/listing/${_results[index].id}'),
        ),
      );
    }
  }

  // List card helper removed in favor of unified ListingCard


  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filters', style: TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Sort By', style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildFilterOption('Newest', _sortBy == 'newest', () => setModalState(() => _sortBy = 'newest')),
                      _buildFilterOption('Price: Low to High', _sortBy == 'price_asc', () => setModalState(() => _sortBy = 'price_asc')),
                      _buildFilterOption('Price: High to Low', _sortBy == 'price_desc', () => setModalState(() => _sortBy = 'price_desc')),
                      _buildFilterOption('Rating', _sortBy == 'rating', () => setModalState(() => _sortBy = 'rating')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Price Range', style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildPriceInput('Min', _minPriceController)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPriceInput('Max', _maxPriceController)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _priceMin = double.tryParse(_minPriceController.text);
                          _priceMax = double.tryParse(_maxPriceController.text);
                        });
                        Navigator.pop(context);
                        _search();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInput(String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixText: '${() { final ls = context.read<LocationBloc>().state; return ls is LocationDetected ? ls.currencySymbol : r'$'; }()} ',
          prefixStyle: const TextStyle(color: Color(0xFF374151), fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
