import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedCounty;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  int _currentStep = 0;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _kenyanCounties = [
    'Baringo County',
    'Bomet County',
    'Bungoma County',
    'Busia County',
    'Elgeyo/Marakwet County',
    'Embu County',
    'Garissa County',
    'Homa Bay County',
    'Isiolo County',
    'Kajiado County',
    'Kakamega County',
    'Kericho County',
    'Kiambu County',
    'Kilifi County',
    'Kirinyaga County',
    'Kisii County',
    'Kisumu County',
    'Kitui County',
    'Kwale County',
    'Laikipia County',
    'Lamu County',
    'Machakos County',
    'Makueni County',
    'Mandera County',
    'Marsabit County',
    'Meru County',
    'Migori County',
    'Mombasa County',
    'Murang\'a County',
    'Nairobi City County',
    'Nakuru County',
    'Nandi County',
    'Narok County',
    'Nyamira County',
    'Nyandarua County',
    'Nyeri County',
    'Samburu County',
    'Siaya County',
    'Taita/Taveta County',
    'Tana River County',
    'Tharaka-Nithi County',
    'Trans Nzoia County',
    'Turkana County',
    'Uasin Gishu County',
    'Vihiga County',
    'Wajir County',
    'West Pokot County',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (_emailController.text.isEmpty || _phoneController.text.isEmpty || _selectedCounty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }
      // Validate phone number format
      final kenyanPhoneRegex = RegExp(r'^(\+254\s?7\d{2}\s?\d{3}\s?\d{3}|07\d{2}\s?\d{3}\s?\d{3})$');
      if (!kenyanPhoneRegex.hasMatch(_phoneController.text.replaceAll(' ', ''))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid Kenyan phone number')),
        );
        return;
      }
      if (!_emailController.text.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')),
        );
        return;
      }
    }
    
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitForm() async {
    debugPrint('=== SIGNUP SUBMIT FORM ===');
    debugPrint('First Name: "${_firstNameController.text}" (Type: ${_firstNameController.text.runtimeType})');
    debugPrint('Last Name: "${_lastNameController.text}" (Type: ${_lastNameController.text.runtimeType})');
    debugPrint('Email: "${_emailController.text}" (Type: ${_emailController.text.runtimeType})');
    debugPrint('Phone: "${_phoneController.text}" (Type: ${_phoneController.text.runtimeType})');
    debugPrint('County: "$_selectedCounty" (Type: ${_selectedCounty.runtimeType})');
    debugPrint('Password: "${_passwordController.text}" (Type: ${_passwordController.text.runtimeType})');
    
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating account...')),
    );
    
    try {
      // Call API service to register user
      final apiService = ApiService();
      final user = await apiService.signup(
        _firstNameController.text,
        _lastNameController.text,
        _emailController.text,
        _phoneController.text,
        _selectedCounty ?? '',
        _passwordController.text,
      );
      
      if (user != null) {
        if (!mounted) return;
        
        // Auto-login the user
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.login(user);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // This shouldn't happen if the API service is working correctly
        throw Exception('Account creation failed - no user data returned');
      }
    } catch (e, stackTrace) {
      debugPrint('Signup error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      // Show detailed error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Signup Error'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('An error occurred during signup:'),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.red, fontFamily: 'Courier'),
                ),
                if (e.toString().contains('type \'double\' is not a subtype of type \'int\'')) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Diagnosis: A data type mismatch occurred. This usually means the app received a decimal number (e.g., 0.5) where it expected a whole number (e.g., 1).',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                   const Text('Potential causes:'),
                   const Text('• Backend returned a decimal for an ID'),
                   const Text('• Animation value calculation error'),
                   const Text('• Screen size calculation error'),
                ],
                const SizedBox(height: 16),
                const Text('Stack Trace (Share this with support):', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: SingleChildScrollView(
                    child: Text(
                      stackTrace.toString(),
                      style: const TextStyle(fontSize: 10, fontFamily: 'Courier'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Account',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  _buildStepIndicator(0),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep >= 1 ? Colors.black : Colors.grey[400],
                    ),
                  ),
                  _buildStepIndicator(1),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep >= 2 ? Colors.black : Colors.grey[400],
                    ),
                  ),
                  _buildStepIndicator(2),
                ],
              ),
            ),
            
            // Form content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCurrentStep(),
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Back',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStep == 2 ? _submitForm : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentStep == 2 ? 'Create Account' : 'Next',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentStep >= step ? Colors.black : Colors.grey[300],
        border: Border.all(
          color: _currentStep >= step ? Colors.black : Colors.grey[500]!,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '${step + 1}',
          style: GoogleFonts.judson(
            textStyle: TextStyle(
              color: _currentStep >= step ? Colors.white : Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Personal Information',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
            labelText: 'First Name',
            labelStyle: GoogleFonts.judson(color: Colors.black54),
            prefixIcon: const Icon(Icons.person, color: Colors.black),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: GoogleFonts.judson(color: Colors.black),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
            labelText: 'Last Name',
            labelStyle: GoogleFonts.judson(color: Colors.black54),
            prefixIcon: const Icon(Icons.person, color: Colors.black),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: GoogleFonts.judson(color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Contact Information',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: GoogleFonts.judson(color: Colors.black54),
            prefixIcon: const Icon(Icons.email, color: Colors.black),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: GoogleFonts.judson(color: Colors.black),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            labelStyle: GoogleFonts.judson(color: Colors.black54),
            prefixIcon: const Icon(Icons.phone, color: Colors.black),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: GoogleFonts.judson(color: Colors.black),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            // Validate Kenyan phone number format: +254 7** *** *** or 07** *** ***
            final kenyanPhoneRegex = RegExp(r'^(\+254\s?7\d{2}\s?\d{3}\s?\d{3}|07\d{2}\s?\d{3}\s?\d{3})$');
            if (!kenyanPhoneRegex.hasMatch(value.replaceAll(' ', ''))) {
              return 'Please enter a valid Kenyan phone number (+254 7** *** *** or 07** *** ***)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _selectedCounty,
          decoration: InputDecoration(
            labelText: 'County',
            labelStyle: GoogleFonts.judson(color: Colors.black54),
            prefixIcon: const Icon(Icons.location_on, color: Colors.black),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          dropdownColor: Colors.white,
          style: GoogleFonts.judson(color: Colors.black),
          items: _kenyanCounties.map((String county) {
            return DropdownMenuItem<String>(
              value: county,
              child: Text(
                county,
                style: GoogleFonts.judson(color: Colors.black),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCounty = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a county';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Create Password',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Password must not be less than 8 characters, first character should have uppercase',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: GoogleFonts.judson(color: Colors.black54),
            prefixIcon: const Icon(Icons.lock, color: Colors.black),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: GoogleFonts.judson(color: Colors.black),
          obscureText: _obscurePassword,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            labelStyle: GoogleFonts.judson(color: Colors.black54),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.black),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: GoogleFonts.judson(color: Colors.black),
          obscureText: _obscureConfirmPassword,
        ),
      ],
    );
  }
}