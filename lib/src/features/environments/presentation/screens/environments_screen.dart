import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/state/app_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/env_info.dart';

class EnvironmentsScreen extends StatelessWidget {
  const EnvironmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, manager, _) {
        return CustomScrollView(
          slivers: [
            const SliverAppBar(floating: true, title: Text('Environments')),
            // Env Cards
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, index) =>
                    _buildEnvCard(context, manager, manager.envs[index]),
                childCount: manager.envs.length,
              ),
            ),
            // Add button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Environment'),
                  onPressed: () => _showAddEnvDialog(context, manager),
                ),
              ),
            ),
            // Settings Section
            SliverToBoxAdapter(child: _buildSettings(context, manager)),
          ],
        );
      },
    );
  }

  Widget _buildEnvCard(
    BuildContext context,
    AppController manager,
    EnvInfo env,
  ) {
    final taskCount = manager.taskCountForEnv(env.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: env.enabled ? AppTheme.teal : AppTheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    env.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(env.endpoint, style: AppTheme.monoSmall),
            if (env.enabled) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 12,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Token: ${env.maskedToken}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showVersionPicker(context, manager, env),
                child: Row(
                  children: [
                    Text(
                      'Version: ${env.zrokVersion ?? manager.settings.defaultZrokVersion ?? "latest"}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              env.enabled
                  ? 'Enabled · $taskCount task${taskCount != 1 ? 's' : ''}'
                  : 'Not enabled',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: env.enabled ? AppTheme.teal : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    if (env.enabled) {
                      manager.disableEnv(env.id);
                    } else {
                      _showEnableDialog(context, manager, env);
                    }
                  },
                  child: Text(env.enabled ? 'Disable' : 'Enable'),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _confirmDelete(context, manager, env),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context, AppController manager) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(
            'Settings',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Notifications'),
            secondary: const Icon(Icons.notifications_outlined),
            value: manager.settings.notificationsEnabled,
            onChanged: (_) => manager.toggleNotifications(),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Auto-reconnect'),
            secondary: const Icon(Icons.sync_outlined),
            value: manager.settings.autoReconnect,
            onChanged: (_) => manager.toggleAutoReconnect(),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Default version'),
            trailing: Text(
              manager.settings.defaultZrokVersion ?? 'latest',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
            onTap: () => _showDefaultVersionPicker(context, manager),
          ),
        ],
      ),
    );
  }

  void _showAddEnvDialog(BuildContext context, AppController manager) {
    final nameCtrl = TextEditingController();
    final endpointCtrl = TextEditingController(text: 'https://api.zrok.io');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Environment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(hintText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endpointCtrl,
              decoration: const InputDecoration(hintText: 'Endpoint'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                manager.createEnv(nameCtrl.text, endpointCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEnableDialog(
    BuildContext context,
    AppController manager,
    EnvInfo env,
  ) {
    final tokenCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enable ${env.name}'),
        content: TextField(
          controller: tokenCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Invite token'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tokenCtrl.text.isNotEmpty) {
                manager.enableEnv(env.id, tokenCtrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showVersionPicker(
    BuildContext context,
    AppController manager,
    EnvInfo env,
  ) {
    final installed = manager.installedVersions;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Version',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ListTile(
            title: const Text('Default'),
            trailing: env.zrokVersion == null
                ? const Icon(Icons.check, color: AppTheme.teal)
                : null,
            onTap: () {
              manager.setEnvVersion(env.id, null);
              Navigator.pop(ctx);
            },
          ),
          ...installed.map(
            (v) => ListTile(
              title: Text(v.displayVersion),
              trailing: env.zrokVersion == v.version
                  ? const Icon(Icons.check, color: AppTheme.teal)
                  : null,
              onTap: () {
                manager.setEnvVersion(env.id, v.version);
                Navigator.pop(ctx);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDefaultVersionPicker(BuildContext context, AppController manager) {
    final installed = manager.installedVersions;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Default Version',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ListTile(
            title: const Text('Latest installed'),
            trailing: manager.settings.defaultZrokVersion == null
                ? const Icon(Icons.check, color: AppTheme.teal)
                : null,
            onTap: () {
              manager.setDefaultVersion(null);
              Navigator.pop(ctx);
            },
          ),
          ...installed.map(
            (v) => ListTile(
              title: Text(v.displayVersion),
              trailing: manager.settings.defaultZrokVersion == v.version
                  ? const Icon(Icons.check, color: AppTheme.teal)
                  : null,
              onTap: () {
                manager.setDefaultVersion(v.version);
                Navigator.pop(ctx);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppController manager,
    EnvInfo env,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Environment'),
        content: Text(
          'Delete "${env.name}"? This will stop all running tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              manager.deleteEnv(env.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
