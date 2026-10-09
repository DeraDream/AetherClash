import 'package:dio/dio.dart';
import 'package:fl_clash/common/request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getTextResponseForUrl propagates the typed DioException', () async {
    // flutter_test's mocked HttpClient answers every request with HTTP 400,
    // which Dio surfaces as a badResponse DioException.
    await expectLater(
      request.getTextResponseForUrl('http://127.0.0.1/anything'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.badResponse,
        ),
      ),
    );
  });

  test('getFileResponseForUrl propagates the typed DioException', () async {
    await expectLater(
      request.getFileResponseForUrl('http://127.0.0.1/anything'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.badResponse,
        ),
      ),
    );
  });

  test('keeps browser destinations aligned with the IP sources', () {
    expect(request.ipInfoSourceLabels.keys, unorderedEquals({
      'https://ipwho.is',
      'http://ip-api.com/json',
      'https://api.ip.sb/geoip',
      'https://my.ippure.com/v1/info',
    }));
    expect(
      request.ipInfoSourceWebsites['https://api.ip.sb/geoip'],
      Uri.parse('https://ip.sb'),
    );
    expect(
      request.ipInfoSourceWebsites['https://my.ippure.com/v1/info'],
      Uri.parse('https://ippure.com'),
    );
  });
}
