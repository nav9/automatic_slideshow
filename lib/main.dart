import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
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
  late int MAX_LEN_IMAGE_EXTN;

  @override
  void initState() {
    super.initState();
    _isWakelockEnabled = false;
    MAX_LEN_IMAGE_EXTN = supportedImageTypes.map((type) => type.length).reduce((a, b) => a > b ? a : b);
    debugPrint('MAX LEN = $MAX_LEN_IMAGE_EXTN');
    WakelockPlus.disable(); // Ensure wakelock is disabled by default
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

  void _searchForImages(Directory dir) {
    List<String> images = [];
    dir.list(recursive: true).listen((file) {
      if (file is File) {
        if (supportedImageTypes.contains(file.path.toLowerCase().substring(file.path.length - MAX_LEN_IMAGE_EXTN))) {
          images.add(file.path);
        }
      }
    }).onDone(() {
      setState(() {imagePaths = images;});
      if (images.isEmpty) {ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No images found in $folderPath')));}
      else {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SlideshowScreen(images: images, interval: interval),),);
      }
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

            //SizedBox(height: 20),
            //ElevatedButton(onPressed: _selectFolder, child: Text('Select Folder'),),
            SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [Checkbox(value: _isWakelockEnabled, onChanged: _toggleWakelock, checkColor: Colors.black, activeColor: Colors.grey[800],),
                           Text('Prevent screen lock during slideshow', style: TextStyle(color: Colors.grey[800]),),
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
  bool showCloseButton = false;

  @override
  void initState() {
    super.initState();
    _startSlideshow();
  }

  void _startSlideshow() {
    Future.delayed(Duration(seconds: widget.interval), _nextImage);
  }

  void _nextImage() {
    if (mounted) {
      setState(() {currentIndex = (currentIndex + 1) % widget.images.length;});
      _startSlideshow();
    }
  }

  void _previousImage() {
    setState(() {currentIndex = (currentIndex - 1 + widget.images.length) % widget.images.length;});
  }

  void _showCloseButton() {
    setState(() {showCloseButton = true;});
    Future.delayed(Duration(seconds: 3), () {
      setState(() {showCloseButton = false;});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black,
      body: GestureDetector(onTap: _showCloseButton,
        //onHorizontalDragEnd: (details) {
        //  if (details.primaryVelocity! > 0) {_previousImage();}
        //  else if (details.primaryVelocity! < 0) {_nextImage();}
        //},
        child: Stack(
          children: [Center(child: Image.file(File(widget.images[currentIndex]), fit: BoxFit.contain,),),
            if (showCloseButton)
              Positioned(top: 20, right: 20, child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(color: Colors.black.withOpacity(0.5), padding: EdgeInsets.all(10), child: Icon(Icons.close, color: Colors.white, size: 30),),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
