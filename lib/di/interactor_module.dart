import 'package:video_streaming/di/injector.dart';
import 'package:video_streaming/domain/interactors/webrtc_interactor.dart';

void initInteractorModule() {
  i.registerFactory<WebrtcInteractor>(() => WebrtcInteractor(i.get()));
}
