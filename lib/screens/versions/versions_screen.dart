import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../managers/app_manager.dart';
import '../../models/zrok_version.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class VersionsScreen extends StatefulWidget {
  const VersionsScreen({super.key});
  @override
  State<VersionsScreen> createState() => _VersionsScreenState();
}

class _VersionsScreenState extends State<VersionsScreen> {
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    // Auto-refresh on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppManager>().refreshVersions();
    });
  }

  void _download(AppManager manager, ZrokVersion version) {
    setState(() => _downloadProgress[version.version] = 0);
    manager
        .downloadVersion(version)
        .listen(
          (progress) =>
              setState(() => _downloadProgress[version.version] = progress),
          onDone: () =>
              setState(() => _downloadProgress.remove(version.version)),
          onError: (_) =>
              setState(() => _downloadProgress.remove(version.version)),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppManager>(
      builder: (context, manager, _) {
        final versions = manager.versions;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Zrok Versions'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh from GitHub',
                  onPressed: () => manager.refreshVersions(),
                ),
              ],
            ),
            if (versions.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No versions',
                  subtitle: 'Tap refresh to fetch from GitHub',
                ),
              )
            else ...[
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) => _buildVersionCard(
                    context,
                    manager,
                    versions[index],
                    index == 0,
                  ),
                  childCount: versions.length,
                ),
              ),
              SliverToBoxAdapter(
                child: FutureBuilder<int>(
                  future: manager.getVersionStorageUsed(),
                  builder: (ctx, snap) {
                    final bytes = snap.data ?? 0;
                    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Storage: $mb MB used',
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildVersionCard(
    BuildContext context,
    AppManager manager,
    ZrokVersion version,
    bool isLatest,
  ) {
    final usedBy = manager.envsUsingVersion(version.version);
    final isDefault = manager.settings.defaultZrokVersion == version.version;
    final progress = _downloadProgress[version.version];
    final isDownloading = progress != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: version + badges
            Row(
              children: [
                Text(
                  version.displayVersion,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (isLatest) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'latest',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppTheme.teal),
                    ),
                  ),
                ],
                if (isDefault) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.push_pin, size: 14, color: AppTheme.amber),
                  const SizedBox(width: 2),
                  Text(
                    'Default',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppTheme.amber),
                  ),
                ],
                const Spacer(),
                if (version.isDownloaded)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 12,
                          color: AppTheme.teal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Installed',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppTheme.teal),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_download_outlined,
                          size: 12,
                          color: Color(0xFFC4C0FF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Available',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: const Color(0xFFC4C0FF)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Size + release date
            Text(
              '${version.sizeFormatted}${version.releaseDate != null ? ' · Released: ${version.releaseDate!.toLocal().toString().substring(0, 10)}' : ''}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (usedBy.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Used by: ${usedBy.join(", ")}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],

            // Download progress
            if (isDownloading) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.surfaceContainerHighest,
                color: AppTheme.teal,
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],

            const SizedBox(height: 10),
            // Actions
            Row(
              children: [
                if (!version.isDownloaded && !isDownloading)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download'),
                    onPressed: version.downloadUrl.isNotEmpty
                        ? () => _download(manager, version)
                        : null,
                  ),
                if (version.isDownloaded && !isDefault)
                  OutlinedButton(
                    onPressed: () => manager.setDefaultVersion(version.version),
                    child: const Text('Set Default'),
                  ),
                const Spacer(),
                if (version.isDownloaded)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _confirmDelete(context, manager, version),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppManager manager,
    ZrokVersion version,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Version'),
        content: Text(
          'Delete ${version.displayVersion}? Envs using this version will reset to default.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              manager.deleteVersion(version);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
