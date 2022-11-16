import 'package:video_streaming/data/repositories/auth_repository.dart';
import 'package:video_streaming/data/repositories/room_repository.dart';
import 'package:video_streaming/di/injector.dart';
import 'package:video_streaming/domain/repositories/auth_repository.dart';
import 'package:video_streaming/domain/repositories/room_repository.dart';

void initRepositoryModule() {
  i.registerSingleton<RoomRepositoryInt>(RoomRepository(i.get()));
  i.registerSingleton<AuthRepositoryInt>(AuthRepository(i.get()));
}
