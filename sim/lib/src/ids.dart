/// A stable, MAC-shaped device id derived from [seed] (e.g. `name:port`).
/// Not a real MAC — `sim` has no network hardware to read one from — but
/// looking like one keeps it a drop-in match for the `id` field's usual
/// shape (docs/01-architektura.md), and deriving it from the launch
/// parameters means the same `--name`/`--port` combo gets the same id run
/// to run, which is convenient once the app starts caching device IDs.
String syntheticMac(String seed) {
  var hash = 0;
  for (final code in seed.codeUnits) {
    hash = (hash * 31 + code) & 0xffffffff;
  }
  final bytes = List<int>.generate(6, (i) => (hash >> (i * 5)) & 0xff);
  bytes[0] = (bytes[0] & 0xfe) | 0x02; // locally administered, unicast
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
}
