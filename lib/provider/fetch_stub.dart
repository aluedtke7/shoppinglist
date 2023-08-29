import 'package:fetch_client/fetch_client.dart';

// see also https://github.com/pocketbase/dart-sdk#limitations

FetchClient getClient() {
  return FetchClient(mode: RequestMode.cors);
}
