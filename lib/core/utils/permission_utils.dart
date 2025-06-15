import 'package:asistencias_app/data/models/user_model.dart';

class PermissionUtils {
  static bool isAdmin(UserModel user) {
    return user.role == 'admin';
  }

  static bool canManageLocations(UserModel user) {
    return user.role == 'admin' && user.isApproved;
  }

  static bool canManageUsers(UserModel user) {
    return user.role == 'admin' && user.isApproved;
  }

  static bool canViewReports(UserModel user) {
    return user.role == 'admin' && user.isApproved;
  }

  static bool canRecordAttendance(UserModel user) {
    return user.isApproved && user.sectorId != null;
  }

  static bool canManageSector(UserModel user, String sectorId) {
    return user.role == 'admin' && user.isApproved || 
           (user.role == 'normal_user' && user.isApproved && user.sectorId == sectorId);
  }
} 