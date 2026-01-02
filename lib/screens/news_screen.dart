import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final List<Map<String, String>> _newsItems = [
    {
      'title': 'Ngày thi THPT quốc gia',
      'description': 'Với Việt Nam, kỳ thi THPT quốc gia là một trong những kỳ thi quan trọng nhất trong năm học. Kỳ thi này không chỉ đánh giá kiến thức của học sinh mà còn quyết định tương lai của họ.',
      'image': 'assets/images/thpt.jpg',
    },
    {
      'title': 'Nhận định đề thi THPT quốc gia môn toán',
      'description': 'Toán là môn học quan trọng trong kỳ thi THPT quốc gia. Đề thi thường bao gồm các phần lý thuyết và bài tập thực hành, giúp đánh giá khả năng tư duy và giải quyết vấn đề của học sinh.',
      'image': 'assets/images/thi toán.png',
    },
    {
      'title': 'Cuộc thi tiếng anh trực tuyến',
      'description': 'Cuộc thi tiếng anh trực tuyến là một trong những hoạt động thú vị và bổ ích cho học sinh. Nó không chỉ giúp học sinh nâng cao kỹ năng ngôn ngữ mà còn tạo cơ hội giao lưu và học hỏi.',
      'image': 'assets/images/anh.jpg',
    },
    {
      'title': 'Vẻ đẹp của văn học Việt Nam',
      'description': 'Văn học Việt Nam là một phần quan trọng trong văn hóa dân tộc. Nó không chỉ phản ánh lịch sử, văn hóa mà còn thể hiện tâm tư, tình cảm của người dân Việt Nam qua các thời kỳ.',
      'image': 'assets/images/văn.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin tức')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _newsItems.length,
        itemBuilder: (context, index) {
          final item = _newsItems[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note: Using a placeholder since assets might not be available
                Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['description']!,
                        style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
