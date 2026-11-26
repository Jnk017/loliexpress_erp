import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App bar variant types for different contexts
enum CustomAppBarVariant {
  /// Standard app bar with title and actions
  standard,

  /// App bar with search functionality
  search,

  /// App bar with back button and title
  detail,

  /// App bar with sync status indicator
  sync,

  /// Transparent app bar for scrollable content
  transparent,
}

/// Custom app bar for Loliexpress ERP
/// Implements professional enterprise design with contextual actions
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final CustomAppBarVariant variant;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool root;
  final VoidCallback? onBackPressed;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final String? searchHint;
  final bool showSyncStatus;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final double elevation;
  final Color? backgroundColor;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    this.title,
    this.variant = CustomAppBarVariant.standard,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.root = false,
    this.onBackPressed,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.searchHint = 'Rechercher...',
    this.showSyncStatus = false,
    this.isSyncing = false,
    this.lastSyncTime,
    this.elevation = 0,
    this.backgroundColor,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      elevation: variant == CustomAppBarVariant.transparent ? 0 : elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: !root,
      leading: _buildLeading(context),
      title: _buildTitle(context),
      actions: _buildActions(context),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (showBackButton && (onBackPressed != null || Navigator.canPop(context))) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        tooltip: 'Retour',
      );
    }

    return null;
  }

  Widget? _buildTitle(BuildContext context) {
    final theme = Theme.of(context);

    switch (variant) {
      case CustomAppBarVariant.search:
        return _buildSearchField(context);

      case CustomAppBarVariant.sync:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: centerTitle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title!,
                style: theme.appBarTheme.titleTextStyle,
              ),
            if (showSyncStatus) _buildSyncStatus(context),
          ],
        );

      case CustomAppBarVariant.standard:
      case CustomAppBarVariant.detail:
      case CustomAppBarVariant.transparent:
        return title != null
            ? Text(
                title!,
                style: theme.appBarTheme.titleTextStyle,
              )
            : null;
    }
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        onSubmitted: (_) => onSearchSubmitted?.call(),
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: searchHint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: searchController?.text.isNotEmpty ?? false
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    searchController?.clear();
                    onSearchChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatus(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isSyncing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Synchronisation…',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
      );
    }

    if (lastSyncTime != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSyncTime!);
      String timeAgo;

      if (difference.inMinutes < 1) {
        timeAgo = 'à l’instant';
      } else if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours} h';
      } else {
        timeAgo = '${difference.inDays} j';
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 12,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Synchronisé $timeAgo',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget>? _buildActions(BuildContext context) {
    if (actions != null && actions!.isNotEmpty) {
      return actions;
    }

    // Default actions based on variant
    switch (variant) {
      case CustomAppBarVariant.search:
        return [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Filter action
            },
            tooltip: 'Filter',
          ),
        ];

      case CustomAppBarVariant.sync:
        return [
          if (!isSyncing)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Sync action
              },
              tooltip: 'Sync',
            ),
        ];

      default:
        return null;
    }
  }
}

/// Sliver variant for use with CustomScrollView
class CustomSliverAppBar extends StatelessWidget {
  final String? title;
  final CustomAppBarVariant variant;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool root;
  final VoidCallback? onBackPressed;
  final bool pinned;
  final bool floating;
  final bool snap;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final Color? backgroundColor;
  final bool centerTitle;

  const CustomSliverAppBar({
    super.key,
    this.title,
    this.variant = CustomAppBarVariant.standard,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.root = false,
    this.onBackPressed,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.expandedHeight = kToolbarHeight,
    this.flexibleSpace,
    this.backgroundColor,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      elevation: variant == CustomAppBarVariant.transparent ? 0 : 4,
      pinned: pinned,
      floating: floating,
      snap: snap,
      expandedHeight: expandedHeight,
      centerTitle: centerTitle,
      automaticallyImplyLeading: !root,
      leading: _buildLeading(context),
      title: title != null
          ? Text(
              title!,
              style: theme.appBarTheme.titleTextStyle,
            )
          : null,
      actions: actions,
      flexibleSpace: flexibleSpace,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (showBackButton && (onBackPressed != null || Navigator.canPop(context))) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        tooltip: 'Retour',
      );
    }

    return null;
  }
}
