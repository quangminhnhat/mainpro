import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'class_list_screen.dart';
import 'course_list_screen.dart';
import 'my_courses_screen.dart';
import 'register_screen.dart';
import 'add_edit_course_screen.dart';
import 'add_edit_class_screen.dart';
import 'enrollment_list_screen.dart';
import 'add_edit_enrollment_screen.dart';
import 'exam_list_screen.dart';
import 'material_list_screen.dart';
import 'upload_material_screen.dart';
import 'request_list_screen.dart';
import 'add_edit_request_screen.dart';
import 'weekly_schedule_screen.dart';
import 'schedule_list_screen.dart';
import 'add_edit_schedule_screen.dart';
import 'user_list_screen.dart';
import 'course_detail_screen.dart';
import 'notifications_screen.dart';
import 'available_courses_screen.dart';
import '../services/AuthService.dart';
import '../services/NotificationService.dart';
import '../config/config_url.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  final AuthService _authService = AuthService();
  List<dynamic> _featuredCourses = [];
  bool _isLoadingCourses = true;

  final List<String> _slideImages = [
    'slide1.jpg',
    'slide2.jpg',
    'slide3.jpg',
    'slide4.jpg',
    'slide5.png',
  ];

  final List<Map<String, String>> _teachers = [
    {'name': 'Hoàng Long', 'title': 'Giám đốc Trung tâm', 'image': 'gv8.png'},
    {'name': 'Nguyễn Thị Lan', 'title': 'Giáo viên IELTS', 'image': 'gv2.png'},
    {'name': 'Trần Văn Minh', 'title': 'Giáo viên Toán', 'image': 'gv4.jpg'},
    {'name': 'Lê Thị Hương', 'title': 'Giáo viên Văn', 'image': 'gv3.png'},
    {'name': 'Phạm Quốc Anh', 'title': 'Giáo viên SAT', 'image': 'gv5.jpg'},
    {'name': 'Ngô Thị Mai', 'title': 'Giáo viên Tiếng Anh', 'image': 'gv6.jpg'},
    {'name': 'Đặng Văn Sơn', 'title': 'Trợ giảng', 'image': 'gv7.jpg'},
    {'name': 'Vũ Thị Thu', 'title': 'Nhân viên tư vấn', 'image': 'gv1.png'},
  ];

  final List<Map<String, String>> _newsItems = [
    {
      'title': 'Ngày thi THPT quốc gia',
      'desc': 'Với Việt Nam, kỳ thi THPT quốc gia là một trong những kỳ thi quan trọng nhất trong năm học. Kỳ thi này không chỉ đánh giá kiến thức của học sinh mà còn quyết định tương lai của họ.',
      'img': 'thpt.jpg'
    },
    {
      'title': 'Nhận định đề thi THPT quốc gia môn toán',
      'desc': 'Toán là môn học quan trọng trong kỳ thi THPT quốc gia. Đề thi thường bao gồm các phần lý thuyết và bài tập thực hành, giúp đánh giá khả năng tư duy và giải quyết vấn đề của học sinh.',
      'img': 'thi toán.png'
    },
    {
      'title': 'Cuộc thi tiếng anh trực tuyến',
      'desc': 'Cuộc thi tiếng anh trực tuyến là một trong những hoạt động thú vị và bổ ích cho học sinh. Nó không chỉ giúp học sinh nâng cao kỹ năng ngôn ngữ mà còn tạo cơ hội giao lưu và học hỏi.',
      'img': 'anh.jpg'
    },
    {
      'title': 'Vẻ đẹp của văn học Việt Nam',
      'desc': 'Văn học Việt Nam là một phần quan trọng trong văn hóa dân tộc. Nó không chỉ phản ánh lịch sử, văn hóa mà còn thể hiện tâm tư, tình cảm của người dân Việt Nam qua các thời kỳ.',
      'img': 'văn.jpg'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUserProfile();
    _fetchFeaturedCourses();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      setState(() {
        _userData = jsonDecode(userStr);
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final dio = AuthService.client;
      final response = await dio.get("/profile");
      if (response.statusCode == 200) {
        final details = response.data['details'];
        if (mounted) {
          setState(() {
            _userData = details;
          });
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(details));
        }
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  Future<void> _fetchFeaturedCourses() async {
    try {
      final dio = AuthService.client;
      final response = await dio.get("/"); 
      if (response.statusCode == 200) {
        setState(() {
          _featuredCourses = response.data['courses'] ?? [];
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingCourses = false);
    }
  }

  String _getImageUrl(String? imgPath) {
    if (imgPath == null || imgPath.isEmpty) {
      return "";
    }
    imgPath = imgPath.replaceAll('\\\\', '/').replaceAll('\\', '/');
    if (imgPath.startsWith('http')) return imgPath;
    String base = Config_URL.baseUrl.split('/api')[0];
    if (!imgPath.contains('/')) return "$base/images/$imgPath";
    if (imgPath.startsWith('images/') || imgPath.startsWith('uploads/')) return "$base/$imgPath";
    if (imgPath.startsWith('/')) return "$base$imgPath";
    return "$base/$imgPath";
  }

  void _logout() async {
    await _authService.logout();
    await NotificationService.cancelAll();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userRole = _userData?['role'] ?? 'student';
    final bool isAdmin = userRole == 'admin';
    final bool isTeacher = userRole == 'teacher';
    final bool isStudent = userRole == 'student';
    final bool canManageClasses = isAdmin || isTeacher;

    String avatarUrl = _getImageUrl(_userData?['profile_pic']);
    String base = Config_URL.baseUrl.split('/api')[0];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talent Education'),
        actions: [
          if (_userData != null)
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
                _fetchUserProfile();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text((_userData?['full_name']?[0] ?? 'U').toUpperCase())
                      : null,
                ),
              ),
            ),
        ],
      ),
      drawer: _buildDrawer(avatarUrl, canManageClasses, isTeacher, isStudent, isAdmin),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSlideshow(),
            _buildFeaturedCourses(),
            _buildTeacherSlider(),
            _buildAboutSection(),
            _buildOpenLetterSection(),
            _buildNewsSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideshow() {
    return SizedBox(
      height: 220,
      child: Swiper(
        itemBuilder: (BuildContext context, int index) {
          String url = _getImageUrl(_slideImages[index]);
          return Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.blue.shade100,
              child: const Center(child: Icon(Icons.image, size: 50, color: Colors.white)),
            ),
          );
        },
        itemCount: _slideImages.length,
        pagination: const SwiperPagination(),
        control: const SwiperControl(),
        autoplay: true,
      ),
    );
  }

  Widget _buildFeaturedCourses() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          _buildSectionTitle('Khóa học nổi bật'),
          const SizedBox(height: 20),
          _isLoadingCourses
              ? const CircularProgressIndicator()
              : SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _featuredCourses.length,
              itemBuilder: (context, index) {
                final course = _featuredCourses[index];
                String fullImgUrl = _getImageUrl(course['img']);

                return Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailScreen(courseId: course['id'].toString()))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          fullImgUrl.isNotEmpty
                              ? Image.network(
                            fullImgUrl,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(height: 140, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                          )
                              : Container(height: 140, color: Colors.grey.shade200),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(course['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Text(course['course_desc'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black54), maxLines: 3, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      color: Colors.blue.withOpacity(0.03),
      child: Column(
        children: [
          _buildSectionTitle('Đội ngũ giáo viên'),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _teachers.length,
              itemBuilder: (context, index) {
                final teacher = _teachers[index];
                String teacherImgUrl = _getImageUrl(teacher['image']);
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: teacherImgUrl.isNotEmpty ? NetworkImage(teacherImgUrl) : null,
                          child: teacherImgUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.blue) : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(teacher['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
                      Text(teacher['title']!, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Về chúng tôi', align: TextAlign.left),
          const SizedBox(height: 16),
          const Text(
            'Trung tâm ngoại ngữ Talent Education Chúng tôi là một trung tâm uy tín hoạt động hợp pháp theo Giấy phép kinh doanh số 0822488288, được cấp bởi Sở Kế hoạch & Đầu tư Thành phố Hà Tĩnh vào ngày 07 tháng 01 năm 2025. Người đại diện pháp luật là ông Hoàng Long.',
            style: TextStyle(fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 20),
          _buildAboutItem('Khóa học Toán Văn Anh', 'Dành cho các bạn học sinh cấp 2 and 3, xây dựng nền tảng học thuật vững chắc.'),
          _buildAboutItem('Khóa học IELTS', 'Thiết kế cho học sinh, sinh viên, người đi làm với mục tiêu du học, định cư.'),
          _buildAboutItem('Khóa học SAT', 'Tập trung vào kỳ thi chuẩn hóa SAT, yêu cầu quan trọng khi xét tuyển Hoa Kỳ.'),
        ],
      ),
    );
  }

  Widget _buildOpenLetterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          _buildSectionTitle('Thư ngỏ'),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              _getImageUrl('gv1.png'),
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(height: 200, color: Colors.grey.shade200, child: const Icon(Icons.person)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Kính gửi quý phụ huynh và các bạn học viên,\n\n'
            'Trung tâm Tiếng Anh của chúng tôi xin gửi lời chào trân trọng nhất tới quý vị. '
            'Chúng tôi rất vui mừng được chia sẻ với các bạn sứ mệnh của mình trong việc mang đến cho mọi người một môi trường học tập tiếng Anh chuyên nghiệp và hiệu quả.\n\n'
            'Tại trung tâm chúng tôi, chúng tôi cam kết cung cấp cho các bạn các khóa học chất lượng cao, được thiết kế để phát triển kỹ năng ngôn ngữ một cách toàn diện. '
            'Chương trình học của chúng tôi không chỉ tập trung vào việc nâng cao khả năng giao tiếp mà còn đảm bảo cho các bạn có được nền tảng vững chắc về ngữ pháp và từ vựng.\n\n'
            'Đội ngũ giáo viên tại trung tâm là những người có kinh nghiệm và trình độ chuyên môn cao, luôn sẵn sàng hỗ trợ và truyền đạt kiến thức một cách truyền cảm hứng. '
            'Chúng tôi tin rằng việc học ngoại ngữ không chỉ là việc học một môn học, mà còn là việc khám phá văn hóa và mở rộng tầm nhìn.\n\n'
            'Trân trọng,\n\n'
            'Hoàng Long\n'
            'Giám đốc Trung tâm Tiếng Anh TLE',
            style: TextStyle(fontSize: 15, height: 1.6),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          _buildSectionTitle('Tin tức'),
          const SizedBox(height: 24),
          ..._newsItems.map((news) => Card(
            margin: const EdgeInsets.only(bottom: 24),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  _getImageUrl(news['img']),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(height: 200, color: Colors.grey.shade200, child: const Icon(Icons.newspaper)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(news['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 10),
                      Text(news['desc']!, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5), textAlign: TextAlign.justify),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {TextAlign align = TextAlign.center}) {
    return Container(
      width: double.infinity,
      child: Text(
        title,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue),
        textAlign: align,
      ),
    );
  }

  Widget _buildAboutItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.blue, size: 22),
          const SizedBox(width: 12),
          Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 15, height: 1.5), children: [TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: desc)]))),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      color: Colors.blueGrey.shade900,
      width: double.infinity,
      child: Column(
        children: [
          const Text('Liên hệ với chúng tôi!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Tìm kiếm chúng tôi trên mạng xã hội hoặc gửi tin nhắn.', style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.facebook),
              const SizedBox(width: 20),
              _buildSocialIcon(Icons.email),
              const SizedBox(width: 20),
              _buildSocialIcon(Icons.phone),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Copyright © 2025 Talent Education', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildDrawer(String avatarUrl, bool canManageClasses, bool isTeacher, bool isStudent, bool isAdmin) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          InkWell(
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              _fetchUserProfile();
            },
            child: UserAccountsDrawerHeader(
              accountName: Text(_userData?['full_name'] ?? 'Người dùng'),
              accountEmail: Text(_userData?['email'] ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty ? Text((_userData?['full_name']?[0] ?? 'U').toUpperCase(), style: const TextStyle(fontSize: 40.0)) : null,
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
          ),
          ListTile(leading: const Icon(Icons.home), title: const Text('Trang Chủ'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.book), title: const Text('Sách Giáo Khoa'), onTap: () { Navigator.pop(context); _launchUrl('https://drive.google.com/drive/folders/1j_lNKViTx_UUyZNXRlkhRd-w9ghDxAYB'); }),
          const Divider(),
          if (isTeacher || isStudent) ...[
            ListTile(leading: const Icon(Icons.calendar_month), title: const Text('My Schedule'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyScheduleScreen())); }),
            ListTile(leading: const Icon(Icons.school), title: const Text('My courses'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const MyCoursesScreen())); }),
          ],
          if (isStudent)
            ListTile(leading: const Icon(Icons.library_add), title: const Text('Available Courses'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const AvailableCoursesScreen())); }),
          ListTile(leading: const Icon(Icons.notifications), title: const Text('Notifications'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())); }),
          ListTile(leading: const Icon(Icons.assignment), title: const Text('Exams'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamListScreen())); }),
          ListTile(leading: const Icon(Icons.description), title: const Text('Materials'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const MaterialListScreen())); }),
          ListTile(leading: const Icon(Icons.help_outline), title: const Text('Requests'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const RequestListScreen())); }),
          if (canManageClasses) ListTile(leading: const Icon(Icons.groups), title: const Text('Classes'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassListScreen())); }),
          if (isAdmin) ...[
            const Divider(),
            const Padding(padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 4.0), child: Text('Admin Tools', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
            ListTile(leading: const Icon(Icons.calendar_today), title: const Text('All Schedules'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleListScreen())); }),
            ListTile(leading: const Icon(Icons.book_online), title: const Text('Courses'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const CourseListScreen())); }),
            ListTile(leading: const Icon(Icons.app_registration), title: const Text('Enrollments'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const EnrollmentListScreen())); }),
            ListTile(leading: const Icon(Icons.people), title: const Text('User List'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const UserListScreen())); }),
            ListTile(leading: const Icon(Icons.person_add), title: const Text('Register User'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())); }),
          ],
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout', style: TextStyle(color: Colors.red)), onTap: _logout),
        ],
      ),
    );
  }
}
