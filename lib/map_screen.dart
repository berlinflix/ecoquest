import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:google_fonts/google_fonts.dart';

class InteractivePollutionMap extends StatefulWidget {
  const InteractivePollutionMap({super.key});

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

  final Color bgColor = const Color(0xFFE5D9C5);
  final Color primaryBlue = const Color(0xFF38BDF8);
  final Color mapBgColor = const Color(0xFFC4B69D);

  Map<String, Color> _generateMapColors() {
    Map<String, Color> colors = {};
    wasteData.forEach((countryCode, siteCount) {
      Color c = mapBgColor;
      if (siteCount >= 200) {
        c = Colors.red.shade500;
      } else if (siteCount >= 50) {
        c = Colors.orange.shade500;
      } else if (siteCount > 0) {
        c = Colors.yellow.shade500;
      }
      colors[countryCode.toLowerCase()] = c;
      colors[countryCode.toUpperCase()] = c;
    });
    return colors;
  }

  String _getFlagEmoji(String countryCode) {
    if (countryCode.length != 2) return "🗺️";
    int offset = 127397;
    int firstChar = countryCode.codeUnitAt(0) + offset;
    int secondChar = countryCode.codeUnitAt(1) + offset;
    return String.fromCharCode(firstChar) + String.fromCharCode(secondChar);
  }

  void _showCountryDetails(BuildContext context, String id, String name) {
    String upperId = id.toUpperCase();
    int count = wasteData.containsKey(upperId) ? wasteData[upperId]! : 0;
    
    String threatLevel = "LOW";
    Color threatColor = Colors.amber.shade600;
    Color threatBg = Colors.amber.shade50.withValues(alpha: 0.5);
    Color threatBorder = Colors.amber.shade200.withValues(alpha: 0.5);
    IconData threatIcon = Icons.info_outline;

    if (count >= 200) {
      threatLevel = "CRITICAL";
      threatColor = Colors.red.shade600;
      threatBg = Colors.red.shade50.withValues(alpha: 0.5);
      threatBorder = Colors.red.shade200.withValues(alpha: 0.5);
      threatIcon = Icons.warning_rounded;
    } else if (count >= 50) {
      threatLevel = "ELEVATED";
      threatColor = Colors.orange.shade600;
      threatBg = Colors.orange.shade50.withValues(alpha: 0.5);
      threatBorder = Colors.orange.shade200.withValues(alpha: 0.5);
      threatIcon = Icons.warning_rounded;
    } else if (count > 0) {
      threatLevel = "STABLE";
      threatColor = Colors.yellow.shade700;
      threatBg = Colors.yellow.shade50.withValues(alpha: 0.5);
      threatBorder = Colors.yellow.shade200.withValues(alpha: 0.5);
      threatIcon = Icons.info_outline;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                spreadRadius: 0,
              )
            ]
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top drag handle
                    Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Header Area
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _getFlagEmoji(upperId),
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueGrey.shade900,
                              height: 1.1,
                            ),
                          ),
                        ),
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: Colors.blueGrey.shade400, size: 16),
                            padding: EdgeInsets.zero,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Stat Cards
                    Row(
                      children: [
                        // Left Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade200.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "WASTE SITES",
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.blue.shade500,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  count.toString(),
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 24,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: threatBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: threatBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "SECTOR THREAT",
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.amber.shade500,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        threatLevel,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: threatColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      threatIcon,
                                      color: threatColor,
                                      size: 14,
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.blueGrey.shade700),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        "WASTE WATCHER",
                        style: GoogleFonts.pressStart2p(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "SATELLITE DATA",
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.radar, color: Colors.white, size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            
            // Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.9),
                border: Border.symmetric(horizontal: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "LINK: STABLE",
                    style: GoogleFonts.pressStart2p(
                      fontSize: 7,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "415",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "SITES",
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Map Area
            Expanded(
              child: InteractiveViewer(
                minScale: 1.0, 
                maxScale: 5.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SimpleMap(
                    instructions: SMapWorld.instructions,
                    defaultColor: mapBgColor,
                    colors: _generateMapColors(),
                    callback: (id, name, tapDetails) {
                      _showCountryDetails(context, id, name);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
