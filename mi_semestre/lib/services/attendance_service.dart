import 'package:url_launcher/url_launcher.dart';

const String attendanceUrl =
    'https://forms.office.com/Pages/ResponsePage.aspx?id=3ewSDS3KfU6FI8WmfMhhJDEyTCRJDoxKq-K_hAxbddZUOThXNkhTUkU5VUlZVjhUUjVLMlNFQVRONy4u&origin=QRCode';

Future<bool> openAttendanceForm() async {
  final uri = Uri.parse(attendanceUrl);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
