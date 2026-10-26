import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/task_repository.dart';
import '../domain/task.dart';
import '../../../core/providers.dart';

class TaskListState {
  const TaskListState({
    this.loading = false,
    this.tasks = const [],
    this.errorMessage,
  });

  final bool loading;
  final List<Task> tasks;
  final String? errorMessage;

  TaskListState copyWith({
    bool? loading,
    List<Task>? tasks,
    String? errorMessage,
  }) {
    return TaskListState(
      loading: loading ?? this.loading,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage,
    );
  }
}

class TaskListNotifier extends Notifier<TaskListState> {
  @override
  TaskListState build() {
    Future.microtask(() => loadTasks());
    return const TaskListState();
  }

  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  Future<void> loadTasks() async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final tasks = await _repository.list();
      state = state.copyWith(loading: false, tasks: tasks, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> toggleCompleted(Task task) async {
    final nextStatus = !task.completed;
    try {
      final updated = await _repository.setCompleted(task, nextStatus);
      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == task.id ? updated : t).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> createTask(String title, String? description) async {
    try {
      final created = await _repository.create(title, description);
      state = state.copyWith(
        tasks: [created, ...state.tasks],
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> deleteTask(Task task) async {
    try {
      await _repository.delete(task.id);
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != task.id).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final taskListProvider =
    NotifierProvider<TaskListNotifier, TaskListState>(TaskListNotifier.new);
