import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class LocationPickerDialog extends StatefulWidget {
  final LatLng initialLocation;

  const LocationPickerDialog({super.key, required this.initialLocation});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  late LatLng _currentLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    // Delay slightly so the dialog builds before the permission prompt blocks the UI thread.
    Future.microtask(() => _getCurrentLocation());
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permission denied');
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      Position? position = await Geolocator.getLastKnownPosition();
      
      // Try to get fresh position, fallback to last known if it takes too long
      try {
         position = await Geolocator.getCurrentPosition(
           desiredAccuracy: LocationAccuracy.medium,
           timeLimit: const Duration(seconds: 5),
         );
      } catch (e) {
         debugPrint("Could not get fresh position, using last known if available: $e");
      }

      if (position != null) {
        if (mounted) {
          setState(() {
             _currentLocation = LatLng(position!.latitude, position.longitude);
          });
          _mapController.move(_currentLocation, 14.0);
        }
      } else {
         throw Exception('Could not determine location. Ensure your GPS is on.');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Iterable<Map<String, dynamic>>> _searchNominatim(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5'),
        headers: {'User-Agent': 'EcoQuestApp/1.0'}
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) => {
          'display_name': item['display_name'],
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
        }).toList();
      }
    } catch (e) {
      debugPrint('Autocomplete search error: $e');
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 16, bottom: 16),
              color: const Color(0xFF0A192F),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Pick Mission Location', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.search, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Autocomplete<Map<String, dynamic>>(
                        optionsBuilder: (TextEditingValue textEditingValue) async {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Map<String, dynamic>>.empty();
                          }
                          return await _searchNominatim(textEditingValue.text);
                        },
                        displayStringForOption: (option) => option['display_name'] as String,
                        onSelected: (option) {
                           setState(() {
                             _currentLocation = LatLng(option['lat'] as double, option['lon'] as double);
                           });
                           _mapController.move(_currentLocation, 14.0);
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(hintText: 'Search city or place...', border: InputBorder.none),
                          );
                        },
                      ),
                    ),
                    if (_isLoading) const Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                    IconButton(
                        icon: const Icon(Icons.my_location, color: Color(0xFF38BDF8)),
                        onPressed: _getCurrentLocation,
                    ),
                  ],
                ),
              ),
            ),

            // Map Area
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 13.0,
                      onTap: (tapPosition, point) => setState(() => _currentLocation = point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.ecoquest',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation,
                            width: 60, height: 60,
                            child: const Icon(Icons.location_on, color: Color(0xFFE11D48), size: 50),
                          )
                        ],
                      )
                    ],
                  ),
                  Positioned(
                    top: 12, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                         child: const Text('Tap map to move pin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _currentLocation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DD4BF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    elevation: 4,
                  ),
                  child: Text('CONFIRM LOCATION', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
