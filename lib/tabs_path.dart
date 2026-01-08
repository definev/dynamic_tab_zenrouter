import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

mixin RouteTab on RouteUnique {
  Widget tabLabel(
    covariant Coordinator coordinator,
    covariant TabsPath path,
    BuildContext context,
    bool active,
  );
}

class TabsPathModel<T> {
  final List<T> stack;
  final int activeIndex;

  TabsPathModel(this.stack, this.activeIndex);
}

class TabsPath<T extends RouteTab> extends StackPath<T>
    with
        StackMutatable<T>,
        StackNavigatable<T>,
        RestorablePath<T, Map<String, dynamic>, TabsPathModel<T>> {
  TabsPath._(super.stack, {super.debugLabel, super.coordinator});

  factory TabsPath.createWith({
    required Coordinator coordinator,
    required String label,
    List<T>? stack,
  }) => TabsPath._(stack ?? [], debugLabel: label, coordinator: coordinator);

  static void definePath() => RouteLayout.definePath(
    key,
    (coordinator, path, layout) =>
        TabsPathBuilder(coordinator: coordinator, path: path as TabsPath),
  );

  static const key = PathKey('TabsPath');

  int? _activeIndex;
  int? get activeIndex => _activeIndex;

  void goToIndexed(int index) {
    _activeIndex = index;
    notifyListeners();
  }

  void goTo(T route) {
    final index = stack.indexOf(route);
    if (index != -1) {
      _activeIndex = index;
      notifyListeners();
    } else {
      push(route);
    }
  }

  @override
  Future<void> activateRoute(T route) async {
    final index = stack.indexOf(route);
    if (index != -1) {
      _activeIndex = index;
    } else {
      push(route);
    }
  }

  @override
  T? get activeRoute =>
      _activeIndex != null && _activeIndex! >= 0 && _activeIndex! < stack.length
      ? stack[_activeIndex!]
      : null;

  @override
  PathKey get pathKey => key;

  @override
  void reset() {
    clear();
    _activeIndex = null;
  }

  @override
  Future<R?> push<R extends Object>(T element) async {
    final future = super.push<R>(element);
    _activeIndex = stack.length;
    return future;
  }

  @override
  Future<bool?> pop([Object? result]) async {
    final length = stack.length;
    final value = await super.pop(result);
    if (value == true && _activeIndex == length - 1) {
      _activeIndex = stack.length - 1;
    }
    return value;
  }

  @override
  void remove(T element, {bool discard = true}) {
    final index = stack.indexOf(element);
    super.remove(element, discard: discard);
    if (index == _activeIndex && index < stack.length) return;
    _activeIndex ??= stack.length - 1;
    if (_activeIndex! >= stack.length) _activeIndex = stack.length - 1;
    notifyListeners();
  }

  @override
  TabsPathModel<T> deserialize(Map<String, dynamic> data) {
    return TabsPathModel([
      for (final route in data['stack'])
        RouteTarget.deserialize(
              route,
              parseRouteFromUri: coordinator!.parseRouteFromUriSync,
            )
            as T,
    ], data['activeIndex']);
  }

  @override
  void restore(TabsPathModel<T> data) {
    bindStack(data.stack);
    _activeIndex = data.activeIndex;
    notifyListeners();
  }

  @override
  Map<String, dynamic> serialize() {
    return {
      'stack': [for (final route in stack) RouteTarget.serialize(route)],
      'activeIndex': _activeIndex,
    };
  }

  @override
  Future<void> navigate(T route) async {
    final index = stack.indexOf(route);
    if (index != -1) {
      _activeIndex = index;
      notifyListeners();
      return;
    }
    push(route);
  }
}

class TabsPathBuilder<T extends RouteTab> extends StatefulWidget {
  const TabsPathBuilder({
    super.key,
    required this.coordinator,
    required this.path,
  });

  final Coordinator coordinator;
  final TabsPath<T> path;

  @override
  State<TabsPathBuilder<T>> createState() => _TabsPathBuilderState<T>();
}

class _TabsPathBuilderState<T extends RouteTab>
    extends State<TabsPathBuilder<T>>
    with SingleTickerProviderStateMixin {
  late final tabController = TabController(
    length: widget.path.stack.length,
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    widget.path.addListener(_onPathChanged);
  }

  @override
  void dispose() {
    widget.path.removeListener(_onPathChanged);
    super.dispose();
  }

  void _onPathChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (final (index, route) in widget.path.stack.indexed)
              route.tabLabel(
                widget.coordinator,
                widget.path,
                context,
                index == widget.path.activeIndex,
              ),
          ],
        ),
        Expanded(
          child: switch (widget.path.activeRoute) {
            null => const SizedBox.shrink(),
            final route => route.build(widget.coordinator, context),
          },
        ),
      ],
    );
  }
}
