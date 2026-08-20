import 'package:flutter/material.dart';
import 'routes/routes.dart';
import 'theme/app_theme.dart';
import 'constants/app_constants.dart';
import '../core/services/service_locator.dart';
import '../core/services/error_reporting/safe_navigator_observer.dart';
import '../core/services/audio/audio_focus_handler.dart';

class ColorMatchTrailApp extends StatelessWidget {
  const ColorMatchTrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locManager = ServiceLocator.instance.localizationManager;

    return ListenableBuilder(
      listenable: locManager,
      builder: (context, _) {
        return AudioFocusHandler(
          child: MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeData,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            navigatorObservers: [SafeNavigatorObserver()],
            locale: locManager.currentLocale.flutterLocale,
            builder: (context, child) {
              return Directionality(
                textDirection: locManager.textDirection,
                child: child!,
              );
            },
          ),
        );
      },
    );
  }
}

