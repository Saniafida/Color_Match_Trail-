import 'package:flutter/material.dart';
import '../service_locator.dart';

class AudioFocusHandler extends StatefulWidget {
  final Widget child;

  const AudioFocusHandler({super.key, required this.child});

  @override
  State<AudioFocusHandler> createState() => _AudioFocusHandlerState();
}

class _AudioFocusHandlerState extends State<AudioFocusHandler> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final audioManager = ServiceLocator.instance.audioManager;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App went to background or was interrupted (e.g. phone call)
        audioManager.pauseAll();
        break;
      case AppLifecycleState.resumed:
        // App returned to foreground
        audioManager.resumeAll();
        break;
      case AppLifecycleState.detached:
        // App is being killed
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
