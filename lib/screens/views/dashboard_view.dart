// dashboard_view.dar
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../widgets/bottom_bar.dart';
import '../models/dashboard_model.dart';
import '../controllers/dashboard_controller.dart';
class DashboardView extends StatefulWidget {
  final String userId;
  final String userPosition;
  
  const DashboardView({
    Key? key,
    required this.userId,
    required this.userPosition,
  }) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardModel _model;
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _model = DashboardModel(
      userId: widget.userId,
      userPosition: widget.userPosition,
    );
    _controller = DashboardController(model: _model);
    _controller.loadUserData();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF5E6D3),
    body: Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            painter: TopHillPainter(),
            size: Size(MediaQuery.of(context).size.width, 280),
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final userData = snapshot.data!.data() as Map<String, dynamic>;
                            final profileImage = userData['profileImage'] as String?;
                            final userName = userData['name'] as String?;
                            
                            // Update the model's userName
                            if (mounted && userName != null && _model.userName != userName) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  _model.userName = userName;
                                });
                              });
                            }

                            return Row(
                              children: [
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(27.5),
                                    child: profileImage != null
                                        ? Image.network(
                                            profileImage,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: Colors.brown[300],
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 35,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome,',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      Text(
                                        userName ?? 'Loading...',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox(
                            height: 55,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        _buildNotificationsButton(),
                        const SizedBox(width: 8),
                        _buildMoreOptionsButton(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'My Sections',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    children: _model.getSectionsForPosition().map((section) => _buildSectionButton(
                      title: section.title,
                      icon: section.icon,
                      onTap: () => section.onTap(context),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildSectionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.brown[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.brown[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.brown[800],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.brown[300],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsButton() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref().onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        bool hasNotifications = false;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map);
          data.forEach((locationKey, locationData) {
            if (locationData is Map) {
              final locationMap = Map<String, dynamic>.from(locationData);
              if (locationMap['ID'] == widget.userId &&
                  locationMap['alarm'] == '1') {
                hasNotifications = true;
              }
            }
          });
        }
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            if (hasNotifications)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMoreOptionsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert,
          color: Colors.white,
          size: 28,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: const [
                Icon(Icons.logout, color: Colors.brown),
                SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(color: Colors.brown),
                ),
              ],
            ),
          ),
        ],
        onSelected: (String value) {
          if (value == 'logout') {
            _controller.showLogoutDialog(context);
          }
        },
      ),
    );
  }
}

class TopHillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[400]!
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.8);
    
    // Create a more natural curve
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 1.0,
      size.width * 0.5,
      size.height * 0.8,
    );
    
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.6,
      size.width,
      size.height * 0.8,
    );
    
    path.lineTo(size.width, 0);
    path.close();

    // Add gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.brown[400]!,
        Colors.brown[300]!,
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Main Dashboard page that uses the view
class DashboardPage extends StatelessWidget {
  final String userId;
  final String userPosition;

  const DashboardPage({
    Key? key,
    required this.userId,
    required this.userPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DashboardView(
      userId: userId,
      userPosition: userPosition,
    );
  }
}