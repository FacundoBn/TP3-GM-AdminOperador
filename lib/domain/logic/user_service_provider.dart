
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tp3_v2/data/user_service.dart';
import 'package:tp3_v2/domain/models/user_model.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final usersByRolProvider = FutureProvider.family<List<UserModel>, String>((ref, role) {
  final userService = ref.read(userServiceProvider);
  return userService.fetchClientsByRole(role);
});