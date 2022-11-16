import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_streaming/data/datasources/remote_datasource.dart';
import 'package:video_streaming/domain/repositories/auth_repository.dart';
import 'package:video_streaming/utils/logger.dart';

class AuthRepository implements AuthRepositoryInt {
  final RemoteDataSource _remoteDatasource;

  AuthRepository(this._remoteDatasource);

  @override
  Future<void> signInAnonymously() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      _remoteDatasource.userId = userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'operation-not-allowed':
          Logger.printRed(
            message: 'Anonymous auth hasn\'t been enabled for this project',
            filename: 'auth_repository',
            method: 'signInAnonymously',
            line: 18,
          );
          break;
        default:
          Logger.printRed(
            message: 'Unknown error',
            filename: 'auth_repository',
            method: 'signInAnonymously',
            line: 26,
          );
      }
    }
  }
}
