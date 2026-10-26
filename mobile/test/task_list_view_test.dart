import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/tasks/domain/task.dart';
import 'package:mobile/features/tasks/presentation/task_page.dart';

void main() {
  testWidgets('displays loading indicator when loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskListView(
            loading: true,
            tasks: const [],
            errorMessage: null,
            onRetry: () {},
            onToggle: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays error message and retry button on error', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskListView(
            loading: false,
            tasks: const [],
            errorMessage: 'Network connection failed',
            onRetry: () => retried = true,
            onToggle: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Network connection failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, true);
  });

  testWidgets('displays empty state message when tasks list is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskListView(
            loading: false,
            tasks: const [],
            errorMessage: null,
            onRetry: () {},
            onToggle: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('No tasks yet. Add your first task.'), findsOneWidget);
  });

  testWidgets('displays tasks and allows toggling and deleting', (tester) async {
    Task? toggledTask;
    Task? deletedTask;

    const testTask = Task(
      id: 'task-1',
      title: 'Complete Security Assignment',
      description: 'Implement JWT and refresh rotation',
      completed: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskListView(
            loading: false,
            tasks: const [testTask],
            errorMessage: null,
            onRetry: () {},
            onToggle: (t) => toggledTask = t,
            onDelete: (t) => deletedTask = t,
          ),
        ),
      ),
    );

    expect(find.text('Complete Security Assignment'), findsOneWidget);
    expect(find.text('Implement JWT and refresh rotation'), findsOneWidget);

    // Toggle checkbox
    await tester.tap(find.byType(Checkbox));
    expect(toggledTask?.id, 'task-1');

    // Tap delete button
    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deletedTask?.id, 'task-1');
  });
}
