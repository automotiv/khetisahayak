import 'package:permission_handler/permission_handler.dart';

abstract class PermissionAdapter {
  Future<PermissionStatus> status(Permission permission);
  Future<PermissionStatus> request(Permission permission);
}

class PermissionAdapterImpl implements PermissionAdapter {
  @override
  Future<PermissionStatus> status(Permission permission) => permission.status;

  @override
  Future<PermissionStatus> request(Permission permission) => permission.request();
}
