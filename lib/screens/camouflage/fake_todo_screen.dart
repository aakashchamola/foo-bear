import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/remote_config_service.dart';
import '../welcome_screen.dart';
import '../home_screen.dart';

class FakeTodoScreen extends StatefulWidget {
  const FakeTodoScreen({super.key});

  @override
  State<FakeTodoScreen> createState() => _FakeTodoScreenState();
}

class _FakeTodoScreenState extends State<FakeTodoScreen>
    with TickerProviderStateMixin {
  final TextEditingController _todoController = TextEditingController();
  final List<String> _fakeTodos = [];
  bool _isChecking = false;
  late AnimationController _unlockController;
  late Animation<double> _unlockAnimation;

  @override
  void initState() {
    super.initState();
    _unlockController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _unlockAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _unlockController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _todoController.dispose();
    _unlockController.dispose();
    super.dispose();
  }

  Future<void> _submitTodo() async {
    final todoText = _todoController.text.trim();
    if (todoText.isEmpty) return;

    setState(() {
      _isChecking = true;
    });

    // Small delay for UX
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // Check if the entered text matches the secret password from Remote Config
      final remoteConfig = RemoteConfigService();

      if (remoteConfig.verifyPassword(todoText)) {
        // 🎉 Password matches! Unlock the real app
        await _unlockRealApp();
        return;
      }

      // Wrong password - just add to fake todo list
      setState(() {
        _fakeTodos.insert(0, todoText);
        _todoController.clear();
        _isChecking = false;
      });
    } catch (e) {
      // If verification fails, just add to fake list
      setState(() {
        _fakeTodos.insert(0, todoText);
        _todoController.clear();
        _isChecking = false;
      });
    }
  }

  Future<void> _unlockRealApp() async {
    // Start unlock animation
    await _unlockController.forward();

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final welcomeCompleted = prefs.getBool('welcome_completed') ?? false;
    final userRole = prefs.getString('user_role'); // Check if role is set

    // If role is not set, show welcome screen regardless of welcome_completed
    final hasCompletedSetup =
        welcomeCompleted && (userRole != null && userRole.isNotEmpty);

    // Navigate to appropriate screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasCompletedSetup ? const HomeScreen() : const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _removeTodo(int index) {
    setState(() {
      _fakeTodos.removeAt(index);
    });
  }

  void _toggleTodo(int index) {
    // Just for show - doesn't do anything real
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _unlockAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _unlockAnimation.value,
          child: Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              backgroundColor: Colors.blue,
              elevation: 2,
              title: const Text(
                'My Tasks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {
                    // Show fake about dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('About My Tasks'),
                        content: const Text(
                            'A simple task manager to organize your daily tasks.\n\nVersion 1.0.0'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // Add Todo Input
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _todoController,
                          enabled: !_isChecking,
                          decoration: InputDecoration(
                            hintText: 'Add a new task...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _submitTodo(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _isChecking ? null : _submitTodo,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: _isChecking
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Todo List
                Expanded(
                  child: _fakeTodos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add a task to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _fakeTodos.length,
                          itemBuilder: (context, index) {
                            return Dismissible(
                              key: Key(_fakeTodos[index] + index.toString()),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _removeTodo(index),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: Checkbox(
                                    value: false,
                                    onChanged: (_) => _toggleTodo(index),
                                    activeColor: Colors.blue,
                                  ),
                                  title: Text(
                                    _fakeTodos[index],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => _removeTodo(index),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
