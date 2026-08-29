import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_event.dart';
import '../../blocs/location/location_state.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/listing_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/support_repository.dart';
import '../widgets/muza_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  // SharedPreferences Keys
  static const String _kPushEnabled = 'push_notifications_enabled';
  static const String _kBookingNotif = 'notif_booking_enabled';
  static const String _kMessageNotif = 'notif_messages_enabled';
  static const String _kPromoNotif = 'notif_promotions_enabled';
  static const String _kCurrency = 'user_currency';
  static const String _kLanguage = 'user_language';

  // Design System Colors
  static const Color _kPrimary = Color(0xFF0D6E75);
  static const Color _kPrimaryLight = Color(0xFFE0F2F1);
  static const Color _kAccent = Color(0xFFF5A623);
  static const Color _kBackground = Color(0xFFF7F8FA);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF111827);
  static const Color _kTextSecondary = Color(0xFF6B7280);
  static const Color _kDivider = Color(0xFFF3F4F6);
  static const Color _kError = Color(0xFFDC2626);
  static const Color _kErrorLight = Color(0xFFFEF2F2);
  static const Color _kSuccess = Color(0xFF16A34A);
  static const Color _kSuccessLight = Color(0xFFF0FDF4);
  static const Color _kWarning = Color(0xFFD97706);
  static const Color _kWarningLight = Color(0xFFFFFBEB);

  // Local state for toggles
  bool _pushEnabled = true;
  bool _bookingNotif = true;
  bool _messageNotif = true;
  bool _promoNotif = false;
  String _currency = 'USD';
  String _language = 'English';

  int _listingCount = 0;
  int _rentalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _fetchListingCount();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool(_kPushEnabled) ?? true;
      _bookingNotif = prefs.getBool(_kBookingNotif) ?? true;
      _messageNotif = prefs.getBool(_kMessageNotif) ?? true;
      _promoNotif = prefs.getBool(_kPromoNotif) ?? false;
      _currency = prefs.getString(_kCurrency) ?? 'USD';
      _language = prefs.getString(_kLanguage) ?? 'English';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _fetchListingCount() async {
    try {
      final results = await Future.wait([
        ListingRepository().getMyListings(),
        BookingRepository().getMyBookings(),
      ]);

      if (mounted) {
        setState(() {
          _listingCount = (results[0] as List).length;
          _rentalCount = (results[1] as List).length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          backgroundColor: _kBackground,
          appBar: AppBar(
            backgroundColor: _kBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _kPrimary),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildUserProfileCard(user),
                const SizedBox(height: 24),

                // Section 1: Account
                _buildStaggeredEntrance(
                  index: 0,
                  child: _SettingsSectionCard(
                    label: 'Account',
                    tiles: [
                      _SettingsTile(
                        icon: Icons.person_outline,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Personal Information',
                        subtitle: 'Name, phone, email',
                        onTap: () => context.push('/profile/edit'),
                      ),
                      _SettingsTile(
                        icon: Icons.verified_user_outlined,
                        iconBg: _getVerificationBg(user?.verificationStatus),
                        iconColor: _getVerificationColor(
                          user?.verificationStatus,
                        ),
                        title: 'Identity Verification',
                        subtitle: _getVerificationSubtitle(
                          user?.verificationStatus,
                        ),
                        trailing: _buildVerificationTrailing(
                          user?.verificationStatus,
                        ),
                        onTap: user?.verificationStatus == 'VERIFIED'
                            ? null
                            : () => context.push('/verification'),
                      ),
                      _SettingsTile(
                        icon: Icons.lock_outline,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: _showChangePasswordSheet,
                      ),
                    ],
                  ),
                ),

                // Section 2: Preferences
                _buildStaggeredEntrance(
                  index: 1,
                  child: _SettingsSectionCard(
                    label: 'Preferences',
                    tiles: [
                      _SettingsTile(
                        icon: Icons.public_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Location',
                        subtitle: 'Change your browsing region',
                        onTap: _showLocationSheet,
                      ),
                      _SettingsTile(
                        icon: Icons.payments_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Local Currency',
                        subtitle: _currency,
                        onTap: _showCurrencyPicker,
                      ),
                      _SettingsTile(
                        icon: Icons.language_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Language',
                        subtitle: _language,
                        onTap: _showLanguagePicker,
                      ),
                    ],
                  ),
                ),

                // Section 3: Notifications
                _buildStaggeredEntrance(
                  index: 2,
                  child: _SettingsSectionCard(
                    label: 'Notifications',
                    tiles: [
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Push Notifications',
                        subtitle: 'Receive alerts on your device',
                        trailing: CupertinoSwitch(
                          value: _pushEnabled,
                          activeTrackColor: _kPrimary,
                          onChanged: (val) {
                            if (!val) {
                              _confirmDisableNotifications();
                            } else {
                              setState(() => _pushEnabled = true);
                              _saveSetting(_kPushEnabled, true);
                            }
                          },
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.calendar_today_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Booking Updates',
                        subtitle: 'Requests, confirmations, cancellations',
                        enabled: _pushEnabled,
                        trailing: CupertinoSwitch(
                          value: _bookingNotif && _pushEnabled,
                          activeTrackColor: _kPrimary,
                          onChanged: _pushEnabled
                              ? (val) {
                                  setState(() => _bookingNotif = val);
                                  _saveSetting(_kBookingNotif, val);
                                }
                              : null,
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.chat_bubble_outline,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'New Messages',
                        subtitle: 'Chat notifications from renters and owners',
                        enabled: _pushEnabled,
                        trailing: CupertinoSwitch(
                          value: _messageNotif && _pushEnabled,
                          activeTrackColor: _kPrimary,
                          onChanged: _pushEnabled
                              ? (val) {
                                  setState(() => _messageNotif = val);
                                  _saveSetting(_kMessageNotif, val);
                                }
                              : null,
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.campaign_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Promotions & Updates',
                        subtitle: 'App news and special offers',
                        enabled: _pushEnabled,
                        trailing: CupertinoSwitch(
                          value: _promoNotif && _pushEnabled,
                          activeTrackColor: _kPrimary,
                          onChanged: _pushEnabled
                              ? (val) {
                                  setState(() => _promoNotif = val);
                                  _saveSetting(_kPromoNotif, val);
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Section 4: Privacy & Security
                _buildStaggeredEntrance(
                  index: 3,
                  child: _SettingsSectionCard(
                    label: 'Privacy & Security',
                    tiles: [
                      _SettingsTile(
                        icon: Icons.visibility_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Profile Visibility',
                        subtitle: 'Public',
                        trailing: const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Color(0xFFD1D5DB),
                        ),
                        onTap: _showProfileVisibilitySheet,
                      ),
                      _SettingsTile(
                        icon: Icons.policy_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Data & Privacy',
                        subtitle: 'Download your data, manage privacy',
                        onTap: _showDataPrivacySheet,
                      ),
                    ],
                  ),
                ),

                // Section 5: Support
                _buildStaggeredEntrance(
                  index: 4,
                  child: _SettingsSectionCard(
                    label: 'Support',
                    tiles: [
                      _SettingsTile(
                        icon: Icons.help_outline,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Help Center',
                        subtitle: 'FAQs and guides',
                        onTap: () => context.push('/support'),
                      ),
                      _SettingsTile(
                        icon: Icons.headset_mic_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Contact Support',
                        subtitle: 'Chat with our support team',
                        onTap: () => context.push('/support/new'),
                      ),
                      _SettingsTile(
                        icon: Icons.bug_report_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Report a Problem',
                        subtitle: 'Tell us what\'s not working',
                        onTap: _showReportProblemSheet,
                      ),
                      _SettingsTile(
                        icon: Icons.star_outline,
                        iconBg: _kWarningLight,
                        iconColor: _kWarning,
                        title: 'Rate RentHubIndia',
                        subtitle: 'Enjoying the app? Let us know!',
                        onTap: _launchStore,
                      ),
                    ],
                  ),
                ),

                // Section 6: About
                _buildStaggeredEntrance(
                  index: 5,
                  child: _SettingsSectionCard(
                    label: 'About',
                    tiles: [
                      _SettingsTile(
                        icon: Icons.info_outline,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'About RentHubIndia',
                        subtitle: 'Our story and mission',
                        onTap: _showAboutSheet,
                      ),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Terms of Service',
                        trailing: const Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: Color(0xFFD1D5DB),
                        ),
                        onTap: () => _launchUrl('https://renthubindia.com/terms'),
                      ),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Privacy Policy',
                        trailing: const Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: Color(0xFFD1D5DB),
                        ),
                        onTap: () => _launchUrl('https://renthubindia.com/privacy'),
                      ),
                      _SettingsTile(
                        icon: Icons.article_outlined,
                        iconBg: _kPrimaryLight,
                        iconColor: _kPrimary,
                        title: 'Open Source Licenses',
                        onTap: () => showLicensePage(context: context),
                      ),
                    ],
                  ),
                ),

                // Section 6: Follow Us
                _buildStaggeredEntrance(
                  index: 6,
                  child: _SettingsSectionCard(
                    label: 'Follow Us',
                    tiles: [
                      _SettingsTile(
                        icon: Icons.camera_alt_outlined,
                        iconBg: const Color(0xFFFCE7F3),
                        iconColor: const Color(0xFFDB2777),
                        title: 'Instagram',
                        subtitle: 'Follow us for updates & news',
                        onTap: () => _launchUrl(
                          'https://www.instagram.com/renthubindia.app/',
                        ),
                      ),
                      _SettingsTile(
                        icon: Icons.play_circle_outline,
                        iconBg: const Color(0xFFFEE2E2),
                        iconColor: const Color(0xFFDC2626),
                        title: 'YouTube',
                        subtitle: 'Watch our latest videos',
                        onTap: () => _launchUrl(
                          'https://youtube.com/@renthubindia-app?si=ptB_SB4DrXsuZNcW',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Logout
                _buildStaggeredEntrance(
                  index: 7,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _SettingsTile(
                      icon: Icons.logout,
                      iconBg: _kErrorLight,
                      iconColor: _kError,
                      title: 'Log Out',
                      isDestructive: true,
                      onTap: _showLogoutConfirmation,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _showDeleteAccountDialog,
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'RentHubIndia v1.0.0',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Made with ❤️ for renters everywhere',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── USER PROFILE CARD ──
  Widget _buildUserProfileCard(UserModel? user) {
    if (user == null) return const SizedBox.shrink();

    final isVerified = user.verificationStatus == 'VERIFIED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _kPrimaryLight,
                backgroundImage: user.avatarUrl != null
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary,
                        ),
                      )
                    : null,
              ),
              if (isVerified)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 14,
                      color: _kPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    color: _kTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: _kAccent),
                    const SizedBox(width: 2),
                    Text(
                      '${user.rating.toStringAsFixed(1)}  •  ',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: _kTextSecondary,
                      ),
                    ),
                    Text(
                      '$_listingCount listings  •  ',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: _kTextSecondary,
                      ),
                    ),
                    Text(
                      '$_rentalCount rentals',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: _kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Edit Button
          OutlinedButton(
            onPressed: () => context.push('/profile/edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 32),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──
  Color _getVerificationBg(String? status) {
    switch (status) {
      case 'VERIFIED':
        return _kSuccessLight;
      case 'PENDING':
        return _kWarningLight;
      default:
        return _kErrorLight;
    }
  }

  Color _getVerificationColor(String? status) {
    switch (status) {
      case 'VERIFIED':
        return _kSuccess;
      case 'PENDING':
        return _kWarning;
      default:
        return _kError;
    }
  }

  String _getVerificationSubtitle(String? status) {
    switch (status) {
      case 'VERIFIED':
        return 'Your identity is verified ✓';
      case 'PENDING':
        return 'Under review — we\'ll notify you';
      default:
        return 'Verify to unlock all features';
    }
  }

  Widget _buildVerificationTrailing(String? status) {
    if (status == 'VERIFIED') {
      return const _SettingsBadge(
        label: 'Verified',
        color: _kSuccess,
        textColor: Colors.white,
      );
    }
    if (status == 'PENDING') {
      return const _SettingsBadge(
        label: 'Pending',
        color: _kWarning,
        textColor: Colors.white,
      );
    }
    return const Icon(Icons.chevron_right, size: 20, color: Color(0xFFD1D5DB));
  }

  void _confirmDisableNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Disable all push notifications?',
          style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You will no longer receive alerts for bookings or messages.',
          style: TextStyle(fontFamily: 'PlusJakartaSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _pushEnabled = false);
              _saveSetting(_kPushEnabled, false);
              Navigator.pop(context);
            },
            child: const Text('Disable', style: TextStyle(color: _kError)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchStore() {
    _launchUrl('https://play.google.com/store/apps/details?id=com.renthubindia.app');
  }

  // ── BOTTOM SHEETS ──

  void _showLocationSheet() {
    final cityController = TextEditingController();
    String selectedCountry = 'Singapore';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            const Text(
              'Change Location',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: cityController,
              decoration: _buildInputDecoration('City', Icons.location_city),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCountry,
              decoration: _buildInputDecoration('Country', Icons.public),
              items: [
                'Singapore',
                'Malaysia',
                'Indonesia',
                'Thailand',
                'Vietnam',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => selectedCountry = val!,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.read<LocationBloc>().add(
                    ManualLocationChanged(
                      city: cityController.text,
                      country: selectedCountry,
                      countryCode: _getCountryCode(selectedCountry),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    final currencies = [
      {'code': 'SGD', 'name': 'Singapore Dollar', 'flag': '🇸🇬'},
      {'code': 'INR', 'name': 'Indian Rupee', 'flag': '🇮🇳'},
      {'code': 'USD', 'name': 'US Dollar', 'flag': '🇺🇸'},
      {'code': 'GBP', 'name': 'British Pound', 'flag': '🇬🇧'},
      {'code': 'JPY', 'name': 'Japanese Yen', 'flag': '🇯🇵'},
      {'code': 'AUD', 'name': 'Australian Dollar', 'flag': '🇦🇺'},
      {'code': 'MYR', 'name': 'Malaysian Ringgit', 'flag': '🇲🇾'},
      {'code': 'IDR', 'name': 'Indonesian Rupiah', 'flag': '🇮🇩'},
      {'code': 'PHP', 'name': 'Philippine Peso', 'flag': '🇵🇭'},
      {'code': 'THB', 'name': 'Thai Baht', 'flag': '🇹🇭'},
      {'code': 'AED', 'name': 'UAE Dirham', 'flag': '🇦🇪'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            const Text(
              'Select Currency',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Reset to automatic option
            ListTile(
              leading: const Icon(Icons.my_location, color: Color(0xFF0D6E75)),
              title: const Text(
                'Use automatic (based on location)',
                style: TextStyle(fontFamily: 'Sora', fontSize: 14),
              ),
              subtitle: BlocBuilder<LocationBloc, LocationState>(
                builder: (context, state) {
                  return FutureBuilder<SharedPreferences>(
                    future: SharedPreferences.getInstance(),
                    builder: (context, snapshot) {
                      final isManual =
                          snapshot.data?.getBool('currency_manually_set') ??
                          false;
                      return Text(
                        isManual
                            ? 'Currently: manual override'
                            : 'Currently active',
                        style: TextStyle(
                          color: isManual
                              ? Colors.orange
                              : const Color(0xFF16A34A),
                          fontSize: 12,
                        ),
                      );
                    },
                  );
                },
              ),
              onTap: () {
                context.read<LocationBloc>().add(const ResetCurrencyToAuto());
                Navigator.of(context).pop();
              },
            ),
            const Divider(),

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final c = currencies[index];
                  final isSelected = _currency == c['code'];
                  return ListTile(
                    onTap: () {
                      context.read<LocationBloc>().add(
                        ManualCurrencyOverride(currencyCode: c['code']!),
                      );
                      Navigator.pop(context);
                    },
                    leading: Text(
                      c['flag']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      '${c['code']} — ${c['name']}',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: _kPrimary)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const Text(
            'Select Language',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            onTap: () => Navigator.pop(context),
            title: const Text(
              'English',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(Icons.check, color: _kPrimary),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showChangePasswordSheet() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(),
              const Text(
                'Change Password',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: oldController,
                obscureText: obscureOld,
                decoration:
                    _buildInputDecoration(
                      'Current Password',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureOld ? Icons.visibility_off : Icons.visibility,
                          color: _kTextSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setSheetState(() => obscureOld = !obscureOld),
                      ),
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: obscureNew,
                decoration:
                    _buildInputDecoration(
                      'New Password',
                      Icons.lock_reset,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                          color: _kTextSecondary,
                          size: 20,
                        ),
                        onPressed: () =>
                            setSheetState(() => obscureNew = !obscureNew),
                      ),
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: obscureConfirm,
                decoration:
                    _buildInputDecoration(
                      'Confirm New Password',
                      Icons.lock_clock,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: _kTextSecondary,
                          size: 20,
                        ),
                        onPressed: () => setSheetState(
                          () => obscureConfirm = !obscureConfirm,
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (newController.text.length < 8) {
                            MuzaSnackbar.show(
                              context,
                              message:
                                  'New password must be at least 8 characters',
                              type: MuzaSnackbarType.error,
                            );
                            return;
                          }
                          if (newController.text != confirmController.text) {
                            MuzaSnackbar.show(
                              context,
                              message: 'Passwords do not match',
                              type: MuzaSnackbarType.error,
                            );
                            return;
                          }

                          setSheetState(() => isLoading = true);
                          try {
                            await AuthRepository().changePassword(
                              oldController.text,
                              newController.text,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              MuzaSnackbar.show(
                                context,
                                message: 'Password updated successfully!',
                                type: MuzaSnackbarType.success,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setSheetState(() => isLoading = false);
                              MuzaSnackbar.show(
                                context,
                                message: 'Error updating password',
                                type: MuzaSnackbarType.error,
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileVisibilitySheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const Text(
            'Profile Visibility',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            onTap: () => Navigator.pop(context),
            leading: const Icon(Icons.public, color: _kPrimary),
            title: const Text(
              '🌍 Public',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text('Anyone can view your profile'),
            trailing: const Icon(Icons.check, color: _kPrimary),
          ),
          ListTile(
            onTap: () => Navigator.pop(context),
            leading: const Icon(Icons.lock, color: _kTextSecondary),
            title: const Text(
              '🔒 Private',
              style: TextStyle(fontFamily: 'PlusJakartaSans'),
            ),
            subtitle: const Text('Only people you\'ve rented with can view'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDataPrivacySheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const Text(
            'Data & Privacy',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            onTap: () {
              Navigator.pop(context);
              MuzaSnackbar.show(
                context,
                message: 'We\'ll email your data within 48 hours',
                type: MuzaSnackbarType.info,
              );
            },
            leading: const Icon(Icons.download, color: _kPrimary),
            title: const Text(
              'Download My Data',
              style: TextStyle(fontFamily: 'Sora', fontSize: 14),
            ),
          ),
          ListTile(
            onTap: () {
              Navigator.pop(context);
              _showDeleteAccountDialog();
            },
            leading: const Icon(Icons.delete_forever, color: _kError),
            title: const Text(
              'Delete My Account',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 14,
                color: _kError,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showReportProblemSheet() {
    String category = 'Bug';
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            const Text(
              'Report a Problem',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: _buildInputDecoration('Category', Icons.category),
              items: [
                'Bug',
                'Wrong info',
                'Inappropriate content',
                'Other',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => category = val!,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: _buildInputDecoration(
                'Describe the issue',
                Icons.description,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (descController.text.isEmpty) return;
                  try {
                    await SupportRepository().createTicket(
                      category,
                      descController.text,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      MuzaSnackbar.show(
                        context,
                        message: 'Report submitted! Thank you.',
                        type: MuzaSnackbarType.success,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      MuzaSnackbar.show(
                        context,
                        message: 'Could not submit report',
                        type: MuzaSnackbarType.error,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Submit Report',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            const CircleAvatar(
              radius: 40,
              backgroundColor: _kPrimary,
              child: Icon(Icons.rocket_launch, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'RentHubIndia',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Rent Anything. Anywhere.',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: _kTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Version 1.0.0 (Build 1)',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: _kTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'RentHubIndia is a premium marketplace connecting owners and renters in a secure, trust-based environment. Our mission is to make high-quality items accessible to everyone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 14,
                color: _kTextPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Made with ❤️ for renters and owners',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: _kTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            const Text(
              'Log out of RentHubIndia?',
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You\'ll need to log in again to access your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: _kTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                      context.go('/auth');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final controller = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete your account?',
            style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will permanently delete all your data, listings, bookings, and messages. This action cannot be undone.',
                style: TextStyle(fontFamily: 'PlusJakartaSans'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                onChanged: (val) =>
                    setState(() => canDelete = val.toUpperCase() == 'DELETE'),
                decoration: _buildInputDecoration(
                  'Type DELETE to confirm',
                  Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: canDelete
                  ? () async {
                      try {
                        await AuthRepository().deleteAccount();
                        if (mounted) {
                          Navigator.pop(context);
                          context.read<AuthBloc>().add(LogoutRequested());
                          context.go('/auth');
                        }
                      } catch (e) {
                        if (mounted) {
                          MuzaSnackbar.show(
                            context,
                            message: 'Could not delete account',
                            type: MuzaSnackbarType.error,
                          );
                        }
                      }
                    }
                  : null,
              child: Text(
                'Delete My Account',
                style: TextStyle(color: canDelete ? _kError : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _kPrimary, size: 20),
      labelStyle: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        color: _kTextSecondary,
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kPrimary),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStaggeredEntrance({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  String _getCountryCode(String country) {
    switch (country) {
      case 'Singapore':
        return 'SG';
      case 'Malaysia':
        return 'MY';
      case 'Indonesia':
        return 'ID';
      case 'Thailand':
        return 'TH';
      case 'Vietnam':
        return 'VN';
      default:
        return 'US';
    }
  }
}

// ── REUSABLE PRIVATE WIDGETS ──

class _SettingsSectionCard extends StatelessWidget {
  final String label;
  final List<Widget> tiles;

  const _SettingsSectionCard({required this.label, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: label),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(tiles.length, (index) {
              return Column(
                children: [
                  tiles[index],
                  if (index < tiles.length - 1)
                    const Divider(
                      height: 1,
                      indent: 64,
                      color: Color(0xFFF3F4F6),
                    ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool enabled;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      splashColor: const Color(0xFF0D6E75).withValues(alpha: 0.06),
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDestructive
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF111827),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFFD1D5DB),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _SettingsBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
