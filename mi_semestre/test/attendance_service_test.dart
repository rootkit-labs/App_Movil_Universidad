import 'package:flutter_test/flutter_test.dart';
import 'package:mi_semestre/services/attendance_service.dart';

void main() {
  test('usa la URL exacta del formulario de asistencia', () {
    final uri = Uri.parse(attendanceUrl);

    expect(uri.scheme, 'https');
    expect(uri.host, 'forms.office.com');
    expect(uri.queryParameters['origin'], 'QRCode');
    expect(
      attendanceUrl,
      contains(
        '3ewSDS3KfU6FI8WmfMhhJDEyTCRJDoxKq-K_hAxbddZUOThXNkhTUkU5VUlZVjhUUjVLMlNFQVRONy4u',
      ),
    );
  });
}
