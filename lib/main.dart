import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // flutter_dotenv প্যাকেজ আমদানি করা হচ্ছে।

// main ফাংশনকে অ্যাসিঙ্ক্রোনাস করা হচ্ছে যাতে .env ফাইল লোড করা যায়।
Future<void> main() async {
  // নিশ্চিত করুন যে Flutter ইঞ্জিন প্রস্তুত আছে।
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI গল্প লেখক',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const StoryWriterPage(),
    );
  }
}

class StoryWriterPage extends StatefulWidget {
  const StoryWriterPage({super.key});

  @override
  State<StoryWriterPage> createState() => _StoryWriterPageState();
}

class _StoryWriterPageState extends State<StoryWriterPage> {
  final TextEditingController _storyController = TextEditingController();
  final TextEditingController _languageController = TextEditingController(
    text: 'বাংলা',
  );
  bool _isLoading = false;
  bool _isStoryStarted = false;

  // এখানে সরাসরি API Key না লিখে, এটি .env ফাইল থেকে লোড করা হচ্ছে।
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];

  // Gemini API-কে কল করার জন্য অ্যাসিঙ্ক্রোনাস ফাংশন।
  Future<void> _generateStory() async {
    if (apiKey == null || apiKey!.isEmpty) {
      setState(() {
        _storyController.text = "দয়া করে আপনার Gemini API Key .env ফাইলে দিন।";
      });
      return;
    }

    // টেক্সট ইনপুট যদি খালি থাকে, তবে কোনো কাজ হবে না।
    if (_storyController.text.isEmpty && !_isStoryStarted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Gemini API-এর এন্ডপয়েন্ট।
    const apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent';

    String userPrompt;
    if (_isStoryStarted) {
      // যদি গল্পটি শুরু হয়ে যায়, তবে বাকি অংশ লেখার জন্য প্রম্পট তৈরি করা হবে।
      userPrompt =
          "এই গল্পটি ${_languageController.text} ভাষায় চালিয়ে যাও: ${_storyController.text}";
    } else {
      // গল্প শুরু করার জন্য প্রম্পট।
      userPrompt =
          "Write a captivating short story in ${_languageController.text} based on this idea: ${_storyController.text}";
    }

    // API-তে পাঠানোর জন্য পেলোড তৈরি করা হচ্ছে।
    final payload = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt},
          ],
        },
      ],
    };

    try {
      // HTTP পোস্ট রিকোয়েস্ট পাঠানো হচ্ছে।
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // যদি রিকোয়েস্ট সফল হয়, রেসপন্স থেকে টেক্সট বের করে নিচ্ছি।
        final jsonResponse = jsonDecode(response.body);
        final generatedText =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];

        setState(() {
          if (!_isStoryStarted) {
            // নতুন গল্প হলে আগের টেক্সট সরিয়ে নতুন টেক্সট বসানো হচ্ছে।
            _storyController.text = generatedText;
            _isStoryStarted = true;
          } else {
            // গল্পটি চালিয়ে যাওয়ার জন্য নতুন টেক্সট যোগ করা হচ্ছে।
            _storyController.text += '\n\n' + generatedText;
          }
        });
      } else {
        // যদি কোনো সমস্যা হয়, এরর মেসেজ দেখাচ্ছি।
        setState(() {
          _storyController.text =
              'API কল করতে সমস্যা হয়েছে: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      // যদি কোনো ব্যতিক্রম (exception) ঘটে, তা দেখাচ্ছি।
      setState(() {
        _storyController.text = 'একটি ত্রুটি ঘটেছে: $e';
      });
    } finally {
      // লোডিং স্টেট বন্ধ করে দিচ্ছি।
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'AI গল্প লেখক',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7F7FD5), Color(0xFF86A8E7), Color(0xFF91EAE4)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 40.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // ভাষা নির্বাচন করার জন্য টেক্সট ফিল্ড
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _languageController,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: InputBorder.none,
                        labelText: 'গল্পের ভাষা লিখুন (যেমন: বাংলা, English)',
                        labelStyle: TextStyle(fontWeight: FontWeight.w500),
                        prefixIcon: Icon(Icons.language),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // গল্প লেখার জন্য বড় টেক্সট ফিল্ড।
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white.withOpacity(0.97),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 320,
                        child: TextFormField(
                          controller: _storyController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText:
                                _isStoryStarted
                                    ? 'গল্পটি সম্পাদনা করুন বা চালিয়ে যান...'
                                    : 'গল্পের ধারণা লিখুন...',
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(fontSize: 17, height: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // জেনারেট বাটন।
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateStory,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF7F7FD5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                _isStoryStarted
                                    ? 'গল্পটি চালিয়ে যাও'
                                    : 'গল্প শুরু করো',
                                style: const TextStyle(color: Colors.white),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
