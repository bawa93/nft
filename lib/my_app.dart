import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nft/generated/l10n.dart';
import 'package:nft/services/app/app_dialog.dart';
import 'package:nft/services/app/app_loading.dart';
import 'package:nft/services/app/auth_provider.dart';
import 'package:nft/services/app/locale_provider.dart';
import 'package:nft/services/cache/cache.dart';
import 'package:nft/services/cache/cache_preferences.dart';
import 'package:nft/services/cache/credential.dart';
import 'package:nft/services/rest_api/api_user.dart';
import 'package:nft/utils/app_extension.dart';
import 'package:nft/utils/app_route.dart';
import 'package:nft/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Future<void> myMain() async {
  /// Start services later
  WidgetsFlutterBinding.ensureInitialized();

  /// Force portrait mode
  await SystemChrome.setPreferredOrientations(
      <DeviceOrientation>[DeviceOrientation.portraitUp]);

  /// Run Application
  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        Provider<AppRoute>(create: (_) => AppRoute()),
        Provider<Cache>(create: (_) => CachePreferences()),
        ChangeNotifierProvider<Credential>(
            create: (BuildContext context) => Credential(
                  Provider.of(context, listen: false),
                )),
        ProxyProvider<Credential, ApiUser>(
            create: (_) => ApiUser(),
            update: (_, Credential credential, ApiUser userApi) {
              return userApi..token = credential.token;
            }),
        Provider<AppLoading>(create: (_) => AppLoading()),
        Provider<AppDialog>(create: (_) => AppDialog()),
        ChangeNotifierProvider<LocaleProvider>(
            create: (BuildContext context) => LocaleProvider()),
        ChangeNotifierProvider<AppThemeProvider>(
            create: (BuildContext context) => AppThemeProvider()),
        ChangeNotifierProvider<AuthProvider>(
            create: (BuildContext context) => AuthProvider(
                  Provider.of(context, listen: false),
                  Provider.of(context, listen: false),
                )),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    /// Init page
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bool hasCredential =
          await context.read<Credential>().loadCredential();
      if (hasCredential) {
        context.navigator().pushReplacementNamed(AppRoute.routeHome);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Get providers
    final AppRoute appRoute = context.watch<AppRoute>();
    final LocaleProvider localeProvider = context.watch<LocaleProvider>();
    final AppTheme appTheme = context.appTheme();

    /// Build Material app
    return MaterialApp(
      navigatorKey: appRoute.navigatorKey,
      locale: localeProvider.locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: appTheme.buildThemeData(),
      //https://stackoverflow.com/questions/57245175/flutter-dynamic-initial-route
      //https://github.com/flutter/flutter/issues/12454
      //home: (appRoute.generateRoute(
      ///            const RouteSettings(name: AppRoute.rootPageRoute))
      ///        as MaterialPageRoute<dynamic>)
      ///    .builder(context),
      initialRoute: AppRoute.routeRoot,
      onGenerateRoute: appRoute.generateRoute,
      navigatorObservers: <NavigatorObserver>[appRoute.routeObserver],
    );
  }
}
