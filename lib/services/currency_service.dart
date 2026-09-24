class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final String country;
  final String countryCode;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.country,
    required this.countryCode,
  });

  /// Converts ISO 3166-1 alpha-2 country code to emoji flag (e.g. "IN" -> 🇮🇳)
  String get flagEmoji {
    if (countryCode.length != 2) return "🌐";
    final int first = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int second = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}

class CurrencyService {
  static const CurrencyInfo defaultCurrency = CurrencyInfo(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    country: 'India',
    countryCode: 'IN',
  );

  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee', country: 'India', countryCode: 'IN'),
    CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar', country: 'United States', countryCode: 'US'),
    CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', country: 'European Union', countryCode: 'EU'),
    CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound', country: 'United Kingdom', countryCode: 'GB'),
    CurrencyInfo(code: 'AED', symbol: 'AED', name: 'UAE Dirham', country: 'United Arab Emirates', countryCode: 'AE'),
    CurrencyInfo(code: 'SAR', symbol: 'SAR', name: 'Saudi Riyal', country: 'Saudi Arabia', countryCode: 'SA'),
    CurrencyInfo(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar', country: 'Canada', countryCode: 'CA'),
    CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', country: 'Australia', countryCode: 'AU'),
    CurrencyInfo(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', country: 'Singapore', countryCode: 'SG'),
    CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen', country: 'Japan', countryCode: 'JP'),
    CurrencyInfo(code: 'KWD', symbol: 'KD', name: 'Kuwaiti Dinar', country: 'Kuwait', countryCode: 'KW'),
    CurrencyInfo(code: 'QAR', symbol: 'QR', name: 'Qatari Riyal', country: 'Qatar', countryCode: 'QA'),
    CurrencyInfo(code: 'OMR', symbol: 'OMR', name: 'Omani Rial', country: 'Oman', countryCode: 'OM'),
    CurrencyInfo(code: 'BHD', symbol: 'BD', name: 'Bahraini Dinar', country: 'Bahrain', countryCode: 'BH'),
    CurrencyInfo(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc', country: 'Switzerland', countryCode: 'CH'),
    CurrencyInfo(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar', country: 'New Zealand', countryCode: 'NZ'),
    CurrencyInfo(code: 'ZAR', symbol: 'R', name: 'South African Rand', country: 'South Africa', countryCode: 'ZA'),
    CurrencyInfo(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real', country: 'Brazil', countryCode: 'BR'),
    CurrencyInfo(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit', country: 'Malaysia', countryCode: 'MY'),
    CurrencyInfo(code: 'PHP', symbol: '₱', name: 'Philippine Peso', country: 'Philippines', countryCode: 'PH'),
    CurrencyInfo(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah', country: 'Indonesia', countryCode: 'ID'),
    CurrencyInfo(code: 'THB', symbol: '฿', name: 'Thai Baht', country: 'Thailand', countryCode: 'TH'),
    CurrencyInfo(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka', country: 'Bangladesh', countryCode: 'BD'),
    CurrencyInfo(code: 'PKR', symbol: 'PKR', name: 'Pakistani Rupee', country: 'Pakistan', countryCode: 'PK'),
    CurrencyInfo(code: 'LKR', symbol: 'Rs', name: 'Sri Lankan Rupee', country: 'Sri Lanka', countryCode: 'LK'),
    CurrencyInfo(code: 'NPR', symbol: 'Rs', name: 'Nepalese Rupee', country: 'Nepal', countryCode: 'NP'),
  ];
}