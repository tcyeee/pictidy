import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pictidy/screens/home_screen.dart';
import 'package:pictidy/services/locale_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PicTidyApp());
}

class PicTidyApp extends StatefulWidget {
  const PicTidyApp({super.key});

  @override
  State<PicTidyApp> createState() => _PicTidyAppState();
}

class _PicTidyAppState extends State<PicTidyApp> {
  Locale _locale = LocaleService.getDefaultLocale();

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final savedLocale = await LocaleService.getSavedLocale();
    if (savedLocale != null && mounted) {
      setState(() {
        _locale = savedLocale;
      });
    }
  }

  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    LocaleService.saveLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PicTidy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleService.supportedLocales,
      home: HomeScreen(onLocaleChanged: _changeLocale),
      debugShowCheckedModeBanner: false,
    );
  }
}

