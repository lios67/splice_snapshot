import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

// Main app widget defining the app's theme and home page
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slpice Snapshot App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 255, 242)),
        textTheme: GoogleFonts.poppinsTextTheme(),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Reduced vertical padding
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          filled: true,
          fillColor: Color(0xFFF5F7FA),
        ),
      ),
      home: VideoFrameHomePage(), // Sets the home screen
    );
  }
}

class VideoFrameHomePage extends StatefulWidget {
  const VideoFrameHomePage({super.key});

  @override
  State<VideoFrameHomePage> createState() => _VideoFrameHomePageState();
}

// State class managing the app's logic and UI
class _VideoFrameHomePageState extends State<VideoFrameHomePage> {
  File? _videoFile; // Stores the selected video file
  List<String> _framePaths = []; // List of paths to extracted frame images
  String? _selectedFrame; // Path of the currently selected frame
  bool _isProcessing = false; // Tracks if frame extraction is in progress
  String _currentFramePrefix = ''; // Unique prefix for frame file names
  final TextEditingController _intervalController = TextEditingController(text: '1'); // Controls frame extraction interval input
  final FocusNode _focusNode = FocusNode(); // Manages keyboard focus for navigation
  final ScrollController _scrollController = ScrollController(); // Controls horizontal scrolling of thumbnails

  // Picks a video file from the desktop file system
  Future<void> _pickVideo() async {
    if (kDebugMode) {
      print('Picking video...');
    }
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null) {
      if (kDebugMode) {
        print('Video selected: ${result.files.single.path}');
      }
      _currentFramePrefix = 'frame_${DateTime.now().millisecondsSinceEpoch}_'; // Unique prefix based on timestamp
      await _clearPreviousFrames();  // Clears old frames before new extraction
      setState(() {
        _videoFile = File(result.files.single.path!);
        _framePaths = [];
        _selectedFrame = null;
      });
      await _extractFrames();
    } else {
      if (kDebugMode) {
        print('No video selected');
      }
    }
  }

  // Clear the frames from the previous video
  Future<void> _clearPreviousFrames() async {  
    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(tempDir.path);
      if (await dir.exists()) {
        await for (var entity in dir.list()) {
          if (entity is File && entity.path.endsWith('.png') && entity.path.contains('frame_')) {
            await entity.delete();
            if (kDebugMode) {
              print('Deleted previous frame: ${entity.path}');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing previous frames: $e');
      }
    }
  }

  // Gets the duration of the selected video using ffprobe
  Future<double?> _getVideoDuration(String videoPath) async {
    try {
      final ffprobePath = Platform.isWindows 
          ? '${Directory.current.path}\\bin\\ffprobe.exe' 
          : '${Directory.current.path}/ffprobe';
      final result = await Process.run(ffprobePath, [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'default=noprint_wrappers=1:nokey=1',
        videoPath,
      ]);

      if (result.exitCode == 0) {
        final duration = double.tryParse(result.stdout.toString().trim());
        if (kDebugMode) {
          print('Video duration: $duration seconds');
        }
        return duration;
      } else {
        if (kDebugMode) {
          print('ffprobe error: ${result.stderr}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception getting video duration: $e');
      }
      return null;
    }
  }

  // Extracts frames from the video using ffmpeg based on the interval
  Future<void> _extractFrames() async {
    if (_videoFile == null) return;

    setState(() => _isProcessing = true); // Shows loading indicator

    await _clearPreviousFrames();
    setState(() {
      _framePaths = [];
      _selectedFrame = null; // Clears previous frames from UI
    });

    final tempDir = await getTemporaryDirectory();
    final outputPattern = '${tempDir.path}${Platform.pathSeparator}$_currentFramePrefix%03d.png'; // Output pattern for frame files
    double interval = double.tryParse(_intervalController.text) ?? 1.0; 
    if (interval <= 0) interval = 1.0; // Ensures a valid interval
    final fps = 1 / interval;// Frames per second based on interval

    final duration = await _getVideoDuration(_videoFile!.path);
    if (duration == null) {
      setState(() => _isProcessing = false);
      return;
    }
    final ffmpegPath = Platform.isWindows 
        ? '${Directory.current.path}\\bin\\ffmpeg.exe' 
        : '${Directory.current.path}/ffmpeg';
    final arguments = ['-i', _videoFile!.path, '-vf', 'fps=$fps', '-y', outputPattern];

    try {
      final result = await Process.run(ffmpegPath, arguments);
      if (result.exitCode == 0) {
        List<String> tempFramePaths = [];
        final expectedFrameCount = (duration / interval).ceil();
        for (int i = 1; i <= expectedFrameCount; i++) {
          final framePath = '${tempDir.path}${Platform.pathSeparator}$_currentFramePrefix${i.toString().padLeft(3, '0')}.png';
          if (await File(framePath).exists()) {
            tempFramePaths.add(framePath);
          } else {
            break; // Stops if a frame is missing
          }
        }
        setState(() {
          _framePaths = tempFramePaths;
          _selectedFrame = _framePaths.isNotEmpty ? _framePaths[0] : null; // Selects first frame by default
          _isProcessing = false;
        });
        _scrollToSelectedFrame(); // Scrolls to the selected frame
      } else {
        if (kDebugMode) {
          print('FFmpeg error: ${result.stderr}');
        }
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception during FFmpeg execution: $e');
      }
      setState(() => _isProcessing = false);
    }
  }

  // Refreshes frame extraction with the current video and interval
  void _refreshFrames() {
    if (_videoFile != null && !_isProcessing) {
      _extractFrames();
    }
  }

  // Changes the selected frame using arrow keys or scroll
  void _changeFrame(int direction) {
    if (_framePaths.isEmpty || _selectedFrame == null) return;

    final currentIndex = _framePaths.indexOf(_selectedFrame!);
    final newIndex = currentIndex + direction;

    if (newIndex >= 0 && newIndex < _framePaths.length) {
      setState(() => _selectedFrame = _framePaths[newIndex]);
      _scrollToSelectedFrame();
    }
  }

  // Handles mouse scroll to navigate frames
  void _handleScroll(PointerScrollEvent event) {
    if (_framePaths.isEmpty || _selectedFrame == null) return;

    final currentIndex = _framePaths.indexOf(_selectedFrame!);
    int newIndex = event.scrollDelta.dy > 0 ? currentIndex + 1 : currentIndex - 1;

    if (newIndex >= 0 && newIndex < _framePaths.length) {
      setState(() => _selectedFrame = _framePaths[newIndex]);
      _scrollToSelectedFrame();
    }
  }

  // Scrolls the thumbnail strip to the selected frame
  void _scrollToSelectedFrame() {
    if (_selectedFrame == null || _framePaths.isEmpty) return;

    final index = _framePaths.indexOf(_selectedFrame!);
    const thumbnailWidth = 96.0; // Total width per thumbnail (image + padding + margin) 80px image + 8px padding + 8px margin
    final targetOffset = index * thumbnailWidth;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;
    final viewportWidth = _scrollController.position.viewportDimension;

    if (targetOffset < currentOffset || targetOffset > currentOffset + viewportWidth - thumbnailWidth) {
      double newOffset = targetOffset - (viewportWidth / 2) + (thumbnailWidth / 2);
      newOffset = newOffset.clamp(0.0, maxScrollExtent); // Keeps offset within bounds
      _scrollController.animateTo(
        newOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic, // Smooth scrolling animation
      );
    }
  }

  // Deletes a specific frame file and updates the UI
  void _deleteFrame(String framePath) async {
    try {
      final file = File(framePath);
      if (await file.exists()) {
        await file.delete();
      }

      setState(() {
        _framePaths.remove(framePath);
        if (_selectedFrame == framePath) {
          _selectedFrame = _framePaths.isNotEmpty ? _framePaths[0] : null; // Resets selection if deleted
        }
      });
      _scrollToSelectedFrame();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting frame: $e');
      }
    }
  }

  // Exports all frames to a ZIP file
  Future<String?> _exportFramesToZip() async {
    if (_framePaths.isEmpty) return 'No frames available to export';

    setState(() => _isProcessing = true);

    try {
      final archive = Archive();
      for (var framePath in _framePaths) {
        final file = File(framePath);
        if (await file.exists()) {
          final frameBytes = await file.readAsBytes();
          final fileName = framePath.split(Platform.pathSeparator).last;
          archive.addFile(ArchiveFile(fileName, frameBytes.length, frameBytes)); // Adds frame to archive
        }
      }

      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ZIP File',
        fileName: 'video_frames_${_currentFramePrefix}zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (outputPath != null) {
        if (!outputPath.endsWith('.zip')) outputPath += '.zip';
        final zipFile = File(outputPath);
        await zipFile.writeAsBytes(zipBytes);
        return 'Frames exported to $outputPath';
      }
      return null;
    } catch (e) {
      return 'Error exporting frames: $e';
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Triggers frame export and shows a snackbar with the result
  void _handleExportFrames() async {
    final result = await _exportFramesToZip();
    if (mounted && result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  // Calculates and formats the timestamp for each frame to hundredths precision
  String _getTimestamp(int index) {
    double interval = double.tryParse(_intervalController.text) ?? 1.0; // Gets interval from user input
    if (interval <= 0) interval = 1.0; // Ensures interval is positive
    final timeInSeconds = index * interval; // Time at this frame
    return '${timeInSeconds.toStringAsFixed(2)}s'; // Changed from 1 (Tens) to 2 (Hundreds) ... etc.
  }

  // Cleans up resources when the widget is disposed
  @override
  void dispose() {
    _intervalController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Builds the UI with controls, main display, and thumbnail strip
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Splice/Snapshot'),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        backgroundColor: colorScheme.surfaceContainer,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      body: Stack(
        children: [
          // Constrains the layout to fit within screen height minus AppBar
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height - kToolbarHeight, // Screen height minus AppBar
            ),
            child: Column(
              children: [
                // Control bar for interval input and actions
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Extract every ',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 18),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _intervalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Seconds',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      Text(
                        ' sec',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: _refreshFrames,
                        child: const Text('Refresh'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _isProcessing ? null : _handleExportFrames,
                        child: const Text('Export ZIP'),
                      ),
                    ],
                  ),
                ),
                // Main display area for the selected frame
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical margin
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: KeyboardListener(
                      focusNode: _focusNode,
                      onKeyEvent: (KeyEvent event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                            _changeFrame(1); // Next frame
                          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                            _changeFrame(-1); // Previous frame
                          }
                        }
                      },
                      child: Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            _handleScroll(pointerSignal); // Scroll wheel navigation
                          }
                        },
                        child: GestureDetector(
                          onTap: () => _focusNode.requestFocus(), // Focuses for keyboard input
                          child: Center(
                            child: _selectedFrame != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_selectedFrame!),
                                      fit: BoxFit.contain, // Displays selected frame
                                    ),
                                  )
                                : Text(
                                    'No video selected',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Thumbnail strip showing all extracted frames
                Container(
                  height: 110, // Reduced from 90
                  padding: const EdgeInsets.symmetric(vertical: 4.0), // Reduced from 8.0 all(4.0)
                  child: _framePaths.isNotEmpty
                      ? Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: colorScheme.surfaceContainer,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
                            child: Row(
                              children: _framePaths.asMap().entries.map((entry) {
                                final index = entry.key;
                                final framePath = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() => _selectedFrame = framePath);
                                              _scrollToSelectedFrame(); // Selects frame on click
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                border: _selectedFrame == framePath
                                                    ? Border.all(color: colorScheme.primary, width: 2)
                                                    : null,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.1),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.file(
                                                  File(framePath),
                                                  width: 80,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: -4,
                                            right: -4,
                                            child: GestureDetector(
                                              onTap: () => _deleteFrame(framePath), // Deletes frame on click
                                              child: CircleAvatar(
                                                radius: 10,
                                                backgroundColor: colorScheme.error.withValues(alpha: 0.9),
                                                child: Transform.translate(
                                                  offset: const Offset(-1, -1),
                                                  child: const Text(
                                                    '\u2212', // Minus sign for delete
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getTimestamp(index), // Displays timestamp below thumbnail
                                        style: TextStyle(
                                          fontSize: 12, 
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            'No frames available',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 18),
                          ),
                        ),
                ),
              ],
            ),
          ),
          // Loading overlay during processing
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ),
        ],
      ),
      // Button to pick a video file
      floatingActionButton: FloatingActionButton(
        onPressed: _isProcessing ? null : _pickVideo,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.video_library),
      ),
    );
  }
}
