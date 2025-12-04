import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch phone call');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch email');
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
          'Help & Support',
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFAQItem(
                    'What is Great Awareness?',
                    'Great Awareness is a platform dedicated to transformation, healing, and integration. We guide people from unconscious living into conscious authorship.',
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    'How do I get started?',
                    'Simply create an account and explore our content, books, and community features. Start with what resonates most with you.',
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    'Is the app free to use?',
                    'Yes, the basic features of Great Awareness are free to use. Some premium content may require a subscription.',
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    'How can I contact support?',
                    'You can contact us through phone, email, or any of our social media channels listed below.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Contact Us Section
            Text(
              'Contact Us',
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildContactItem(
                    icon: Icons.phone,
                    title: 'Phone',
                    subtitle: '+254 725 630 194',
                    onTap: () => _makePhoneCall('+254725630194'),
                    iconColor: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: 'greatawareness1@gmail.com',
                    onTap: () => _sendEmail('greatawareness1@gmail.com'),
                    iconColor: Colors.blue,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Social Media Section
            Text(
              'Connect With Us',
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSocialMediaItem(
                    icon: FontAwesomeIcons.whatsapp,
                    title: 'WhatsApp Group',
                    subtitle: 'Join our community group',
                    onTap: () => _launchUrl('https://chat.whatsapp.com/H8DGK7wnp6IHMcR91KajlC?mode=hqrc'),
                    iconColor: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildSocialMediaItem(
                    icon: FontAwesomeIcons.whatsapp,
                    title: 'WhatsApp Channel',
                    subtitle: 'Follow our updates',
                    onTap: () => _launchUrl('https://whatsapp.com/channel/0029Vb6Ej107IUYZJY9gPI0o'),
                    iconColor: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildSocialMediaItem(
                    icon: FontAwesomeIcons.tiktok,
                    title: 'TikTok',
                    subtitle: 'Follow us on TikTok',
                    onTap: () => _launchUrl('https://www.tiktok.com/@ashwa.vlogs'),
                    iconColor: Colors.black,
                  ),
                  const SizedBox(height: 16),
                  _buildSocialMediaItem(
                    icon: FontAwesomeIcons.youtube,
                    title: 'YouTube',
                    subtitle: 'Subscribe to our channel',
                    onTap: () => _launchUrl('https://www.youtube.com/@GreatAwareness1'),
                    iconColor: Colors.red,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: icon is IconData ? Icon(icon, color: iconColor, size: 24) : FaIcon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaItem({
    required dynamic icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}