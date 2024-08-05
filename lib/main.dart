import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
  int interval = 5;
  List<String> imagePaths = [];
  String folderPath = "";

  void _incrementInterval() {
    setState(() {interval++;});
  }

  void _decrementInterval() {
    setState(() {if (interval > 1) interval--;});
  }

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
        if (['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(file.path.toLowerCase().substring(file.path.length - 4))) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Automatic Slideshow', style: TextStyle(color: Colors.grey)), backgroundColor: Colors.black,),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Pause seconds between images:", style: TextStyle(color: Colors.white)),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [IconButton(icon: Icon(Icons.remove), color: Colors.white, onPressed: _decrementInterval,),
                          Text('$interval', style: TextStyle(color: Colors.white, fontSize: 24),),
                          IconButton(icon: Icon(Icons.add), color: Colors.white, onPressed: _incrementInterval,),
                        ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _selectFolder, child: Text('Select Folder'),),
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
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {_previousImage();}
          else if (details.primaryVelocity! < 0) {_nextImage();}
        },
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
