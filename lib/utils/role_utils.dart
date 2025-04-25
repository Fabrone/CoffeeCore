import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class RoleUtils {
  static final Logger _logger = Logger(printer: PrettyPrinter());

  static Future<String> getUserRole(String userId, String cooperativeName) async {
    try {
      String formattedCoopName = cooperativeName.replaceAll(' ', '_');
      _logger.i('Checking role for userId: $userId in cooperative: $formattedCoopName');

      // Check if user is a Coop Admin
      DocumentSnapshot coopAdminDoc = await FirebaseFirestore.instance
          .collection('CoopAdmins')
          .doc(userId)
          .get();
      if (coopAdminDoc.exists && coopAdminDoc['cooperative'] == formattedCoopName) {
        _logger.i('User $userId is a Coop Admin');
        return 'Coop Admin';
      } else {
        _logger.i('User $userId is not a Coop Admin');
      }

      // Check if user is a Market Manager
      String marketManagerCollection = '${formattedCoopName}_marketmanagers';
      DocumentSnapshot marketManagerDoc = await FirebaseFirestore.instance
          .collection(marketManagerCollection)
          .doc(userId)
          .get();
      if (marketManagerDoc.exists) {
        _logger.i('User $userId is a Market Manager in $marketManagerCollection');
        return 'Market Manager';
      } else {
        _logger.i('User $userId is not a Market Manager in $marketManagerCollection');
      }

      // Default to User
      _logger.i('User $userId is a regular User');
      return 'User';
    } catch (e) {
      _logger.e('Error determining user role for $userId in $cooperativeName: $e');
      return 'User';
    }
  }
}