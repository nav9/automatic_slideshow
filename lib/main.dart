import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  runApp(SlideshowApp());
}

class SlideshowApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automatic Slideshow',
      theme: ThemeData(primarySwatch: Colors.blue,),
      home: SlideshowHomePage(),
    );
  }
}

class SlideshowHomePage extends StatefulWidget {
  @override
  _SlideshowHomePageState createState() => _SlideshowHomePageState();
}

class _SlideshowHomePageState extends State<SlideshowHomePage> {
  final List supportedImageTypes = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
  int interval = 6;//seconds to pause at each image (can be overridden by user via GUI)
  List<String> imagePaths = [];
  String folderPath = "";
  late bool _isWakelockEnabled; // State variable for checkbox
  late bool _searchSubdirectories; //search subdirectories for images

  @override
  void initState() {
    super.initState();
    _searchSubdirectories = true;
    _isWakelockEnabled = true;
    if (_isWakelockEnabled) {WakelockPlus.enable();} else {WakelockPlus.disable();}
  }

  void _incrementInterval() {setState(() {interval++;});}

  void _decrementInterval() {setState(() {if (interval > 1) interval--;});}

  Future<void> _selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      folderPath = selectedDirectory;
      _searchForImages(Directory(folderPath));
    }
  }

  void toggleSearchSubdirectories(bool? checkboxValue) {
    setState(() {_searchSubdirectories = checkboxValue ?? !_searchSubdirectories;});
  }

  void _searchForImages(Directory dir) {
    List<String> images = [];
    dir.list(recursive: _searchSubdirectories).listen((file) {
      if (file is File) {
        String fileName = file.path.split('/').last.toLowerCase();
        // Check if the file name ends with any of the supported image types
        bool isImage = supportedImageTypes.any((ext) => fileName.endsWith(ext));
        if (isImage) {images.add(file.path);}
      }
    }).onDone(() {
      setState(() {imagePaths = images;});
      if (images.isEmpty) {ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No images found in $folderPath')));}
      else {Navigator.push(context, MaterialPageRoute(builder: (context) => SlideshowScreen(images: images, interval: interval),),);}
    });
  }

  void _toggleWakelock(bool? checkboxValue) {
    setState(() {if (checkboxValue == true) {WakelockPlus.enable();_isWakelockEnabled = true;} else {WakelockPlus.disable();_isWakelockEnabled = false;}});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Automatic Slideshow', style: TextStyle(color: Colors.grey)), backgroundColor: Colors.black,),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Pause seconds between images:", style: TextStyle(color: Colors.grey)),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [IconButton(icon: Icon(Icons.remove), color: Colors.grey, onPressed: _decrementInterval,),
                          Text('$interval', style: TextStyle(color: Colors.grey, fontSize: 24),),
                          IconButton(icon: Icon(Icons.add), color: Colors.grey, onPressed: _incrementInterval,),
                        ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _selectFolder, child: Text('Select Folder', style: TextStyle(color: Colors.grey[900]),), style: ElevatedButton.styleFrom(foregroundColor: Colors.grey, backgroundColor: Colors.orangeAccent,),),

            SizedBox(height: 60),
            Row(mainAxisAlignment: MainAxisAlignment.start,
                children: [Checkbox(value: _isWakelockEnabled, onChanged: _toggleWakelock, checkColor: Colors.black, activeColor: Colors.grey[800],),
                           Text('Prevent screen lock during slideshow', style: TextStyle(color: Colors.grey[800]),),
                          ],
               ),
            SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.start,
              children: [Checkbox(value: _searchSubdirectories, onChanged: toggleSearchSubdirectories, checkColor: Colors.black, activeColor: Colors.grey[800],),
                Text('Search subfolders for images too', style: TextStyle(color: Colors.grey[800]),),
              ],
            ),


          ],
        ),
      ),
    );
  }
}





class SlideshowScreen extends StatefulWidget {
  final List<String> images;
  final int interval;

  SlideshowScreen({required this.images, required this.interval});

  @override
  _SlideshowScreenState createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  int currentIndex = 0;
  bool showOverlayButtons = false;
  Timer? _slideshowTimer;
  Timer? _overlayButtonsTimer;
  late bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _startSlideshow();
  }

  void _startSlideshow() {
    _cancelSlideshowTimer();
    _slideshowTimer = Timer.periodic(Duration(seconds: widget.interval), (timer) {_nextImage();});
  }

  void _nextImage() {
    if (mounted) {
      setState(() {_isPlaying = true; currentIndex = (currentIndex + 1) % widget.images.length;});
      _startSlideshow();
    }
  }

  void _previousImage() {
    setState(() {_isPlaying = true; currentIndex = (currentIndex - 1 + widget.images.length) % widget.images.length;});
    _startSlideshow();
  }

  void _showOverlayButtons() {
    setState(() {showOverlayButtons = true;});
    _cancelOverlayButtonsTimer();
    _overlayButtonsTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {showOverlayButtons = false;});
    });
    //Future.delayed(Duration(seconds: 3), () {setState(() {showOverlayButtons = false;});});
  }

  void _togglePlayPause() {if (_isPlaying) {_pauseAtImage();} else {_forceNextImage();}}
  void _pauseAtImage() {setState(() {_isPlaying = false; _cancelSlideshowTimer();});}
  void _cancelSlideshowTimer() {if (_slideshowTimer != null) {_slideshowTimer!.cancel();}}
  void _forceNextImage() {_cancelSlideshowTimer(); _nextImage();}
  void _forcePreviousImage() {_cancelSlideshowTimer(); _previousImage();}
  void _cancelOverlayButtonsTimer() {if (_overlayButtonsTimer != null) {_overlayButtonsTimer!.cancel();}}

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black,
      body: GestureDetector(onTap: _showOverlayButtons,
        onHorizontalDragEnd: (details) {
         if (details.primaryVelocity! > 0) {_forcePreviousImage();}
         else if (details.primaryVelocity! < 0) {_forceNextImage();}
        },
        child: Stack(
          children: [Center(child: Image.file(File(widget.images[currentIndex]), fit: BoxFit.contain,),),
                      if (showOverlayButtons)
                        Positioned(top: 20, right: 20, child: GestureDetector(onTap: () => Navigator.pop(context),
                                                                              child: Container(color: Colors.black.withOpacity(0.5), padding: EdgeInsets.all(10), child: Icon(Icons.close, color: Colors.grey, size: 30),),
                                                                             ),
                                  ),
                      if (showOverlayButtons)
                      Positioned(bottom: 20, left: 0, right: 0,
                        child: Row(mainAxisAlignment: MainAxisAlignment.center,
                          children: [GestureDetector(onTap: () {_forcePreviousImage(); _showOverlayButtons();},
                                                     child: Container(color: Colors.black.withOpacity(0.5), padding: EdgeInsets.all(10), child: Icon(Icons.navigate_before, color: Colors.grey, size: 30),),
                                                    ),
                                     SizedBox(width: 5), // Spacing between buttons
                                     GestureDetector(onTap: () {_togglePlayPause(); _showOverlayButtons();},
                                                     child: Container(color: Colors.black.withOpacity(0.5), padding: EdgeInsets.all(10),
                                                                      child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.grey, size: 30,),
                                                                     ),
                                                    ),
                                     SizedBox(width: 5), // Spacing between buttons
                                     GestureDetector(onTap: () {_forceNextImage(); _showOverlayButtons();},
                                                     child: Container(color: Colors.black.withOpacity(0.5), padding: EdgeInsets.all(10), child: Icon(Icons.navigate_next, color: Colors.grey, size: 30),),
                                                    ),
                                    ],
                                 ),
                              ),
                 ],
                ),




        ),
      );
  }
}
