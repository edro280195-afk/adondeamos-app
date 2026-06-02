import 'package:adondeamos/app/app_config.dart';
import 'package:adondeamos/core/api/auth_api.dart';
import 'package:adondeamos/core/api/decisions_api.dart';
import 'package:adondeamos/core/api/groups_api.dart';
import 'package:adondeamos/core/api/http_client.dart';
import 'package:adondeamos/core/api/invitations_api.dart';
import 'package:adondeamos/core/api/lists_api.dart';
import 'package:adondeamos/core/api/places_api.dart';
import 'package:adondeamos/core/api/saves_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final httpClientProvider = Provider<HttpApiClient>((ref) {
  return HttpApiClient(baseUrl: AppConfig.apiBaseUrl);
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.read(httpClientProvider));
});

final placesApiProvider = Provider<PlacesApi>((ref) {
  return PlacesApi(ref.read(httpClientProvider));
});

final savesApiProvider = Provider<SavesApi>((ref) {
  return SavesApi(ref.read(httpClientProvider));
});

final groupsApiProvider = Provider<GroupsApi>((ref) {
  return GroupsApi(ref.read(httpClientProvider));
});

final invitationsApiProvider = Provider<InvitationsApi>((ref) {
  return InvitationsApi(ref.read(httpClientProvider));
});

final listsApiProvider = Provider<ListsApi>((ref) {
  return ListsApi(ref.read(httpClientProvider));
});

final decisionsApiProvider = Provider<DecisionsApi>((ref) {
  return DecisionsApi(ref.read(httpClientProvider));
});
