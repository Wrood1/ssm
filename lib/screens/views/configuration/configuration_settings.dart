import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ConfigurationSettingsPage extends StatefulWidget {
  final String userId;
  const ConfigurationSettingsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ConfigurationSettingsPageState createState() => _ConfigurationSettingsPageState();
}

class _ConfigurationSettingsPageState extends State<ConfigurationSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _database = FirebaseDatabase.instance.ref();
  
  // Map to store room configurations
  Map<String, Map<String, dynamic>> _roomConfigs = {};
  // Selected room from dropdown
  String? _selectedRoom;
  // Map to store room IDs and their names
  Map<String, String> _roomNames = {};
  // List to store all rooms in the location
  List<String> _rooms = [];
  
  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final snapshot = await _database.get();
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        data.forEach((locationKey, locationData) {
          if (locationData is Map) {
            final locationMap = Map<String, dynamic>.from(locationData);
            if (locationMap['ID'] == widget.userId) {
              // Find all rooms and their names in this location
              locationMap.forEach((key, value) {
                if (key.startsWith('room') && value is Map) {
                  _rooms.add(key);
                  // Store the room name if it exists, otherwise use room ID
                  _roomNames[key] = (value['name'] as String?) ?? key;
                  
                  // Initialize configurations for each room
                  _roomConfigs[key] = {
                    'priorities': {
                      'temperature': 2,
                      'humidity': 2,
                      'gas': 2,
                    },
                    'thresholds': {
                      'temperature': {'medium': 25, 'maximum': 35},
                      'humidity': {'medium': 60, 'maximum': 80},
                      'gas': {'medium': 30, 'maximum': 50},
                    }
                  };
                }
              });
              setState(() {});
            }
          }
        });
      }
    } catch (e) {
      print('Error loading rooms: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5E6D3),
      body: Stack(
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
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRoomDropdown(),
                          SizedBox(height: 20),
                          _buildConfigurationCards(),
                          SizedBox(height: 30),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 12),
          Text(
            'Room Configuration',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDropdown() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Room for Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedRoom,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: Text('Select a room'),
              items: _rooms.map((String roomId) {
                return DropdownMenuItem<String>(
                  value: roomId,
                  child: Row(
                    children: [
                      Text(
                        roomId,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '- ${_roomNames[roomId]}',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRoom = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a room';
                }
                return null;
              },
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCards() {
    if (_selectedRoom == null) {
      return Center(
        child: Text('Select a room to configure',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return _buildRoomConfigCard(_selectedRoom!);
  }

  Widget _buildRoomConfigCard(String room) {
    final config = _roomConfigs[room]!;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  room,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '- ${_roomNames[room]}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildPrioritySection(room, config),
            SizedBox(height: 16),
            _buildThresholdSection(room, config),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySection(String room, Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priorities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        _buildPrioritySlider('Temperature', room, 'temperature', config),
        _buildPrioritySlider('Humidity', room, 'humidity', config),
        _buildPrioritySlider('Gas', room, 'gas', config),
      ],
    );
  }

  Widget _buildPrioritySlider(String label, String room, String field, Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label Priority'),
        Slider(
          value: config['priorities'][field].toDouble(),
          min: 1,
          max: 3,
          divisions: 2,
          label: config['priorities'][field].toString(),
          onChanged: (value) {
            setState(() {
              _roomConfigs[room]!['priorities'][field] = value.round();
            });
          },
        ),
      ],
    );
  }

  Widget _buildThresholdSection(String room, Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thresholds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        _buildThresholdFields('Temperature', room, 'temperature', '°C', config),
        _buildThresholdFields('Humidity', room, 'humidity', '%', config),
        _buildThresholdFields('Gas', room, 'gas', 'ppm', config),
      ],
    );
  }

  Widget _buildThresholdFields(String label, String room, String field, String unit, Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: config['thresholds'][field]['medium'].toString(),
                decoration: InputDecoration(
                  labelText: 'Medium ($unit)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _roomConfigs[room]!['thresholds'][field]['medium'] = double.tryParse(value) ?? 0;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: config['thresholds'][field]['maximum'].toString(),
                decoration: InputDecoration(
                  labelText: 'Maximum ($unit)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _roomConfigs[room]!['thresholds'][field]['maximum'] = double.tryParse(value) ?? 0;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[700],
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _saveConfiguration,
        child: Text(
          'Save Configuration',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  void _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoom == null) return;

    try {
      final snapshot = await _database.get();
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        data.forEach((locationKey, locationData) {
          if (locationData is Map) {
            final locationMap = Map<String, dynamic>.from(locationData);
            if (locationMap['ID'] == widget.userId) {
              // Update configuration for selected room
              _database.child(locationKey).child(_selectedRoom!).update({
                'configuration': _roomConfigs[_selectedRoom!],
              });
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Configuration saved successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving configuration: $e')),
      );
    }
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