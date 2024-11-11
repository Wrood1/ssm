// view.dart
import 'package:flutter/material.dart';
import '../../widgets/bottom_bar.dart';
import '../models/employee_management_factory_manager_model.dart';
import '../controllers/employee_management_factory_manager_controller.dart';

class FactoryManagementPage extends StatefulWidget {
  final String factoryManagerId;

  const FactoryManagementPage({Key? key, required this.factoryManagerId})
      : super(key: key);

  @override
  _FactoryManagementPageState createState() => _FactoryManagementPageState();
}

class _FactoryManagementPageState extends State<FactoryManagementPage>
    with SingleTickerProviderStateMixin {
  late FactoryManagementController _controller;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  List<Person> _safetyPersons = [];
  List<Person> _employees = [];
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = FactoryManagementController(factoryManagerId: widget.factoryManagerId);
    _tabController = TabController(length: 2, vsync: this);
    _loadData();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  Future<void> _loadData() async {
    final safetyPersons = await _controller.loadPersonsByPosition('Safety Person');
    final employees = await _controller.loadPersonsByPosition('Employee');
    
    setState(() {
      _safetyPersons = safetyPersons;
      _employees = employees;
    });
  }

  void _showAddPersonDialog(BuildContext context, String position) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add $position'),
          content: TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "Enter ${position.toLowerCase()}'s email"
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (_emailController.text.isNotEmpty) {
                  await _controller.addPerson(
                    _emailController.text,
                    position,
                    context
                  );
                  _emailController.clear();
                  Navigator.of(context).pop();
                  _loadData();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserList(bool isSafetyPerson) {
    final List<Person> users = isSafetyPerson ? _safetyPersons : _employees;
    final String position = isSafetyPerson ? 'Safety Person' : 'Employee';

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            painter: TopHillPainter(),
            size: Size(MediaQuery.of(context).size.width, 250),
          ),
        ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search $position',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  // Implement search functionality
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final person = users[index];

                  return Dismissible(
                    key: Key(person.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await _controller.deletePerson(person.id, context);
                      _loadData();
                    },
                    child: ListTile(
                      title: Text(person.name),
                      subtitle: Text(person.email),
                      leading: CircleAvatar(
                        backgroundImage: person.profileImage != null
                            ? NetworkImage(person.profileImage!)
                            : null,
                        child: person.profileImage == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _controller.deletePerson(person.id, context);
                          _loadData();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: Colors.brown[300],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Safety Persons'),
            Tab(text: 'Employees'),
          ],
          indicatorColor: Colors.white,
        ),
        title: const Text(
          'Factory Management',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildUserList(true),
              _buildUserList(false),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 36,
            child: FloatingActionButton(
              backgroundColor: Colors.brown[300],
              child: const Icon(Icons.add),
              onPressed: () {
                if (_tabController.index == 0) {
                  _showAddPersonDialog(context, 'Safety Person');
                } else {
                  _showAddPersonDialog(context, 'Employee');
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class TopHillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[300]!
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.2,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}