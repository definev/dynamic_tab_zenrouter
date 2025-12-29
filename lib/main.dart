import 'dart:async';
import 'dart:math';

import 'package:dynamic_tab_zenrouter/tabs_path.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

abstract class AppRoute extends RouteTarget with RouteUnique {}

abstract class TabRoute extends AppRoute with RouteTab {}

class FixedTabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(TabCoordinator coordinator) =>
      coordinator.homeTab;

  @override
  Widget build(covariant TabCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fixed Tab Layout')),
      body: buildPath(coordinator),
      bottomNavigationBar: ListenableBuilder(
        listenable: coordinator.homeTab,
        builder: (context, child) => BottomNavigationBar(
          currentIndex: coordinator.homeTab.activeIndex,
          onTap: (index) => coordinator.homeTab.goToIndexed(index),
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Tab'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class TabLayout extends AppRoute with RouteLayout<TabLayout> {
  @override
  Type? get layout => FixedTabLayout;

  @override
  TabsPath<TabRoute> resolvePath(covariant TabCoordinator coordinator) =>
      coordinator.tabsPath;
}

class HomeFirstTab extends TabRoute {
  @override
  Type? get layout => TabLayout;

  @override
  Widget build(covariant TabCoordinator coordinator, BuildContext context) {
    final path =
        resolveLayout(coordinator)!.resolvePath(coordinator) as TabsPath;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Home First Tab'),
          ElevatedButton(
            onPressed: () {
              final random = Random().nextInt(10);
              path.goTo(DetailFirstTab(id: random));
            },
            child: Text('Open random detail'),
          ),
        ],
      ),
    );
  }

  @override
  Widget tabLabel(
    TabCoordinator coordinator,
    TabsPath path,
    BuildContext context,
    bool active,
  ) => GestureDetector(
    onTap: () => path.goTo(this),
    child: Container(
      height: 40,
      padding: EdgeInsets.all(8),
      color: active ? Colors.blue : Colors.grey,
      child: const Text('Home'),
    ),
  );

  @override
  Uri toUri() => Uri.parse('/first/home');
}

class DetailFirstTab extends TabRoute {
  DetailFirstTab({required this.id});

  final int id;

  @override
  List<Object?> get props => [id];

  @override
  Type? get layout => TabLayout;

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return Center(child: Text('Detail First Tab\nID: $id'));
  }

  @override
  Widget tabLabel(
    TabCoordinator coordinator,
    TabsPath path,
    BuildContext context,
    bool active,
  ) => GestureDetector(
    onTap: () => path.goTo(this),
    child: Row(
      children: [
        Container(
          height: 40,
          padding: EdgeInsets.all(8),
          color: active ? Colors.blue : Colors.grey,
          child: Text('Detail $id'),
        ),
        GestureDetector(
          onTap: () => path.remove(this),
          child: Icon(Icons.close),
        ),
      ],
    ),
  );

  @override
  Uri toUri() => Uri.parse('/first/detail/$id');
}

class SettingsRoute extends AppRoute {
  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return const Center(child: Text('Settings'));
  }

  @override
  Uri toUri() => Uri.parse('/settings');
}

class IndexRoute extends AppRoute with RouteRedirect {
  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) => SizedBox.shrink();

  @override
  Uri toUri() => Uri.parse('/');

  @override
  FutureOr<RouteTarget?> redirect() => HomeFirstTab();
}

class TabCoordinator extends Coordinator<AppRoute> {
  late final homeTab = IndexedStackPath<AppRoute>.createWith(
    [TabLayout(), SettingsRoute()],
    coordinator: this,
    label: 'home',
  );

  late final tabsPath = TabsPath<TabRoute>.createWith(
    coordinator: this,
    label: 'tabs',
  );

  @override
  List<StackPath<RouteTarget>> get paths => [...super.paths, homeTab, tabsPath];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(FixedTabLayout, FixedTabLayout.new);
    RouteLayout.defineLayout(TabLayout, TabLayout.new);
  }

  @override
  FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['first', 'home'] => HomeFirstTab(),
      ['first', 'detail', final id] => DetailFirstTab(id: int.parse(id)),
      ['settings'] => SettingsRoute(),
      _ => HomeFirstTab(),
    };
  }
}

void main() {
  TabsPath.definePath();

  final coordinator = TabCoordinator();

  runApp(
    MaterialApp.router(
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    ),
  );
}
