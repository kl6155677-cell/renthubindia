import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/currency_utils.dart';
import '../../data/services/location_service.dart';
import '../../data/services/api_service.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {

  // SharedPreferences keys
  static const _kCity              = 'user_city';
  static const _kCountry           = 'user_country';
  static const _kCountryCode       = 'user_country_code';
  static const _kCurrency          = 'user_currency';
  static const _kCurrencySymbol    = 'user_currency_symbol';
  static const _kLat               = 'user_lat';
  static const _kLng               = 'user_lng';
  static const _kCurrencyManualSet = 'currency_manually_set';
  static const _kLastDetected      = 'location_last_detected';

  LocationBloc({required dynamic authRepository}) : super(LocationInitial()) {
    on<DetectLocation>(_onDetectLocation);
    on<ManualLocationChanged>(_onManualLocationChanged);
    on<ManualCurrencyOverride>(_onManualCurrencyOverride);
    on<ResetCurrencyToAuto>(_onResetCurrencyToAuto);
  }

  // ─── DETECT LOCATION ─────────────────────────────────────
  Future<void> _onDetectLocation(
    DetectLocation event,
    Emitter<LocationState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // STEP 1: Emit saved data immediately (instant UX)
    await _emitSavedLocation(prefs, emit);

    // STEP 2: Check if we need to re-detect
    // Re-detect if: no saved data OR last detection > 1 hour ago
    final lastDetected = prefs.getInt(_kLastDetected) ?? 0;
    final hoursSinceLastDetection =
        (DateTime.now().millisecondsSinceEpoch - lastDetected) / 3600000;

    if (!event.force &&
        prefs.getString(_kCountryCode) != null &&
        hoursSinceLastDetection < 1) {
      // Location is fresh — no need to re-detect
      return;
    }

    // STEP 3: Detect from GPS or IP
    emit(LocationDetecting());

    final result = await LocationService.detectLocation();

    if (result != null) {
      await _saveAndEmit(prefs, emit, result);
    } else {
      // Both GPS and IP failed
      // Already emitted saved data in Step 1 — just log
      if (state is! LocationDetected) {
        // No saved data either — use default
        await _emitDefault(prefs, emit);
      }
    }
  }

  // ─── MANUAL LOCATION CHANGE ─────────────────────────────
  Future<void> _onManualLocationChanged(
    ManualLocationChanged event,
    Emitter<LocationState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user manually set currency — if so, keep it
    final isManualCurrency = prefs.getBool(_kCurrencyManualSet) ?? false;

    final currency = isManualCurrency
        ? (prefs.getString(_kCurrency) ?? CurrencyUtils.fromCountry(event.countryCode))
        : CurrencyUtils.fromCountry(event.countryCode); // AUTO from new country

    final currencySymbol = CurrencyUtils.symbolFromCode(currency);

    // If country changed and no manual override — auto-update currency
    if (!isManualCurrency) {
      await prefs.setString(_kCurrency, currency);
      await prefs.setString(_kCurrencySymbol, currencySymbol);
    }

    await prefs.setString(_kCity,        event.city);
    await prefs.setString(_kCountry,     event.country);
    await prefs.setString(_kCountryCode, event.countryCode);

    // Get current latitude/longitude from existing state
    final currentState = state;
    final latitude = currentState is LocationDetected ? currentState.latitude : 0.0;
    final longitude = currentState is LocationDetected ? currentState.longitude : 0.0;

    // Send to backend (non-blocking)
    _updateBackend(city: event.city, country: event.country, currency: currency);

    emit(LocationDetected(
      city:           event.city,
      country:        event.country,
      countryCode:    event.countryCode,
      currency:       currency,
      currencySymbol: currencySymbol,
      latitude:       latitude,
      longitude:      longitude,
    ));
  }

  // ─── MANUAL CURRENCY OVERRIDE (from Settings) ────────────
  Future<void> _onManualCurrencyOverride(
    ManualCurrencyOverride event,
    Emitter<LocationState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final currencySymbol = CurrencyUtils.symbolFromCode(event.currencyCode);

    // Save override + flag that currency was manually set
    await prefs.setString(_kCurrency,          event.currencyCode);
    await prefs.setString(_kCurrencySymbol,     currencySymbol);
    await prefs.setBool(_kCurrencyManualSet,    true);

    // Send to backend
    _updateBackend(currency: event.currencyCode);

    // Update current state with new currency
    final currentState = state;
    if (currentState is LocationDetected) {
      emit(LocationDetected(
        city:           currentState.city,
        country:        currentState.country,
        countryCode:    currentState.countryCode,
        currency:       event.currencyCode,
        currencySymbol: currencySymbol,
        latitude:       currentState.latitude,
        longitude:      currentState.longitude,
      ));
    }
  }

  // ─── RESET CURRENCY TO AUTO ──────────────────────────────
  Future<void> _onResetCurrencyToAuto(
    ResetCurrencyToAuto event,
    Emitter<LocationState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Clear manual override flag
    await prefs.setBool(_kCurrencyManualSet, false);

    // Re-derive currency from current country
    final countryCode = prefs.getString(_kCountryCode) ?? 'US';
    final currency       = CurrencyUtils.fromCountry(countryCode);
    final currencySymbol = CurrencyUtils.symbolFromCode(currency);

    await prefs.setString(_kCurrency,      currency);
    await prefs.setString(_kCurrencySymbol, currencySymbol);

    // Send to backend
    _updateBackend(currency: currency);

    final currentState = state;
    if (currentState is LocationDetected) {
      emit(LocationDetected(
        city:           currentState.city,
        country:        currentState.country,
        countryCode:    currentState.countryCode,
        currency:       currency,
        currencySymbol: currencySymbol,
        latitude:       currentState.latitude,
        longitude:      currentState.longitude,
      ));
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────

  /// Emit location from SharedPreferences (instant on app start)
  Future<void> _emitSavedLocation(
    SharedPreferences prefs,
    Emitter<LocationState> emit,
  ) async {
    final savedCity        = prefs.getString(_kCity);
    final savedCountry     = prefs.getString(_kCountry);
    final savedCountryCode = prefs.getString(_kCountryCode);
    final savedCurrency    = prefs.getString(_kCurrency);

    if (savedCity != null &&
        savedCountry != null &&
        savedCountryCode != null &&
        savedCurrency != null) {

      emit(LocationDetected(
        city:           savedCity,
        country:        savedCountry,
        countryCode:    savedCountryCode,
        currency:       savedCurrency,
        currencySymbol: prefs.getString(_kCurrencySymbol) ??
            CurrencyUtils.symbolFromCode(savedCurrency),
        latitude:       prefs.getDouble(_kLat) ?? 0.0,
        longitude:      prefs.getDouble(_kLng) ?? 0.0,
      ));
      
      // Post-emission check if serviceable
      await _checkIfServiceable(savedCity, emit);
    }
  }

  Future<void> _checkIfServiceable(String city, Emitter<LocationState> emit) async {
    try {
      final response = await ApiService.dio.get('/api/cities/active');
      final activeCities = (response.data['data'] as List).map((c) => c['name'].toString().toLowerCase()).toList();
      
      if (!activeCities.contains(city.toLowerCase())) {
        emit(LocationNotServiceable(city));
      }
    } catch (e) {
      // If backend fails, we allow them in, or we could block. For now, fail open.
    }
  }

  /// Save detected location and emit state
  Future<void> _saveAndEmit(
    SharedPreferences prefs,
    Emitter<LocationState> emit,
    LocationResult result,
  ) async {
    // Check if currency was manually overridden — if so, keep it
    final isManualCurrency = prefs.getBool(_kCurrencyManualSet) ?? false;

    final currency = isManualCurrency
        ? (prefs.getString(_kCurrency) ?? CurrencyUtils.fromCountry(result.countryCode))
        : CurrencyUtils.fromCountry(result.countryCode);

    final currencySymbol = CurrencyUtils.symbolFromCode(currency);

    // Save everything to SharedPreferences
    await Future.wait([
      prefs.setString(_kCity,           result.city),
      prefs.setString(_kCountry,        result.country),
      prefs.setString(_kCountryCode,    result.countryCode),
      prefs.setString(_kCurrency,       currency),
      prefs.setString(_kCurrencySymbol, currencySymbol),
      prefs.setDouble(_kLat,            result.lat),
      prefs.setDouble(_kLng,            result.lng),
      prefs.setInt(_kLastDetected,
          DateTime.now().millisecondsSinceEpoch),
    ]);

    // Send to backend (non-blocking)
    _updateBackend(
      city:     result.city,
      country:  result.country,
      currency: currency,
    );

    emit(LocationDetected(
      city:           result.city,
      country:        result.country,
      countryCode:    result.countryCode,
      currency:       currency,
      currencySymbol: currencySymbol,
      latitude:       result.lat,
      longitude:      result.lng,
    ));

    await _checkIfServiceable(result.city, emit);
  }

  /// Emit default USD if all detection fails
  Future<void> _emitDefault(
    SharedPreferences prefs,
    Emitter<LocationState> emit,
  ) async {
    await prefs.setString(_kCurrency,       'USD');
    await prefs.setString(_kCurrencySymbol, r'$');

    emit(const LocationDetected(
      city:           'New York City',
      country:        'United States',
      countryCode:    'US',
      currency:       'USD',
      currencySymbol: r'$',
      latitude:       40.7128,
      longitude:      -74.0060,
    ));
  }

  /// Send location/currency update to backend (fire and forget)
  void _updateBackend({
    String? city,
    String? country,
    String? currency,
  }) {
    final body = <String, dynamic>{};
    if (city != null)     body['city']     = city;
    if (country != null)  body['country']  = country;
    if (currency != null) body['currency'] = currency;

    if (body.isNotEmpty) {
      ApiService.dio.put('/api/users/profile', data: body).then((_) {}).catchError((_) {
        // Non-blocking — ignore backend errors for location updates
      });
    }
  }
}
