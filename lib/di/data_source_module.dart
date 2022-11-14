import 'package:video_streaming/data/datasources/remote_datasource.dart';
import 'package:video_streaming/di/injector.dart';

void initDataSourceModule() {
  i.registerSingleton<RemoteDataSource>(
    RemoteDataSource(),
  );
}
