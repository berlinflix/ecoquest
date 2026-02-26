import 'package:flutter/material.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart'; // Typically needed for SMapWorld if not auto-exported

class InteractivePollutionMap extends StatefulWidget {
  const InteractivePollutionMap({Key? key}) : super(key: key);

  @override
  State<InteractivePollutionMap> createState() => _InteractivePollutionMapState();
}

class _InteractivePollutionMapState extends State<InteractivePollutionMap> {
  final Map<String, int> wasteData = {
    'AL': 37, 'DZ': 74, 'AO': 2, 'AI': 2, 'AG': 1, 'AR': 102, 'AU': 16,
    'AZ': 11, 'BD': 23, 'BB': 1, 'BZ': 4, 'BJ': 2, 'BO': 7, 'BW': 1,
    'BR': 158, 'BN': 4, 'KH': 37, 'CM': 4, 'KY': 1, 'TD': 1, 'CL': 1,
    'CN': 415, 'CO': 14, 'CR': 3, 'HR': 20, 'CU': 14, 'CY': 2, 'CI': 8,
    'CD': 1, 'DJ': 2, 'DM': 1, 'DO': 64, 'EC': 14, 'EG': 19, 'SV': 11,
    'ET': 2, 'FR': 13, 'GA': 2, 'DE': 33, 'GH': 66, 'GR': 20, 'GD': 1,
    'GT': 53, 'GN': 1, 'GY': 3, 'HT': 8, 'HN': 57, 'IN': 690, 'ID': 373,
    'IR': 8, 'IQ': 1, 'IL': 3, 'IT': 11, 'JM': 8, 'JP': 58, 'JO': 1,
    'KE': 15, 'LA': 17, 'LR': 1, 'MK': 5, 'MY': 103, 'ML': 7, 'MX': 221,
    'ME': 1, 'MA': 54, 'MZ': 2, 'MM': 49, 'NR': 1, 'NP': 5, 'NC': 1,
    'NZ': 1, 'NI': 48, 'NG': 116, 'PA': 28, 'PG': 2, 'PY': 2, 'PE': 23,
    'PH': 190, 'PT': 11, 'PR': 2, 'CG': 1, 'KR': 4, 'LC': 1, 'VC': 3,
    'SA': 2, 'SN': 1, 'SL': 1, 'SG': 4, 'SO': 1, 'ZA': 26, 'ES': 18,
    'LK': 28, 'SD': 2, 'SR': 1, 'SY': 1, 'TW': 46, 'TZ': 10, 'TH': 158,
    'TL': 1, 'TG': 7, 'TT': 4, 'TN': 3, 'TR': 73, 'UG': 1, 'US': 71,
    'VI': 1, 'UY': 16, 'VU': 1, 'VE': 50, 'VN': 198, 'YE': 7, 'ZW': 2
  };

  String selectedCountryName = "SCANNING PLANET...";
  String selectedWasteCount = "Tap a region to analyze.";
  Color panelColor = Colors.grey.shade900;

  Map<String, Color> _generateMapColors() {
    Map<String, Color> colors = {};
    wasteData.forEach((countryCode, siteCount) {
      Color c = Colors.grey.shade300;
      if (siteCount >= 200) {
        c = Colors.redAccent;
      } else if (siteCount >= 50) {
        c = Colors.orangeAccent;
      } else if (siteCount > 0) {
        c = Colors.yellowAccent;
      }
      colors[countryCode.toLowerCase()] = c;
      colors[countryCode.toUpperCase()] = c;
    });
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        title: const Text('GLOBAL THREAT RADAR', style: TextStyle(color: Color(0xFF0A192F), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF25F4AF)),
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(color: panelColor),
            child: Column(
              children: [
                Text(selectedCountryName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(selectedWasteCount, style: const TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 1.0, 
              maxScale: 5.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SimpleMap(
                  instructions: SMapWorld.instructions,
                  defaultColor: Colors.grey.shade300,
                  colors: _generateMapColors(),
                  callback: (id, name, tapDetails) {
                    setState(() {
                      selectedCountryName = name;
                      String upperId = id.toUpperCase();
                      if (wasteData.containsKey(upperId)) {
                        int count = wasteData[upperId]!;
                        selectedWasteCount = "$count DETECTED WASTE SITES";
                        if (count >= 200) {
                          panelColor = Colors.red.shade900;
                        } else if (count >= 50) {
                          panelColor = Colors.orange.shade900;
                        } else {
                          panelColor = Colors.yellow.shade900;
                        }
                      } else {
                        selectedWasteCount = "0 DETECTED WASTE SITES";
                        panelColor = Colors.grey.shade900;
                      }
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
