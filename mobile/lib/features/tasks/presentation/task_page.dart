import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/task.dart';
import 'task_controller.dart';
import '../../../core/providers.dart';

class TaskPage extends ConsumerWidget {
  const TaskPage({super.key});

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Task'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter task title',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (val.trim().length > 120) {
                    return 'Maximum 120 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter details',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await ref.read(taskListProvider.notifier).createTask(
                        titleController.text.trim(),
                        descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              ref.read(taskListProvider.notifier).deleteTask(task);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Task Manager'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.read(authStateProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: TaskListView(
        loading: state.loading,
        tasks: state.tasks,
        errorMessage: state.errorMessage,
        onRetry: () => ref.read(taskListProvider.notifier).loadTasks(),
        onToggle: (task) =>
            ref.read(taskListProvider.notifier).toggleCompleted(task),
        onDelete: (task) => _confirmDelete(context, ref, task),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}

/// Renders an asynchronous task-list result.
class TaskListView extends StatelessWidget {
  /// Creates a task list view.
  const TaskListView({
    super.key,
    required this.loading,
    required this.tasks,
    required this.errorMessage,
    required this.onRetry,
    required this.onToggle,
    required this.onDelete,
  });

  /// Whether the repository is loading tasks.
  final bool loading;

  /// Tasks to display after a successful load.
  final List<Task> tasks;

  /// Safe error message, if the request failed.
  final String? errorMessage;

  /// Callback to retry loading.
  final VoidCallback onRetry;

  /// Callback for completion changes.
  final ValueChanged<Task> onToggle;

  /// Callback for deletion.
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            const Text(
              'No tasks yet. Add your first task.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            elevation: 0,
            color: task.completed
                ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
                : null,
            child: ListTile(
              leading: Checkbox(
                value: task.completed,
                onChanged: (_) => onToggle(task),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration:
                      task.completed ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: task.description == null
                  ? null
                  : Text(
                      task.description!,
                      style: TextStyle(
                        decoration:
                            task.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
              trailing: IconButton(
                tooltip: 'Delete task',
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => onDelete(task),
              ),
            ),
          );
        },
      ),
    );
  }
}
