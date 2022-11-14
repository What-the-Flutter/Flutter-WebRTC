import 'package:get_it/get_it.dart';
import 'package:video_streaming/di/cubit_module.dart';
import 'package:video_streaming/di/data_source_module.dart';
import 'package:video_streaming/di/interactor_module.dart';
import 'package:video_streaming/di/repository_module.dart';

GetIt get i => GetIt.instance;

void initInjector() {
  initDataSourceModule();
  initRepositoryModule();
  initInteractorModule();
  initCubitModule();
}
