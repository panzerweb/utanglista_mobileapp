import 'package:get_it/get_it.dart';
import 'package:utanglista_mobileapp/core/config/app_database.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<AppDatabase>(() => AppDatabase());

  /*
    REGISTRY FOR STORE SERVICES, REPOSITORIES, AND CUBITS
  */
}
