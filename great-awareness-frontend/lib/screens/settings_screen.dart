import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_provider.dart';
import '../models/user.dart';
import 'admin_posting_screen.dart';
import 'about_us_screen.dart';
import 'help_support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dataSaverEnabled = false;
  String _userName = 'John Doe';
  String _userEmail = 'john.doe@example.com';
  String _accountType = 'Premium'; // Can be 'Premium', 'Trial', or 'Free'
  int _trialDaysLeft = 7; // Only relevant for trial accounts
  String? _profileImagePath;
  Uint8List? _profileImageBytes; // For web compatibility
  late final AuthService _authService;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize AuthService via Provider to access app-wide instance
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadUserSettings();
    
    // Listen for auth changes to update user data
    _authService.addListener(_onAuthChanged);
  }
  
  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }
  
  void _onAuthChanged() {
    // Reload user settings when auth state changes
    _loadUserSettings();
  }

  void _navigateToAdminPosting() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminPostingScreen(),
      ),
    );
    
    // Show feedback if a post was created
    if (result != null && result is Map<String, dynamic>) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New post created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
      }
    }
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Use real user data from AuthService if available, otherwise fall back to SharedPreferences
    final currentUser = _authService.currentUser;
    final userName = currentUser?.name ?? prefs.getString('user_name') ?? 'John Doe';
    final userEmail = currentUser?.email ?? prefs.getString('user_email') ?? 'john.doe@example.com';
    
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _dataSaverEnabled = prefs.getBool('data_saver_enabled') ?? false;
      _userName = userName;
      _userEmail = userEmail;
      _accountType = prefs.getString('account_type') ?? 'Premium';
      _trialDaysLeft = prefs.getInt('trial_days_left') ?? 7;
      _profileImagePath = prefs.getString('profile_image_path');
      
      // Load image data for web if available
      if (kIsWeb) {
        _profileImageBytes = null; // Reset bytes
        _profileImagePath = null; // Don't use path on web
      }
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        if (!mounted) return;
        if (kIsWeb) {
          // For web, read the image bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _profileImageBytes = bytes;
            _profileImagePath = null; // Don't use path on web
          });
          // Store the bytes as base64 for persistence
          await _saveSetting('profile_image_data', bytes.toString());
        } else {
          // For mobile, use the file path
          setState(() {
            _profileImagePath = pickedFile.path;
            _profileImageBytes = null;
          });
          await _saveSetting('profile_image_path', pickedFile.path);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile picture updated successfully',
                style: GoogleFonts.judson(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() {
      _profileImagePath = null;
      _profileImageBytes = null;
    });
    await _saveSetting('profile_image_path', '');
    await _saveSetting('profile_image_data', '');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile picture removed',
            style: GoogleFonts.judson(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Profile Picture',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.judson(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage();
                },
              ),
              if (_profileImagePath != null || _profileImageBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Remove Profile Picture',
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(color: Colors.red),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: Text(
                  'Cancel',
                  style: GoogleFonts.judson(),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showProfilePictureOptions(),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFD3E4DE),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _profileImageBytes != null
                    ? Image.memory(
                        _profileImageBytes!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.black,
                          );
                        },
                      )
                    : _profileImagePath != null && !kIsWeb
                        ? Image.file(
                            File(_profileImagePath!),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.black,
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.black,
                          ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: GoogleFonts.judson(
                    textStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accountType == 'Premium' 
                            ? Colors.green[100] 
                            : _accountType == 'Trial' 
                                ? Colors.orange[100]
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _accountType,
                        style: GoogleFonts.judson(
                          textStyle: TextStyle(
                            fontSize: 12,
                            color: _accountType == 'Premium' 
                                ? Colors.green[700] 
                                : _accountType == 'Trial' 
                                    ? Colors.orange[700]
                                    : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (_accountType == 'Trial') ...[
                      const SizedBox(width: 8),
                      Text(
                        '$_trialDaysLeft days left',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.judson(
              textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: GoogleFonts.judson(
          textStyle: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.judson(
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingsItem(
      icon: icon,
      title: title,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFFD3E4DE),
        activeTrackColor: const Color(0xFFD3E4DE),
      ),
      onTap: () => onChanged(!value),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Edit Profile',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.judson(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: GoogleFonts.judson(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.judson(
                  textStyle: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _userName = nameController.text;
                });
                _saveSetting('user_name', _userName);
                
                // Update AuthService with new user data (keep original email)
                if (_authService.currentUser != null) {
                  final updatedUser = User(
                    id: _authService.currentUser!.id,
                    email: _authService.currentUser!.email, // Keep original email
                    name: _userName,
                    token: _authService.currentUser!.token,
                    role: _authService.currentUser!.role,
                    firstName: _authService.currentUser!.firstName,
                    lastName: _authService.currentUser!.lastName,
                    phoneNumber: _authService.currentUser!.phoneNumber,
                    county: _authService.currentUser!.county,
                  );
                  _authService.updateUser(updatedUser);
                }
                
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD3E4DE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAccountUpgradeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Upgrade Account',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upgrade to Premium for full access:',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem('Unlimited access to all content'),
              _buildFeatureItem('Priority customer support'),
              _buildFeatureItem('Ad-free experience'),
              _buildFeatureItem('Advanced analytics'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Special offer: 30% off first month',
                      style: GoogleFonts.judson(
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Later',
                style: GoogleFonts.judson(
                  textStyle: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle upgrade logic here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Redirecting to payment...',
                      style: GoogleFonts.judson(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Upgrade Now',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 16),
          const SizedBox(width: 8),
          Text(
            feature,
            style: GoogleFonts.judson(
              textStyle: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? theme.scaffoldBackgroundColor : const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.judson(
            textStyle: TextStyle(
              color: theme.appBarTheme.foregroundColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserProfileSection(),
            const SizedBox(height: 24),
            
            _buildSettingsSection(
              'Preferences',
              [
                _buildSwitchItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _saveSetting('notifications_enabled', value);
                  },
                ),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildSwitchItem(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.setDarkMode(value);
                      },
                    );
                  },
                ),
                _buildSwitchItem(
                  icon: Icons.data_saver_on,
                  title: 'Data Saver',
                  value: _dataSaverEnabled,
                  onChanged: (value) {
                    setState(() {
                      _dataSaverEnabled = value;
                    });
                    _saveSetting('data_saver_enabled', value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSettingsSection(
              'Account',
              [
                _buildSettingsItem(
                  icon: Icons.person_outline,
                  title: 'Account Information',
                  subtitle: 'Manage your account details',
                  onTap: () {
                    // Navigate to account information screen
                  },
                ),
                if (_accountType != 'Premium')
                  _buildSettingsItem(
                    icon: Icons.star,
                    title: 'Upgrade to Premium',
                    subtitle: 'Unlock all features',
                    onTap: _showAccountUpgradeDialog,
                  ),
                _buildSettingsItem(
                  icon: Icons.payment,
                  title: 'Payment Methods',
                  subtitle: 'Manage your payment options',
                  onTap: () {
                    // Navigate to payment methods screen
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.history,
                  title: 'Purchase History',
                  subtitle: 'View your past purchases',
                  onTap: () {
                    // Navigate to purchase history screen
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Admin Section (only visible to admins)
            if (_authService.isAdmin) ...[
              _buildSettingsSection(
                'Admin Tools',
                [
                  _buildSettingsItem(
                    icon: Icons.post_add,
                    title: 'Create Post',
                    subtitle: 'Add new content to the feed',
                    onTap: () => _navigateToAdminPosting(),
                  ),
                  _buildSettingsItem(
                    icon: Icons.manage_accounts,
                    title: 'Manage Users',
                    subtitle: 'View and manage user accounts',
                    onTap: () {
                      // Navigate to user management screen
                      Navigator.pushNamed(context, '/admin/users');
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.analytics,
                    title: 'Content Analytics',
                    subtitle: 'View post performance metrics',
                    onTap: () {
                      // Navigate to analytics screen - for now just show the admin users screen which has analytics
                      Navigator.pushNamed(context, '/admin/users');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            
            _buildSettingsSection(
              'Content & Privacy',
              [
                _buildSettingsItem(
                  icon: Icons.lock_outline,
                  title: 'Privacy Settings',
                  subtitle: 'Control your privacy',
                  onTap: () {
                    // Navigate to privacy settings screen
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.content_copy,
                  title: 'Content Preferences',
                  subtitle: 'Customize your content',
                  onTap: () {
                    // Navigate to content preferences screen
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.block,
                  title: 'Blocked Users',
                  subtitle: 'Manage blocked users',
                  onTap: () {
                    // Navigate to blocked users screen
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSettingsSection(
              'Support & About',
              [
                _buildSettingsItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.info_outline,
                  title: 'About Us',
                  subtitle: 'Learn more about Great Awareness',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutUsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.rate_review_outlined,
                  title: 'Rate App',
                  subtitle: 'Rate us on the app store',
                  onTap: () {
                    // Handle app rating
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.share_outlined,
                  title: 'Share App',
                  subtitle: 'Share with friends',
                  onTap: () {
                    // Handle app sharing
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildSettingsSection(
              'Security',
              [
                _buildSettingsItem(
                  icon: Icons.security,
                  title: 'Security Settings',
                  subtitle: 'Two-factor authentication',
                  onTap: () {
                    // Navigate to security settings screen
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.vpn_key_outlined,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () {
                    // Navigate to change password screen
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  onTap: () {
                    _showSignOutDialog();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Sign Out',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.judson(
                  textStyle: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Handle sign out logic here
                _authService.logout();
                if (mounted) {
                  // Navigate to login screen after successful sign out
                  Navigator.of(context).pushReplacementNamed('/login1');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}