import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

const String LAGUAGE_CODE = 'languageCode';
String? languageFlag;
const String ENGLISH = 'en';
const String HINDI = 'hi';
const String CHINESE = 'zh';
const String SPANISH = 'es';
const String ARABIC = 'ar';
const String RUSSIAN = 'ru';
const String JAPANESE = 'ja';
const String DEUTSCH = 'de';
Locale? loc;
int lang = 0;
Future<Locale> setLocale(final String languageCode) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(LAGUAGE_CODE, languageCode);
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String languageCode = prefs.getString(LAGUAGE_CODE) ?? "en";
  languageFlag = languageCode;
  return _locale(languageCode);
}

Locale _locale(final String languageCode) {
  switch (languageCode) {
    case ENGLISH:
      return const Locale(ENGLISH, 'US');
    case HINDI:
      return const Locale(HINDI, "IN");
    case CHINESE:
      return const Locale(CHINESE, "CN");
    case SPANISH:
      return const Locale(SPANISH, "ES");
    case ARABIC:
      return const Locale(ARABIC, "DZ");
    case RUSSIAN:
      return const Locale(RUSSIAN, "RU");
    case JAPANESE:
      return const Locale(JAPANESE, "JP");
    case DEUTSCH:
      return const Locale(DEUTSCH, "DE");
    default:
      return const Locale(ENGLISH, 'US');
  }
}

Future<void> changeLanguage(final BuildContext context, final String language) async {
  languageFlag = language;
  final Locale loc = await setLocale(language);
  MyApp.setLocale(context, loc);
}
