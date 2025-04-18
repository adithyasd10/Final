import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:projects/pages/profile_page.dart';
import '../backend.dart'; // Import the backend file
import '../pages/teacher_group_page.dart'; // Import Teacher Group Page
import '../pages/student_group_page.dart'; // Import background service
import 'dart:math';
import 'dart:ui'; // For blur effect
import 'package:animate_do/animate_do.dart';

class IVTrackingHome extends StatefulWidget {
  @override
  _IVTrackingHomeState createState() => _IVTrackingHomeState();
}

class _IVTrackingHomeState extends State<IVTrackingHome> {

  final String _customMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      { "color": "#1B1B1B" }  // Deep Charcoal Background
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#E0E0E0" }  // Soft White for Readability
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      { "color": "#1B1B1B" }  // Background Matched Stroke for Clean Look
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      { "color": "#2D2D2D" }  // Dark Grey Roads for Visibility
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      { "color": "#3A3A3A" },  // Slightly Lighter Highways for Contrast
      { "lightness": 10 }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      { "color": "#0F172A" }  // Deep Navy Blue Water for Elegance
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      { "color": "#252525" }  // Subtle Grey for Points of Interest
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      { "color": "#202020" }  // Dark Transit Lines for a Minimalist Look
    ]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [
      { "color": "#1B1B1B" }  // Dark Landscape for Depth
    ]
  }
]
''';


  String? userRole;
  bool isSliderVisible = false;
  GoogleMapController? mapController;

  // Variables for geofence creation
  double geofenceRadius = 100.0; // in meters
  LatLng? selectedLocation;
  Set<Circle> geofenceCircles = {};

  LatLng simulatedLocation = LatLng(37.7749, -122.4194); // Initial position
  Set<Marker> markers = {};
  bool isInsideGeofence = true; // Track geofence status

  // Define the initial position of the camera
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState(); // This should now work!
    _fetchUserRole(); // Fetch user role from backend
    _loadGeofencesForGroup("groupId123"); // Load geofences for the group
    _setupGeofence(); // Initialize geofence
    _updateMarker();
  }

  void _fetchUserRole() async {
    userRole = await Backend.fetchUserRole(); // Call backend function
    setState(() {});
  }

  void _loadGeofencesForGroup(String groupId) async {
    final geofences = await Backend.fetchGeofencesForGroup(groupId);
    setState(() {
      if (geofences.isNotEmpty) {
        final latestGeofence = geofences.last;
        final center = LatLng(
          latestGeofence['center']['lat'],
          latestGeofence['center']['lng'],
        );
        geofenceCircles = {
          Circle(
            circleId: CircleId(center.toString()),
            center: center,
            radius: latestGeofence['radius'],
            fillColor: Colors.blue.withOpacity(0.5),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        };
      } else {
        geofenceCircles.clear();
      }
    });
  }


  void _setupGeofence() {
    geofenceCircles.add(
      Circle(
        circleId: CircleId("geofence"),
        center: LatLng(37.7749, -122.4194), // Geofence Center
        radius: 100, // 100 meters radius
        strokeColor: Colors.blue,
        strokeWidth: 2,
        fillColor: Colors.blue.withOpacity(0.3),
      ),
    );
  }

  void _updateMarker() {
    setState(() {
      markers.clear();
      markers.add(
        Marker(
          markerId: MarkerId("simulated"),
          position: simulatedLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      if (!isPointInsideGeofence(simulatedLocation)) {
        if (isInsideGeofence) {
          isInsideGeofence = false;
          print("Exited geofence!");
          _showExitPopup();
        }
      } else {
        isInsideGeofence = true;
      }
    });
  }

  bool isPointInsideGeofence(LatLng point) {
    for (var circle in geofenceCircles) {
      final distance = _calculateDistance(
        point.latitude,
        point.longitude,
        circle.center.latitude,
        circle.center.longitude,
      );
      if (distance <= circle.radius) {
        return true;
      }
    }
    return false;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _showExitPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Geofence Alert"),
          content: Text("You have exited the geofence."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void moveMarker(String direction) {
    double step = 0.0001; // Adjust for small movements
    setState(() {
      if (direction == "UP") {
        simulatedLocation = LatLng(
            simulatedLocation.latitude + step, simulatedLocation.longitude);
      } else if (direction == "DOWN") {
        simulatedLocation = LatLng(
            simulatedLocation.latitude - step, simulatedLocation.longitude);
      } else if (direction == "LEFT") {
        simulatedLocation = LatLng(
            simulatedLocation.latitude, simulatedLocation.longitude - step);
      } else if (direction == "RIGHT") {
        simulatedLocation = LatLng(
            simulatedLocation.latitude, simulatedLocation.longitude + step);
      }
      _updateMarker();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer(); // Open the drawer
                },
              ),
            ),
          ),
          drawer: Drawer(
            child: Stack(
              children: [
                // Gradient Background Image
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/animations/gradient10.jpg"), // Ensure this image exists in assets
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Drawer Content
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Solid Black "Menu" Section with Profile Image
                    DrawerHeader(
                      decoration: BoxDecoration(color: Colors.black),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage("assets/animations/profile.jpg"), // Ensure this image exists
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Menu',
                            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // Animated Buttons with Rounded Containers
                    FadeInLeft(
                      duration: Duration(milliseconds: 500),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.map, color: Colors.white),
                            title: Text('Map', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                    ),

                    FadeInLeft(
                      duration: Duration(milliseconds: 600),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.group, color: Colors.white),
                            title: Text('Groups', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            onTap: () {
                              if (userRole == 'teacher') {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => GroupPage()));
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => StudentPage()));
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    FadeInLeft(
                      duration: Duration(milliseconds: 700),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.person, color: Colors.white),
                            title: Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
                            },
                          ),
                        ),
                      ),
                    ),

                    if (userRole == 'teacher')
                      FadeInLeft(
                        duration: Duration(milliseconds: 800),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.add_location_alt, color: Colors.white),
                              title: Text('Create Geofence', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              onTap: () {
                                Navigator.pop(context);
                                Future.delayed(Duration(milliseconds: 300), () {
                                  _showGeofenceBottomSheet(context);
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: initialCameraPosition,
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                  mapController!.setMapStyle(_customMapStyle);
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
                compassEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                circles: geofenceCircles, // Display geofences
                markers: markers,
              ),

              Positioned(
                bottom: 90, // Adjusted position for better spacing
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => moveMarker("UP"),
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(22), // Spacious and rounded
                        backgroundColor: Color(0xFFF5F5F5), // Light grey for elegance
                        shadowColor: Colors.black.withOpacity(0.1),
                        elevation: 6, // Soft shadow effect
                      ),
                      child: Text("UP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF3F0071))),
                    ),
                    SizedBox(height: 15), // Increased spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => moveMarker("LEFT"),
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(22),
                            backgroundColor: Color(0xFFF5F5F5),
                            shadowColor: Colors.black.withOpacity(0.1),
                            elevation: 6,
                          ),
                          child: Text("LEFT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF610094))),
                        ),
                        SizedBox(width: 50), // **More spacing between buttons**
                        ElevatedButton(
                          onPressed: () => moveMarker("RIGHT"),
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(22),
                            backgroundColor: Color(0xFFF5F5F5),
                            shadowColor: Colors.black.withOpacity(0.1),
                            elevation: 6,
                          ),
                          child: Text("RIGHT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF610094))),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () => moveMarker("DOWN"),
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(22),
                        backgroundColor: Color(0xFFF5F5F5),
                        shadowColor: Colors.black.withOpacity(0.1),
                        elevation: 6,
                      ),
                      child: Text("DOWN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF150050))),
                    ),
                  ],
                ),
              )



            ],
          ),
        );
      },
    );
  }

  void _showGeofenceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: initialCameraPosition,
                      onMapCreated: (GoogleMapController controller) {
                        mapController = controller;
                      },
                      onTap: (LatLng tappedPoint) {
                        setState(() {
                          selectedLocation = tappedPoint;
                          geofenceCircles = {
                            Circle(
                              circleId: CircleId(tappedPoint.toString()),
                              center: tappedPoint,
                              radius: geofenceRadius,
                              fillColor: Colors.blue.withOpacity(0.5),
                              strokeColor: Colors.blue,
                              strokeWidth: 2,
                            ),
                          };
                        });
                      },
                      circles: geofenceCircles,
                      myLocationEnabled: true,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Adjust Geofence Radius'),
                        Slider(
                          value: geofenceRadius,
                          min: 50,
                          max: 500,
                          divisions: 9,
                          label: '${geofenceRadius.round()} meters',
                          onChanged: (value) {
                            setState(() {
                              geofenceRadius = value;
                              if (selectedLocation != null) {
                                geofenceCircles = {
                                  Circle(
                                    circleId:
                                    CircleId(selectedLocation.toString()),
                                    center: selectedLocation!,
                                    radius: geofenceRadius,
                                    fillColor: Colors.blue.withOpacity(0.5),
                                    strokeColor: Colors.blue,
                                    strokeWidth: 2,
                                  ),
                                };
                              }
                            });
                          },
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (selectedLocation != null) {
                              // Delete old geofence data before saving the new one
                              await Backend.deleteOldGeofenceFromFirebase(
                                  "groupId123"); // Replace with actual group ID
                              await Backend.saveGeofenceToFirebase(
                                  selectedLocation!,
                                  geofenceRadius,
                                  "groupId123"); // Replace with actual group ID
                              _loadGeofencesForGroup(
                                  "groupId123"); // Reload geofences after saving
                              Navigator.pop(context);
                            }
                          },
                          child: Text('Confirm Geofence'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}