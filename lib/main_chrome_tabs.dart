import 'dart:async';
import 'dart:math';

import 'package:dynamic_tab_zenrouter/chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/tabs_path.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Route Definitions
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

abstract class TabRoute extends AppRoute with RouteTab {}

/// Main layout with Chrome-style tabs
class ChromeTabLayout extends AppRoute with RouteLayout<ChromeTabLayout> {
  @override
  TabsPath<TabRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabsPath;

  @override
  Widget buildPath(covariant AppCoordinator coordinator) {
    return ChromeTabs<TabRoute>(
      coordinator: coordinator,
      path: coordinator.tabsPath,
      onNewTab: () {
        // Add a random detail tab when the '+' button is pressed
        final random = Random().nextInt(100);
        coordinator.navigate(DetailTab(id: random, title: 'Tab $random'));
      },
    );
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chrome Tabs Demo'),
        centerTitle: false,
        elevation: 0,
      ),
      body: buildPath(coordinator),
    );
  }
}

/// Home tab - the first tab
class HomeTab extends TabRoute {
  @override
  Type? get layout => ChromeTabLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Chrome Tabs!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'This is a demo of a Chrome-like tab layout built with ZenRouter.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  final random = Random().nextInt(100);
                  coordinator.navigate(
                    DetailTab(id: random, title: 'Random Tab $random'),
                  );
                },
                icon: const Icon(Icons.tab),
                label: const Text('Open Random Tab'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  coordinator.navigate(AboutTab());
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Open About'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  coordinator.navigate(SettingsTab());
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Features:',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._buildFeatureList(context),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureList(BuildContext context) {
    final features = [
      'Chrome-like tab styling with rounded corners',
      'Smooth hover effects and animations',
      'Click tabs to switch between them',
      'Close button appears on hover',
      'Add new tabs with the + button',
      'Horizontal scrolling for many tabs',
      'Dark mode support',
    ];

    return features
        .map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 20, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  @override
  Widget tabLabel(
    AppCoordinator coordinator,
    TabsPath path,
    BuildContext context,
    bool active,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.home, size: 16),
        const SizedBox(width: 8),
        Text(
          'Home',
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Uri toUri() => Uri.parse('/home');
}

/// Detail tab with customizable content
class DetailTab extends TabRoute {
  DetailTab({required this.id, required this.title});

  final int id;
  final String title;

  @override
  List<Object?> get props => [id];

  @override
  Type? get layout => ChromeTabLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Tab ID: $id',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Text(
                        'Tab Information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, 'Created', DateTime.now().toString()),
                  _buildInfoRow(context, 'Type', 'Detail Tab'),
                  _buildInfoRow(context, 'Closeable', 'Yes'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget tabLabel(
    AppCoordinator coordinator,
    TabsPath path,
    BuildContext context,
    bool active,
  ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Uri toUri() => Uri.parse('/detail/$id');
}

/// About tab
class AboutTab extends TabRoute {
  @override
  Type? get layout => ChromeTabLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'This is a demonstration of Chrome-style tabs using ZenRouter.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text(
            'Technologies Used:',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTechItem(context, 'Flutter', 'UI Framework'),
          _buildTechItem(context, 'ZenRouter', 'Navigation & Routing'),
          _buildTechItem(context, 'TabsPath', 'Tab State Management'),
        ],
      ),
    );
  }

  Widget _buildTechItem(BuildContext context, String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget tabLabel(
    AppCoordinator coordinator,
    TabsPath path,
    BuildContext context,
    bool active,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info, size: 16),
        const SizedBox(width: 8),
        Text(
          'About',
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Uri toUri() => Uri.parse('/about');
}

/// Settings tab
class SettingsTab extends TabRoute {
  @override
  Type? get layout => ChromeTabLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildSettingItem(
            context,
            'Theme',
            'Automatically switches between light and dark mode',
            Icons.brightness_6,
          ),
          _buildSettingItem(
            context,
            'Tab Behavior',
            'Close tabs with middle click or close button',
            Icons.tab,
          ),
          _buildSettingItem(
            context,
            'Animations',
            'Smooth transitions and hover effects enabled',
            Icons.animation,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget tabLabel(
    AppCoordinator coordinator,
    TabsPath path,
    BuildContext context,
    bool active,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.settings, size: 16),
        const SizedBox(width: 8),
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Uri toUri() => Uri.parse('/settings');
}

/// Index route that redirects to home
class IndexRoute extends AppRoute with RouteRedirect {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) =>
      const SizedBox.shrink();

  @override
  Uri toUri() => Uri.parse('/');

  @override
  FutureOr<RouteTarget?> redirect() => HomeTab();
}

// ============================================================================
// Coordinator
// ============================================================================

class AppCoordinator extends Coordinator<AppRoute> {
  late final tabsPath = TabsPath<TabRoute>.createWith(
    coordinator: this,
    label: 'tabs',
    stack: [HomeTab()], // Start with home tab
  );

  @override
  List<StackPath<RouteTarget>> get paths => [...super.paths, tabsPath];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(ChromeTabLayout, ChromeTabLayout.new);
  }

  @override
  FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['home'] => HomeTab(),
      ['detail', final id] => DetailTab(
        id: int.tryParse(id) ?? 0,
        title: 'Detail $id',
      ),
      ['about'] => AboutTab(),
      ['settings'] => SettingsTab(),
      _ => HomeTab(),
    };
  }
}

// ============================================================================
// Main
// ============================================================================

void main() {
  TabsPath.definePath();

  final coordinator = AppCoordinator();

  runApp(
    MaterialApp.router(
      title: 'Chrome Tabs Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    ),
  );
}
