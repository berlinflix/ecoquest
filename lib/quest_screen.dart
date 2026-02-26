import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:math' as math;
import 'quest_state.dart';

const Color primaryBlue = Color(0xFF0d93f2);
const Color bgLight = Color(0xFFf5f7f8);

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isVerifying = false;
  final QuestState _questState = QuestState();

  @override
  void initState() {
    super.initState();
    _questState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _questState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> captureImage(bool isBefore) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, spreadRadius: 5)
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ListTile(
                    leading: const Icon(Icons.camera_alt, color: primaryBlue),
                    title: const Text('Take Photo', style: TextStyle(color: Color(0xFF101b22), fontWeight: FontWeight.bold)),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: const Icon(Icons.photo_library, color: primaryBlue),
                    title: const Text('Upload from Gallery (Testing)', style: TextStyle(color: Color(0xFF101b22), fontWeight: FontWeight.bold)),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? photo = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (photo != null) {
      if (isBefore) {
        _showTimeSelectionDialog(File(photo.path));
      } else {
        _questState.setAfterImage(File(photo.path));
      }
    }
  }

  void _showTimeSelectionDialog(File image) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.spaceBetween,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('TARGET LOCKED', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(image, height: 160, fit: BoxFit.cover)),
            const SizedBox(height: 20),
            const Text('How much time do you need to clean this area?', style: TextStyle(color: Color(0xFF101b22))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              captureImage(true);
            },
            child: const Text('RETAKE', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _questState.startQuest(image, 15);
                },
                child: const Text('15 MIN', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _questState.startQuest(image, 30);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text('30 MIN', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // AI VERIFICATION using Gemini 1.5 Flash (Kept Intact)
  Future<void> verifyWithAI() async {
    if (_questState.beforeImage == null || _questState.afterImage == null) return;

    setState(() => _isVerifying = true);

    try {
      const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_API_KEY');
      if (apiKey == 'YOUR_API_KEY') {
        debugPrint('WARNING: Please set your Gemini API key');
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final beforeBytes = await _questState.beforeImage!.readAsBytes();
      final afterBytes = await _questState.afterImage!.readAsBytes();

      final prompt = TextPart(
          'Analyze these two images. The first image is the "before" state of an area, and the second image is the "after" state. '
          'Verify if the trash in the "before" image was cleaned up in the "after" image. '
          'You must output strictly either "1" (yes, it is clean) or "0" (no, it is not clean). Do not output any other text.');
      
      final imageParts = [
        DataPart('image/jpeg', beforeBytes),
        DataPart('image/jpeg', afterBytes),
      ];

      final response = await model.generateContent([
        Content.multi([...imageParts, prompt])
      ]);

      final text = response.text?.trim() ?? '0';

      setState(() => _isVerifying = false);
      
      if (text == '1') {
        if (mounted) {
          _showResultDialog(true, 'QUEST CLEARED!', 'AI verified the location is clean. +50 EXP added to your profile!', const Color(0xFF4CAF50));
        }
      } else {
        if (mounted) {
           _showResultDialog(false, 'QUEST FAILED', 'AI detected that the trash was not properly cleaned. Try again!', Colors.orangeAccent);
        }
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    }
  }

  void _showResultDialog(bool success, String title, String message, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        content: Text(message, style: const TextStyle(color: Color(0xFF101b22))),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.of(context).pop();
              if (success) {
                _questState.clearQuest();
                Navigator.of(context).pop();
              } else {
                _questState.setAfterImage(File('')); 
                _questState.afterImage = null; 
              }
            },
            child: Text(success ? 'COLLECT REWARD' : 'RETRY POST-CLEANUP', style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: bgLight,
          image: DecorationImage(
             image: const CachedNetworkImageProvider('https://lh3.googleusercontent.com/aida-public/AB6AXuCtzKhniqWljsh4GjuJlikuzrEvoffL3SJh3QWErjHv4cWxgf4dlbkjBb1p-MLFMAmylwi7pFW5a3aZkQLR7O5Fj5l1y2DdpeX0sP1E1xF3zzzoNY-czRxVQlIm-YpwwC5eiFAnqm3oR-kYu0Jm_5XJ35LBQ-4fSenmnBpIB7v6X5-2ddyXJfZI_s9sb83_AaYY7FmHulfx_CVdn_izr3IBnDoJIJfDSRQ6p-STwGT8D6HuA4NK--BOfNmIXawefCXb3MKSi18iyPs'),
             fit: BoxFit.cover,
             colorFilter: ColorFilter.mode(bgLight.withOpacity(0.9), BlendMode.lighten),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 150),
                        child: Column(
                          children: [
                            if (_isVerifying)
                               _buildLoader()
                            else ...[
                              _buildBeforeSection(),
                              const SizedBox(height: 32),
                              if (_questState.isActive) ...[
                                _buildAfterSection(),
                                const SizedBox(height: 48),
                                // NEW RESET BUTTON
                                TextButton.icon(
                                  onPressed: () {
                                     _questState.clearQuest();
                                     ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Quest Aborted. Images cleared.'))
                                     );
                                  },
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                                  label: const Text('ABORT QUEST & START OVER', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                ),
                              ]
                            ]
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_questState.isActive && !_isVerifying)
                Positioned(
                  top: 80, right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(_formatTime(_questState.remainingSeconds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              _buildBottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
              child: const Icon(Icons.arrow_back, color: Color(0xFF101b22)),
            ),
          ),
          const Column(
            children: [
              Text('Active Mission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF101b22))),
              Text('BEACH CLEAN-UP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryBlue, letterSpacing: 2)),
            ],
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
            child: const Icon(Icons.info_outline, color: Color(0xFF101b22)),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeSection() {
    final image = _questState.beforeImage;
    if (image == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.camera_alt_outlined, size: 80, color: primaryBlue),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => captureImage(true),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Open Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Transform.rotate(
          angle: -0.05, // -2 degrees
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            decoration: BoxDecoration(color: Colors.white, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))]),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                     colorFilter: const ColorFilter.matrix([
                        0.33, 0.33, 0.33, 0, 0,
                        0.33, 0.33, 0.33, 0, 0,
                        0.33, 0.33, 0.33, 0, 0,
                        0, 0, 0, 1, 0,
                     ]),
                    child: Image.file(image, fit: BoxFit.cover)
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                      child: const Text('BEFORE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!_questState.isActive) ...[
          const SizedBox(height: 24),
           ElevatedButton.icon(
            onPressed: () => captureImage(true),
            icon: const Icon(Icons.refresh),
            label: const Text('Retake Before'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: primaryBlue.withOpacity(0.2), width: 2)),
              elevation: 0,
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildAfterSection() {
    final image = _questState.afterImage;
    return Column(
      children: [
        Transform.rotate(
          angle: 0.02, // 1 degree
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            decoration: BoxDecoration(color: Colors.white, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))]),
            child: AspectRatio(
              aspectRatio: 1,
              child: image == null
                ? Container(
                    decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade200, width: 2, style: BorderStyle.none)), // Fake dashed border via CustomPainter or simple border
                    child: Stack(
                      children: [
                        Positioned.fill(
                             child: DecoratedBox(
                                 decoration: BoxDecoration(
                                     border: Border.all(color: Colors.grey.shade300, width: 2)
                                 ),
                             )
                         ),
                         Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                             Icon(Icons.image, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text('Waiting for impact', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          ],
                        ),
                        Positioned(
                          top: 8, left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
                            child: const Text('AFTER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(image, fit: BoxFit.cover),
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: primaryBlue.withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
                          child: const Text('AFTER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (image == null)
          ElevatedButton.icon(
            onPressed: () => captureImage(false),
            icon: const Icon(Icons.upload),
            label: const Text('Upload Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: primaryBlue.withOpacity(0.2), width: 2)),
              elevation: 0,
            ),
          )
        else
           Column(
             children: [
               ElevatedButton.icon(
                  onPressed: verifyWithAI,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('VERIFY CLEANUP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                  ),
                ),
               TextButton(
                 onPressed: () => captureImage(false),
                 child: const Text('Retake Upload', style: TextStyle(color: Colors.grey)),
               ),
             ],
           )
      ],
    );
  }
  
   Widget _buildLoader() {
      return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120, height: 120,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                    strokeWidth: 6,
                    backgroundColor: primaryBlue.withOpacity(0.1),
                  ),
                ),
                const Icon(Icons.auto_awesome, size: 50, color: primaryBlue),
              ],
            ),
            const SizedBox(height: 40),
            const Text('AI IS ANALYZING...', 
              style: TextStyle(color: primaryBlue, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            const Text('Determining environmental impact.', style: TextStyle(color: Colors.grey)),
          ],
      );
  }

  Widget _buildBottomNavBar() {
    return Positioned(
      bottom: 16, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavIcon(Icons.track_changes, 'Missions', isActive: true),
            _buildNavIcon(Icons.map_outlined, 'Map'),
            GestureDetector(
              onTap: () {
                // If quest is active, upload AFTER photo. If not, capture BEFORE photo.
                captureImage(!_questState.isActive); 
              },
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                   width: 56, height: 56,
                   decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle, border: Border.all(color: bgLight, width: 4), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                   child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
            _buildNavIcon(Icons.emoji_events_outlined, 'Rank'),
            _buildNavIcon(Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? primaryBlue : Colors.grey.shade400, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? primaryBlue : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}