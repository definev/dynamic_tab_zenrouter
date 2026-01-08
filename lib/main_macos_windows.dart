import 'dart:async';

import 'package:dynamic_tab_zenrouter/windows_path.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Route Definitions
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

abstract class WindowRoute extends AppRoute with RouteWindow {}

/// Main layout with macOS-style windows
class MacOSWindowLayout extends AppRoute with RouteLayout<MacOSWindowLayout> {
  @override
  WindowsPath<WindowRoute> resolvePath(WindowCoordinator coordinator) =>
      coordinator.windowsPath;

  @override
  Widget buildPath(covariant WindowCoordinator coordinator) {
    return WindowsPathBuilder<WindowRoute>(
      coordinator: coordinator,
      path: coordinator.windowsPath,
    );
  }

  @override
  Widget build(WindowCoordinator coordinator, BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B26),
      body: Column(
        children: [
          // macOS-style menu bar
          _MacOSMenuBar(coordinator: coordinator),
          Expanded(child: buildPath(coordinator)),
        ],
      ),
    );
  }
}

// ============================================================================
// macOS Menu Bar
// ============================================================================

class _MacOSMenuBar extends StatelessWidget {
  const _MacOSMenuBar({required this.coordinator});

  final WindowCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF3B3B4F), const Color(0xFF2D2D3F)],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Apple logo placeholder
          Icon(Icons.laptop_mac, size: 16, color: Colors.white70),
          const SizedBox(width: 16),
          _MenuButton(
            label: 'File',
            items: [
              _MenuItem(
                'New Finder',
                () => coordinator.navigate(FinderWindow()),
              ),
              _MenuItem(
                'New Terminal',
                () => coordinator.navigate(TerminalWindow()),
              ),
              _MenuItem('New Notes', () => coordinator.navigate(NotesWindow())),
              _MenuItem(
                'New Settings',
                () => coordinator.navigate(SettingsWindow()),
              ),
            ],
          ),
          _MenuButton(
            label: 'Window',
            items: [
              _MenuItem('Minimize All', () {
                for (final window in coordinator.windowsPath.stack) {
                  coordinator.windowsPath.minimizeWindow(window);
                }
              }),
              _MenuItem('Close All', () {
                while (coordinator.windowsPath.stack.isNotEmpty) {
                  coordinator.windowsPath.remove(
                    coordinator.windowsPath.stack.first,
                  );
                }
              }),
            ],
          ),
          _MenuButton(
            label: 'Help',
            items: [
              _MenuItem('About', () => coordinator.navigate(AboutWindow())),
            ],
          ),
          const Spacer(),
          // Status icons
          Icon(Icons.wifi, size: 14, color: Colors.white70),
          const SizedBox(width: 12),
          Icon(Icons.bluetooth, size: 14, color: Colors.white70),
          const SizedBox(width: 12),
          Icon(Icons.battery_full, size: 14, color: Colors.white70),
          const SizedBox(width: 12),
          Text(
            _formatTime(DateTime.now()),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${time.month}/${time.day} $hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _MenuButton extends StatefulWidget {
  const _MenuButton({required this.label, required this.items});

  final String label;
  final List<_MenuItem> items;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: PopupMenuButton<_MenuItem>(
        offset: const Offset(0, 32),
        color: const Color(0xFF2D2D3F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tooltip: '',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        itemBuilder: (context) => widget.items.map((item) {
          return PopupMenuItem<_MenuItem>(
            value: item,
            height: 36,
            onTap: item.onTap,
            child: Text(
              item.label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final VoidCallback onTap;

  _MenuItem(this.label, this.onTap);
}

// ============================================================================
// Window Routes
// ============================================================================

/// Finder-style window
class FinderWindow extends WindowRoute {
  FinderWindow({this.path = '/home'});

  final String path;

  @override
  List<Object?> get props => [path, DateTime.now().millisecondsSinceEpoch];

  @override
  Type? get layout => MacOSWindowLayout;

  @override
  Widget build(WindowCoordinator coordinator, BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E2E),
      child: Column(
        children: [
          // Toolbar
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF252536),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                _ToolbarButton(icon: Icons.arrow_back_ios, onTap: () {}),
                _ToolbarButton(icon: Icons.arrow_forward_ios, onTap: () {}),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    path,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                const Spacer(),
                _ToolbarButton(icon: Icons.grid_view, onTap: () {}),
                _ToolbarButton(icon: Icons.view_list, onTap: () {}),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Sidebar
                Container(
                  width: 180,
                  color: const Color(0xFF1A1B26),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SidebarSection(
                        title: 'Favorites',
                        items: [
                          _SidebarItem(Icons.desktop_mac, 'Desktop'),
                          _SidebarItem(Icons.folder, 'Documents'),
                          _SidebarItem(Icons.download, 'Downloads'),
                          _SidebarItem(Icons.image, 'Pictures'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SidebarSection(
                        title: 'iCloud',
                        items: [_SidebarItem(Icons.cloud, 'iCloud Drive')],
                      ),
                      const SizedBox(height: 16),
                      _SidebarSection(
                        title: 'Locations',
                        items: [
                          _SidebarItem(Icons.laptop_mac, 'MacBook Pro'),
                          _SidebarItem(Icons.sd_storage, 'External Drive'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 100,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final icons = [
                          Icons.folder,
                          Icons.insert_drive_file,
                          Icons.image,
                          Icons.music_note,
                          Icons.movie,
                        ];
                        final names = [
                          'Projects',
                          'Documents',
                          'Photos',
                          'Music',
                          'Movies',
                          'Downloads',
                          'Desktop',
                          'Applications',
                          'Library',
                          'System',
                          'Users',
                          'Volumes',
                        ];
                        return _FileItem(
                          icon: icons[index % icons.length],
                          name: names[index % names.length],
                          isFolder: index < 6,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Status bar
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF252536),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '12 items, 45.6 GB available',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildWindowTitle(
    WindowCoordinator coordinator,
    WindowsPath path,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(Icons.folder, size: 16, color: const Color(0xFF5FB3F8)),
        const SizedBox(width: 8),
        const Text('Finder'),
      ],
    );
  }

  @override
  Widget buildDockIcon(
    WindowCoordinator coordinator,
    WindowsPath path,
    BuildContext context,
  ) {
    return Icon(Icons.folder_special, size: 24, color: const Color(0xFF5FB3F8));
  }

  @override
  Uri toUri() => Uri.parse('/finder?path=$path');
}

class _ToolbarButton extends StatefulWidget {
  const _ToolbarButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _isHovered ? Colors.white.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(widget.icon, size: 14, color: Colors.white54),
        ),
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({required this.title, required this.items});

  final String title;
  final List<_SidebarItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(item.icon, size: 14, color: const Color(0xFF5FB3F8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;

  _SidebarItem(this.icon, this.label);
}

class _FileItem extends StatefulWidget {
  const _FileItem({
    required this.icon,
    required this.name,
    required this.isFolder,
  });

  final IconData icon;
  final String name;
  final bool isFolder;

  @override
  State<_FileItem> createState() => _FileItemState();
}

class _FileItemState extends State<_FileItem> {
  bool _isHovered = false;
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => setState(() => _isSelected = !_isSelected),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _isSelected
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                    : _isHovered
                    ? Colors.white.withValues(alpha: 0.05)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                size: 40,
                color: widget.isFolder
                    ? const Color(0xFF5FB3F8)
                    : Colors.white54,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _isSelected ? const Color(0xFF7C3AED) : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Terminal window
class TerminalWindow extends WindowRoute {
  TerminalWindow({this.sessionId});

  final String? sessionId;

  @override
  List<Object?> get props => [
    sessionId ?? DateTime.now().millisecondsSinceEpoch,
  ];

  @override
  Type? get layout => MacOSWindowLayout;

  @override
  Widget build(WindowCoordinator coordinator, BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D14),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last login: Mon Dec 30 20:23:12 on ttys001',
              style: _terminalStyle.copyWith(color: Colors.white38),
            ),
            const SizedBox(height: 8),
            _TerminalLine(prompt: '~', command: 'ls -la'),
            _TerminalOutput('''total 48
drwxr-xr-x  12 user  staff   384 Dec 30 10:00 .
drwxr-xr-x   5 root  admin   160 Dec 25 08:00 ..
drwx------   3 user  staff    96 Dec 30 09:00 .Trash
-rw-r--r--   1 user  staff   285 Dec 29 15:00 .zshrc
drwxr-xr-x  14 user  staff   448 Dec 30 10:00 Documents
drwxr-xr-x   8 user  staff   256 Dec 28 14:00 Downloads
drwxr-xr-x  32 user  staff  1024 Dec 30 09:30 Library'''),
            const SizedBox(height: 8),
            _TerminalLine(prompt: '~', command: 'echo "Welcome to Terminal!"'),
            _TerminalOutput('Welcome to Terminal!'),
            const SizedBox(height: 8),
            _TerminalLine(prompt: '~', command: 'flutter --version'),
            _TerminalOutput(
              '''Flutter 3.27.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 85f8a5e • 2024-12-17 (4 days ago)
Engine • revision 7c3a72d
Tools • Dart 3.6.0 • DevTools 2.40.0''',
            ),
            const SizedBox(height: 16),
            _TerminalLine(prompt: '~', command: '', cursor: true),
          ],
        ),
      ),
    );
  }

  TextStyle get _terminalStyle => const TextStyle(
    color: Colors.greenAccent,
    fontSize: 13,
    fontFamily: 'JetBrains Mono, SF Mono, Monaco, monospace',
  );

  @override
  Widget buildWindowTitle(
    WindowCoordinator coordinator,
    WindowsPath path,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(Icons.terminal, size: 16, color: Colors.greenAccent),
        const SizedBox(width: 8),
        const Text('Terminal'),
      ],
    );
  }

  @override
  Widget buildDockIcon(
    WindowCoordinator coordinator,
    WindowsPath path,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.terminal, size: 24, color: Colors.greenAccent),
    );
  }

  @override
  Uri toUri() =>
      Uri.parse('/terminal${sessionId != null ? '?session=$sessionId' : ''}');
}

class _TerminalLine extends StatelessWidget {
  const _TerminalLine({
    required this.prompt,
    required this.command,
    this.cursor = false,
  });

  final String prompt;
  final String command;
  final bool cursor;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'JetBrains Mono, SF Mono, Monaco, monospace',
          fontSize: 13,
        ),
        children: [
          TextSpan(
            text: 'user@macbook ',
            style: TextStyle(color: Colors.greenAccent),
          ),
          TextSpan(
            text: prompt,
            style: TextStyle(color: const Color(0xFF5FB3F8)),
          ),
          TextSpan(
            text: ' % ',
            style: TextStyle(color: Colors.white54),
          ),
          TextSpan(
            text: command,
            style: TextStyle(color: Colors.white),
          ),
          if (cursor) WidgetSpan(child: _BlinkingCursor()),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 16,
          color: Colors.white.withValues(alpha: _controller.value),
        );
      },
    );
  }
}

class _TerminalOutput extends StatelessWidget {
  const _TerminalOutput(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontFamily: 'JetBrains Mono, SF Mono, Monaco, monospace',
        ),
      ),
    );
  }
}

/// Notes window - Apple Notes-inspired design
class NotesWindow extends WindowRoute {
  NotesWindow({this.noteId});

  final String? noteId;

  @override
  List<Object?> get props => [noteId ?? DateTime.now().millisecondsSinceEpoch];

  @override
  Type? get layout => MacOSWindowLayout;

  @override
  Widget build(WindowCoordinator coordinator, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFFFFBF0), const Color(0xFFFFF8E7)],
        ),
      ),
      child: Row(
        children: [
          // Folder sidebar
          Container(
            width: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF6E3).withValues(alpha: 0.9),
              border: Border(
                right: BorderSide(color: const Color(0xFFE8DCC8), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // iCloud header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFB347),
                              const Color(0xFFFF9500),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.cloud, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'iCloud',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Folder list
                _NoteFolderItem(
                  icon: Icons.note_alt_outlined,
                  label: 'All Notes',
                  count: 24,
                  isSelected: true,
                  color: const Color(0xFFFF9500),
                ),
                _NoteFolderItem(
                  icon: Icons.star_outline,
                  label: 'Favorites',
                  count: 5,
                  isSelected: false,
                  color: const Color(0xFFFFCC00),
                ),
                _NoteFolderItem(
                  icon: Icons.share_outlined,
                  label: 'Shared',
                  count: 3,
                  isSelected: false,
                  color: const Color(0xFF34C759),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'FOLDERS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _NoteFolderItem(
                  icon: Icons.folder_outlined,
                  label: 'Personal',
                  count: 12,
                  isSelected: false,
                  color: const Color(0xFF007AFF),
                ),
                _NoteFolderItem(
                  icon: Icons.work_outline,
                  label: 'Work',
                  count: 8,
                  isSelected: false,
                  color: const Color(0xFF5856D6),
                ),
                _NoteFolderItem(
                  icon: Icons.lightbulb_outline,
                  label: 'Ideas',
                  count: 4,
                  isSelected: false,
                  color: const Color(0xFFFF2D55),
                ),
                const Spacer(),
                // Recently deleted
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: _NoteFolderItem(
                    icon: Icons.delete_outline,
                    label: 'Recently Deleted',
                    count: 2,
                    isSelected: false,
                    color: Colors.grey[400]!,
                  ),
                ),
              ],
            ),
          ),
          // Notes list
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              border: Border(
                right: BorderSide(color: const Color(0xFFE8DCC8), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0E6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE8DCC8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 18,
                          color: const Color(0xFFB8A88A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Search Notes',
                            style: TextStyle(
                              color: const Color(0xFFB8A88A),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8DCC8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '⌘F',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF8B7355),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Notes header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '24 Notes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.sort,
                        size: 16,
                        color: const Color(0xFFFF9500),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE8DCC8)),
                // Notes list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: [
                      _NoteListItemEnhanced(
                        title: 'Shopping List',
                        preview: '🥛 Milk, 🥚 Eggs, 🍞 Bread, 🧀 Cheese...',
                        date: 'Today',
                        time: '8:23 PM',
                        isSelected: true,
                        isPinned: true,
                        hasChecklist: true,
                      ),
                      _NoteListItemEnhanced(
                        title: 'Meeting Notes - Q1 Planning',
                        preview:
                            'Discussed roadmap for Q1 2025. Key points: 1) Launch new...',
                        date: 'Today',
                        time: '3:45 PM',
                        isSelected: false,
                        isPinned: true,
                        hasAttachment: true,
                      ),
                      _NoteListItemEnhanced(
                        title: 'Recipe: Homemade Pasta',
                        preview:
                            'Ingredients: 2 cups flour, 3 eggs, pinch of salt...',
                        date: 'Yesterday',
                        time: '7:12 PM',
                        isSelected: false,
                        hasImage: true,
                      ),
                      _NoteListItemEnhanced(
                        title: 'App Ideas 2025',
                        preview:
                            '💡 AI-powered note taking, 🎨 Creative tools, 📱 Mobile-first...',
                        date: 'Dec 28',
                        time: '2:30 PM',
                        isSelected: false,
                      ),
                      _NoteListItemEnhanced(
                        title: 'Travel Plans - Tokyo',
                        preview:
                            'Day 1: Shibuya & Harajuku, Day 2: Senso-ji Temple...',
                        date: 'Dec 25',
                        time: '10:15 AM',
                        isSelected: false,
                        hasImage: true,
                      ),
                      _NoteListItemEnhanced(
                        title: 'Book Notes: Atomic Habits',
                        preview:
                            'Key takeaways: 1% better every day, habit stacking...',
                        date: 'Dec 22',
                        time: '9:00 PM',
                        isSelected: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Note content
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFE8DCC8),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _NotesToolbarButton(
                          icon: Icons.format_bold,
                          tooltip: 'Bold',
                        ),
                        _NotesToolbarButton(
                          icon: Icons.format_italic,
                          tooltip: 'Italic',
                        ),
                        _NotesToolbarButton(
                          icon: Icons.format_underlined,
                          tooltip: 'Underline',
                        ),
                        _NotesToolbarButton(
                          icon: Icons.strikethrough_s,
                          tooltip: 'Strikethrough',
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: const Color(0xFFE8DCC8),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        _NotesToolbarButton(
                          icon: Icons.format_list_bulleted,
                          tooltip: 'Bullet List',
                        ),
                        _NotesToolbarButton(
                          icon: Icons.format_list_numbered,
                          tooltip: 'Numbered List',
                        ),
                        _NotesToolbarButton(
                          icon: Icons.checklist,
                          tooltip: 'Checklist',
                          isActive: true,
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: const Color(0xFFE8DCC8),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        _NotesToolbarButton(
                          icon: Icons.table_chart_outlined,
                          tooltip: 'Table',
                        ),
                        _NotesToolbarButton(icon: Icons.link, tooltip: 'Link'),
                        _NotesToolbarButton(
                          icon: Icons.image_outlined,
                          tooltip: 'Image',
                        ),
                        const Spacer(),
                        _NotesToolbarButton(
                          icon: Icons.push_pin_outlined,
                          tooltip: 'Pin',
                        ),
                        _NotesToolbarButton(
                          icon: Icons.share_outlined,
                          tooltip: 'Share',
                        ),
                        _NotesToolbarButton(
                          icon: Icons.more_horiz,
                          tooltip: 'More',
                        ),
                      ],
                    ),
                  ),
                  // Content area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            'Shopping List',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D2D2D),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: const Color(0xFFB8A88A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'December 30, 2024 at 8:23 PM',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFFB8A88A),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF9500,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.folder_outlined,
                                      size: 12,
                                      color: const Color(0xFFFF9500),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Personal',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: const Color(0xFFFF9500),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFE8DCC8),
                                  const Color(0xFFE8DCC8).withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Checklist items
                          ...[
                            ('🥛 Milk', true),
                            ('🥚 Eggs (1 dozen)', true),
                            ('🍞 Whole wheat bread', true),
                            ('🧀 Cheddar cheese', false),
                            ('🍎 Apples (6 pack)', false),
                            ('🥬 Mixed vegetables', false),
                            ('🍗 Chicken breast', false),
                            ('🍝 Pasta', false),
                          ].map(
                            (item) => _ChecklistItem(
                              text: item.$1,
                              isChecked: item.$2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Additional notes section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9E6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFE4B5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 16,
                                      color: const Color(0xFFFF9500),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Quick Tips',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF8B7355),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '• Check for sales on organic produce\n• Buy in bulk for frequently used items\n• Remember reusable bags!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF6B5B47),
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildWindowTitle(
    WindowCoordinator coordinator,
    WindowsPath path,
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFFFB347), const Color(0xFFFF9500)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.sticky_note_2, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 8),
        const Text('Notes'),
      ],
    );
  }

  @override
  Widget buildDockIcon(
    WindowCoordinator coordinator,
    WindowsPath path,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFFFF5C3), const Color(0xFFFFE4A0)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9500).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.sticky_note_2,
        size: 24,
        color: const Color(0xFFFF9500),
      ),
    );
  }

  @override
  Uri toUri() => Uri.parse('/notes${noteId != null ? '/$noteId' : ''}');
}

class _NoteFolderItem extends StatefulWidget {
  const _NoteFolderItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isSelected;
  final Color color;

  @override
  State<_NoteFolderItem> createState() => _NoteFolderItemState();
}

class _NoteFolderItemState extends State<_NoteFolderItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? widget.color.withValues(alpha: 0.15)
              : _isHovered
              ? Colors.black.withValues(alpha: 0.04)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 18,
              color: widget.isSelected ? widget.color : Colors.grey[600],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: widget.isSelected ? widget.color : Colors.grey[800],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? widget.color.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${widget.count}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: widget.isSelected ? widget.color : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteListItemEnhanced extends StatefulWidget {
  const _NoteListItemEnhanced({
    required this.title,
    required this.preview,
    required this.date,
    required this.time,
    required this.isSelected,
    this.isPinned = false,
    this.hasChecklist = false,
    this.hasImage = false,
    this.hasAttachment = false,
  });

  final String title;
  final String preview;
  final String date;
  final String time;
  final bool isSelected;
  final bool isPinned;
  final bool hasChecklist;
  final bool hasImage;
  final bool hasAttachment;

  @override
  State<_NoteListItemEnhanced> createState() => _NoteListItemEnhancedState();
}

class _NoteListItemEnhancedState extends State<_NoteListItemEnhanced> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFFFF9500).withValues(alpha: 0.12)
              : _isHovered
              ? const Color(0xFFF5F0E6)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: widget.isSelected
              ? Border.all(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.isPinned) ...[
                  Icon(
                    Icons.push_pin,
                    size: 12,
                    color: const Color(0xFFFF9500),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D2D2D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  widget.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFFB8A88A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.preview,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (widget.hasChecklist ||
                widget.hasImage ||
                widget.hasAttachment) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (widget.hasChecklist) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.checklist,
                            size: 10,
                            color: const Color(0xFF34C759),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '3/8',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF34C759),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (widget.hasImage) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        size: 10,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (widget.hasAttachment)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5856D6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.attach_file,
                        size: 10,
                        color: const Color(0xFF5856D6),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotesToolbarButton extends StatefulWidget {
  const _NotesToolbarButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final bool isActive;

  @override
  State<_NotesToolbarButton> createState() => _NotesToolbarButtonState();
}

class _NotesToolbarButtonState extends State<_NotesToolbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFFFF9500).withValues(alpha: 0.15)
                : _isHovered
                ? Colors.black.withValues(alpha: 0.05)
                : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.isActive
                ? const Color(0xFFFF9500)
                : _isHovered
                ? const Color(0xFF6B5B47)
                : const Color(0xFF8B7355),
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatefulWidget {
  const _ChecklistItem({required this.text, required this.isChecked});

  final String text;
  final bool isChecked;

  @override
  State<_ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<_ChecklistItem> {
  late bool _isChecked;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.isChecked;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => setState(() => _isChecked = !_isChecked),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF5F0E6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isChecked
                      ? const Color(0xFFFF9500)
                      : Colors.transparent,
                  border: Border.all(
                    color: _isChecked
                        ? const Color(0xFFFF9500)
                        : const Color(0xFFD4C4A8),
                    width: 2,
                  ),
                ),
                child: _isChecked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    fontSize: 16,
                    color: _isChecked
                        ? const Color(0xFFB8A88A)
                        : const Color(0xFF2D2D2D),
                    decoration: _isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: const Color(0xFFB8A88A),
                  ),
                  child: Text(widget.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteListItem extends StatefulWidget {
  const _NoteListItem({
    required this.title,
    required this.preview,
    required this.date,
    required this.isSelected,
  });

  final String title;
  final String preview;
  final String date;
  final bool isSelected;

  @override
  State<_NoteListItem> createState() => _NoteListItemState();
}

class _NoteListItemState extends State<_NoteListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Colors.orange.withValues(alpha: 0.2)
              : _isHovered
              ? Colors.orange.withValues(alpha: 0.1)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown[800],
                    ),
                  ),
                ),
                Text(
                  widget.date,
                  style: TextStyle(fontSize: 11, color: Colors.brown[400]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.preview,
              style: TextStyle(fontSize: 12, color: Colors.brown[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings window
class SettingsWindow extends WindowRoute {
  @override
  Type? get layout => MacOSWindowLayout;

  @override
  bool get canMinimize => true;

  @override
  Widget build(WindowCoordinator coordinator, BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E2E),
      child: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: const Color(0xFF1A1B26),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsSidebarItem(Icons.person, 'Apple ID', true),
                _SettingsSidebarItem(Icons.family_restroom, 'Family', false),
                const Divider(color: Colors.white12, height: 24),
                _SettingsSidebarItem(Icons.wifi, 'Wi-Fi', false),
                _SettingsSidebarItem(Icons.bluetooth, 'Bluetooth', false),
                _SettingsSidebarItem(Icons.network_cell, 'Network', false),
                const Divider(color: Colors.white12, height: 24),
                _SettingsSidebarItem(
                  Icons.notifications,
                  'Notifications',
                  false,
                ),
                _SettingsSidebarItem(Icons.volume_up, 'Sound', false),
                _SettingsSidebarItem(Icons.brightness_6, 'Displays', false),
                _SettingsSidebarItem(Icons.wallpaper, 'Wallpaper', false),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF7C3AED),
                          const Color(0xFFEC4899),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'user@icloud.com',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud, color: const Color(0xFF5FB3F8)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'iCloud',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '45.6 GB of 200 GB used',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 150,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.23,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF5FB3F8),
                                    const Color(0xFF7C3AED),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildWindowTitle(
    WindowCoordinator coordinator,
    WindowsPath path,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(Icons.settings, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        const Text('System Settings'),
      ],
    );
  }

  @override
  Widget buildDockIcon(
    WindowCoordinator coordinator,
    WindowsPath path,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4D),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.settings, size: 24, color: Colors.grey),
    );
  }

  @override
  Uri toUri() => Uri.parse('/settings');
}

class _SettingsSidebarItem extends StatefulWidget {
  const _SettingsSidebarItem(this.icon, this.label, this.isSelected);

  final IconData icon;
  final String label;
  final bool isSelected;

  @override
  State<_SettingsSidebarItem> createState() => _SettingsSidebarItemState();
}

class _SettingsSidebarItemState extends State<_SettingsSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
              : _isHovered
              ? Colors.white.withValues(alpha: 0.05)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 18,
              color: widget.isSelected
                  ? const Color(0xFFA78BFA)
                  : Colors.white54,
            ),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.isSelected ? Colors.white : Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// About window
class AboutWindow extends WindowRoute {
  @override
  Type? get layout => MacOSWindowLayout;

  @override
  bool get canResize => false;

  @override
  Size get minSize => const Size(400, 300);

  @override
  Widget build(WindowCoordinator coordinator, BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E2E),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF7C3AED),
                  const Color(0xFFEC4899),
                  const Color(0xFFF59E0B),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.laptop_mac, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'macOS Sonoma',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 14.2.1',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _AboutRow('Chip', 'Apple M2 Pro'),
                _AboutRow('Memory', '16 GB'),
                _AboutRow('Startup Disk', 'Macintosh HD'),
                _AboutRow('Serial Number', 'XXXXXXXXXXX'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Software Update...',
                  style: TextStyle(color: const Color(0xFF5FB3F8)),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {},
                child: Text(
                  'More Info...',
                  style: TextStyle(color: const Color(0xFF5FB3F8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget buildWindowTitle(
    WindowCoordinator coordinator,
    WindowsPath path,
    BuildContext context,
  ) {
    return const Text('About This Mac');
  }

  @override
  Widget buildDockIcon(
    WindowCoordinator coordinator,
    WindowsPath path,
    BuildContext context,
  ) {
    return Icon(Icons.info, size: 24, color: Colors.white54);
  }

  @override
  Uri toUri() => Uri.parse('/about');
}

class _AboutRow extends StatelessWidget {
  const _AboutRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Index route that redirects to finder
class IndexRoute extends AppRoute with RouteRedirect {
  @override
  Widget build(WindowCoordinator coordinator, BuildContext context) =>
      const SizedBox.shrink();

  @override
  Uri toUri() => Uri.parse('/');

  @override
  FutureOr<RouteTarget> redirect() => FinderWindow();
}

// ============================================================================
// Coordinator
// ============================================================================

class WindowCoordinator extends Coordinator<AppRoute> {
  late final windowsPath = WindowsPath<WindowRoute>.createWith(
    coordinator: this,
    label: 'windows',
    stack: [FinderWindow(), TerminalWindow()],
  );

  @override
  List<StackPath<RouteTarget>> get paths => [...super.paths, windowsPath];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(MacOSWindowLayout, MacOSWindowLayout.new);
  }

  @override
  FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['finder'] => FinderWindow(path: uri.queryParameters['path'] ?? '/home'),
      ['terminal'] => TerminalWindow(sessionId: uri.queryParameters['session']),
      ['notes'] => NotesWindow(
        noteId: uri.pathSegments.length > 1 ? uri.pathSegments[1] : null,
      ),
      ['settings'] => SettingsWindow(),
      ['about'] => AboutWindow(),
      _ => FinderWindow(),
    };
  }
}

// ============================================================================
// Main
// ============================================================================

void main() {
  WindowsPath.definePath();

  final coordinator = WindowCoordinator();

  runApp(
    MaterialApp.router(
      title: 'macOS Windows Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Text',
      ),
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    ),
  );
}
