import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static CurrencyService? _instance;
  static CurrencyService get instance => _instance ??= CurrencyService._();
  CurrencyService._();

  static const String defaultCurrency = 'CDF';
  static const List<String> supportedCurrencies = ['CDF', 'USD'];

  double _exchangeRate = 2750.0; // 1 USD = 2750 CDF (default)
  String _displayCurrency = defaultCurrency;

  double get exchangeRate => _exchangeRate;
  String get displayCurrency => _displayCurrency;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _exchangeRate = prefs.getDouble('exchange_rate') ?? 2750.0;
    _displayCurrency = prefs.getString('display_currency') ?? defaultCurrency;
  }

  Future<void> setExchangeRate(double rate) async {
    _exchangeRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('exchange_rate', rate);
  }

  Future<void> setDisplayCurrency(String currency) async {
    if (!supportedCurrencies.contains(currency)) return;
    _displayCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_currency', currency);
  }

  double convertToUSD(double amountCDF) => amountCDF / _exchangeRate;
  double convertToCDF(double amountUSD) => amountUSD * _exchangeRate;

  double convert(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) {
      return amount;
    }
    if (fromCurrency == 'CDF' && toCurrency == 'USD') {
      return convertToUSD(amount);
    }
    if (fromCurrency == 'USD' && toCurrency == 'CDF') {
      return convertToCDF(amount);
    }
    return amount;
  }

  String formatAmount(double amount, String currency) {
    if (currency == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    }
    return '${amount.toStringAsFixed(0)} FC';
  }

  String get currencySymbol => 'FC';
  String symbolFor(String currency) => currency == 'USD' ? '\$' : 'FC';
}
