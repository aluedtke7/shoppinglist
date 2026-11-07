import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shoppinglist/service/article_repository.dart';

/// Records realtime (un)subscriptions instead of opening a connection to a server.
class FakeRecordService extends RecordService {
  FakeRecordService(super.client, super.collectionIdOrName);

  final listeners = <RecordSubscriptionFunc>[];
  var unsubscribeAllCalls = 0;

  @override
  Future<UnsubscribeFunc> subscribe(
    String topic,
    RecordSubscriptionFunc callback, {
    String? expand,
    String? filter,
    String? fields,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
  }) async {
    listeners.add(callback);
    return () async => listeners.remove(callback);
  }

  @override
  Future<void> unsubscribe([String topic = '']) async => unsubscribeAllCalls++;

  void emit(String action, Map<String, dynamic> record) {
    for (final listener in List.of(listeners)) {
      listener(RecordSubscriptionEvent(action: action, record: RecordModel(record)));
    }
  }
}

class FakePocketBase extends PocketBase {
  FakePocketBase() : super('http://localhost:8090');

  late final service = FakeRecordService(this, 'shoppinglist');

  @override
  RecordService collection(String collectionIdOrName) => service;
}

void main() {
  late FakePocketBase pb;
  late ArticleRepository repository;
  late int changes;

  setUp(() {
    pb = FakePocketBase();
    changes = 0;
    repository = ArticleRepository(pbSync: () => pb, ensurePb: () async => true, onChange: () => changes++);
  });

  test('shows articles changed on another device', () async {
    await repository.subscribeActive();

    pb.service.emit('create', {'id': '1', 'article': 'Milch', 'amount': 2, 'active': true});

    expect(repository.active.single.article, 'Milch');
    expect(changes, 1);
  });

  test('subscribes only once when called repeatedly', () async {
    await Future.wait([repository.subscribeActive(), repository.subscribeActive()]);
    await repository.subscribeActive();

    expect(pb.service.listeners, hasLength(1));
  });

  test('removes only its own listener when unsubscribing', () async {
    void otherListener(RecordSubscriptionEvent e) {}
    await pb.service.subscribe('*', otherListener);
    await repository.subscribeActive();

    await repository.unsubscribeActive();

    expect(pb.service.listeners, [otherListener]);
    expect(pb.service.unsubscribeAllCalls, 0);
  });

  test('replaces the subscription by a fresh one when resubscribing', () async {
    await repository.subscribeActive();
    final oldListener = pb.service.listeners.single;

    await repository.resubscribeActive();

    expect(pb.service.listeners, hasLength(1));
    expect(pb.service.listeners.single, isNot(same(oldListener)));
  });
}
