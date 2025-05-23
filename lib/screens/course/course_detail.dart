import 'package:finbedu/models/section_model.dart';
import 'package:finbedu/screens/quiz/quiz_result.dart';
import 'package:finbedu/services/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:finbedu/screens/course/video_player.dart';
import 'package:finbedu/models/course_model.dart';
import 'package:finbedu/models/video_model.dart';
import 'package:finbedu/models/course_access.dart';
import 'package:finbedu/providers/course_provider.dart';
import 'package:finbedu/providers/section_provider.dart';
import 'package:finbedu/providers/access_provider.dart';
import 'package:finbedu/providers/video_provider.dart';
import 'package:finbedu/widgets/custom_button.dart';
import 'package:finbedu/providers/quiz_provider.dart';
import 'package:finbedu/screens/quiz/quiz_screen.dart';

class CourseDetailPage extends StatefulWidget {
  final int courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

Map<int, List<Video>> _videosPerSection = {};
Set<int> _loadingSections = {};

class _CourseDetailPageState extends State<CourseDetailPage> {
  late Future<void> _loadData;

  @override
  void initState() {
    super.initState();
    _loadData = _initializeData();
    final accessProvider = Provider.of<AccessProvider>(context, listen: false);
    accessProvider.checkUserEnrollment(widget.courseId);
  }

  Future<void> _initializeData() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final sectionProvider = Provider.of<SectionProvider>(
      context,
      listen: false,
    );

    await courseProvider.fetchCourseById(widget.courseId);
    if (courseProvider.courseById != null) {
      await sectionProvider.fetchSections(widget.courseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final course = courseProvider.courseById;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: FutureBuilder(
        future: _loadData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (course == null) {
            return const Center(child: Text("Course not found"));
          }

          return DefaultTabController(
            length: 2,
            child: Stack(
              children: [
                Column(
                  children: [
                    // Thumbnail Header
                    Stack(
                      children: [
                        course.image != null
                            ? Image.network(
                              '${Constants.imgUrl}/${course.image}',
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover, // Agar gambar memenuhi area
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) {
                                  return child; // Jika loading selesai, tampilkan gambar
                                }
                                return Container(
                                  height: 250,
                                  width: double.infinity,
                                  color:
                                      Colors
                                          .grey
                                          .shade200, // Latar belakang saat loading
                                  child: const Center(
                                    child:
                                        CircularProgressIndicator(), // Indikator loading
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 250,
                                  width: double.infinity,
                                  color:
                                      Colors.black, // Latar belakang saat error
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image, // Ikon untuk error
                                      color: Colors.white,
                                      size: 72,
                                    ),
                                  ),
                                );
                              },
                            )
                            : Container(
                              height: 250,
                              width: double.infinity,
                              color: Colors.black,
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 72,
                                ),
                              ),
                            ),
                        Positioned(
                          left: 20,
                          top: 48,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(Icons.arrow_back),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // TabBar
                    Container(
                      color: Colors.white,
                      child: const TabBar(
                        labelColor: Colors.black,
                        indicatorColor: Color(0xFF202244),
                        tabs: [Tab(text: 'Overview'), Tab(text: 'Curriculum')],
                      ),
                    ),
                    // TabBarView
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Overview Tab
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Info Box
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            course.level ?? "Unknown Level",
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          // Row(
                                          //   children: [
                                          //     const Icon(
                                          //       Icons.star,
                                          //       size: 16,
                                          //       color: Colors.orange,
                                          //     ),
                                          //     const SizedBox(width: 4),
                                          //     Text(
                                          //       course.rating?.toString() ??
                                          //           "-",
                                          //     ),
                                          //   ],
                                          // ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        course.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 20,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          ClipOval(
                                            child:
                                                course.user!.photo != null
                                                    ? Image.network(
                                                      '${Constants.imgUrl}/${course.user!.photo}',
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          width: 50,
                                                          height: 50,
                                                          color: Colors.white,
                                                          child: const Icon(
                                                            Icons.person,
                                                            size: 50,
                                                            color: Colors.grey,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                    : Container(
                                                      width: 50,
                                                      height: 50,
                                                      color: Colors.white,
                                                      child: const Icon(
                                                        Icons.person,
                                                        size: 70,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  course.user!.name ?? "-",
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const Text(
                                                  "Mentor",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Row(
                                      //   children: [
                                      //     _buildMeta(
                                      //       Icons.menu_book,
                                      //       "${course.totalLessons ?? 0} Lessons",
                                      //     ),
                                      //     const SizedBox(width: 12),
                                      //     _buildMeta(
                                      //       Icons.access_time,
                                      //       course.name ?? "-",
                                      //     ),
                                      //     const SizedBox(width: 12),
                                      //     _buildMeta(
                                      //       Icons.group,
                                      //       "${course.totalStudents ?? 0} Students",
                                      //     ),
                                      //   ],
                                      // ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),
                                Container(
                                  // padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _buildAboutSection(
                                    course.desc ?? "",
                                    Provider.of<SectionProvider>(
                                      context,
                                    ).sections,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          // Curriculum Tab
                          SingleChildScrollView(
                            // padding: const EdgeInsets.all(20),
                            child: _buildCurriculumSection(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Enroll Button
                // Enroll Button
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Consumer<AccessProvider>(
                    builder: (context, accessProvider, child) {
                      if (accessProvider.isEnrolled) {
                        // Jika sudah enroll, tidak tampilkan tombol
                        return const SizedBox.shrink();
                      }

                      // Jika belum enroll, tampilkan tombol enroll
                      return ActionButton(
                        label:
                            "Enroll Course -  ${Constants().formatRupiah(course.price)}",
                        color: const Color(0xFF202244),
                        height: 56,
                        width: double.infinity,
                        onTap: () async {
                          final newAccess = CourseAccess(
                            courseId: course.id!,
                            accessStatus: 'ongoing',
                          );

                          final result = await accessProvider.addAccess(
                            newAccess,
                          );

                          if (result != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Berhasil enroll ke course!'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  accessProvider.errorMessage ??
                                      'Gagal enroll.',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }

  Widget _buildCurriculumSection() {
    final accessProvider = Provider.of<AccessProvider>(context);
    final sectionProvider = Provider.of<SectionProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    final sections = sectionProvider.sections;

    if (accessProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isEnrolled = accessProvider.isEnrolled;

    if (sections.isEmpty) {
      return const Center(child: Text("No sections available"));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = sections[sectionIndex];

        return ExpansionTile(
          title: Text(
            section.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onExpansionChanged: (isExpanded) async {
            if (isExpanded &&
                !_videosPerSection.containsKey(section.id) &&
                !_loadingSections.contains(section.id)) {
              setState(() {
                _loadingSections.add(section.id);
              });
              try {
                final videos = await videoProvider.fetchVideos(section.id);
                setState(() {
                  _videosPerSection[section.id] = videos;
                });
              } catch (e) {
                // Bisa ditambahkan error handling di sini jika perlu
                debugPrint(
                  'Failed to load videos for section ${section.id}: $e',
                );
              } finally {
                setState(() {
                  _loadingSections.remove(section.id);
                });
              }
            }
          },
          children: [
            if (!isEnrolled)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Anda belum enroll. Materi terkunci.",
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),

            if (_loadingSections.contains(section.id))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_videosPerSection[section.id] == null)
              const SizedBox.shrink()
            else if (_videosPerSection[section.id]!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: Text("No videos available")),
              )
            else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _videosPerSection[section.id]!.length,
                itemBuilder: (context, videoIndex) {
                  final video = _videosPerSection[section.id]![videoIndex];
                  return ListTile(
                    leading: Icon(
                      isEnrolled ? Icons.play_circle : Icons.lock,
                      color: isEnrolled ? Colors.blue : Colors.grey,
                    ),

                    title: Text(
                      video.title,
                      style: TextStyle(
                        color: isEnrolled ? Colors.black : Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      video.duration ?? "Unknown Duration",
                      style: TextStyle(
                        color: isEnrolled ? Colors.black54 : Colors.grey,
                      ),
                    ),
                    enabled: isEnrolled,
                    onTap:
                        isEnrolled
                            ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => VideoPlayerScreen(
                                        videoUrl: video.url,
                                      ),
                                ),
                              );
                            }
                            : null,
                  );
                },
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FutureBuilder<int?>(
                    future: Provider.of<QuizProvider>(
                      context,
                      listen: false,
                    ).getQuizIdBySectionId(
                      section.id,
                    ), // Dapatkan quizId berdasarkan sectionId
                    builder: (context, quizIdSnapshot) {
                      if (quizIdSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final quizId = quizIdSnapshot.data;

                      if (quizId == null) {
                        return const Center(
                          child: Text("Quiz tidak tersedia untuk section ini"),
                        );
                      }

                      return FutureBuilder<int?>(
                        future: Provider.of<QuizProvider>(
                          context,
                          listen: false,
                        ).getQuizResult(
                          quizId,
                        ), // Periksa hasil quiz berdasarkan quizId
                        builder: (context, resultSnapshot) {
                          if (resultSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final score = resultSnapshot.data;

                          return ElevatedButton.icon(
                            onPressed:
                                isEnrolled
                                    ? () async {
                                      if (score != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => QuizResultScreen(
                                                  score: score,
                                                ),
                                          ),
                                        );
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    QuizPage(quizId: quizId),
                                          ),
                                        );
                                      }
                                    }
                                    : null,
                            icon: Icon(
                              score != null
                                  ? Icons.visibility
                                  : Icons.assignment,
                              color: isEnrolled ? Colors.white : Colors.grey,
                            ),
                            label: Text(
                              score != null ? "Lihat Score" : "Kerjakan Quiz",
                              style: TextStyle(
                                color: isEnrolled ? Colors.white : Colors.grey,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isEnrolled
                                      ? (score != null
                                          ? Colors.blue
                                          : Colors.green)
                                      : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  void _playVideo(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Could not launch $url")));
    }
  }

  Widget _buildAboutSection(String about, List<Section> sections) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "About This Course",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            about,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          const Text(
            "What You'll Get",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _infoItem(
            Icons.play_circle,
            "${_calculateTotalLessons(sections)} Lessons",
          ),
          _infoItem(Icons.devices, "Access Mobile, Desktop & TV"),
          _infoItem(Icons.lock_open, "Lifetime Access"),
          _infoItem(Icons.quiz, "${_calculateTotalLessons(sections)} Quizzes"),
          _infoItem(Icons.verified, "Certificate of Completion"),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  int _calculateTotalLessons(List<Section> sections) {
    return sections.length; // Jumlah section adalah jumlah lessons
  }
}
