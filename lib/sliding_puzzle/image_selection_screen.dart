import 'sliding_puzzle_screen.dart';
import 'package:flutter/material.dart';

class ImageSelectionScreen extends StatefulWidget {
  const ImageSelectionScreen({super.key});

  @override
  State<ImageSelectionScreen> createState() => _ImageSelectionScreenState();
}

class _ImageSelectionScreenState extends State<ImageSelectionScreen> {
  // Sử dụng danh sách ảnh cố định từ pubspec.yaml để đảm bảo luôn load được
  final List<String> _imageAssets = [
    'assets/Hinh Bo.jpg',
    'assets/Hinh Bo Sua.jpg',
    'assets/Hinh Ca.jpg',
    'assets/Hinh Capy.jpg',
    'assets/Hinh Chim.jpg',
    'assets/Hinh Cho.jpg',
    'assets/Hinh Ga.jpg',
    'assets/Hinh Meo.jpg',
    'assets/Hinh Trau.jpg',
    'assets/Hinh Vit.jpg',
  ];

  void _showDifficultyDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Chọn độ khó', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDifficultyButton(context, imagePath, 3, 'Dễ (3x3)', Colors.green),
              const SizedBox(height: 10),
              _buildDifficultyButton(context, imagePath, 4, 'Trung bình (4x4)', Colors.orange),
              const SizedBox(height: 10),
              _buildDifficultyButton(context, imagePath, 5, 'Khó (5x5)', Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDifficultyButton(BuildContext context, String imagePath, int gridSize, String text, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          Navigator.of(context).pop(); // Đóng dialog
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SlidingPuzzleScreen(
                imagePath: imagePath,
                gridSize: gridSize,
                levelNumber: 1,
              ),
            ),
          );
        },
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Chọn Ảnh Xếp Hình', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _imageAssets.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final imagePath = _imageAssets[index];
          // Lấy tên ảnh từ đường dẫn (Ví dụ: "Hinh Bo")
          final imageName = imagePath.split('/').last.split('.').first;

          return Card(
            elevation: 2.0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: InkWell(
              onTap: () => _showDifficultyDialog(imagePath),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      child: Text(
                        imageName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
