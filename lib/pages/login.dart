import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:dio/io.dart';
import 'dashboard.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final storage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://10.0.2.2:7153/api/Reports',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));

    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        // Note: Only use this in development. For production, properly handle certificates
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        print('API Error: ${error.message}');
        if (error.response?.statusCode == 401) {
          // Handle unauthorized access
          await storage.delete(key: 'userId');
          Get.offAll(() => const LoginPage());
        }
        return handler.next(error);
      },
      onRequest: (request, handler) {
        print('API Request: ${request.uri}');
        return handler.next(request);
      },
      onResponse: (response, handler) {
        print('API Response: ${response.statusCode}');
        return handler.next(response);
      },
    ));
  }

  Future<Map<String, dynamic>> login(String passcode) async {
    try {
      final response = await _dio.post('/login',
        data: {'passcode': passcode},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        switch (error.response?.statusCode) {
          case 400:
            return 'Invalid passcode';
          case 401:
            return 'Unauthorized access';
          case 404:
            return 'Service not found';
          default:
            return 'Server error occurred';
        }
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error occurred';
    }
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _passcodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePasscode = true;

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(_passcodeController.text);
      final userId = response['userId'];

      // Securely store the userId
      await _apiService.storage.write(
        key: 'userId',
        value: userId.toString(),
        aOptions: const AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: const IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );

      Get.offAll(() => const DashboardPage());
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          e.toString(),
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(10),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validatePasscode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your passcode';
    }
    if (value.length < 6) {
      return 'Passcode must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(context),
                  const SizedBox(height: 48),
                  _buildLoginCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/ceylon_logo.png',
          width: double.infinity,
          color: Colors.white,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login to your account',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _passcodeController,
              obscureText: _obscurePasscode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your passcode';
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: 'Passcode',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePasscode ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscurePasscode = !_obscurePasscode),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildLionLogo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLionLogo(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(height: 55),
          Image.asset(
            'assets/images/lion_logo.png',
            height: 300,
            color: Colors.white,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 55),
        ],
      ),
    );
  }
}