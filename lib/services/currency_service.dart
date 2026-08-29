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
  ];
}