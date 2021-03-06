import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

Stream<int> _getStream() {
  StreamController<int> controller = new StreamController<int>();

  new Timer(const Duration(milliseconds: 10), () => controller.add(1));
  new Timer(const Duration(milliseconds: 20), () => controller.add(2));
  new Timer(const Duration(milliseconds: 30), () => controller.add(3));
  new Timer(const Duration(milliseconds: 40), () {
    controller.add(4);
    controller.close();
  });

  return controller.stream;
}

Stream<int> _getOtherStream(int value) {
  StreamController<int> controller = new StreamController<int>();

  new Timer(const Duration(milliseconds: 15), () => controller.add(value + 1));
  new Timer(const Duration(milliseconds: 25), () => controller.add(value + 2));
  new Timer(const Duration(milliseconds: 35), () => controller.add(value + 3));
  new Timer(const Duration(milliseconds: 45), () {
    controller.add(value + 4);
    controller.close();
  });

  return controller.stream;
}

Stream<int> range() =>
    new Stream<int>.fromIterable(<int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

void main() {
  test('rx.Observable.switchMap', () async {
    const List<int> expectedOutput = const <int>[5, 6, 7, 8];
    int count = 0;

    new Observable<int>(_getStream())
        .switchMap(_getOtherStream)
        .listen(expectAsync1((num result) {
          expect(result, expectedOutput[count++]);
        }, count: expectedOutput.length));
  });

  test('rx.Observable.switchMap.reusable', () async {
    final SwitchMapStreamTransformer<int, int> transformer =
        new SwitchMapStreamTransformer<int, int>(_getOtherStream);
    const List<int> expectedOutput = const <int>[5, 6, 7, 8];
    int countA = 0, countB = 0;

    new Observable<int>(_getStream())
        .transform(transformer)
        .listen(expectAsync1((num result) {
          expect(result, expectedOutput[countA++]);
        }, count: expectedOutput.length));

    new Observable<int>(_getStream())
        .transform(transformer)
        .listen(expectAsync1((num result) {
          expect(result, expectedOutput[countB++]);
        }, count: expectedOutput.length));
  });

  test('rx.Observable.switchMap.asBroadcastStream', () async {
    Stream<num> stream = new Observable<int>(_getStream().asBroadcastStream())
        .switchMap(_getOtherStream);

    // listen twice on same stream
    stream.listen((_) {});
    stream.listen((_) {});
    // code should reach here
    await expectLater(true, true);
  });

  test('rx.Observable.switchMap.error.shouldThrowA', () async {
    Stream<int> observableWithError =
        new Observable<int>(new ErrorStream<int>(new Exception()))
            .switchMap(_getOtherStream);

    observableWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('rx.Observable.switchMap.error.shouldThrowB', () async {
    Stream<int> observableWithError = new Observable<int>.just(1).switchMap(
        (_) => new ErrorStream<int>(new Exception('Catch me if you can!')));

    observableWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('rx.Observable.switchMap.error.shouldThrowC', () async {
    Stream<int> observableWithError =
        new Observable<int>.just(1).switchMap((_) {
      throw new Exception('oh noes!');
    });

    observableWithError.listen(null,
        onError: expectAsync2((Exception e, StackTrace s) {
      expect(e, isException);
    }));
  });

  test('rx.Observable.switchMap.pause.resume', () async {
    StreamSubscription<int> subscription;
    Observable<int> stream = new Observable<int>.just(0)
        .switchMap((_) => new Observable<int>.just(1));

    subscription = stream.listen(expectAsync1((int value) {
      expect(value, 1);

      subscription.cancel();
    }, count: 1));

    subscription.pause();
    subscription.resume();
  });
}
