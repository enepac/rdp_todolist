import 'package:flutter/material.dart'; // Material UI package.
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for database.
import 'package:table_calendar/table_calendar.dart'; // Calendar widget.

// HomePage widget for the app.
class HomePage extends StatefulWidget {
  // StatefulWidget for dynamic state.
  const HomePage({super.key}); // Constructor.

  @override
  State<HomePage> createState() => _HomePageState(); // Create state.
}

// State class for HomePage.
class _HomePageState extends State<HomePage> {
  // State for HomePage.
  final FirebaseFirestore db =
      FirebaseFirestore.instance; // Firestore instance.
  final TextEditingController nameController =
      TextEditingController(); // Input controller.
  final List<Map<String, dynamic>> tasks = []; // Task list.

  @override
  void initState() {
    super.initState(); // Initialize state.
    fetchTasks(); // Fetch tasks on start.
  }

  //Fetches tasks from the firestore and update local task list
  Future<void> fetchTasks() async {
    // Fetch tasks from Firestore.
    final snapshot = await db.collection('tasks').orderBy('timestamp').get();

    setState(() {
      // Update state with tasks.
      tasks.clear(); // Clear existing tasks.
      tasks.addAll(
        snapshot.docs.map((doc) => {
              // Map Firestore docs.
              'id': doc.id, // Task ID.
              'name': doc.get('name'), // Task name.
              'completed': doc.get('completed') ?? false, // Completion status.
            }),
      );
    });
  }

  //Function that adds new tasks to local state & firestore database
  Future<void> addTask() async {
    // Add a new task.
    final taskName = nameController.text.trim(); // Get task name.

    if (taskName.isNotEmpty) {
      // Check if input is not empty.
      final newTask = {
        'name': taskName, // Task name.
        'completed': false, // Default status.
        'timestamp': FieldValue.serverTimestamp(), // Add timestamp.
      };

      //docRef give us the insertion id of the task from the database
      final docRef =
          await db.collection('tasks').add(newTask); // Save to Firestore.

      setState(() {
        // Update state with new task.
        tasks.add({'id': docRef.id, ...newTask}); // Add locally.
      });
      nameController.clear(); // Clear input field.
    }
  }

  //Updates the completion status of the task in Firestore & locally
  Future<void> updateTask(int index, bool completed) async {
    // Update task status.
    final task = tasks[index]; // Get task.
    await db
        .collection('tasks')
        .doc(task['id'])
        .update({'completed': completed}); // Update Firestore.

    setState(() {
      // Update local state.
      tasks[index]['completed'] = completed;
    });
  }

  //Edit the task locally & in the Firestore
  Future<void> editTask(int index) async {
    // Edit task name.
    final task = tasks[index]; // Get task to edit.
    final controller =
        TextEditingController(text: task['name']); // Prefill with current name.

    final updatedName = await showDialog<String>(
      // Show edit dialog.
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'), // Dialog title.
        content: TextField(
          controller: controller, // Input field for editing.
          decoration:
              const InputDecoration(labelText: 'Task Name'), // Input label.
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Cancel action.
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context)
                .pop(controller.text.trim()), // Save action.
            child: const Text('Save'),
          ),
        ],
      ),
    );

    //Update the task name in the Firestore & locally
    if (updatedName != null && updatedName.isNotEmpty) {
      // If valid input.
      await db
          .collection('tasks')
          .doc(task['id'])
          .update({'name': updatedName}); // Update Firestore.

      setState(() {
        // Update local state.
        tasks[index]['name'] = updatedName; // Change name.
      });
    }
  }

  //Shows a confirmation dialog before deleting the task
  Future<void> showDeleteConfirmationDialog(int index) async {
    // Confirm deletion.
    final task = tasks[index]; // Get task.
    final result = await showDialog<bool>(
      // Show dialog.
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'), // Dialog title.
        content: Text(
            'Are you sure you want to delete the task "${task['name']}"?'), // Confirm message.
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancel.
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Delete.
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    //Remove the task if the user confirms the deletion
    if (result == true) {
      // If confirmed.
      removeTasks(index); // Delete task.
    }
  }

  //Removes the task from the Firestore & locally
  Future<void> removeTasks(int index) async {
    // Remove task.
    final task = tasks[index]; // Get task.
    await db
        .collection('tasks')
        .doc(task['id'])
        .delete(); // Delete in Firestore.
    setState(() {
      // Update state.
      tasks.removeAt(index); // Remove locally.
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build UI.
    // Build UI.
    return Scaffold(
      // Scaffold for app structure.
      appBar: AppBar(
        backgroundColor: Colors.blue, // AppBar color.
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Center title.
          children: [
            Expanded(
                child: Image.asset('assets/rdplogo.png', height: 85)), // Logo.
            const Text(
              'Daily Planner', // App title.
              style: TextStyle(
                fontFamily: 'Caveat', // Font style.
                fontSize: 32, // Font size.
                color: Colors.white, // Font color.
              ),
            ),
          ],
        ),
      ),
      body: Column(
        // Body content.
        children: [
          Expanded(
            child: SingleChildScrollView(
              // Scrollable content.
              child: Column(
                children: [
                  // Calendar and task list.
                  TableCalendar(
                    // Calendar widget.
                    calendarFormat: CalendarFormat.month, // Calendar format.
                    focusedDay: DateTime.now(), // Current day.
                    firstDay: DateTime(2024), // Start date.
                    lastDay: DateTime(2025), // End date.
                  ),
                  buildTaskList(tasks, showDeleteConfirmationDialog, updateTask,
                      editTask), // Task list.
                ],
              ),
            ),
          ),
          buildAddTaskSection(nameController, addTask), // Task input.
        ],
      ),
      drawer: const Drawer(), // App drawer.
    );
  }
}

// Widget functions for building UI components.
Widget buildAddTaskSection(
    TextEditingController nameController, Function addTask) {
  // Input section.
  return Container(
    decoration: const BoxDecoration(color: Colors.white), // Background color.
    child: Padding(
      padding: const EdgeInsets.all(12.0), // Padding.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Align items.
        children: [
          Expanded(
            child: SizedBox(
              height: 60, // Input height.
              child: TextField(
                maxLength: 32, // Limit characters.
                controller: nameController, // Controller.
                decoration: const InputDecoration(
                  labelText: 'Add Task', // Label.
                  labelStyle:
                      TextStyle(fontSize: 12, color: Colors.grey), // Style.
                  border: OutlineInputBorder(), // Border.
                ),
                onSubmitted: (value) => addTask(), // Add task.
              ),
            ),
          ),
          const SizedBox(width: 6), // Space.
          SizedBox(
            height: 60, // Button height.
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromARGB(255, 198, 228, 218)), // Style.
              onPressed: () => addTask(), // Add task.
              child: const Icon(Icons.add), // Add icon.
            ),
          ),
        ],
      ),
    ),
  );
}

// Widget function for building task list.
Widget buildTaskList(
    tasks, showDeleteConfirmationDialog, updateTask, editTask) {
  // Task list.
  return ListView.builder(
    shrinkWrap: true, // Wrap content.
    physics: const NeverScrollableScrollPhysics(), // No scroll.
    itemCount: tasks.length, // Item count.
    itemBuilder: (context, index) {
      final task = tasks[index]; // Task.
      final isEven = index % 2 == 0; // Alternate colors.

      return Padding(
        padding: const EdgeInsets.all(1.0), // Padding.
        child: SizedBox(
          height: 50, // Item height.
          child: ListTile(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)), // Rounded corners.
            // Alternate colors.
            tileColor: isEven
                ? const Color.fromARGB(255, 215, 219, 240)
                : const Color.fromARGB(255, 190, 212, 230), // Color.
            leading: GestureDetector(
              onTap: () =>
                  updateTask(index, !task['completed']), // Toggle complete.
              child: Icon(
                  task['completed']
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  size: 20), // Icon.
            ),
            title: Text(
              task['name'], // Task name.
              style: TextStyle(
                  decoration:
                      task['completed'] ? TextDecoration.lineThrough : null,
                  decorationColor: task['completed'] ? Colors.red : null,
                  fontSize: 14), // Style.
              overflow: TextOverflow.ellipsis, // Ellipsis for overflow.
              maxLines: 2, // Two lines.
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min, // Compact icons.
              children: [
                IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => editTask(index),
                    padding: EdgeInsets.zero), // Edit.
                IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => showDeleteConfirmationDialog(index),
                    padding: EdgeInsets.zero), // Delete.
              ],
            ),
          ),
        ),
      );
    },
  );
}
