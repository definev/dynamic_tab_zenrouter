import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// ==================== Base Route Classes ====================

abstract class AppRoute extends RouteTarget with RouteUnique {}

// ==================== Master-Detail Layout ====================

/// The root layout that handles responsive master-detail display.
/// - Wide screens (≥800px): Shows master list and detail side by side
/// - Narrow screens: Shows only master list; detail pushes fullscreen
class HostLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(MasterDetailCoordinator coordinator) =>
      coordinator.homeHost;

  @override
  Widget build(MasterDetailCoordinator coordinator, BuildContext context) {
    return MasterDetailScaffold(
      coordinator: coordinator,
      path: coordinator.homeHost,
    );
  }
}

class MasterDetailScaffold extends StatelessWidget {
  const MasterDetailScaffold({
    super.key,
    required this.coordinator,
    required this.path,
  });

  final MasterDetailCoordinator coordinator;
  final IndexedStackPath<AppRoute> path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: path,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final isWide = constraints.maxWidth >= 800;
            final masterWidth = isWide ? size.width * 0.3 : size.width;
            final detailWidth = isWide ? size.width * 0.7 : size.width;

            return Stack(
              children: [
                // Build master list
                Align(
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: SizedBox(
                      height: size.height,
                      width: masterWidth,
                      child: path.stack[0].build(coordinator, context),
                    ),
                  ),
                ),
                // Build detail
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: size.height,
                    width: detailWidth,
                    child: ListenableBuilder(
                      listenable: coordinator.detailPath,
                      builder: (context, child) => Stack(
                        children: [
                          if (isWide)
                            Positioned.fill(
                              child: Center(
                                child: Text(
                                  'Click on item in master to open detail',
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: path.stack[1].build(coordinator, context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: switch (coordinator.activeLayoutPaths.contains(
          coordinator.homeHost,
        )) {
          true => 0,
          false => 1,
        },
        onTap: (index) {
          switch (index) {
            case 0:
              coordinator.navigate(MasterLayout());
            case 1:
              coordinator.push(SettingsRoute());
          }
        },
      ),
    );
  }
}

class ChatListRoute extends AppRoute {
  @override
  Type? get layout => MasterLayout;

  @override
  Uri toUri() => Uri.parse('/chat');

  @override
  Widget build(MasterDetailCoordinator coordinator, BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => ListTile(
        title: Text('Chat $index'),
        onTap: () => coordinator.push(ChatDetailRoute(id: index.toString())),
      ),
    );
  }
}

class ChatDetailRoute extends AppRoute {
  ChatDetailRoute({required this.id});

  final String id;

  @override
  Type? get layout => DetailLayout;

  @override
  Uri toUri() => Uri.parse('/chat/detail/$id');

  @override
  Widget build(MasterDetailCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Detail'),
        leading: BackButton(onPressed: () => coordinator.tryPopDetail()),
      ),
      body: Center(child: Text('Chat Detail $id')),
    );
  }
}

class SettingsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(MasterDetailCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(child: Text('Settings')),
    );
  }
}

// ==================== Index/Redirect Route ====================
class IndexRoute extends AppRoute with RouteRedirect {
  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) => const SizedBox.shrink();

  @override
  Uri toUri() => Uri.parse('/');

  @override
  FutureOr<RouteTarget> redirect() => ChatListRoute();
}

// ==================== Layout ====================
class MasterLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Type? get layout => HostLayout;

  @override
  StackPath<RouteUnique> resolvePath(MasterDetailCoordinator coordinator) =>
      coordinator.masterPath;
}

class DetailLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Type? get layout => HostLayout;

  @override
  StackPath<RouteUnique> resolvePath(MasterDetailCoordinator coordinator) =>
      coordinator.detailPath;
}

// ==================== Coordinator ====================

class MasterDetailCoordinator extends Coordinator<AppRoute> {
  late final homeHost = IndexedStackPath<AppRoute>.createWith(
    [MasterLayout(), DetailLayout()],
    coordinator: this,
    label: 'home',
  );

  late final masterPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'master',
  );

  late final detailPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'detail',
  );

  @override
  List<StackPath<RouteTarget>> get paths => [
    ...super.paths,
    homeHost,
    masterPath,
    detailPath,
  ];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(HostLayout, HostLayout.new);
    RouteLayout.defineLayout(MasterLayout, MasterLayout.new);
    RouteLayout.defineLayout(DetailLayout, DetailLayout.new);
  }

  @override
  FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['chat'] => ChatListRoute(),
      ['chat', 'detail', final id] => ChatDetailRoute(id: id),
      ['settings'] => SettingsRoute(),
      _ => IndexRoute(),
    };
  }

  void tryPopDetail() {
    if (detailPath.stack.isEmpty) {
      masterPath.reset();
    } else {
      detailPath.pop();
    }
  }
}

// ==================== Main Entry Point ====================

void main() {
  final coordinator = MasterDetailCoordinator();

  runApp(
    MaterialApp.router(
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    ),
  );
}
