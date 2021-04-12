import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zebra_rfid/flutter_zebra_rfid.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_zebra_rfid');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getSdkVersion', () async {
    expect(await FlutterZebraRfid().sdkVersion, '42');
  });
}
