
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tp3_v2/data/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());