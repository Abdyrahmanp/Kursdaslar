import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topar_115/core/network/byethost_aes_solver.dart';
import 'package:topar_115/core/network/byethost_http_client.dart';

import 'dart:io';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  HttpOverrides.global = _RealHttpOverrides();


  group('ByethostAesSolver', () {
    test('solves challenge matching known test vector', () {
      const key = "f655ba9d09a112d4968c63579db590b4";
      const iv  = "98344c2eee86c3994890592585b49f80";
      const ct  = "887aeb236b7bdaccd02f7149e6219c32";
      const expected = "439a48c495a28ee8bec65951ab68dd0b";

      final solved = ByethostAesSolver.solve(key, iv, ct);
      expect(solved, expected);
    });

    test('extracts and solves from HTML script tag', () {
      const html = '''
<html><body><script type="text/javascript" src="/aes.js" ></script><script>
var a=toNumbers("f655ba9d09a112d4968c63579db590b4"),b=toNumbers("98344c2eee86c3994890592585b49f80"),c=toNumbers("887aeb236b7bdaccd02f7149e6219c32");
document.cookie="__test="+toHex(slowAES.decrypt(c,2,a,b))+"; max-age=21600; expires=Thu, 31-Dec-37 23:55:55 GMT; path=/";
</script></body></html>
''';
      final solved = ByethostAesSolver.extractAndSolve(html);
      expect(solved, "439a48c495a28ee8bec65951ab68dd0b");
    });
  });

  group('ByethostHttpClient live test', () {
    test('successfully fetches JSON from Byethost bypassing challenge', () async {
      SharedPreferences.setMockInitialValues({});
      final client = ByethostHttpClient();

      final res = await client.get(
        Uri.parse('https://kursdaslar.byethost4.com/api/announcements.php'),
        headers: {'Accept': 'application/json'},
      );

      expect(res.statusCode, 200);
      final decoded = jsonDecode(res.body);
      expect(decoded['success'], true);
      expect(decoded['data'], isA<List>());
      client.close();
    });
  });
}
