import 'package:flutter/material.dart';

// A global RouteObserver that can be used to track route transitions
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// A mixin that can be used with StatefulWidget's State to track tab navigation
mixin TabNavigationObserver<T extends StatefulWidget> on State<T>
    implements RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute as PageRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    // Route was pushed onto navigator and is now topmost route
    onTabVisible();
  }

  @override
  void didPopNext() {
    // Covering route was popped off the navigator
    onTabVisible();
  }

  @override
  void didPushNext() {
    // This route is no longer visible
    onTabInvisible();
  }

  @override
  void didPop() {
    // This route was popped off the navigator
    onTabInvisible();
  }

  // Override these methods to handle tab visibility changes
  void onTabVisible() {}
  void onTabInvisible() {}
}

// For use in non-tab navigation contexts
abstract class TabAwareState<T extends StatefulWidget> extends State<T>
    with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute as PageRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    // Route was pushed onto navigator and is now topmost route
    onTabEnter();
  }

  @override
  void didPopNext() {
    // Covering route was popped off the navigator
    onTabEnter();
  }

  @override
  void didPushNext() {
    // This route is no longer visible
    onTabExit();
  }

  @override
  void didPop() {
    // This route was popped off the navigator
    onTabExit();
  }

  // Override these in your state class
  void onTabEnter() {}
  void onTabExit() {}

  @override
  Widget build(BuildContext context) {
    // Must be overridden by subclasses
    throw UnimplementedError();
  }
}
