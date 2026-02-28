import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';

// --- DATABASE IMPORT ---
import 'mongo_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MongoDB Atlas connection before app starts
  await MongoDatabase.connect();

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
ValueNotifier<List<String>> savedCattles = ValueNotifier<List<String>>([]);

String translate(String key) {
  final Map<String, Map<String, String>> dictionary = {
    'en': {
      'select_lang': 'Select Language', 'welcome': 'Welcome!', 'login_user': 'Login as User',
      'login_admin': 'Login as Admin', 'enter_mobile': 'Enter Mobile Number', 'enter_email': 'Enter email Id',
      'password': 'Password', 'login_btn': 'Login', 'no_account': 'Don’t have an account? ',
      'signup_link': 'sign-up here', 'forgot_pass': 'Forgot Password?', 'signup_title': 'Sign Up',
      'create_acc': 'Create Account', 'reset_pass': 'Reset Password', 'send_otp': 'Send OTP',
      'full_name_admin': 'Full Name (Admin)', 'full_name_farmer': 'Full Name', 'create_password': 'Create Password',
      'recovery_msg': 'Enter your registered ID to receive a recovery OTP.', 'id_hint': 'Mobile or Email ID',
      'field_req': 'Field Required', 'pass_rec': 'Recommendation: Use at least 8 characters',
      'invalid_email': 'Enter a valid email address (@ and .)', 'dash_scan': 'Scan/Upload Cattle',
      'dash_saved': 'Saved Cattles', 'dash_library': 'Breed Library', 'dash_aadhar': 'Pashu Adhaar',
      'welcome_admin': 'Welcome, Admin!', 'welcome_user': 'Welcome!', 'no_cattles': 'No cattles saved yet.',
      'cattle_record': 'Cattle Record #', 'lib_title': 'Top Indigenous Breeds', 'lib_origin': 'Origin',
      'lib_milk': 'Milk Yield', 'lib_weight': 'Weight', 'lib_height': 'Height', 'lib_lifespan': 'Lifespan',
      'lib_appearance': 'Appearance', 'filter_all': 'All', 'filter_cow': 'Cow', 'filter_buffalo': 'Buffalo',
      'filter_camel': 'Camel', 'coming_soon': 'Coming Soon! Camel breeds will be added in the next update.',
      'voice_btn': 'Voice Guide',
      'voice_script': 'Welcome to the Desi Moo dashboard. Tap the first button to scan cattle. Tap the second to view saved cattle. Tap the third to open the Breed Library. Tap the fourth to access Pashu Mandi for buying and selling.',
      'listen_btn': 'Listen to Details',
      'dialog_info': 'Breed Information', 'dialog_breed': 'Breed', 'dialog_type': 'Type', 'dialog_back': 'Go back',
      'dash_market': 'Pashu Mandi (Buy/Sell)', 'market_title': 'Cattle Marketplace', 'buy_tab': 'Buy',
      'sell_tab': 'Sell', 'price': 'Price: ₹', 'contact_seller': 'Contact Seller', 'list_cattle_btn': 'List Cattle for Sale',
      'form_breed': 'Breed Name', 'form_age': 'Age (Years)', 'form_milk': 'Milk Capacity (Liters)', 'form_price': 'Expected Price (₹)',
      'dialog_diet': 'Recommended Diet' // <-- NEW DIET KEY
    },
    'hi': {
      'select_lang': 'भाषा चुनें', 'welcome': 'स्वागत है!', 'login_user': 'यूजर लॉगिन',
      'login_admin': 'एडमिन लॉगिन', 'enter_mobile': 'मोबाइल नंबर दर्ज करें', 'enter_email': 'ईमेल आईडी दर्ज करें',
      'password': 'पासवर्ड', 'login_btn': 'लॉगिन', 'no_account': 'खाता नहीं है? ',
      'signup_link': 'यहाँ साइन-अप करें', 'forgot_pass': 'पासवर्ड भूल गए?', 'signup_title': 'साइन अप',
      'create_acc': 'खाता बनाएं', 'reset_pass': 'पासवर्ड रीसेट', 'send_otp': 'ओटीपी भेजें',
      'full_name_admin': 'पूरा नाम (एडमिन)', 'full_name_farmer': 'पूरा नाम', 'create_password': 'पासवर्ड बनाएं',
      'recovery_msg': 'रिकवरी ओटीपी प्राप्त करने के लिए अपनी पंजीकृत आईडी दर्ज करें।', 'id_hint': 'मोबाइल या ईमेल आईडी',
      'field_req': 'क्षेत्र आवश्यक है', 'pass_rec': 'सिफारिश: कम से कम 8 वर्णों का उपयोग करें',
      'invalid_email': 'एक वैध ईमेल पता दर्ज करें (@ और .)', 'dash_scan': 'पशु स्कैन/अपलोड करें',
      'dash_saved': 'सहेजे गए पशु', 'dash_library': 'प्रजाति पुस्तकालय', 'dash_aadhar': 'पशु आधार',
      'welcome_admin': 'स्वागत है, एडमिन!', 'welcome_user': 'स्वागत है!', 'no_cattles': 'अभी तक कोई पशु नहीं बचाया गया है।',
      'cattle_record': 'पशु रिकॉर्ड #', 'lib_title': 'शीर्ष स्वदेशी प्रजातियां', 'lib_origin': 'मूल स्थान',
      'lib_milk': 'दूध उत्पादन', 'lib_weight': 'वजन', 'lib_height': 'ऊँचाई', 'lib_lifespan': 'जीवनकाल',
      'lib_appearance': 'दिखावट', 'filter_all': 'सभी', 'filter_cow': 'गाय', 'filter_buffalo': 'भैंस',
      'filter_camel': 'ऊंट', 'coming_soon': 'जल्द आ रहा है! ऊंट की प्रजातियों को अगले अपडेट में जोड़ा जाएगा।',
      'voice_btn': 'आवाज़ गाइड',
      'voice_script': 'देसी मू डैशबोर्ड में आपका स्वागत है। पशु को स्कैन करने के लिए पहला बटन दबाएं। सहेजे गए पशु देखने के लिए दूसरा बटन दबाएं। प्रजाति पुस्तकालय खोलने के लिए तीसरा बटन दबाएं। पशु खरीदने और बेचने के लिए चौथा बटन दबाएं।',
      'listen_btn': 'विवरण सुनें',
      'dialog_info': 'प्रजाति की जानकारी', 'dialog_breed': 'प्रजाति', 'dialog_type': 'प्रकार', 'dialog_back': 'वापस जाएं',
      'dash_market': 'पशु मंडी (खरीदें/बेचें)', 'market_title': 'पशु मंडी', 'buy_tab': 'खरीदें',
      'sell_tab': 'बेचें', 'price': 'कीमत: ₹', 'contact_seller': 'विक्रेता से संपर्क करें', 'list_cattle_btn': 'बिक्री के लिए पशु जोड़ें',
      'form_breed': 'प्रजाति का नाम', 'form_age': 'उम्र (वर्ष)', 'form_milk': 'दूध क्षमता (लीटर)', 'form_price': 'अपेक्षित कीमत (₹)',
      'dialog_diet': 'अनुशंसित आहार' // <-- NEW DIET KEY
    },
    'mr': {
      'select_lang': 'भाषा निवडा', 'welcome': 'स्वागत आहे!', 'login_user': 'वापरकर्ता लॉगिन',
      'login_admin': 'अ‍ॅडमिन लॉगिन', 'enter_mobile': 'मोबाईल नंबर टाका', 'enter_email': 'ईमेल आयडी टाका',
      'password': 'पासवर्ड', 'login_btn': 'लॉगिन', 'no_account': 'खाते नाही? ',
      'signup_link': 'येथे साइन-अप करा', 'forgot_pass': 'पासवर्ड विसरलात?', 'signup_title': 'साइन अप',
      'create_acc': 'खाते तयार करा', 'reset_pass': 'पासवर्ड रीसेट करा', 'send_otp': 'ओटीपी पाठवा',
      'full_name_admin': 'पूर्ण नाव (अ‍ॅडमिन)', 'full_name_farmer': 'पूर्ण नाव', 'create_password': 'पासवर्ड तयार करा',
      'recovery_msg': 'रिकव्हरी ओटीपी मिळवण्यासाठी तुमचा नोंदणीकृत आयडी टाका.', 'id_hint': 'मोबाईल किंवा ईमेल आयडी',
      'field_req': 'क्षेत्र आवश्यक आहे', 'pass_rec': 'शिफारस: किमान 8 अक्षरे वापरा',
      'invalid_email': 'वैध ईमेल पत्ता प्रविष्ट करा (@ आणि .)', 'dash_scan': 'पशु स्कॅन/अपलोड करा',
      'dash_saved': 'जतन केलेले पशु', 'dash_library': 'प्रजाती लायब्ररी', 'dash_aadhar': 'पशु आधार',
      'welcome_admin': 'स्वागत आहे, अ‍ॅडमिन!', 'welcome_user': 'स्वागत आहे!', 'no_cattles': 'अद्याप कोणतेही पशु जतन केलेले नाहीत.',
      'cattle_record': 'पशु रेकॉर्ड #', 'lib_title': 'शीर्ष देशी प्रजाती', 'lib_origin': 'मूळ स्थान',
      'lib_milk': 'दूध उत्पादन', 'lib_weight': 'वजन', 'lib_height': 'उंची', 'lib_lifespan': 'आयुर्मान',
      'lib_appearance': 'स्वरूप', 'filter_all': 'सर्व', 'filter_cow': 'गाय', 'filter_buffalo': 'म्हैस',
      'filter_camel': 'उंट', 'coming_soon': 'लवकरच येत आहे! पुढील अपडेटमध्ये उंटांच्या प्रजाती जोडल्या जातील.',
      'voice_btn': 'आवाज मार्गदर्शक',
      'voice_script': 'देसी मू डॅशबोर्डवर आपले स्वागत आहे. पशु स्कॅन करण्यासाठी पहिले बटण दाबा. जतन केलेले पशु पाहण्यासाठी दुसरे बटण दाबा. प्रजाती लायब्ररी उघडण्यासाठी तिसरे बटण दाबा. पशु खरेदी आणि विक्रीसाठी चौथे बटण दाबा.',
      'listen_btn': 'माहिती ऐका',
      'dialog_info': 'प्रजातीची माहिती', 'dialog_breed': 'प्रजाती', 'dialog_type': 'प्रकार', 'dialog_back': 'मागे जा',
      'dash_market': 'पशु बाजार (खरेदी/विक्री)', 'market_title': 'पशु बाजार', 'buy_tab': 'खरेदी करा',
      'sell_tab': 'विक्री करा', 'price': 'किंमत: ₹', 'contact_seller': 'विक्रेत्याशी संपर्क साधा', 'list_cattle_btn': 'विक्रीसाठी पशु जोडा',
      'form_breed': 'प्रजातीचे नाव', 'form_age': 'वय (वर्षे)', 'form_milk': 'दूध क्षमता (लिटर)', 'form_price': 'अपेक्षित किंमत (₹)',
      'dialog_diet': 'सुचवलेला आहार' // <-- NEW DIET KEY
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

                // --- CONNECTED TO DATABASE: LOGIN LOGIC ---
                _actionButton(translate('login_btn'), () async {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Verifying details..."), duration: Duration(seconds: 1)),
                    );

                    bool isValid = await MongoDatabase.loginUser(
                        _idController.text.trim(),
                        _passController.text.trim(),
                        widget.isAdmin
                    );

                    if (!mounted) return;

                    if (isValid) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(isAdmin: widget.isAdmin)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invalid Credentials or User does not exist!"), backgroundColor: Colors.red)
                      );
                    }
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
class SignUpScreen extends StatefulWidget {
  final bool isAdmin;
  const SignUpScreen({super.key, required this.isAdmin});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- CONNECTED TO DATABASE: REGISTRATION LOGIC ---
  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String result = await MongoDatabase.registerUser(
        _nameController.text.trim(),
        _idController.text.trim(),
        _passController.text.trim(),
        widget.isAdmin,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account Created Successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(isAdmin: widget.isAdmin)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: Text(translate('signup_title'))),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(widget.isAdmin ? translate('full_name_admin') : translate('full_name_farmer')),
                  validator: (v) => v == null || v.isEmpty ? translate('field_req') : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _idController,
                  keyboardType: widget.isAdmin ? TextInputType.emailAddress : TextInputType.phone,
                  decoration: _inputDecoration(widget.isAdmin ? translate('enter_email') : translate('enter_mobile')),
                  validator: (v) => v == null || v.isEmpty ? translate('field_req') : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  decoration: _inputDecoration(translate('create_password')),
                  validator: (v) => v == null || v.length < 8 ? translate('pass_rec') : null,
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF64DD17)))
                    : _actionButton(translate('create_acc'), _handleSignUp),
              ],
            ),
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
            _actionButton(translate('send_otp'), () => debugPrint("Sending recovery email/OTP...")),
          ],
        ),
      ),
    );
  }
}

// --- 7. DASHBOARD SCREEN ---
class DashboardScreen extends StatefulWidget {
  final bool isAdmin;
  const DashboardScreen({super.key, required this.isAdmin});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  tflite.Interpreter? _interpreter;
  List<String>? _labels;
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadModel();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speakGuidance() async {
    if (appLanguage.value == 'hi') {
      await flutterTts.setLanguage("hi-IN");
    } else if (appLanguage.value == 'mr') {
      await flutterTts.setLanguage("mr-IN");
    } else {
      await flutterTts.setLanguage("en-IN");
    }
    await flutterTts.speak(translate('voice_script'));
  }

  // <-- UPDATED VOICE SCRIPT WITH DIET -->
  Future<void> _speakCattleDetails(String breedName, Map<String, String> details) async {
    String lang = appLanguage.value;
    String textToSpeak = "";

    String safeName = details['name'] ?? breedName;
    String safeLifespan = details['lifespan'] ?? "";
    String safeMilk = details['milk'] ?? "";
    String safeOrigin = details['origin'] ?? "";
    String safeDiet = details['diet'] ?? "";

    if (lang == 'hi') {
      await flutterTts.setLanguage("hi-IN");
      safeLifespan = safeLifespan.replaceAll('-', ' से ');
      safeMilk = safeMilk.replaceAll('-', ' से ');
      textToSpeak = "यह $safeName प्रजाति है। इसका मूल स्थान $safeOrigin है। इसका जीवनकाल $safeLifespan है, और यह प्रतिदिन $safeMilk देती है। इसका अनुशंसित आहार है: $safeDiet";
    } else if (lang == 'mr') {
      await flutterTts.setLanguage("mr-IN");
      safeLifespan = safeLifespan.replaceAll('-', ' ते ');
      safeMilk = safeMilk.replaceAll('-', ' ते ');
      textToSpeak = "ही $safeName प्रजाती आहे. याचे मूळ स्थान $safeOrigin आहे. याचे आयुर्मान $safeLifespan आहे, आणि हे दररोज $safeMilk देते. याचा सुचवलेला आहार आहे: $safeDiet";
    } else {
      await flutterTts.setLanguage("en-IN");
      safeLifespan = safeLifespan.replaceAll('-', ' to ');
      safeMilk = safeMilk.replaceAll('-', ' to ');
      textToSpeak = "This is the $safeName breed. It originates from $safeOrigin. It has a lifespan of $safeLifespan, and produces $safeMilk. Its recommended diet is: $safeDiet";
    }

    await flutterTts.speak(textToSpeak);
  }

  Future<void> _loadModel() async {
    try {
      final options = tflite.InterpreterOptions();
      if (Platform.isAndroid) {
        options.useNnApiForAndroid = true;
      }
      _interpreter = await tflite.Interpreter.fromAsset('assets/model/best_float16.tflite', options: options);
      final labelData = await DefaultAssetBundle.of(context).loadString('assets/model/labels.txt');
      _labels = labelData.split('\n').where((s) => s.isNotEmpty).toList();
      debugPrint("Model Loaded Successfully");
    } catch (e) {
      debugPrint("Error loading model: $e");
    }
  }

  // --- UPDATED: DATABASE WITH DIET PLANS ---
  Map<String, String> getBreedInfo(String breedName) {
    String searchKey = breedName.toLowerCase().trim();
    String lang = appLanguage.value;

    Map<String, Map<String, String>> breedData;

    if (lang == 'hi') {
      breedData = {
        'gir': {'name': 'गिर', 'type': 'गाय', 'origin': 'गुजरात (सौराष्ट्र)', 'lifespan': '12-15 वर्ष', 'milk': '12-20 लीटर/दिन', 'weight': '385-545 किग्रा', 'height': '130-140 सेमी', 'appearance': 'उत्तल माथा, लंबे लटकते कान, लाल/धब्बेदार।', 'diet': 'हरा चारा (15-20 किलो), सूखा चारा (5-7 किलो), दाना (3-4 किलो), खनिज (50 ग्राम)।'},
        'sahiwal': {'name': 'साहीवाल', 'type': 'गाय', 'origin': 'पंजाब/हरियाणा', 'lifespan': '14-16 वर्ष', 'milk': '10-15 लीटर/दिन', 'weight': '400-500 किग्रा', 'height': '120-130 सेमी', 'appearance': 'लाल-भूरा रंग, भारी त्वचा की सिलवटें।', 'diet': 'हरा चारा (15-20 किलो), सूखा चारा (5-7 किलो), दाना (3-4 किलो), खनिज (50 ग्राम)।'},
        'kankrej': {'name': 'कांक्रेज', 'type': 'गाय', 'origin': 'गुजरात/राजस्थान', 'lifespan': '12-16 वर्ष', 'milk': '8-10 लीटर/दिन', 'weight': '420-590 किग्रा', 'height': '130-140 सेमी', 'appearance': 'चांदी-भूरा रंग, बड़े मजबूत सींग।', 'diet': 'सूखा चारा (6-8 किलो), चराई, दाना मिश्रण (2 किलो) और नमक।'},
        'ongole': {'name': 'ओंगोल', 'type': 'गाय', 'origin': 'आंध्र प्रदेश', 'lifespan': '15-20 वर्ष', 'milk': '5-8 लीटर/दिन', 'weight': '430-500 किग्रा', 'height': '135-150 सेमी', 'appearance': 'सफेद रंग, बड़ा कूबड़, मांसल शरीर।', 'diet': 'सूखा चारा (6-8 किलो), चराई, दाना मिश्रण (2 किलो) और नमक।'},
        'red sindhi': {'name': 'लाल सिंधी', 'type': 'गाय', 'origin': 'सिंध/राजस्थान', 'lifespan': '12-15 वर्ष', 'milk': '12-18 लीटर/दिन', 'weight': '300-450 किग्रा', 'height': '115-130 सेमी', 'appearance': 'गहरा लाल रंग, गठीला शरीर, मोटे सींग।', 'diet': 'हरा चारा (15-20 किलो), सूखा चारा (5-7 किलो), दाना (3-4 किलो), खनिज (50 ग्राम)।'},
        'tharparkar': {'name': 'थारपारकर', 'type': 'गाय', 'origin': 'राजस्थान', 'lifespan': '14-18 वर्ष', 'milk': '10-14 लीटर/दिन', 'weight': '400-500 किग्रा', 'height': '120-140 सेमी', 'appearance': 'सफेद/हल्का भूरा रंग।', 'diet': 'हरा चारा (15-20 किलो), सूखा चारा (5-7 किलो), दाना (3-4 किलो), खनिज (50 ग्राम)।'},
        'rathi': {'name': 'राठी', 'type': 'गाय', 'origin': 'राजस्थान', 'lifespan': '13-15 वर्ष', 'milk': '8-12 लीटर/दिन', 'weight': '280-350 किग्रा', 'height': '115-125 सेमी', 'appearance': 'सफेद धब्बों के साथ भूरा रंग।', 'diet': 'हरा चारा (15-20 किलो), सूखा चारा (5-7 किलो), दाना (3-4 किलो), खनिज (50 ग्राम)।'},
        'hariana': {'name': 'हरियाणवी', 'type': 'गाय', 'origin': 'हरियाणा', 'lifespan': '14-18 वर्ष', 'milk': '8-12 लीटर/दिन', 'weight': '350-500 किग्रा', 'height': '130-140 सेमी', 'appearance': 'सफेद या हल्का भूरा, लंबा चेहरा।', 'diet': 'सूखा चारा (6-8 किलो), चराई, दाना मिश्रण (2 किलो) और नमक।'},
        'deoni': {'name': 'देओनी', 'type': 'गाय', 'origin': 'महाराष्ट्र/कर्नाटक', 'lifespan': '12-15 वर्ष', 'milk': '6-10 लीटर/दिन', 'weight': '400-500 किग्रा', 'height': '120-135 सेमी', 'appearance': 'काले और सफेद धब्बे, लटकते कान।', 'diet': 'हरा चारा (15-20 किलो), सूखा चारा (5-7 किलो), दाना (3-4 किलो), खनिज (50 ग्राम)।'},
        'malnad gidda': {'name': 'मलनाड गिड्डा', 'type': 'गाय (बौनी)', 'origin': 'कर्नाटक', 'lifespan': '10-14 वर्ष', 'milk': '2-4 लीटर/दिन', 'weight': '120-200 किग्रा', 'height': '90-100 सेमी', 'appearance': 'छोटा कद, रोग प्रतिरोधी, फुर्तीली।', 'diet': 'चराई, सूखा चारा (2-3 किलो), और कम दाना।'},
        'banni': {'name': 'बन्नी', 'type': 'भैंस', 'origin': 'गुजरात (कच्छ)', 'lifespan': '15-20 वर्ष', 'milk': '12-15 लीटर/दिन', 'weight': '450-550 किग्रा', 'height': '130-140 सेमी', 'appearance': 'रात में चरने वाली, घुमावदार सींग।', 'diet': 'हरा चारा (20-25 किलो), सूखा चारा (8-10 किलो), उच्च प्रोटीन दाना (4-5 किलो), कैल्शियम।'},
        'jaffarabadi': {'name': 'जाफराबादी', 'type': 'भैंस', 'origin': 'गुजरात', 'lifespan': '18-22 वर्ष', 'milk': '15-20 लीटर/दिन', 'weight': '700-800 किग्रा', 'height': '140-150 सेमी', 'appearance': 'भारी शरीर, लटकते सींग।', 'diet': 'हरा चारा (20-25 किलो), सूखा चारा (8-10 किलो), उच्च प्रोटीन दाना (4-5 किलो), कैल्शियम।'},
        'nili ravi': {'name': 'नीली रावी', 'type': 'भैंस', 'origin': 'पंजाब', 'lifespan': '14-18 वर्ष', 'milk': '12-18 लीटर/दिन', 'weight': '500-600 किग्रा', 'height': '130-140 सेमी', 'appearance': 'सफेद आंखें, चेहरे और पैरों पर सफेद निशान।', 'diet': 'हरा चारा (20-25 किलो), सूखा चारा (8-10 किलो), उच्च प्रोटीन दाना (4-5 किलो), कैल्शियम।'},
        'mehsana': {'name': 'मेहसाणा', 'type': 'भैंस', 'origin': 'गुजरात', 'lifespan': '15-20 वर्ष', 'milk': '10-15 लीटर/दिन', 'weight': '450-550 किग्रा', 'height': '130-140 सेमी', 'appearance': 'मुर्रा और सुरती का संकर, दरांती जैसे सींग।', 'diet': 'हरा चारा (20-25 किलो), सूखा चारा (8-10 किलो), उच्च प्रोटीन दाना (4-5 किलो), कैल्शियम।'},
        'nagpuri': {'name': 'नागपुरी', 'type': 'भैंस', 'origin': 'महाराष्ट्र', 'lifespan': '15-18 वर्ष', 'milk': '5-8 लीटर/दिन', 'weight': '350-450 किग्रा', 'height': '120-130 सेमी', 'appearance': 'लंबे और चपटे तलवार जैसे सींग।', 'diet': 'हरा चारा (20-25 किलो), सूखा चारा (8-10 किलो), उच्च प्रोटीन दाना (4-5 किलो), कैल्शियम।'},
        'toda': {'name': 'टोडा', 'type': 'भैंस', 'origin': 'तमिलनाडु', 'lifespan': '15-18 वर्ष', 'milk': '4-6 लीटर/दिन', 'weight': '350-400 किग्रा', 'height': '120-130 सेमी', 'appearance': 'भूरा रंग, विशिष्ट अर्धचंद्राकार सींग।', 'diet': 'हरा चारा (20-25 किलो), सूखा चारा (8-10 किलो), उच्च प्रोटीन दाना (4-5 किलो), कैल्शियम।'}
      };
    } else if (lang == 'mr') {
      breedData = {
        'gir': {'name': 'गीर', 'type': 'गाय', 'origin': 'गुजरात (सौराष्ट्र)', 'lifespan': '12-15 वर्षे', 'milk': '12-20 लिटर/दिवस', 'weight': '385-545 किलो', 'height': '130-140 सेमी', 'appearance': 'बहिर्वक्र कपाळ, लांब लोंबकळणारे कान, लाल/ठिपकेदार.', 'diet': 'हिरवा चारा (15-20 किलो), सुका चारा (5-7 किलो), पशुखाद्य (3-4 किलो), खनिज (50 ग्रॅम).'},
        'sahiwal': {'name': 'साहीवाल', 'type': 'गाय', 'origin': 'पंजाब/हरियाणा', 'lifespan': '14-16 वर्षे', 'milk': '10-15 लिटर/दिवस', 'weight': '400-500 किलो', 'height': '120-130 सेमी', 'appearance': 'लाल-तपकिरी रंग, त्वचेच्या घड्या.', 'diet': 'हिरवा चारा (15-20 किलो), सुका चारा (5-7 किलो), पशुखाद्य (3-4 किलो), खनिज (50 ग्रॅम).'},
        'kankrej': {'name': 'कांकरेज', 'type': 'गाय', 'origin': 'गुजरात/राजस्थान', 'lifespan': '12-16 वर्षे', 'milk': '8-10 लिटर/दिवस', 'weight': '420-590 किलो', 'height': '130-140 सेमी', 'appearance': 'चांदी-तपकिरी रंग, मोठी मजबूत शिंगे.', 'diet': 'सुका चारा (6-8 किलो), चराई, पशुखाद्य (2 किलो) आणि मीठ.'},
        'ongole': {'name': 'ओंगोल', 'type': 'गाय', 'origin': 'आंध्र प्रदेश', 'lifespan': '15-20 वर्षे', 'milk': '5-8 लिटर/दिवस', 'weight': '430-500 किलो', 'height': '135-150 सेमी', 'appearance': 'पांढरा रंग, मोठे वशिंड, मजबूत शरीर.', 'diet': 'सुका चारा (6-8 किलो), चराई, पशुखाद्य (2 किलो) आणि मीठ.'},
        'red sindhi': {'name': 'लाल सिंधी', 'type': 'गाय', 'origin': 'सिंध/राजस्थान', 'lifespan': '12-15 वर्षे', 'milk': '12-18 लिटर/दिवस', 'weight': '300-450 किलो', 'height': '115-130 सेमी', 'appearance': 'गडद लाल रंग, कॉम्पॅक्ट फ्रेम.', 'diet': 'हिरवा चारा (15-20 किलो), सुका चारा (5-7 किलो), पशुखाद्य (3-4 किलो), खनिज (50 ग्रॅम).'},
        'tharparkar': {'name': 'थारपारकर', 'type': 'गाय', 'origin': 'राजस्थान', 'lifespan': '14-18 वर्षे', 'milk': '10-14 लिटर/दिवस', 'weight': '400-500 किलो', 'height': '120-140 सेमी', 'appearance': 'पांढरा/फिकट राखाडी रंग.', 'diet': 'हिरवा चारा (15-20 किलो), सुका चारा (5-7 किलो), पशुखाद्य (3-4 किलो), खनिज (50 ग्रॅम).'},
        'rathi': {'name': 'राठी', 'type': 'गाय', 'origin': 'राजस्थान', 'lifespan': '13-15 वर्षे', 'milk': '8-12 लिटर/दिवस', 'weight': '280-350 किलो', 'height': '115-125 सेमी', 'appearance': 'पांढऱ्या ठिपक्यांसह तपकिरी रंग.', 'diet': 'हिरवा चारा (15-20 किलो), सुका चारा (5-7 किलो), पशुखाद्य (3-4 किलो), खनिज (50 ग्रॅम).'},
        'hariana': {'name': 'हरियाणवी', 'type': 'गाय', 'origin': 'हरियाणा', 'lifespan': '14-18 वर्षे', 'milk': '8-12 लिटर/दिवस', 'weight': '350-500 किलो', 'height': '130-140 सेमी', 'appearance': 'पांढरा किंवा फिकट राखाडी, लांब चेहरा.', 'diet': 'सुका चारा (6-8 किलो), चराई, पशुखाद्य (2 किलो) आणि मीठ.'},
        'deoni': {'name': 'देवणी', 'type': 'गाय', 'origin': 'महाराष्ट्र/कर्नाटक', 'lifespan': '12-15 वर्षे', 'milk': '6-10 लिटर/दिवस', 'weight': '400-500 किलो', 'height': '120-135 सेमी', 'appearance': 'काळे आणि पांढरे ठिपके, लोंबकळणारे कान.', 'diet': 'हिरवा चारा (15-20 किलो), सुका चारा (5-7 किलो), पशुखाद्य (3-4 किलो), खनिज (50 ग्रॅम).'},
        'malnad gidda': {'name': 'मलनाड गिड्डा', 'type': 'गाय (बुटकी)', 'origin': 'कर्नाटक', 'lifespan': '10-14 वर्षे', 'milk': '2-4 लिटर/दिवस', 'weight': '120-200 किलो', 'height': '90-100 सेमी', 'appearance': 'लहान उंची, रोगप्रतिकारक, चपळ.', 'diet': 'चराई, सुका चारा (2-3 किलो), आणि थोडे पशुखाद्य.'},
        'banni': {'name': 'बन्नी', 'type': 'म्हैस', 'origin': 'गुजरात (कच्छ)', 'lifespan': '15-20 वर्षे', 'milk': '12-15 लिटर/दिवस', 'weight': '450-550 किलो', 'height': '130-140 सेमी', 'appearance': 'रात्री चरणाऱ्या, वळलेली शिंगे.', 'diet': 'हिरवा चारा (20-25 किलो), सुका चारा (8-10 किलो), उच्च प्रथिनेयुक्त पशुखाद्य (4-5 किलो).'},
        'jaffarabadi': {'name': 'जाफराबादी', 'type': 'म्हैस', 'origin': 'गुजरात', 'lifespan': '18-22 वर्षे', 'milk': '15-20 लिटर/दिवस', 'weight': '700-800 किलो', 'height': '140-150 सेमी', 'appearance': 'जड शरीर, लोंबकळणारी शिंगे.', 'diet': 'हिरवा चारा (20-25 किलो), सुका चारा (8-10 किलो), उच्च प्रथिनेयुक्त पशुखाद्य (4-5 किलो).'},
        'nili ravi': {'name': 'नीली रावी', 'type': 'म्हैस', 'origin': 'पंजाब', 'lifespan': '14-18 वर्षे', 'milk': '12-18 लिटर/दिवस', 'weight': '500-600 किलो', 'height': '130-140 सेमी', 'appearance': 'पांढरे डोळे, चेहरा आणि पायांवर पांढरे डाग.', 'diet': 'हिरवा चारा (20-25 किलो), सुका चारा (8-10 किलो), उच्च प्रथिनेयुक्त पशुखाद्य (4-5 किलो).'},
        'mehsana': {'name': 'मेहसाणा', 'type': 'म्हैस', 'origin': 'गुजरात', 'lifespan': '15-20 वर्षे', 'milk': '10-15 लिटर/दिवस', 'weight': '450-550 किलो', 'height': '130-140 सेमी', 'appearance': 'विळ्याच्या आकाराची शिंगे.', 'diet': 'हिरवा चारा (20-25 किलो), सुका चारा (8-10 किलो), उच्च प्रथिनेयुक्त पशुखाद्य (4-5 किलो).'},
        'nagpuri': {'name': 'नागपुरी', 'type': 'म्हैस', 'origin': 'महाराष्ट्र', 'lifespan': '15-18 वर्षे', 'milk': '5-8 लिटर/दिवस', 'weight': '350-450 किलो', 'height': '120-130 सेमी', 'appearance': 'लांब आणि सपाट तलवारीसारखी शिंगे.', 'diet': 'हिरवा चारा (20-25 किलो), सुका चारा (8-10 किलो), उच्च प्रथिनेयुक्त पशुखाद्य (4-5 किलो).'},
        'toda': {'name': 'टोडा', 'type': 'म्हैस', 'origin': 'तमिळनाडू', 'lifespan': '15-18 वर्षे', 'milk': '4-6 लिटर/दिवस', 'weight': '350-400 किलो', 'height': '120-130 सेमी', 'appearance': 'राखाडी रंग, अर्धचंद्राकृती शिंगे.', 'diet': 'हिरवा चारा (20-25 किलो), सुका चारा (8-10 किलो), उच्च प्रथिनेयुक्त पशुखाद्य (4-5 किलो).'}
      };
    } else {
      breedData = {
        'gir': {'name': 'Gir', 'type': 'Cow', 'origin': 'Gujarat (Saurashtra)', 'lifespan': '12-15 years', 'milk': '12-20 Liters/day', 'weight': '385kg - 545kg', 'height': '130 - 140 cm', 'appearance': 'Convex forehead, long pendulous ears, red/spotted.', 'diet': 'Green fodder (15-20kg), Dry fodder (5-7kg), Concentrate (3-4kg), Minerals (50g).'},
        'sahiwal': {'name': 'Sahiwal', 'type': 'Cow', 'origin': 'Punjab/Haryana', 'lifespan': '14-16 years', 'milk': '10-15 Liters/day', 'weight': '400kg - 500kg', 'height': '120 - 130 cm', 'appearance': 'Reddish brown color, heavy skin folds, prominent dewlap.', 'diet': 'Green fodder (15-20kg), Dry fodder (5-7kg), Concentrate (3-4kg), Minerals (50g).'},
        'kankrej': {'name': 'Kankrej', 'type': 'Cow', 'origin': 'Gujarat/Rajasthan', 'lifespan': '12-16 years', 'milk': '8-10 Liters/day', 'weight': '420kg - 590kg', 'height': '130 - 140 cm', 'appearance': 'Silver-grey to iron-grey, large strong crescent horns.', 'diet': 'Dry fodder (6-8kg), Grazing, Concentrate (2kg), and Salt.'},
        'ongole': {'name': 'Ongole', 'type': 'Cow', 'origin': 'Andhra Pradesh', 'lifespan': '15-20 years', 'milk': '5-8 Liters/day', 'weight': '430kg - 500kg', 'height': '135 - 150 cm', 'appearance': 'Glossy white, huge hump, short horns, muscular build.', 'diet': 'Dry fodder (6-8kg), Grazing, Concentrate (2kg), and Salt.'},
        'red sindhi': {'name': 'Red Sindhi', 'type': 'Cow', 'origin': 'Sindh/Rajasthan', 'lifespan': '12-15 years', 'milk': '12-18 Liters/day', 'weight': '300kg - 450kg', 'height': '115 - 130 cm', 'appearance': 'Deep red color, compact frame, thick horns.', 'diet': 'Green fodder (15-20kg), Dry fodder (5-7kg), Concentrate (3-4kg), Minerals (50g).'},
        'tharparkar': {'name': 'Tharparkar', 'type': 'Cow', 'origin': 'Rajasthan', 'lifespan': '14-18 years', 'milk': '10-14 Liters/day', 'weight': '400kg - 500kg', 'height': '120 - 140 cm', 'appearance': 'White/light grey color, lyre-shaped horns.', 'diet': 'Green fodder (15-20kg), Dry fodder (5-7kg), Concentrate (3-4kg), Minerals (50g).'},
        'rathi': {'name': 'Rathi', 'type': 'Cow', 'origin': 'Rajasthan', 'lifespan': '13-15 years', 'milk': '8-12 Liters/day', 'weight': '280kg - 350kg', 'height': '115 - 125 cm', 'appearance': 'Brown with white patches, medium horns, efficient in arid regions.', 'diet': 'Green fodder (15-20kg), Dry fodder (5-7kg), Concentrate (3-4kg), Minerals (50g).'},
        'hariana': {'name': 'Hariana', 'type': 'Cow', 'origin': 'Haryana', 'lifespan': '14-18 years', 'milk': '8-12 Liters/day', 'weight': '350kg - 500kg', 'height': '130 - 140 cm', 'appearance': 'White or light grey, long narrow face, small horns.', 'diet': 'Dry fodder (6-8kg), Grazing, Concentrate (2kg), and Salt.'},
        'deoni': {'name': 'Deoni', 'type': 'Cow', 'origin': 'Maharashtra/Karnataka', 'lifespan': '12-15 years', 'milk': '6-10 Liters/day', 'weight': '400kg - 500kg', 'height': '120 - 135 cm', 'appearance': 'Black and white patches, prominent forehead, drooping ears.', 'diet': 'Green fodder (15-20kg), Dry fodder (5-7kg), Concentrate (3-4kg), Minerals (50g).'},
        'malnad gidda': {'name': 'Malnad Gidda', 'type': 'Cow (Dwarf)', 'origin': 'Karnataka', 'lifespan': '10-14 years', 'milk': '2-4 Liters/day', 'weight': '120kg - 200kg', 'height': '90 - 100 cm', 'appearance': 'Small/dwarf stature, highly disease resistant, agile.', 'diet': 'Grazing, Dry fodder (2-3kg), and minimal concentrate.'},
        'banni': {'name': 'Banni', 'type': 'Buffalo', 'origin': 'Gujarat (Kutch)', 'lifespan': '15-20 years', 'milk': '12-15 Liters/day', 'weight': '450kg - 550kg', 'height': '130 - 140 cm', 'appearance': 'Night grazers, black, typical coiled horns.', 'diet': 'Green fodder (20-25kg), Dry fodder (8-10kg), High-protein concentrate (4-5kg).'},
        'jaffarabadi': {'name': 'Jaffarabadi', 'type': 'Buffalo', 'origin': 'Gujarat', 'lifespan': '18-22 years', 'milk': '15-20 Liters/day', 'weight': '700kg - 800kg', 'height': '140 - 150 cm', 'appearance': 'Heavy built, massive body, drooping horns.', 'diet': 'Green fodder (20-25kg), Dry fodder (8-10kg), High-protein concentrate (4-5kg).'},
        'nili ravi': {'name': 'Nili Ravi', 'type': 'Buffalo', 'origin': 'Punjab', 'lifespan': '14-18 years', 'milk': '12-18 Liters/day', 'weight': '500kg - 600kg', 'height': '130 - 140 cm', 'appearance': 'Wall eyes, white markings on face and legs.', 'diet': 'Green fodder (20-25kg), Dry fodder (8-10kg), High-protein concentrate (4-5kg).'},
        'mehsana': {'name': 'Mehsana', 'type': 'Buffalo', 'origin': 'Gujarat', 'lifespan': '15-20 years', 'milk': '10-15 Liters/day', 'weight': '450kg - 550kg', 'height': '130 - 140 cm', 'appearance': 'Cross between Murrah and Surti, sickle-shaped horns.', 'diet': 'Green fodder (20-25kg), Dry fodder (8-10kg), High-protein concentrate (4-5kg).'},
        'nagpuri': {'name': 'Nagpuri', 'type': 'Buffalo', 'origin': 'Maharashtra', 'lifespan': '15-18 years', 'milk': '5-8 Liters/day', 'weight': '350kg - 450kg', 'height': '120 - 130 cm', 'appearance': 'Long, flat, sword-shaped horns.', 'diet': 'Green fodder (20-25kg), Dry fodder (8-10kg), High-protein concentrate (4-5kg).'},
        'toda': {'name': 'Toda', 'type': 'Buffalo', 'origin': 'Tamil Nadu', 'lifespan': '15-18 years', 'milk': '4-6 Liters/day', 'weight': '350kg - 400kg', 'height': '120 - 130 cm', 'appearance': 'Fawn to ash-grey color, distinct crescent-shaped horns.', 'diet': 'Green fodder (20-25kg), Dry fodder (8-10kg), High-protein concentrate (4-5kg).'}
      };
    }

    for (String key in breedData.keys) {
      if (searchKey.contains(key)) return breedData[key]!;
    }

    return {
      'type': 'Cattle', 'name': breedName, 'origin': 'Unknown/Mixed', 'lifespan': '10-20 years',
      'milk': 'Data unavailable', 'weight': 'Data unavailable', 'height': 'Data unavailable',
      'appearance': 'Could not accurately pull specific breed traits.', 'diet': 'General cattle feed'
    };
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Upload from Gallery'),
              onTap: () { Navigator.pop(bottomSheetContext); _scanCattle(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Capture with Camera'),
              onTap: () { Navigator.pop(bottomSheetContext); _scanCattle(ImageSource.camera); },
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _performAIClassification(String imagePath) async {
    if (_interpreter == null || _labels == null) return "Model Not Loaded";
    try {
      var imageBytes = File(imagePath).readAsBytesSync();
      img.Image? oriImage = img.decodeImage(imageBytes);
      if (oriImage == null) return "Error Decoding Image";

      img.Image resizedImage = img.copyResize(oriImage, width: 640, height: 640);
      var input = Float32List(1 * 640 * 640 * 3);
      var bufferIndex = 0;
      for (var y = 0; y < 640; y++) {
        for (var x = 0; x < 640; x++) {
          var pixel = resizedImage.getPixel(x, y);
          input[bufferIndex++] = pixel.r / 255.0;
          input[bufferIndex++] = pixel.g / 255.0;
          input[bufferIndex++] = pixel.b / 255.0;
        }
      }

      int outputElements = 36;
      var output = List.filled(1 * outputElements * 8400, 0.0).reshape([1, outputElements, 8400]);
      _interpreter!.run(input.reshape([1, 640, 640, 3]), output);

      double maxScore = -1;
      int bestIdx = -1;
      int totalModelClasses = 32;

      for (int i = 0; i < 8400; i++) {
        for (int c = 0; c < totalModelClasses; c++) {
          double score = output[0][4 + c][i];
          if (score > maxScore) { maxScore = score; bestIdx = c; }
        }
      }

      debugPrint("====== AI DIAGNOSTICS ======");
      debugPrint("Max Confidence Score: $maxScore");
      debugPrint("Winning Class Index: $bestIdx");
      debugPrint("Total Labels in txt: ${_labels!.length}");
      debugPrint("============================");

      if (bestIdx != -1) {
        if (bestIdx < _labels!.length) { return _labels![bestIdx].trim(); }
        else { return "Model Guessed Class #$bestIdx"; }
      }
      return "Unknown Breed";
    } catch (e) {
      debugPrint("Inference Error: $e");
      return "Inference Error";
    }
  }

  Future<void> _scanCattle(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(toolbarTitle: 'Focus on Cattle', toolbarColor: const Color(0xFF64DD17), toolbarWidgetColor: Colors.white, initAspectRatio: CropAspectRatioPreset.original, lockAspectRatio: false),
            IOSUiSettings(title: 'Focus on Cattle'),
          ],
        );
        if (croppedFile != null) {
          String breed = await _performAIClassification(croppedFile.path);
          if (!mounted) return;
          savedCattles.value = List.from(savedCattles.value)..add(croppedFile.path);
          _showResultDialog(context, breed, croppedFile.path);
        }
      }
    } catch (e) {
      debugPrint("Error during scan/crop: $e");
    }
  }

  void _showResultDialog(BuildContext context, String breed, String imagePath) {
    final details = getBreedInfo(breed);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), color: const Color(0xFF64DD17),
                    child: Center(child: Text(translate('dialog_info'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(imagePath), height: 200, width: double.infinity, fit: BoxFit.contain),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoText("${translate('dialog_breed')} :- ${details['name'] ?? breed}"),
                        _infoText("${translate('dialog_type')}: ${details['type'] ?? ''}"),
                        _infoText("${translate('lib_origin')}: ${details['origin'] ?? ''}"),
                        _infoText("${translate('lib_lifespan')}: ${details['lifespan'] ?? ''}"),
                        _infoText("${translate('lib_milk')}: ${details['milk'] ?? ''}"),
                        _infoText("${translate('lib_weight')} :- ${details['weight'] ?? ''}"),
                        _infoText("${translate('lib_height')} :- ${details['height'] ?? ''}"),
                        _infoText("${translate('lib_appearance')}: ${details['appearance'] ?? ''}"),
                        const Divider(),
                        _infoText("${translate('dialog_diet')}: ${details['diet'] ?? ''}"), // <-- ADDED DIET TO UI
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.volume_up, color: Colors.white),
                            label: Text(translate('listen_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () => _speakCattleDetails(breed, details),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF64DD17),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              flutterTts.stop();
                              Navigator.pop(context);
                            },
                            child: Text(translate('dialog_back'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(height: 35, width: double.infinity, color: const Color(0xFF64DD17)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoText(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF64DD17),
        title: Text(widget.isAdmin ? translate('welcome_admin') : translate('welcome_user'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                flutterTts.stop();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()));
              }
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _speakGuidance,
        backgroundColor: const Color(0xFF64DD17),
        icon: const Icon(Icons.record_voice_over, color: Colors.white),
        label: Text(translate('voice_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/farmer_cattles.png',
                width: double.infinity, fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200, color: Colors.grey[200], child: const Center(child: Text("Image not found in assets", style: TextStyle(color: Colors.red))),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                children: [
                  _dashButton(Icons.camera_alt_outlined, translate('dash_scan'), () => _showImageSourceDialog(context)),
                  const SizedBox(height: 20),
                  _dashButton(Icons.bookmark_outline, translate('dash_saved'), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedCattlesScreen()))),
                  const SizedBox(height: 20),
                  _dashButton(Icons.book_outlined, translate('dash_library'), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BreedLibraryScreen()))),
                  const SizedBox(height: 20),
                  _dashButton(Icons.storefront, translate('dash_market'), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MarketplaceScreen()))),
                  if (widget.isAdmin) ...[
                    const SizedBox(height: 20),
                    _dashButton(Icons.badge_outlined, translate('dash_aadhar'), () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PashuAadhaarRegistrationScreen()));
                    }),
                  ],
                  const SizedBox(height: 80),
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
            const SizedBox(width: 15), Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 15), Text(label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter?.close();
    flutterTts.stop();
    super.dispose();
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
            return Center(child: Text(translate('no_cattles'), style: const TextStyle(fontSize: 18, color: Colors.grey)));
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
                    child: CircleAvatar(radius: 35, backgroundImage: FileImage(File(imagePath))),
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

// --- 9. BREED LIBRARY SCREEN ---
class BreedLibraryScreen extends StatefulWidget {
  const BreedLibraryScreen({super.key});

  @override
  State<BreedLibraryScreen> createState() => _BreedLibraryScreenState();
}

class _BreedLibraryScreenState extends State<BreedLibraryScreen> {
  String _selectedFilter = 'All';

  List<Map<String, String>> getLocalizedBreeds(String lang) {
    if (lang == 'hi') {
      return [
        {'category': 'Cow', 'name': 'गिर', 'type': 'गाय', 'origin': 'गुजरात', 'lifespan': '12-15 वर्ष', 'milk': '12-20 लीटर/दिन', 'weight': '385-545 किग्रा', 'height': '130-140 सेमी', 'appearance': 'उत्तल माथा, लंबे लटकते कान, लाल/धब्बेदार।', 'image': 'assets/breeds/gir.jpg'},
        {'category': 'Cow', 'name': 'साहीवाल', 'type': 'गाय', 'origin': 'पंजाब/हरियाणा', 'lifespan': '14-16 वर्ष', 'milk': '10-15 लीटर/दिन', 'weight': '400-500 किग्रा', 'height': '120-130 सेमी', 'appearance': 'लाल-भूरा रंग, भारी त्वचा की सिलवटें।', 'image': 'assets/breeds/sahiwal.jpg'},
        {'category': 'Cow', 'name': 'कांक्रेज', 'type': 'गाय', 'origin': 'गुजरात/राजस्थान', 'lifespan': '12-16 वर्ष', 'milk': '8-10 लीटर/दिन', 'weight': '420-590 किग्रा', 'height': '130-140 सेमी', 'appearance': 'चांदी-भूरा रंग, बड़े मजबूत सींग।', 'image': 'assets/breeds/kankrej.jpg'},
        {'category': 'Cow', 'name': 'ओंगोल', 'type': 'गाय', 'origin': 'आंध्र प्रदेश', 'lifespan': '15-20 वर्ष', 'milk': '5-8 लीटर/दिन', 'weight': '430-500 किग्रा', 'height': '135-150 सेमी', 'appearance': 'सफेद रंग, बड़ा कूबड़, मांसल शरीर।', 'image': 'assets/breeds/ongole.jpg'},
        {'category': 'Cow', 'name': 'लाल सिंधी', 'type': 'गाय', 'origin': 'सिंध/राजस्थान', 'lifespan': '12-15 वर्ष', 'milk': '12-18 लीटर/दिन', 'weight': '300-450 किग्रा', 'height': '115-130 सेमी', 'appearance': 'गहरा लाल रंग, गठीला शरीर, मोटे सींग।', 'image': 'assets/breeds/red_sindhi.jpg'},
        {'category': 'Cow', 'name': 'थारपारकर', 'type': 'गाय', 'origin': 'राजस्थान', 'lifespan': '14-18 वर्ष', 'milk': '10-14 लीटर/दिन', 'weight': '400-500 किग्रा', 'height': '120-140 सेमी', 'appearance': 'सफेद/हल्का भूरा रंग।', 'image': 'assets/breeds/tharparkar.jpg'},
        {'category': 'Cow', 'name': 'राठी', 'type': 'गाय', 'origin': 'राजस्थान', 'lifespan': '13-15 वर्ष', 'milk': '8-12 लीटर/दिन', 'weight': '280-350 किग्रा', 'height': '115-125 सेमी', 'appearance': 'सफेद धब्बों के साथ भूरा रंग।', 'image': 'assets/breeds/rathi.jpg'},
        {'category': 'Cow', 'name': 'हरियाणवी', 'type': 'गाय', 'origin': 'हरियाणा', 'lifespan': '14-18 वर्ष', 'milk': '8-12 लीटर/दिन', 'weight': '350-500 किग्रा', 'height': '130-140 सेमी', 'appearance': 'सफेद या हल्का भूरा, लंबा चेहरा।', 'image': 'assets/breeds/hariana.jpg'},
        {'category': 'Cow', 'name': 'देओनी', 'type': 'गाय', 'origin': 'महाराष्ट्र/कर्नाटक', 'lifespan': '12-15 वर्ष', 'milk': '6-10 लीटर/दिन', 'weight': '400-500 किग्रा', 'height': '120-135 सेमी', 'appearance': 'काले और सफेद धब्बे, लटकते कान।', 'image': 'assets/breeds/deoni.jpg'},
        {'category': 'Cow', 'name': 'मलनाड गिड्डा', 'type': 'गाय (बौनी)', 'origin': 'कर्नाटक', 'lifespan': '10-14 वर्ष', 'milk': '2-4 लीटर/दिन', 'weight': '120-200 किग्रा', 'height': '90-100 सेमी', 'appearance': 'छोटा कद, रोग प्रतिरोधी, फुर्तीली।', 'image': 'assets/breeds/malnad_gidda.jpg'},
        {'category': 'Buffalo', 'name': 'बन्नी', 'type': 'भैंस', 'origin': 'गुजरात (कच्छ)', 'lifespan': '15-20 वर्ष', 'milk': '12-15 लीटर/दिन', 'weight': '450-550 किग्रा', 'height': '130-140 सेमी', 'appearance': 'रात में चरने वाली, घुमावदार सींग।', 'image': 'assets/breeds/banni.jpg'},
        {'category': 'Buffalo', 'name': 'जाफराबादी', 'type': 'भैंस', 'origin': 'गुजरात', 'lifespan': '18-22 वर्ष', 'milk': '15-20 लीटर/दिन', 'weight': '700-800 किग्रा', 'height': '140-150 सेमी', 'appearance': 'भारी शरीर, लटकते सींग।', 'image': 'assets/breeds/jaffarabadi.jpg'},
        {'category': 'Buffalo', 'name': 'नीली रावी', 'type': 'भैंस', 'origin': 'पंजाब', 'lifespan': '14-18 वर्ष', 'milk': '12-18 लीटर/दिन', 'weight': '500-600 किग्रा', 'height': '130-140 सेमी', 'appearance': 'सफेद आंखें, चेहरे और पैरों पर सफेद निशान।', 'image': 'assets/breeds/nili_ravi.jpg'},
        {'category': 'Buffalo', 'name': 'मेहसाणा', 'type': 'भैंस', 'origin': 'गुजरात', 'lifespan': '15-20 वर्ष', 'milk': '10-15 लीटर/दिन', 'weight': '450-550 किग्रा', 'height': '130-140 सेमी', 'appearance': 'मुर्रा और सुरती का संकर, दरांती जैसे सींग।', 'image': 'assets/breeds/mehsana.jpg'},
        {'category': 'Buffalo', 'name': 'नागपुरी', 'type': 'भैंस', 'origin': 'महाराष्ट्र', 'lifespan': '15-18 वर्ष', 'milk': '5-8 लीटर/दिन', 'weight': '350-450 किग्रा', 'height': '120-130 सेमी', 'appearance': 'लंबे और चपटे तलवार जैसे सींग।', 'image': 'assets/breeds/nagpuri.jpg'},
        {'category': 'Buffalo', 'name': 'टोडा', 'type': 'भैंस', 'origin': 'तमिलनाडु', 'lifespan': '15-18 वर्ष', 'milk': '4-6 लीटर/दिन', 'weight': '350-400 किग्रा', 'height': '120-130 सेमी', 'appearance': 'भूरा रंग, विशिष्ट अर्धचंद्राकार सींग।', 'image': 'assets/breeds/toda.jpg'},
      ];
    } else if (lang == 'mr') {
      return [
        {'category': 'Cow', 'name': 'गीर', 'type': 'गाय', 'origin': 'गुजरात', 'lifespan': '12-15 वर्षे', 'milk': '12-20 लिटर/दिवस', 'weight': '385-545 किलो', 'height': '130-140 सेमी', 'appearance': 'बहिर्वक्र कपाळ, लांब लोंबकळणारे कान, लाल/ठिपकेदार.', 'image': 'assets/breeds/gir.jpg'},
        {'category': 'Cow', 'name': 'साहीवाल', 'type': 'गाय', 'origin': 'पंजाब/हरियाणा', 'lifespan': '14-16 वर्षे', 'milk': '10-15 लिटर/दिवस', 'weight': '400-500 किलो', 'height': '120-130 सेमी', 'appearance': 'लाल-तपकिरी रंग, त्वचेच्या घड्या.', 'image': 'assets/breeds/sahiwal.jpg'},
        {'category': 'Cow', 'name': 'कांकरेज', 'type': 'गाय', 'origin': 'गुजरात/राजस्थान', 'lifespan': '12-16 वर्षे', 'milk': '8-10 लिटर/दिवस', 'weight': '420-590 किलो', 'height': '130-140 सेमी', 'appearance': 'चांदी-तपकिरी रंग, मोठी मजबूत शिंगे.', 'image': 'assets/breeds/kankrej.jpg'},
        {'category': 'Cow', 'name': 'ओंगोल', 'type': 'गाय', 'origin': 'आंध्र प्रदेश', 'lifespan': '15-20 वर्षे', 'milk': '5-8 लिटर/दिवस', 'weight': '430-500 किलो', 'height': '135-150 सेमी', 'appearance': 'पांढरा रंग, मोठे वशिंड, मजबूत शरीर.', 'image': 'assets/breeds/ongole.jpg'},
        {'category': 'Cow', 'name': 'लाल सिंधी', 'type': 'गाय', 'origin': 'सिंध/राजस्थान', 'lifespan': '12-15 वर्षे', 'milk': '12-18 लिटर/दिवस', 'weight': '300-450 किलो', 'height': '115-130 सेमी', 'appearance': 'गडद लाल रंग, कॉम्पॅक्ट फ्रेम.', 'image': 'assets/breeds/red_sindhi.jpg'},
        {'category': 'Cow', 'name': 'थारपारकर', 'type': 'गाय', 'origin': 'राजस्थान', 'lifespan': '14-18 वर्षे', 'milk': '10-14 लिटर/दिवस', 'weight': '400-500 किलो', 'height': '120-140 सेमी', 'appearance': 'पांढरा/फिकट राखाडी रंग.', 'image': 'assets/breeds/tharparkar.jpg'},
        {'category': 'Cow', 'name': 'राठी', 'type': 'गाय', 'origin': 'राजस्थान', 'lifespan': '13-15 वर्षे', 'milk': '8-12 लिटर/दिवस', 'weight': '280-350 किलो', 'height': '115-125 सेमी', 'appearance': 'पांढऱ्या ठिपक्यांसह तपकिरी रंग.', 'image': 'assets/breeds/rathi.jpg'},
        {'category': 'Cow', 'name': 'हरियाणवी', 'type': 'गाय', 'origin': 'हरियाणा', 'lifespan': '14-18 वर्षे', 'milk': '8-12 लिटर/दिवस', 'weight': '350-500 किलो', 'height': '130-140 सेमी', 'appearance': 'पांढरा किंवा फिकट राखाडी, लांब चेहरा.', 'image': 'assets/breeds/hariana.jpg'},
        {'category': 'Cow', 'name': 'देवणी', 'type': 'गाय', 'origin': 'महाराष्ट्र/कर्नाटक', 'lifespan': '12-15 वर्षे', 'milk': '6-10 लिटर/दिवस', 'weight': '400-500 किलो', 'height': '120-135 सेमी', 'appearance': 'काळे आणि पांढरे ठिपके, लोंबकळणारे कान.', 'image': 'assets/breeds/deoni.jpg'},
        {'category': 'Cow', 'name': 'मलनाड गिड्डा', 'type': 'गाय (बुटकी)', 'origin': 'कर्नाटक', 'lifespan': '10-14 वर्षे', 'milk': '2-4 लिटर/दिवस', 'weight': '120-200 किलो', 'height': '90-100 सेमी', 'appearance': 'लहान उंची, रोगप्रतिकारक, चपळ.', 'image': 'assets/breeds/malnad_gidda.jpg'},
        {'category': 'Buffalo', 'name': 'बन्नी', 'type': 'म्हैस', 'origin': 'गुजरात (कच्छ)', 'lifespan': '15-20 वर्षे', 'milk': '12-15 लिटर/दिवस', 'weight': '450-550 किलो', 'height': '130-140 सेमी', 'appearance': 'रात्री चरणाऱ्या, वळलेली शिंगे.', 'image': 'assets/breeds/banni.jpg'},
        {'category': 'Buffalo', 'name': 'जाफराबादी', 'type': 'म्हैस', 'origin': 'गुजरात', 'lifespan': '18-22 वर्षे', 'milk': '15-20 लिटर/दिवस', 'weight': '700-800 किलो', 'height': '140-150 सेमी', 'appearance': 'जड शरीर, लोंबकळणारी शिंगे.', 'image': 'assets/breeds/jaffarabadi.jpg'},
        {'category': 'Buffalo', 'name': 'नीली रावी', 'type': 'म्हैस', 'origin': 'पंजाब', 'lifespan': '14-18 वर्षे', 'milk': '12-18 लिटर/दिवस', 'weight': '500-600 किलो', 'height': '130-140 सेमी', 'appearance': 'पांढरे डोळे, चेहरा आणि पायांवर पांढरे डाग.', 'image': 'assets/breeds/nili_ravi.jpg'},
        {'category': 'Buffalo', 'name': 'मेहसाणा', 'type': 'म्हैस', 'origin': 'गुजरात', 'lifespan': '15-20 वर्षे', 'milk': '10-15 लिटर/दिवस', 'weight': '450-550 किलो', 'height': '130-140 सेमी', 'appearance': 'विळ्याच्या आकाराची शिंगे.', 'image': 'assets/breeds/mehsana.jpg'},
        {'category': 'Buffalo', 'name': 'नागपुरी', 'type': 'म्हैस', 'origin': 'महाराष्ट्र', 'lifespan': '15-18 वर्षे', 'milk': '5-8 लिटर/दिवस', 'weight': '350-450 किलो', 'height': '120-130 सेमी', 'appearance': 'लांब आणि सपाट तलवारीसारखी शिंगे.', 'image': 'assets/breeds/nagpuri.jpg'},
        {'category': 'Buffalo', 'name': 'टोडा', 'type': 'म्हैस', 'origin': 'तमिळनाडू', 'lifespan': '15-18 वर्षे', 'milk': '4-6 लिटर/दिवस', 'weight': '350-400 किलो', 'height': '120-130 सेमी', 'appearance': 'राखाडी रंग, अर्धचंद्राकृती शिंगे.', 'image': 'assets/breeds/toda.jpg'},
      ];
    }
    // Default English
    return [
      {'category': 'Cow', 'name': 'Gir', 'type': 'Cow', 'origin': 'Gujarat', 'lifespan': '12-15 years', 'milk': '12-20 Liters/day', 'weight': '385-545kg', 'height': '130-140 cm', 'appearance': 'Convex forehead, long pendulous ears, red/spotted.', 'image': 'assets/breeds/gir.jpg'},
      {'category': 'Cow', 'name': 'Sahiwal', 'type': 'Cow', 'origin': 'Punjab/Haryana', 'lifespan': '14-16 years', 'milk': '10-15 Liters/day', 'weight': '400-500kg', 'height': '120-130 cm', 'appearance': 'Reddish brown color, heavy skin folds, prominent dewlap.', 'image': 'assets/breeds/sahiwal.jpg'},
      {'category': 'Cow', 'name': 'Kankrej', 'type': 'Cow', 'origin': 'Gujarat/Rajasthan', 'lifespan': '12-16 years', 'milk': '8-10 Liters/day', 'weight': '420-590kg', 'height': '130-140 cm', 'appearance': 'Silver-grey to iron-grey, large strong crescent horns.', 'image': 'assets/breeds/kankrej.jpg'},
      {'category': 'Cow', 'name': 'Ongole', 'type': 'Cow', 'origin': 'Andhra Pradesh', 'lifespan': '15-20 years', 'milk': '5-8 Liters/day', 'weight': '430-500kg', 'height': '135-150 cm', 'appearance': 'Glossy white, huge hump, short horns, muscular build.', 'image': 'assets/breeds/ongole.jpg'},
      {'category': 'Cow', 'name': 'Red Sindhi', 'type': 'Cow', 'origin': 'Sindh/Rajasthan', 'lifespan': '12-15 years', 'milk': '12-18 Liters/day', 'weight': '300-450kg', 'height': '115-130 cm', 'appearance': 'Deep red color, compact frame, thick horns.', 'image': 'assets/breeds/red_sindhi.jpg'},
      {'category': 'Cow', 'name': 'Tharparkar', 'type': 'Cow', 'origin': 'Rajasthan', 'lifespan': '14-18 years', 'milk': '10-14 Liters/day', 'weight': '400-500kg', 'height': '120-140 cm', 'appearance': 'White/light grey color, lyre-shaped horns.', 'image': 'assets/breeds/tharparkar.jpg'},
      {'category': 'Cow', 'name': 'Rathi', 'type': 'Cow', 'origin': 'Rajasthan', 'lifespan': '13-15 years', 'milk': '8-12 Liters/day', 'weight': '280-350kg', 'height': '115-125 cm', 'appearance': 'Brown with white patches, medium horns, efficient in arid regions.', 'image': 'assets/breeds/rathi.jpg'},
      {'category': 'Cow', 'name': 'Hariana', 'type': 'Cow', 'origin': 'Haryana', 'lifespan': '14-18 years', 'milk': '8-12 Liters/day', 'weight': '350-500kg', 'height': '130-140 cm', 'appearance': 'White or light grey, long narrow face, small horns.', 'image': 'assets/breeds/hariana.jpg'},
      {'category': 'Cow', 'name': 'Deoni', 'type': 'Cow', 'origin': 'Maharashtra/Karnataka', 'lifespan': '12-15 years', 'milk': '6-10 Liters/day', 'weight': '400-500kg', 'height': '120-135 cm', 'appearance': 'Black and white patches, prominent forehead, drooping ears.', 'image': 'assets/breeds/deoni.jpg'},
      {'category': 'Cow', 'name': 'Malnad Gidda', 'type': 'Cow (Dwarf)', 'origin': 'Karnataka', 'lifespan': '10-14 years', 'milk': '2-4 Liters/day', 'weight': '120-200kg', 'height': '90-100 cm', 'appearance': 'Small/dwarf stature, highly disease resistant, agile.', 'image': 'assets/breeds/malnad_gidda.jpg'},
      {'category': 'Buffalo', 'name': 'Banni', 'type': 'Buffalo', 'origin': 'Gujarat (Kutch)', 'lifespan': '15-20 years', 'milk': '12-15 Liters/day', 'weight': '450-550kg', 'height': '130-140 cm', 'appearance': 'Night grazers, black, typical coiled horns.', 'image': 'assets/breeds/banni.jpg'},
      {'category': 'Buffalo', 'name': 'Jaffarabadi', 'type': 'Buffalo', 'origin': 'Gujarat', 'lifespan': '18-22 years', 'milk': '15-20 Liters/day', 'weight': '700-800kg', 'height': '140-150 cm', 'appearance': 'Heavy built, massive body, drooping horns.', 'image': 'assets/breeds/jaffarabadi.jpg'},
      {'category': 'Buffalo', 'name': 'Nili Ravi', 'type': 'Buffalo', 'origin': 'Punjab', 'lifespan': '14-18 years', 'milk': '12-18 Liters/day', 'weight': '500-600kg', 'height': '130-140 cm', 'appearance': 'Wall eyes, white markings on face and legs.', 'image': 'assets/breeds/nili_ravi.jpg'},
      {'category': 'Buffalo', 'name': 'Mehsana', 'type': 'Buffalo', 'origin': 'Gujarat', 'lifespan': '15-20 years', 'milk': '10-15 Liters/day', 'weight': '450-550kg', 'height': '130-140 cm', 'appearance': 'Cross between Murrah and Surti, sickle-shaped horns.', 'image': 'assets/breeds/mehsana.jpg'},
      {'category': 'Buffalo', 'name': 'Nagpuri', 'type': 'Buffalo', 'origin': 'Maharashtra', 'lifespan': '15-18 years', 'milk': '5-8 Liters/day', 'weight': '350-450kg', 'height': '120-130 cm', 'appearance': 'Long, flat, sword-shaped horns.', 'image': 'assets/breeds/nagpuri.jpg'},
      {'category': 'Buffalo', 'name': 'Toda', 'type': 'Buffalo', 'origin': 'Tamil Nadu', 'lifespan': '15-18 years', 'milk': '4-6 Liters/day', 'weight': '350-400kg', 'height': '120-130 cm', 'appearance': 'Fawn to ash-grey color, distinct crescent-shaped horns.', 'image': 'assets/breeds/toda.jpg'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    String currentLang = appLanguage.value;

    List<Map<String, String>> allBreeds = getLocalizedBreeds(currentLang);

    List<Map<String, String>> filteredList = allBreeds.where((breed) {
      if (_selectedFilter == 'All') return true;
      return breed['category'] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF64DD17),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(translate('lib_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  _buildFilterChip('All', translate('filter_all')),
                  const SizedBox(width: 10),
                  _buildFilterChip('Cow', translate('filter_cow')),
                  const SizedBox(width: 10),
                  _buildFilterChip('Buffalo', translate('filter_buffalo')),
                  const SizedBox(width: 10),
                  _buildFilterChip('Camel', translate('filter_camel')),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),

          Expanded(
            child: _selectedFilter == 'Camel'
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_empty, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      translate('coming_soon'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final breed = filteredList[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.asset(
                            breed['image'] ?? 'assets/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                  const SizedBox(height: 10),
                                  Text("Add ${breed['image'] ?? 'image'} to assets", style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(breed['name'] ?? 'Unknown', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF64DD17))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: const Color(0xFF64DD17).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(breed['type'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64DD17))),
                                )
                              ],
                            ),
                            const SizedBox(height: 15),
                            _detailRow(Icons.location_on, translate('lib_origin'), breed['origin'] ?? ''),
                            _detailRow(Icons.water_drop, translate('lib_milk'), breed['milk'] ?? ''),
                            _detailRow(Icons.monitor_weight, translate('lib_weight'), breed['weight'] ?? ''),
                            _detailRow(Icons.height, translate('lib_height'), breed['height'] ?? ''),
                            _detailRow(Icons.favorite, translate('lib_lifespan'), breed['lifespan'] ?? ''),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
                            Text("${translate('lib_appearance')}:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                            const SizedBox(height: 5),
                            Text(breed['appearance'] ?? '', style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black54)),
                          ],
                        ),
                      ),
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

  Widget _buildFilterChip(String categoryValue, String displayLabel) {
    bool isSelected = _selectedFilter == categoryValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = categoryValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF64DD17) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF64DD17) : Colors.transparent),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 15, color: Colors.black54))),
        ],
      ),
    );
  }
}

// --- 10. FULL SCREEN IMAGE VIEWER ---
class FullScreenImage extends StatelessWidget {
  final String imagePath;
  const FullScreenImage({super.key, required this.imagePath});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: InteractiveViewer(child: Image.file(File(imagePath))))
    );
  }
}

// --- COMMON UI COMPONENTS ---
InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
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
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF64DD17), width: 2.5)
      ),
      child: Center(
          child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF64DD17)))
      ),
    ),
  );
}

// --- 11. PASHU AADHAAR REGISTRATION SCREEN (ADMIN ONLY) ---
class PashuAadhaarRegistrationScreen extends StatefulWidget {
  const PashuAadhaarRegistrationScreen({super.key});

  @override
  State<PashuAadhaarRegistrationScreen> createState() => _PashuAadhaarRegistrationScreenState();
}

class _PashuAadhaarRegistrationScreenState extends State<PashuAadhaarRegistrationScreen> {
  final _pashuIdController = TextEditingController();
  final _farmerAadhaarController = TextEditingController();
  final _breedController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _addMoreCattle = false;

  Future<void> _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String pashuId = _pashuIdController.text.trim();
      String farmerId = _farmerAadhaarController.text.trim();
      String breed = _breedController.text.trim();

      Map<String, dynamic> result = await MongoDatabase.registerCattleSafe(pashuId, farmerId, breed);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
        );

        if (_addMoreCattle) {
          setState(() {
            _pashuIdController.clear();
            _breedController.clear();
          });
        } else {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'], style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF64DD17),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Register Pashu Aadhaar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    "Link Cattle to Owner",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF64DD17))
                ),
                const SizedBox(height: 10),
                const Text(
                  "Enter the 12-digit Pashu Aadhaar to verify existence before linking.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _pashuIdController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  decoration: _inputDecoration("12-Digit Pashu Aadhaar UID"),
                  validator: (v) => (v == null || v.length != 12) ? "Exactly 12 digits required" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _farmerAadhaarController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  decoration: _inputDecoration("Owner's 12-Digit Aadhaar"),
                  validator: (v) => (v == null || v.length != 12) ? "Exactly 12 digits required" : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _breedController,
                  decoration: _inputDecoration("Cattle Breed (e.g., Gir, Sahiwal)"),
                  validator: (v) => v == null || v.isEmpty ? translate('field_req') : null,
                ),
                const SizedBox(height: 15),

                CheckboxListTile(
                  title: const Text(
                      "Register another cattle for this owner?",
                      style: TextStyle(color: Color(0xFF64DD17), fontWeight: FontWeight.bold)
                  ),
                  value: _addMoreCattle,
                  activeColor: const Color(0xFF64DD17),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (bool? value) {
                    setState(() {
                      _addMoreCattle = value ?? false;
                    });
                  },
                ),
                const SizedBox(height: 25),

                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF64DD17)))
                    : _actionButton("Verify & Register", _handleRegistration),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 12. MARKETPLACE SCREEN (MOCK UI FOR HACKATHON) ---
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: const Color(0xFF64DD17),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(translate('market_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: translate('buy_tab'), icon: const Icon(Icons.shopping_cart)),
              Tab(text: translate('sell_tab'), icon: const Icon(Icons.storefront)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBuyTab(),
            _buildSellTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyTab() {
    // Mock Data for Hackathon
    final List<Map<String, String>> cattleForSale = [
      {'breed': 'Gir Cow', 'price': '45,000', 'location': 'Pune, Maharashtra', 'milk': '15 Liters/day', 'age': '4 Years'},
      {'breed': 'Murrah Buffalo', 'price': '60,000', 'location': 'Nashik, Maharashtra', 'milk': '18 Liters/day', 'age': '5 Years'},
      {'breed': 'Sahiwal Cow', 'price': '42,000', 'location': 'Satara, Maharashtra', 'milk': '14 Liters/day', 'age': '3 Years'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cattleForSale.length,
      itemBuilder: (context, index) {
        final cattle = cattleForSale[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: const Icon(Icons.pets, size: 60, color: Colors.grey),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cattle['breed']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF64DD17))),
                    const SizedBox(height: 5),
                    Text("${translate('price')}${cattle['price']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(cattle['location']!, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text("Age: ${cattle['age']} | Milk: ${cattle['milk']}", style: const TextStyle(color: Colors.black54, fontSize: 14)),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.phone, color: Colors.white),
                        label: Text(translate('contact_seller'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Calling seller in Demo Mode..."), backgroundColor: Colors.blue),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSellTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Enter Cattle Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF64DD17))),
          const SizedBox(height: 20),
          TextFormField(decoration: _inputDecoration(translate('form_breed'))),
          const SizedBox(height: 15),
          TextFormField(keyboardType: TextInputType.number, decoration: _inputDecoration(translate('form_age'))),
          const SizedBox(height: 15),
          TextFormField(keyboardType: TextInputType.number, decoration: _inputDecoration(translate('form_milk'))),
          const SizedBox(height: 15),
          TextFormField(keyboardType: TextInputType.number, decoration: _inputDecoration(translate('form_price'))),
          const SizedBox(height: 30),
          _actionButton(translate('list_cattle_btn'), () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Cattle Listed Successfully! (Demo)"), backgroundColor: Colors.green),
            );
          })
        ],
      ),
    );
  }
}