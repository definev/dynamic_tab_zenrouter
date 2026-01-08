import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Window State Enums and Models
// ============================================================================

/// Represents the state of a window
enum WindowState {
  /// Window is floating freely and can be moved/resized
  floating,

  /// Window is minimized to the dock
  minimized,

  /// Window is maximized to fill the available space
  maximized,

  /// Window is pinned (always on top, cannot be moved behind other windows)
  pinned,
}

/// Represents the bounds of a window
class WindowRect {
  final double x;
  final double y;
  final double width;
  final double height;

  const WindowRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Rect toRect() => Rect.fromLTWH(x, y, width, height);

  WindowRect copyWith({double? x, double? y, double? width, double? height}) {
    return WindowRect(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory WindowRect.fromJson(Map<String, dynamic> json) {
    return WindowRect(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  static WindowRect defaultRect({double offsetX = 100, double offsetY = 100}) =>
      WindowRect(x: offsetX, y: offsetY, width: 600, height: 400);
}

/// A notifier that holds the window's rectangle and state
class WindowNotifier extends ChangeNotifier {
  WindowRect _rect;
  WindowState _state;
  WindowRect? _floatingRect; // Saved rect when maximized/minimized

  WindowNotifier({
    required WindowRect rect,
    WindowState state = WindowState.floating,
  }) : _rect = rect,
       _state = state;

  WindowRect get rect => _rect;
  WindowState get state => _state;

  bool get isMinimized => _state == WindowState.minimized;
  bool get isMaximized => _state == WindowState.maximized;
  bool get isFloating => _state == WindowState.floating;
  bool get isPinned => _state == WindowState.pinned;

  void updateRect(WindowRect rect) {
    if (_state == WindowState.floating || _state == WindowState.pinned) {
      _rect = rect;
      notifyListeners();
    }
  }

  void move(double dx, double dy) {
    if (_state == WindowState.floating || _state == WindowState.pinned) {
      _rect = _rect.copyWith(x: _rect.x + dx, y: _rect.y + dy);
      notifyListeners();
    }
  }

  void resize(double width, double height, {double? x, double? y}) {
    if (_state == WindowState.floating || _state == WindowState.pinned) {
      _rect = _rect.copyWith(
        x: x ?? _rect.x,
        y: y ?? _rect.y,
        width: width.clamp(200, double.infinity),
        height: height.clamp(150, double.infinity),
      );
      notifyListeners();
    }
  }

  void minimize() {
    if (_state != WindowState.minimized) {
      _floatingRect = _rect;
      _state = WindowState.minimized;
      notifyListeners();
    }
  }

  void maximize(Size availableSize) {
    if (_state == WindowState.maximized) {
      // Restore from maximized
      if (_floatingRect != null) {
        _rect = _floatingRect!;
      }
      _state = WindowState.floating;
    } else {
      // Maximize
      _floatingRect = _rect;
      _rect = WindowRect(
        x: 0,
        y: 0,
        width: availableSize.width,
        height: availableSize.height,
      );
      _state = WindowState.maximized;
    }
    notifyListeners();
  }

  void restore() {
    if (_floatingRect != null) {
      _rect = _floatingRect!;
    }
    _state = WindowState.floating;
    notifyListeners();
  }

  void togglePin() {
    _state = _state == WindowState.pinned
        ? WindowState.floating
        : WindowState.pinned;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'rect': _rect.toJson(),
    'state': _state.name,
    'floatingRect': _floatingRect?.toJson(),
  };

  factory WindowNotifier.fromJson(Map<String, dynamic> json) {
    return WindowNotifier(
        rect: WindowRect.fromJson(json['rect']),
        state: WindowState.values.firstWhere(
          (e) => e.name == json['state'],
          orElse: () => WindowState.floating,
        ),
      )
      .._floatingRect = json['floatingRect'] != null
          ? WindowRect.fromJson(json['floatingRect'])
          : null;
  }
}

// ============================================================================
// RouteWindow Mixin
// ============================================================================

/// Mixin for routes that can be displayed as windows
mixin RouteWindow on RouteUnique {
  /// The window notifier that manages the window's rect and state
  late final WindowNotifier windowNotifier = WindowNotifier(
    rect: WindowRect.defaultRect(
      offsetX: _randomOffset,
      offsetY: _randomOffset,
    ),
  );

  double get _randomOffset => 50.0 + (hashCode % 200);

  /// Build the window's title bar content
  Widget buildWindowTitle(
    covariant Coordinator coordinator,
    covariant WindowsPath path,
    BuildContext context,
  );

  /// Build the window's dock icon (when minimized)
  Widget buildDockIcon(
    covariant Coordinator coordinator,
    covariant WindowsPath path,
    BuildContext context,
  );

  /// The minimum size of this window
  Size get minSize => const Size(300, 200);

  /// Whether this window can be minimized
  bool get canMinimize => true;

  /// Whether this window can be maximized
  bool get canMaximize => true;

  /// Whether this window can be closed
  bool get canClose => true;

  /// Whether this window can be resized
  bool get canResize => true;

  /// Called when the route is popped from the stack.
  /// Disposes the windowNotifier to clean up resources.
  @override
  void onDidPop(
    Object? result,
    covariant Coordinator<RouteUnique>? coordinator,
  ) {
    windowNotifier.dispose();
    super.onDidPop(result, coordinator);
  }
}

// ============================================================================
// WindowsPath Model
// ============================================================================

class WindowsPathModel<T> {
  final List<T> stack;
  final List<Map<String, dynamic>> windowStates;
  final T? activeWindow;

  WindowsPathModel(this.stack, this.windowStates, this.activeWindow);
}

// ============================================================================
// WindowsPath - StackPath Implementation
// ============================================================================

class WindowsPath<T extends RouteWindow> extends StackPath<T>
    with
        StackMutatable<T>,
        StackNavigatable<T>,
        RestorablePath<T, Map<String, dynamic>, WindowsPathModel<T>> {
  WindowsPath._(super.stack, {super.debugLabel, super.coordinator});

  factory WindowsPath.createWith({
    required Coordinator coordinator,
    required String label,
    List<T>? stack,
  }) => WindowsPath._(stack ?? [], debugLabel: label, coordinator: coordinator);

  static void definePath() => RouteLayout.definePath(
    key,
    (coordinator, path, layout) =>
        WindowsPathBuilder(coordinator: coordinator, path: path as WindowsPath),
  );

  static const key = PathKey('WindowsPath');

  T? _activeWindow;
  T? get activeWindow => _activeWindow;

  /// Z-order of windows (last item is on top)
  final List<T> _zOrder = [];
  List<T> get zOrder => List.unmodifiable(_zOrder);

  /// Minimized windows (shown in dock)
  List<T> get minimizedWindows =>
      stack.where((w) => w.windowNotifier.isMinimized).toList();

  /// Visible windows (not minimized)
  List<T> get visibleWindows =>
      stack.where((w) => !w.windowNotifier.isMinimized).toList();

  /// Bring a window to front
  void bringToFront(T window) {
    if (!_zOrder.contains(window)) {
      _zOrder.add(window);
    } else {
      _zOrder.remove(window);
      _zOrder.add(window);
    }
    _activeWindow = window;
    notifyListeners();
  }

  /// Focus a window (brings to front and restores if minimized)
  void focusWindow(T window) {
    if (window.windowNotifier.isMinimized) {
      window.windowNotifier.restore();
    }
    bringToFront(window);
  }

  void minimizeWindow(T window) {
    window.windowNotifier.minimize();
    if (_activeWindow == window) {
      _activeWindow = visibleWindows.lastOrNull;
    }
    notifyListeners();
  }

  void maximizeWindow(T window, Size availableSize) {
    window.windowNotifier.maximize(availableSize);
    bringToFront(window);
  }

  void restoreWindow(T window) {
    window.windowNotifier.restore();
    bringToFront(window);
  }

  void togglePinWindow(T window) {
    window.windowNotifier.togglePin();
    notifyListeners();
  }

  void closeWindow(T window) {
    remove(window);
  }

  @override
  Future<void> activateRoute(T route) async {
    if (!stack.contains(route)) {
      await push(route);
    }
    focusWindow(route);
  }

  @override
  T? get activeRoute => _activeWindow;

  @override
  PathKey get pathKey => key;

  @override
  void reset() {
    clear();
    _activeWindow = null;
    _zOrder.clear();
  }

  @override
  Future<R?> push<R extends Object>(T element) async {
    // If element already exists, just focus it instead of adding duplicate
    if (stack.contains(element)) {
      focusWindow(element);
      return null;
    }
    final future = super.push<R>(element);
    _zOrder.add(element);
    _activeWindow = element;
    notifyListeners();
    return future;
  }

  @override
  Future<bool?> pop([Object? result]) async {
    if (_activeWindow != null && _activeWindow!.canClose) {
      remove(_activeWindow!);
      return true;
    }
    return false;
  }

  @override
  void remove(T element, {bool discard = true}) {
    _zOrder.remove(element);
    // Call onDidPop to ensure proper cleanup (windowNotifier disposal)
    // before removing the element from the stack
    element.onDidPop(null, coordinator);
    super.remove(element, discard: discard);
    if (_activeWindow == element) {
      _activeWindow = _zOrder.lastOrNull;
    }
    notifyListeners();
  }

  @override
  WindowsPathModel<T> deserialize(Map<String, dynamic> data) {
    final stack = <T>[];
    final windowStates = <Map<String, dynamic>>[];

    for (int i = 0; i < (data['stack'] as List).length; i++) {
      final routeData = data['stack'][i];
      final route =
          RouteTarget.deserialize(
                routeData,
                parseRouteFromUri: coordinator!.parseRouteFromUriSync,
              )
              as T;
      stack.add(route);

      if (data['windowStates'] != null &&
          i < (data['windowStates'] as List).length) {
        windowStates.add(data['windowStates'][i]);
      }
    }

    T? activeWindow;
    if (data['activeWindowIndex'] != null) {
      final index = data['activeWindowIndex'] as int;
      if (index >= 0 && index < stack.length) {
        activeWindow = stack[index];
      }
    }

    return WindowsPathModel(stack, windowStates, activeWindow);
  }

  @override
  void restore(WindowsPathModel<T> data) {
    bindStack(data.stack);
    _zOrder.clear();
    _zOrder.addAll(data.stack);

    // Restore window states
    for (
      int i = 0;
      i < data.stack.length && i < data.windowStates.length;
      i++
    ) {
      final window = data.stack[i];
      final stateData = data.windowStates[i];
      final notifier = WindowNotifier.fromJson(stateData);
      window.windowNotifier.updateRect(notifier.rect);
      if (notifier.isMinimized) {
        window.windowNotifier.minimize();
      } else if (notifier.isMaximized) {
        window.windowNotifier.maximize(const Size(1920, 1080)); // Default size
      } else if (notifier.isPinned) {
        window.windowNotifier.togglePin();
      }
    }

    _activeWindow = data.activeWindow;
    notifyListeners();
  }

  @override
  Map<String, dynamic> serialize() {
    return {
      'stack': [for (final route in stack) RouteTarget.serialize(route)],
      'windowStates': [
        for (final window in stack) window.windowNotifier.toJson(),
      ],
      'activeWindowIndex': _activeWindow != null
          ? stack.indexOf(_activeWindow!)
          : null,
    };
  }

  @override
  Future<void> navigate(T route) async {
    final existingIndex = stack.indexOf(route);
    if (existingIndex != -1) {
      focusWindow(stack[existingIndex]);
    } else {
      await push(route);
    }
  }
}

// ============================================================================
// WindowsPath Builder Widget
// ============================================================================

class WindowsPathBuilder<T extends RouteWindow> extends StatefulWidget {
  const WindowsPathBuilder({
    super.key,
    required this.coordinator,
    required this.path,
  });

  final Coordinator coordinator;
  final WindowsPath<T> path;

  @override
  State<WindowsPathBuilder<T>> createState() => _WindowsPathBuilderState<T>();
}

class _WindowsPathBuilderState<T extends RouteWindow>
    extends State<WindowsPathBuilder<T>> {
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1B26),
            const Color(0xFF24283B),
            const Color(0xFF1A1B26),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Desktop wallpaper/background pattern
          Positioned.fill(child: _buildDesktopBackground()),

          // Windows layer
          LayoutBuilder(
            builder: (context, constraints) {
              // Sort visible windows by z-index so active window appears on top
              // Use Set to ensure uniqueness and avoid duplicate keys
              final sortedWindows = widget.path.visibleWindows.toSet().toList()
                ..sort(
                  (a, b) => widget.path.zOrder
                      .indexOf(a)
                      .compareTo(widget.path.zOrder.indexOf(b)),
                );
              return Stack(
                children: [
                  for (final window in sortedWindows)
                    _WindowWidget<T>(
                      key: ValueKey(window),
                      window: window,
                      coordinator: widget.coordinator,
                      path: widget.path,
                      isActive: window == widget.path.activeWindow,
                      zIndex: widget.path.zOrder.indexOf(window),
                      availableSize: constraints.biggest,
                    ),
                ],
              );
            },
          ),

          // Dock at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: _MacOSDock<T>(
              coordinator: widget.coordinator,
              path: widget.path,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBackground() {
    return CustomPaint(painter: _DesktopBackgroundPainter());
  }
}

class _DesktopBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw subtle grid pattern
    const gridSize = 40.0;
    paint.color = Colors.white.withValues(alpha: 0.02);

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// Window Widget
// ============================================================================

class _WindowWidget<T extends RouteWindow> extends StatefulWidget {
  const _WindowWidget({
    super.key,
    required this.window,
    required this.coordinator,
    required this.path,
    required this.isActive,
    required this.zIndex,
    required this.availableSize,
  });

  final T window;
  final Coordinator coordinator;
  final WindowsPath<T> path;
  final bool isActive;
  final int zIndex;
  final Size availableSize;

  @override
  State<_WindowWidget<T>> createState() => _WindowWidgetState<T>();
}

class _WindowWidgetState<T extends RouteWindow>
    extends State<_WindowWidget<T>> {
  @override
  void initState() {
    super.initState();
    widget.window.windowNotifier.addListener(_onNotifierChanged);
  }

  @override
  void dispose() {
    widget.window.windowNotifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  void _onNotifierChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final canResize =
        widget.window.canResize && !widget.window.windowNotifier.isMaximized;

    return ListenableBuilder(
      listenable: widget.window.windowNotifier,
      builder: (context, child) {
        final notifier = widget.window.windowNotifier;
        final rect = notifier.rect;

        return Positioned(
          left: rect.x,
          top: rect.y,
          width: rect.width,
          height: rect.height,
          child: Listener(
            onPointerDown: (_) => widget.path.bringToFront(widget.window),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main window content
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isActive
                              ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.4),
                          blurRadius: widget.isActive ? 24 : 16,
                          spreadRadius: widget.isActive ? 2 : 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: widget.isActive
                            ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          // Title bar
                          _WindowTitleBar<T>(
                            window: widget.window,
                            coordinator: widget.coordinator,
                            path: widget.path,
                            isActive: widget.isActive,
                            availableSize: widget.availableSize,
                          ),
                          // Content
                          Expanded(
                            child: Container(
                              color: const Color(0xFF1E1E2E),
                              child: widget.window.build(
                                widget.coordinator,
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Resize handles
                if (canResize) ...[
                  // Right edge
                  _ResizeHandle(
                    alignment: Alignment.centerRight,
                    cursor: SystemMouseCursors.resizeLeftRight,
                    onDrag: (dx, dy) {
                      notifier.resize(rect.width + dx, rect.height);
                    },
                  ),
                  // Bottom edge
                  _ResizeHandle(
                    alignment: Alignment.bottomCenter,
                    cursor: SystemMouseCursors.resizeUpDown,
                    onDrag: (dx, dy) {
                      notifier.resize(rect.width, rect.height + dy);
                    },
                  ),
                  // Left edge
                  _ResizeHandle(
                    alignment: Alignment.centerLeft,
                    cursor: SystemMouseCursors.resizeLeftRight,
                    onDrag: (dx, dy) {
                      notifier.resize(
                        rect.width - dx,
                        rect.height,
                        x: rect.x + dx,
                      );
                    },
                  ),
                  // Top edge
                  _ResizeHandle(
                    alignment: Alignment.topCenter,
                    cursor: SystemMouseCursors.resizeUpDown,
                    onDrag: (dx, dy) {
                      notifier.resize(
                        rect.width,
                        rect.height - dy,
                        y: rect.y + dy,
                      );
                    },
                  ),
                  // Bottom-right corner
                  _ResizeHandle(
                    alignment: Alignment.bottomRight,
                    cursor: SystemMouseCursors.resizeDownRight,
                    isCorner: true,
                    onDrag: (dx, dy) {
                      notifier.resize(rect.width + dx, rect.height + dy);
                    },
                  ),
                  // Bottom-left corner
                  _ResizeHandle(
                    alignment: Alignment.bottomLeft,
                    cursor: SystemMouseCursors.resizeDownLeft,
                    isCorner: true,
                    onDrag: (dx, dy) {
                      notifier.resize(
                        rect.width - dx,
                        rect.height + dy,
                        x: rect.x + dx,
                      );
                    },
                  ),
                  // Top-right corner
                  _ResizeHandle(
                    alignment: Alignment.topRight,
                    cursor: SystemMouseCursors.resizeUpRight,
                    isCorner: true,
                    onDrag: (dx, dy) {
                      notifier.resize(
                        rect.width + dx,
                        rect.height - dy,
                        y: rect.y + dy,
                      );
                    },
                  ),
                  // Top-left corner
                  _ResizeHandle(
                    alignment: Alignment.topLeft,
                    cursor: SystemMouseCursors.resizeUpLeft,
                    isCorner: true,
                    onDrag: (dx, dy) {
                      notifier.resize(
                        rect.width - dx,
                        rect.height - dy,
                        x: rect.x + dx,
                        y: rect.y + dy,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Resize Handle Widget
// ============================================================================

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.alignment,
    required this.cursor,
    required this.onDrag,
    this.isCorner = false,
  });

  final Alignment alignment;
  final MouseCursor cursor;
  final void Function(double dx, double dy) onDrag;
  final bool isCorner;

  @override
  Widget build(BuildContext context) {
    const edgeSize = 6.0;
    const cornerSize = 12.0;

    double? left, right, top, bottom;
    double width, height;

    if (isCorner) {
      width = cornerSize;
      height = cornerSize;
      if (alignment == Alignment.topLeft) {
        left = -edgeSize / 2;
        top = -edgeSize / 2;
      } else if (alignment == Alignment.topRight) {
        right = -edgeSize / 2;
        top = -edgeSize / 2;
      } else if (alignment == Alignment.bottomLeft) {
        left = -edgeSize / 2;
        bottom = -edgeSize / 2;
      } else {
        right = -edgeSize / 2;
        bottom = -edgeSize / 2;
      }
    } else {
      if (alignment == Alignment.centerLeft) {
        left = -edgeSize / 2;
        top = cornerSize;
        bottom = cornerSize;
        width = edgeSize;
        height = double.infinity;
      } else if (alignment == Alignment.centerRight) {
        right = -edgeSize / 2;
        top = cornerSize;
        bottom = cornerSize;
        width = edgeSize;
        height = double.infinity;
      } else if (alignment == Alignment.topCenter) {
        left = cornerSize;
        right = cornerSize;
        top = -edgeSize / 2;
        width = double.infinity;
        height = edgeSize;
      } else {
        left = cornerSize;
        right = cornerSize;
        bottom = -edgeSize / 2;
        width = double.infinity;
        height = edgeSize;
      }
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      width: width == double.infinity ? null : width,
      height: height == double.infinity ? null : height,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            onDrag(details.delta.dx, details.delta.dy);
          },
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}

// ============================================================================
// Window Title Bar
// ============================================================================

class _WindowTitleBar<T extends RouteWindow> extends StatelessWidget {
  const _WindowTitleBar({
    required this.window,
    required this.coordinator,
    required this.path,
    required this.isActive,
    required this.availableSize,
  });

  final T window;
  final Coordinator coordinator;
  final WindowsPath<T> path;
  final bool isActive;
  final Size availableSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        window.windowNotifier.move(details.delta.dx, details.delta.dy);
      },
      onDoubleTap: () {
        if (window.canMaximize) {
          path.maximizeWindow(window, availableSize);
        }
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isActive
                ? [const Color(0xFF2D2D3F), const Color(0xFF252536)]
                : [const Color(0xFF252536), const Color(0xFF1E1E2E)],
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // macOS-style traffic lights
            _TrafficLights(
              window: window,
              path: path,
              availableSize: availableSize,
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                child: window.buildWindowTitle(coordinator, path, context),
              ),
            ),
            // Pin indicator
            if (window.windowNotifier.isPinned) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.push_pin,
                      size: 12,
                      color: const Color(0xFFA78BFA),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pinned',
                      style: TextStyle(
                        color: const Color(0xFFA78BFA),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Action buttons
            _WindowActionButton(
              icon: Icons.push_pin,
              onPressed: () => path.togglePinWindow(window),
              tooltip: window.windowNotifier.isPinned ? 'Unpin' : 'Pin',
              isActive: window.windowNotifier.isPinned,
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Traffic Lights (macOS-style window controls)
// ============================================================================

class _TrafficLights<T extends RouteWindow> extends StatefulWidget {
  const _TrafficLights({
    required this.window,
    required this.path,
    required this.availableSize,
  });

  final T window;
  final WindowsPath<T> path;
  final Size availableSize;

  @override
  State<_TrafficLights<T>> createState() => _TrafficLightsState<T>();
}

class _TrafficLightsState<T extends RouteWindow>
    extends State<_TrafficLights<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button (red)
          _TrafficLight(
            color: widget.window.canClose
                ? const Color(0xFFFF5F57)
                : const Color(0xFF3C3C3C),
            icon: _isHovered && widget.window.canClose ? Icons.close : null,
            onTap: widget.window.canClose
                ? () => widget.path.closeWindow(widget.window)
                : null,
          ),
          const SizedBox(width: 8),
          // Minimize button (yellow)
          _TrafficLight(
            color: widget.window.canMinimize
                ? const Color(0xFFFFBD2E)
                : const Color(0xFF3C3C3C),
            icon: _isHovered && widget.window.canMinimize ? Icons.remove : null,
            onTap: widget.window.canMinimize
                ? () => widget.path.minimizeWindow(widget.window)
                : null,
          ),
          const SizedBox(width: 8),
          // Maximize button (green)
          _TrafficLight(
            color: widget.window.canMaximize
                ? const Color(0xFF28C840)
                : const Color(0xFF3C3C3C),
            icon: _isHovered && widget.window.canMaximize
                ? (widget.window.windowNotifier.isMaximized
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen)
                : null,
            onTap: widget.window.canMaximize
                ? () => widget.path.maximizeWindow(
                    widget.window,
                    widget.availableSize,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _TrafficLight extends StatefulWidget {
  const _TrafficLight({required this.color, this.icon, this.onTap});

  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  State<_TrafficLight> createState() => _TrafficLightState();
}

class _TrafficLightState extends State<_TrafficLight> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.9)
                : widget.color.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: widget.icon != null
              ? Icon(widget.icon, size: 10, color: Colors.black54)
              : null,
        ),
      ),
    );
  }
}

// ============================================================================
// Window Action Button
// ============================================================================

class _WindowActionButton extends StatefulWidget {
  const _WindowActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isActive;

  @override
  State<_WindowActionButton> createState() => _WindowActionButtonState();
}

class _WindowActionButtonState extends State<_WindowActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.1)
                  : widget.isActive
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.isActive ? const Color(0xFFA78BFA) : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// macOS-style Dock
// ============================================================================

class _MacOSDock<T extends RouteWindow> extends StatelessWidget {
  const _MacOSDock({required this.coordinator, required this.path});

  final Coordinator coordinator;
  final WindowsPath<T> path;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // All windows (visible and minimized)
              ...path.stack.map((window) {
                final isMinimized = window.windowNotifier.isMinimized;
                final isActive = window == path.activeWindow;

                return _DockItem<T>(
                  window: window,
                  coordinator: coordinator,
                  path: path,
                  isMinimized: isMinimized,
                  isActive: isActive,
                );
              }),
              if (path.stack.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 8),
              ],
              // Window count indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.layers, size: 16, color: Colors.white54),
                    const SizedBox(width: 6),
                    Text(
                      '${path.stack.length}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem<T extends RouteWindow> extends StatefulWidget {
  const _DockItem({
    required this.window,
    required this.coordinator,
    required this.path,
    required this.isMinimized,
    required this.isActive,
  });

  final T window;
  final Coordinator coordinator;
  final WindowsPath<T> path;
  final bool isMinimized;
  final bool isActive;

  @override
  State<_DockItem<T>> createState() => _DockItemState<T>();
}

class _DockItemState<T extends RouteWindow> extends State<_DockItem<T>>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _bounceController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _bounceController.reverse();
      },
      child: GestureDetector(
        onTap: () => widget.path.focusWindow(widget.window),
        child: AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bounceAnimation.value),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isActive
                          ? const Color(0xFFA78BFA).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: widget.window.buildDockIcon(
                          widget.coordinator,
                          widget.path,
                          context,
                        ),
                      ),
                      if (widget.isMinimized)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFBD2E),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Active indicator dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? const Color(0xFFA78BFA)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
