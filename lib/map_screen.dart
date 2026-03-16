import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InteractivePollutionMap extends StatefulWidget {
  const InteractivePollutionMap({super.key});

  @override
  State<InteractivePollutionMap> createState() => _InteractivePollutionMapState();
}

class _InteractivePollutionMapState extends State<InteractivePollutionMap> {
  MapboxMap? mapboxMap;
  bool _isLoading = true;
  String? _errorMessage;
  String? _gpwApiKey;
  String? _mapboxApiKey;

  @override
  void initState() {
    super.initState();
    _fetchApiKeys();
  }

  Future<void> _fetchApiKeys() async {
    try {
      final configDoc = await FirebaseFirestore.instance
          .collection('config')
          .doc('api_keys')
          .get();

      if (configDoc.exists) {
        final apiKey = configDoc.data()?['maps_api_key'] as String?;
        final gpwKey = configDoc.data()?['gpw_api_key'] as String?;

        if (apiKey != null && apiKey.isNotEmpty && gpwKey != null && gpwKey.isNotEmpty) {
          final trimmedKey = apiKey.trim();
          print('Loaded token length: ${trimmedKey.length}, starts with: ${trimmedKey.substring(0, 3)}');
          
          MapboxOptions.setAccessToken(trimmedKey);

          setState(() {
            _mapboxApiKey = trimmedKey;
            _gpwApiKey = gpwKey.trim();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'One or both API Keys are empty in Firestore.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Mapbox API Key document not found in Firestore.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching API key: $e';
        _isLoading = false;
      });
    }
  }

  void _showSiteDetails(Map<String, dynamic> props) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final entries = props.entries.toList();
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                props['name']?.toString() ?? props['location']?.toString() ?? 'Waste Site Details',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${e.key}',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${e.value}',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onMapTap(MapContentGestureContext context) async {
    if (mapboxMap == null) return;

    try {
      final features = await mapboxMap!.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenBox(
          ScreenBox(
            min: ScreenCoordinate(
              x: context.touchPosition.x - 30, // Padding for taps
              y: context.touchPosition.y - 30,
            ),
            max: ScreenCoordinate(
              x: context.touchPosition.x + 30,
              y: context.touchPosition.y + 30,
            ),
          )
        ),
        RenderedQueryOptions(
          layerIds: ['plastic-sites-layer-unclustered-inner', 'plastic-sites-layer-unclustered-outer'],
          filter: null,
        ),
      );

      if (features.isNotEmpty) {
        final feature = features.first;
        if (feature != null && feature.queriedFeature.feature.containsKey('properties')) {
          final props = feature.queriedFeature.feature['properties'] as Map<dynamic, dynamic>?;
          if (props != null) {
            _showSiteDetails(props.cast<String, dynamic>());
          }
        }
      }
    } catch (e) {
      print("Error handling map tap: $e");
    }
  }

  Future<void> _fetchAndPlotPlasticData() async {
    if (mapboxMap == null || _gpwApiKey == null || _gpwApiKey!.isEmpty) {
      print("Cannot fetch GPW data: Missing API key or map is null.");
      return;
    }

    try {
      final response = await http.get(Uri.parse('https://api.globalplasticwatch.org/sites?apikey=$_gpwApiKey&limit=10000'));
      
      if (response.statusCode == 200) {
        final geoJsonData = response.body;

        try {
          // Add the GeoJson source with clustering enabled
          await mapboxMap!.style.addSource(GeoJsonSource(
            id: 'gpw-data',
            data: geoJsonData,
            cluster: true,
            clusterRadius: 50.0,
            clusterMaxZoom: 14.0,
          ));

          // Layer A: Cluster Circles
          await mapboxMap!.style.addLayer(CircleLayer(
            id: 'plastic-sites-layer-clustered',
            sourceId: 'gpw-data',
            circleColor: const Color(0xFFFFCC00).value,
            circleRadius: 18.0,
            circleOpacity: 0.7,
            circleStrokeWidth: 1.0,
            circleStrokeColor: Colors.black.value,
            filter: ['has', 'point_count'],
          ));
          
          // Layer B: Cluster Text
          await mapboxMap!.style.addLayer(SymbolLayer(
            id: 'plastic-sites-layer-count',
            sourceId: 'gpw-data',
            textField: '{point_count}',
            textSize: 12.0,
            textColor: Colors.black.value,
            textAllowOverlap: true,
            filter: ['has', 'point_count'],
          ));

          // Layer C: Unclustered Outer Ring
          await mapboxMap!.style.addLayer(CircleLayer(
            id: 'plastic-sites-layer-unclustered-outer',
            sourceId: 'gpw-data',
            circleColor: Colors.transparent.value,
            circleRadius: 8.0,
            circleStrokeWidth: 2.0,
            circleStrokeColor: const Color(0xFFFFCC00).value,
            circleStrokeOpacity: 0.8,
            filter: ['!', ['has', 'point_count']],
          ));

          // Layer D: Unclustered Inner Dot
          await mapboxMap!.style.addLayer(CircleLayer(
            id: 'plastic-sites-layer-unclustered-inner',
            sourceId: 'gpw-data',
            circleColor: const Color(0xFFFFCC00).value,
            circleRadius: 3.0,
            circleOpacity: 1.0,
            circleStrokeWidth: 0.0,
            filter: ['!', ['has', 'point_count']],
          ));
          
          print("GPW data loaded and plotted successfully.");
        } catch (layerError) {
          print("Error adding GeoJSON source or layer: $layerError");
        }
      } else {
        print("Failed to load GPW data: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error fetching GPW data: $e");
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    
    // Fix Mapbox built-in UI elements getting clipped by placing them normally now that we don't extend behind the appbar
    mapboxMap.compass.updateSettings(CompassSettings(marginTop: 16.0, marginRight: 16.0));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(marginTop: 16.0, marginLeft: 16.0));
    mapboxMap.logo.updateSettings(LogoSettings(marginBottom: 16.0, marginLeft: 16.0));
    mapboxMap.attribution.updateSettings(AttributionSettings(marginBottom: 16.0, marginRight: 16.0));

    // Enable the location component to show the user's location puck
    mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        puckBearingEnabled: true,
        showAccuracyRing: true,
      ),
    );
  }

  void _onStyleLoaded(StyleLoadedEventData data) async {
    try {
      await mapboxMap?.style.setProjection(StyleProjection(name: StyleProjectionName.globe));
    } catch(e) {
      print("Error setting projection: $e");
    }
    _fetchAndPlotPlasticData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E), // sleek dark theme background
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'GLOBAL ',
                    style: GoogleFonts.anton(
                      color: Colors.white,
                      fontSize: 26,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: 'PLASTIC',
                    style: GoogleFonts.anton(
                      color: const Color(0xFFFFCC00),
                      fontSize: 26,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'WASTE SITES',
              style: GoogleFonts.bebasNeue(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E), // Solid dark background for Appbar
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MapWidget(
          key: const ValueKey("mapWidget"),
          cameraOptions: CameraOptions(
            zoom: 1.0,
            center: Point(coordinates: Position(78.96, 20.59)),
          ),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          onMapLoadErrorListener: (data) {
            print("Map Load Error: ${data.message}");
          },
          onTapListener: _onMapTap,
          styleUri: MapboxStyles.DARK, // sleek modern UI matching GPW
        ),
    );
  }
}
