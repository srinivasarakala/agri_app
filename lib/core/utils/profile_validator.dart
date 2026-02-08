import 'package:flutter/material.dart';
import '../../features/profile/user_profile.dart';
import '../../features/shell/app_shell.dart';

class ProfileValidator {
  /// Checks if the user profile is complete enough to place orders
  static bool isProfileComplete(UserProfile profile) {
    // Required fields for order placement
    final hasName =
        profile.firstName != null && profile.firstName!.trim().isNotEmpty;
    final hasAddress =
        profile.address != null && profile.address!.trim().isNotEmpty;
    final hasCity = profile.city != null && profile.city!.trim().isNotEmpty;
    final hasState = profile.state != null && profile.state!.trim().isNotEmpty;
    final hasPincode =
        profile.pincode != null && profile.pincode!.trim().isNotEmpty;

    return hasName && hasAddress && hasCity && hasState && hasPincode;
  }

  /// Returns a list of missing fields
  static List<String> getMissingFields(UserProfile profile) {
    final missing = <String>[];

    if (profile.firstName == null || profile.firstName!.trim().isEmpty) {
      missing.add('First Name');
    }
    if (profile.address == null || profile.address!.trim().isEmpty) {
      missing.add('Delivery Address');
    }
    if (profile.city == null || profile.city!.trim().isEmpty) {
      missing.add('City');
    }
    if (profile.state == null || profile.state!.trim().isEmpty) {
      missing.add('State');
    }
    if (profile.pincode == null || profile.pincode!.trim().isEmpty) {
      missing.add('Pincode');
    }

    return missing;
  }

  /// Shows a dialog prompting user to complete their profile
  static void showIncompleteProfileDialog(
    BuildContext context,
    List<String> missingFields,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Complete Your Profile'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please complete your profile before placing an order.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Missing information:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ...missingFields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(field, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to Profile tab (index 3)
              appTabIndex.value = 3;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete Profile'),
          ),
        ],
      ),
    );
  }
}
