import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _dataSaverEnabled = false;
  String _userName = 'John Doe';
  String _userEmail = 'john.doe@example.com';
  String _accountType = 'Premium'; // Can be 'Premium', 'Trial', or 'Free'
  int _trialDaysLeft = 7; // Only relevant for trial accounts

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
      _dataSaverEnabled = prefs.getBool('data_saver_enabled') ?? false;
      _userName = prefs.getString('user_name') ?? 'John Doe';
      _userEmail = prefs.getString('user_email') ?? 'john.doe@example.com';
      _accountType = prefs.getString('account_type') ?? 'Premium';
      _trialDaysLeft = prefs.getInt('trial_days_left') ?? 7;
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFD3E4DE),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person,
              size: 30,
              color: Colors.black,
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
        activeColor: const Color(0xFFD3E4DE),
        activeTrackColor: const Color(0xFFD3E4DE),
      ),
      onTap: () => onChanged(!value),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);

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
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.judson(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: GoogleFonts.judson(),
                keyboardType: TextInputType.emailAddress,
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
                  _userEmail = emailController.text;
                });
                _saveSetting('user_name', _userName);
                _saveSetting('user_email', _userEmail);
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
    return Scaffold(
      backgroundColor: const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
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
                _buildSwitchItem(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    _saveSetting('dark_mode_enabled', value);
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
                    // Navigate to help and support screen
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () {
                    _showAboutDialog();
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'About Great Awareness',
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
                'Version 1.0.0',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your companion for mental health and wellness.',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '© 2024 Great Awareness. All rights reserved.',
                style: GoogleFonts.judson(
                  textStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.judson(
                  textStyle: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        );
      },
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
              onPressed: () {
                Navigator.of(context).pop();
                // Handle sign out logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Signed out successfully',
                      style: GoogleFonts.judson(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
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