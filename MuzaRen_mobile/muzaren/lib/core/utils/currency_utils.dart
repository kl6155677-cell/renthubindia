import 'package:intl/intl.dart';

class CurrencyUtils {
  static final Map<String, String> _countryToCurrency = {
    // A-C
    'AF': 'AFN', 'AL': 'ALL', 'DZ': 'DZD', 'AD': 'EUR', 'AO': 'AOA', 'AR': 'ARS', 'AM': 'AMD', 'AU': 'AUD', 'AT': 'EUR', 'AZ': 'AZN',
    'BS': 'BSD', 'BH': 'BHD', 'BD': 'BDT', 'BB': 'BBD', 'BY': 'BYN', 'BE': 'EUR', 'BZ': 'BZD', 'BJ': 'XOF', 'BT': 'BTN', 'BO': 'BOB',
    'BA': 'BAM', 'BW': 'BWP', 'BR': 'BRL', 'BN': 'BND', 'BG': 'BGN', 'BF': 'XOF', 'BI': 'BIF', 'KH': 'KHR', 'CM': 'XAF', 'CA': 'CAD',
    'CV': 'CVE', 'CF': 'XAF', 'TD': 'XAF', 'CL': 'CLP', 'CN': 'CNY', 'CO': 'COP', 'KM': 'KMF', 'CG': 'XAF', 'CR': 'CRC', 'HR': 'EUR',
    'CU': 'CUP', 'CY': 'EUR', 'CZ': 'CZK',
    // D-G
    'DK': 'DKK', 'DJ': 'DJF', 'DM': 'XCD', 'DO': 'DOP', 'EC': 'USD', 'EG': 'EGP', 'SV': 'USD', 'GQ': 'XAF', 'ER': 'ERN', 'EE': 'EUR',
    'ET': 'ETB', 'FJ': 'FJD', 'FI': 'EUR', 'FR': 'EUR', 'GA': 'XAF', 'GM': 'GMD', 'GE': 'GEL', 'DE': 'EUR', 'GH': 'GHS', 'GR': 'EUR',
    'GD': 'XCD', 'GT': 'GTQ', 'GN': 'GNF', 'GW': 'XOF', 'GY': 'GYD',
    // H-L
    'HT': 'HTG', 'HN': 'HNL', 'HK': 'HKD', 'HU': 'HUF', 'IS': 'ISK', 'IN': 'INR', 'ID': 'IDR', 'IR': 'IRR', 'IQ': 'IQD', 'IE': 'EUR',
    'IL': 'ILS', 'IT': 'EUR', 'CI': 'XOF', 'JM': 'JMD', 'JP': 'JPY', 'JO': 'JOD', 'KZ': 'KZT', 'KE': 'KES', 'KI': 'AUD', 'KP': 'KPW',
    'KR': 'KRW', 'KW': 'KWD', 'KG': 'KGS', 'LA': 'LAK', 'LV': 'EUR', 'LB': 'LBP', 'LS': 'LSL', 'LR': 'LRD', 'LY': 'LYD', 'LI': 'CHF',
    'LT': 'EUR', 'LU': 'EUR',
    // M-P
    'MO': 'MOP', 'MK': 'MKD', 'MG': 'MGA', 'MW': 'MWK', 'MY': 'MYR', 'MV': 'MVR', 'ML': 'XOF', 'MT': 'EUR', 'MH': 'USD', 'MR': 'MRU',
    'MU': 'MUR', 'MX': 'MXN', 'FM': 'USD', 'MD': 'MDL', 'MC': 'EUR', 'MN': 'MNT', 'ME': 'EUR', 'MA': 'MAD', 'MZ': 'MZN', 'MM': 'MMK',
    'NA': 'NAD', 'NR': 'AUD', 'NP': 'NPR', 'NL': 'EUR', 'NZ': 'NZD', 'NI': 'NIO', 'NE': 'XOF', 'NG': 'NGN', 'NO': 'NOK', 'OM': 'OMR',
    'PK': 'PKR', 'PW': 'USD', 'PA': 'PAB', 'PG': 'PGK', 'PY': 'PYG', 'PE': 'PEN', 'PH': 'PHP', 'PL': 'PLN', 'PT': 'EUR',
    // Q-S
    'QA': 'QAR', 'RO': 'RON', 'RU': 'RUB', 'RW': 'RWF', 'KN': 'XCD', 'LC': 'XCD', 'VC': 'XCD', 'WS': 'WST', 'SM': 'EUR', 'ST': 'STN',
    'SA': 'SAR', 'SN': 'XOF', 'RS': 'RSD', 'SC': 'SCR', 'SL': 'SLL', 'SG': 'SGD', 'SK': 'EUR', 'SI': 'EUR', 'SB': 'SBD', 'SO': 'SOS',
    'ZA': 'ZAR', 'ES': 'EUR', 'LK': 'LKR', 'SD': 'SDG', 'SR': 'SRD', 'SZ': 'SZL', 'SE': 'SEK', 'CH': 'CHF', 'SY': 'SYP',
    // T-Z
    'TW': 'TWD', 'TJ': 'TJS', 'TZ': 'TZS', 'TH': 'THB', 'TL': 'USD', 'TG': 'XOF', 'TO': 'TOP', 'TT': 'TTD', 'TN': 'TND', 'TR': 'TRY',
    'TM': 'TMT', 'TV': 'AUD', 'UG': 'UGX', 'UA': 'UAH', 'AE': 'AED', 'GB': 'GBP', 'US': 'USD', 'UY': 'UYU', 'UZ': 'UZS', 'VU': 'VUV',
    'VE': 'VES', 'VN': 'VND', 'YE': 'YER', 'ZM': 'ZMW', 'ZW': 'ZWL',
  };

  static final Map<String, String> _currencyToSymbol = {
    'SGD': 'S\$', 'INR': '₹', 'USD': r'$', 'GBP': '£', 'JPY': '¥', 'AUD': 'A\$', 'MYR': 'RM', 'IDR': 'Rp', 'PHP': '₱', 'THB': '฿',
    'AED': 'د.إ', 'SAR': 'ر.س', 'MAD': 'DH', 'EGP': 'E£', 'TRY': '₺', 'EUR': '€', 'CAD': 'C\$', 'QAR': 'ر.ق', 'OMR': 'ر.ع.',
    'KWD': 'د.ك', 'BHD': '.د.ب', 'JOD': 'د.أ', 'LBP': 'ل.ل', 'CNY': '¥', 'HKD': 'HK\$', 'NZD': 'NZ\$', 'KRW': '₩', 'TWD': 'NT\$',
    'BRL': 'R\$', 'RUB': '₽', 'ZAR': 'R', 'MXN': 'Mex\$', 'PKR': 'Rs', 'VND': '₫', 'ILS': '₪', 'PLN': 'zł', 'SEK': 'kr', 'NOK': 'kr',
    'DKK': 'kr', 'CHF': 'CHF', 'HUF': 'Ft', 'CZK': 'Kč', 'RON': 'lei', 'GEL': '₾', 'AZN': '₼', 'KZT': '₸', 'UAH': '₴', 'NGN': '₦',
    'GHS': 'GH₵', 'KES': 'KSh', 'DZD': 'DA', 'TND': 'DT', 'CLP': 'CLP\$', 'COP': 'COL\$', 'PEN': 'S/',
    'ARS': 'AR\$', 'UYU': '\$U', 'PYG': 'Gs', 'BOB': 'Bs', 'CRC': '₡', 'GTQ': 'Q', 'HNL': 'L', 'NIO': 'C\$', 'PAB': 'B/.', 'DOP': 'RD\$',
    'AFN': '؋', 'BDT': '৳', 'LKR': 'Rs', 'NPR': 'Rs', 'KHR': '៛', 'LAK': '₭', 'MMK': 'K', 'MVR': 'Rf', 'MNT': '₮', 'IQD': 'ID',
    'IRR': 'IR', 'YER': 'YR', 'SYP': 'LS', 'KPW': '₩', 'BND': 'B\$', 'FJD': 'FJ\$', 'PGK': 'K', 'WST': 'T', 'TOP': 'T\$',
  };

  static String fromCountry(String country) {
    final clean = country.trim().toUpperCase();
    
    // Check if it's a 2-letter code
    if (_countryToCurrency.containsKey(clean)) {
      return _countryToCurrency[clean]!;
    }

    // Check by full name or common aliases (case-insensitive)
    final Map<String, String> nameToCode = {
      'SINGAPORE': 'SG',
      'SGP': 'SG',
      'INDIA': 'IN',
      'IND': 'IN',
      'UNITED STATES': 'US',
      'USA': 'US',
      'UNITED KINGDOM': 'GB',
      'UK': 'GB',
      'JAPAN': 'JP',
      'JPN': 'JP',
      'AUSTRALIA': 'AU',
      'AUS': 'AU',
      'MALAYSIA': 'MY',
      'MYS': 'MY',
      'INDONESIA': 'ID',
      'IDN': 'ID',
      'PHILIPPINES': 'PH',
      'PHL': 'PH',
      'THAILAND': 'TH',
      'THA': 'TH',
      'UNITED ARAB EMIRATES': 'AE',
      'UAE': 'AE',
      'SAUDI ARABIA': 'SA',
      'SAU': 'SA',
      'MOROCCO': 'MA',
      'MAR': 'MA',
      'EGYPT': 'EG',
      'EGY': 'EG',
      'TURKEY': 'TR',
      'TUR': 'TR',
      'FRANCE': 'FR',
      'FRA': 'FR',
      'GERMANY': 'DE',
      'DEU': 'DE',
      'CANADA': 'CA',
      'CAN': 'CA',
      'QATAR': 'QA',
      'QAT': 'QA',
      'OMAN': 'OM',
      'OMN': 'OM',
      'KUWAIT': 'KW',
      'KWT': 'KW',
      'BAHRAIN': 'BH',
      'BHR': 'BH',
      'JORDAN': 'JO',
      'JOR': 'JO',
      'LEBANON': 'LB',
      'LBN': 'LB',
      'CHINA': 'CN',
      'CHN': 'CN',
    };

    final code = nameToCode[clean];
    if (code != null) return _countryToCurrency[code] ?? 'USD';

    return 'USD';
  }

  static String symbolFromCode(String currencyCode) {
    try {
      return NumberFormat.simpleCurrency(name: currencyCode.toUpperCase()).currencySymbol;
    } catch (_) {
      return _currencyToSymbol[currencyCode.toUpperCase()] ?? r'$';
    }
  }

  static String format(double amount, String country) {
    try {
      String currencyCode = fromCountry(country);
      return NumberFormat.simpleCurrency(name: currencyCode, decimalDigits: 0).format(amount);
    } catch (_) {
      String currencyCode = fromCountry(country);
      String symbol = symbolFromCode(currencyCode);
      return '$symbol${amount.toStringAsFixed(0)}';
    }
  }
}
