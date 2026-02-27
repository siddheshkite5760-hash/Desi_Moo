import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DesiMooApp());
}

class DesiMooApp extends StatelessWidget {
  const DesiMooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF64DD17),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

// --- GLOBAL STATE MANAGERS ---
ValueNotifier<String> appLanguage = ValueNotifier<String>('en');

// This stores our cropped images for the session
ValueNotifier<List<String>> savedCattles = ValueNotifier<List<String>>([]);

String translate(String key) {
  final Map<String, Map<String, String>> dictionary = {
    'en': {
      'select_lang': 'Select Language',
      'welcome': 'Welcome!',
      'login_user': 'Login as User',
      'login_admin': 'Login as Admin',
      'enter_mobile': 'Enter Mobile Number',
      'enter_email': 'Enter email Id',
      'password': 'Password',
      'login_btn': 'Login',
      'no_account': 'Don’t have an account? ',
      'signup_link': 'sign-up here',
      'forgot_pass': 'Forgot Password?',
      'signup_title': 'Sign Up',
      'create_acc': 'Create Account',
      'reset_pass': 'Reset Password',
      'send_otp': 'Send OTP',
      'full_name_admin': 'Full Name (Admin)',
      'full_name_farmer': 'Full Name',
      'create_password': 'Create Password',
      'recovery_msg': 'Enter your registered ID to receive a recovery OTP.',
      'id_hint': 'Mobile or Email ID',
      'field_req': 'Field Required',
      'pass_rec': 'Recommendation: Use at least 8 characters',
      'invalid_email': 'Enter a valid email address (@ and .)',
      'dash_scan': 'Scan/Upload Cattle',
      'dash_saved': 'Saved Cattles',
      'dash_library': 'Breed Library',
      'dash_aadhar': 'Pashu Adhaar',
      'welcome_admin': 'Welcome, Admin!',
      'welcome_user': 'Welcome!',
      'no_cattles': 'No cattles saved yet.',
      'cattle_record': 'Cattle Record #',
    },
    'hi': {
      'select_lang': 'भाषा चुनें',
      'welcome': 'स्वागत है!',
      'login_user': 'यूजर लॉगिन',
      'login_admin': 'एडमिन लॉगिन',
      'enter_mobile': 'मोबाइल नंबर दर्ज करें',
      'enter_email': 'ईमेल आईडी दर्ज करें',
      'password': 'पासवर्ड',
      'login_btn': 'लॉगिन',
      'no_account': 'खाता नहीं है? ',
      'signup_link': 'यहाँ साइन-अप करें',
      'forgot_pass': 'पासवर्ड भूल गए?',
      'signup_title': 'साइन अप',
      'create_acc': 'खाता बनाएं',
      'reset_pass': 'पासवर्ड रीसेट',
      'send_otp': 'ओटीपी भेजें',
      'full_name_admin': 'पूरा नाम (एडमिन)',
      'full_name_farmer': 'पूरा नाम',
      'create_password': 'पासवर्ड बनाएं',
      'recovery_msg': 'रिकवरी ओटीपी प्राप्त करने के लिए अपनी पंजीकृत आईडी दर्ज करें।',
      'id_hint': 'मोबाइल या ईमेल आईडी',
      'field_req': 'क्षेत्र आवश्यक है',
      'pass_rec': 'सिफारिश: कम से कम 8 वर्णों का उपयोग करें',
      'invalid_email': 'एक वैध ईमेल पता दर्ज करें (@ और .)',
      'dash_scan': 'पशु स्कैन/अपलोड करें',
      'dash_saved': 'सहेजे गए पशु',
      'dash_library': 'नस्ल पुस्तकालय',
      'dash_aadhar': 'पशु आधार',
      'welcome_admin': 'स्वागत है, एडमिन!',
      'welcome_user': 'स्वागत है!',
      'no_cattles': 'अभी तक कोई पशु नहीं बचाया गया है।',
      'cattle_record': 'पशु रिकॉर्ड #',
    },
    'mr': {
      'select_lang': 'भाषा निवडा',
      'welcome': 'स्वागत आहे!',
      'login_user': 'वापरकर्ता लॉगिन',
      'login_admin': 'अ‍ॅडमिन लॉगिन',
      'enter_mobile': 'मोबाईल नंबर टाका',
      'enter_email': 'ईमेल आयडी टाका',
      'password': 'पासवर्ड',
      'login_btn': 'लॉगिन',
      'no_account': 'खाते नाही? ',
      'signup_link': 'येथे साइन-अप करा',
      'forgot_pass': 'पासवर्ड विसरलात?',
      'signup_title': 'साइन अप',
      'create_acc': 'खाते तयार करा',
      'reset_pass': 'पासवर्ड रीसेट करा',
      'send_otp': 'ओटीपी पाठवा',
      'full_name_admin': 'पूर्ण नाव (अ‍ॅडमिन)',
      'full_name_farmer': 'पूर्ण नाव',
      'create_password': 'पासवर्ड तयार करा',
      'recovery_msg': 'रिकव्हरी ओटीपी मिळवण्यासाठी तुमचा नोंदणीकृत आयडी टाका.',
      'id_hint': 'मोबाईल किंवा ईमेल आयडी',
      'field_req': 'क्षेत्र आवश्यक आहे',
      'pass_rec': 'शिफारस: किमान 8 अक्षरे वापरा',
      'invalid_email': 'वैध ईमेल पत्ता प्रविष्ट करा (@ आणि .)',
      'dash_scan': 'पशु स्कॅन/अपलोड करा',
      'dash_saved': 'जतन केलेले पशु',
      'dash_library': 'नस्ल लायब्ररी',
      'dash_aadhar': 'पशु आधार',
      'welcome_admin': 'स्वागत आहे, अ‍ॅडमिन!',
      'welcome_user': 'स्वागत आहे!',
      'no_cattles': 'अद्याप कोणतेही पशु जतन केलेले नाहीत.',
      'cattle_record': 'पशु रेकॉर्ड #',
    },
  };
  return dictionary[appLanguage.value]?[key] ?? key;
}

// --- 1. MAIN LOGO SPLASH ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(top: 0, left: 0, right: 0, child: Container(height: 40, color: const Color(0xFF64DD17))),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png', width: 280),
                const SizedBox(height: 35),
                const Text("Innovating India’s Diary through Intelligence.",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF424242), fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 55, color: const Color(0xFF64DD17), alignment: Alignment.center,
              child: const Text("Powered by Mind Flayers", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }
}

// --- 2. LANGUAGE SELECTION ---
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 80, color: Color(0xFF64DD17)),
            const SizedBox(height: 20),
            Text(translate('select_lang'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF64DD17))),
            const SizedBox(height: 40),
            _langBtn(context, "English", "en"),
            _langBtn(context, "हिंदी", "hi"),
            _langBtn(context, "मराठी", "mr"),
          ],
        ),
      ),
    );
  }

  Widget _langBtn(BuildContext context, String label, String code) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
      child: GestureDetector(
        onTap: () {
          appLanguage.value = code;
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AnimatedLoginScreen()));
        },
        child: Container(
          height: 55, width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF64DD17), width: 2)),
          child: Center(child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF64DD17)))),
        ),
      ),
    );
  }
}

// --- 3. ANIMATED WELCOME & LOGIN ---
class AnimatedLoginScreen extends StatefulWidget {
  const AnimatedLoginScreen({super.key});
  @override
  State<AnimatedLoginScreen> createState() => _AnimatedLoginScreenState();
}

class _AnimatedLoginScreenState extends State<AnimatedLoginScreen> {
  bool _isAnimating = false;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  _startAnimation() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isAnimating = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showButtons = true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
            top: _isAnimating ? size.height * 0.2 : (size.height / 2) - 30,
            left: 0, right: 0,
            child: Center(
              child: Text(translate('welcome'),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF64DD17))),
            ),
          ),
          Positioned(
            top: size.height * 0.4, left: 50, right: 50,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _showButtons ? 1.0 : 0.0,
              child: Column(
                children: [
                  _loginButton(context, translate('login_user'), false),
                  const SizedBox(height: 25),
                  _loginButton(context, translate('login_admin'), true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginButton(BuildContext context, String label, bool isAdmin) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginInputScreen(isAdmin: isAdmin)),
        );
      },
      child: Container(
        width: double.infinity, height: 55,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF64DD17), width: 2.5)),
        child: Center(child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF64DD17)))),
      ),
    );
  }
}

// --- 4. LOGIN INPUT SCREEN ---
class LoginInputScreen extends StatefulWidget {
  final bool isAdmin;
  const LoginInputScreen({super.key, required this.isAdmin});

  @override
  State<LoginInputScreen> createState() => _LoginInputScreenState();
}

class _LoginInputScreenState extends State<LoginInputScreen> {
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return translate('field_req');
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return translate('invalid_email');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(widget.isAdmin ? translate('login_admin') : translate('login_user')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                TextFormField(
                  controller: _idController,
                  keyboardType: widget.isAdmin ? TextInputType.emailAddress : TextInputType.phone,
                  decoration: _inputDecoration(widget.isAdmin ? translate('enter_email') : translate('enter_mobile')),
                  validator: (v) {
                    if (widget.isAdmin) return _validateEmail(v);
                    return (v == null || v.length != 10) ? translate('field_req') : null;
                  },
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  decoration: _inputDecoration(translate('password')),
                  validator: (v) => (v == null || v.length < 8) ? translate('pass_rec') : null,
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(translate('no_account'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen(isAdmin: widget.isAdmin))),
                      child: Text(translate('signup_link'), style: const TextStyle(color: Color(0xFF64DD17), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                  child: Text(translate('forgot_pass'), style: const TextStyle(color: Color(0xFF64DD17), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 50),
                _actionButton(translate('login_btn'), () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(isAdmin: widget.isAdmin)));
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 5. SIGN UP SCREEN ---
class SignUpScreen extends StatelessWidget {
  final bool isAdmin;
  const SignUpScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: Text(translate('signup_title'))),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              TextFormField(decoration: _inputDecoration(isAdmin ? translate('full_name_admin') : translate('full_name_farmer'))),
              const SizedBox(height: 20),
              TextFormField(decoration: _inputDecoration(isAdmin ? translate('enter_email') : translate('enter_mobile'))),
              const SizedBox(height: 20),
              TextFormField(obscureText: true, decoration: _inputDecoration(translate('create_password'))),
              const SizedBox(height: 40),
              _actionButton(translate('create_acc'), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(isAdmin: isAdmin)))),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 6. FORGOT PASSWORD SCREEN ---
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: Text(translate('forgot_pass'))),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(translate('recovery_msg'), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            TextFormField(decoration: _inputDecoration(translate('id_hint'))),
            const SizedBox(height: 40),
            _actionButton(translate('send_otp'), () => print("Sending recovery email/OTP...")),
          ],
        ),
      ),
    );
  }
}

// --- 7. DASHBOARD SCREEN ---
class DashboardScreen extends StatelessWidget {
  final bool isAdmin;
  const DashboardScreen({super.key, required this.isAdmin});

  // Camera & Crop Logic Function
  Future<void> _scanCattle(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Cattle Image',
              toolbarColor: const Color(0xFF64DD17),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ],
            ),
            IOSUiSettings(
              title: 'Crop Cattle Image',
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ],
            ),
          ],
        );

        if (croppedFile != null) {
          // Saving image to our global library list
          savedCattles.value = List.from(savedCattles.value)..add(croppedFile.path);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Cattle Saved Successfully!")),
            );
          }
        }
      }
    } catch (e) {
      print("Error during scan/crop: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF64DD17),
        title: Text(isAdmin ? translate('welcome_admin') : translate('welcome_user'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()))
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              // --- FULLY UPDATED .png PATH HERE ---
              child: Image.asset(
                'assets/farmer_cattles.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200, color: Colors.grey[200],
                  child: const Center(child: Text("Image not found in assets", style: TextStyle(color: Colors.red))),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  _dashButton(Icons.camera_alt_outlined, translate('dash_scan'), () => _scanCattle(context)),
                  const SizedBox(height: 20),
                  _dashButton(Icons.bookmark_outline, translate('dash_saved'), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedCattlesScreen()))),
                  const SizedBox(height: 20),
                  _dashButton(Icons.book_outlined, translate('dash_library'), () {}),

                  // Completely removed for users - no light shadow left
                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    _dashButton(Icons.badge_outlined, translate('dash_aadhar'), () {}),
                  ],
                ],
              ),
            ),
          ),
          Container(height: 40, color: const Color(0xFF64DD17)),
        ],
      ),
    );
  }

  Widget _dashButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(color: const Color(0xFF64DD17), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const SizedBox(width: 15),
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 15),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- 8. SAVED CATTLES SCREEN ---
class SavedCattlesScreen extends StatelessWidget {
  const SavedCattlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF64DD17),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(translate('dash_saved'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: savedCattles,
        builder: (context, cattles, child) {
          if (cattles.isEmpty) {
            return Center(
              child: Text(translate('no_cattles'), style: const TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }
          return ListView.builder(
            itemCount: cattles.length,
            itemBuilder: (context, index) {
              final imagePath = cattles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImage(imagePath: imagePath))),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundImage: FileImage(File(imagePath)),
                    ),
                  ),
                  title: Text("${translate('cattle_record')}${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                    onPressed: () {
                      savedCattles.value = List.from(savedCattles.value)..removeAt(index);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- 9. FULL SCREEN IMAGE VIEWER ---
class FullScreenImage extends StatelessWidget {
  final String imagePath;
  const FullScreenImage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}

// --- COMMON UI COMPONENTS ---
InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF64DD17), width: 2.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF64DD17), width: 2.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 2)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 2.5)),
  );
}

Widget _actionButton(String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 55,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF64DD17), width: 2.5)),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF64DD17)))),
    ),
  );
}