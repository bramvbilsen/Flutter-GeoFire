import 'dart:math';

String generateUUID() {
  int d = new DateTime.now().millisecondsSinceEpoch;
  String uuid = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx";
  Random ran = new Random();
  return uuid.replaceAllMapped(new RegExp(r'y|x'), (Match m) {
    for(int i = 0; i < m[0].length; i++) {
      String c = m[0][i];
      int r = ((d + ran.nextDouble()*16)%16).toInt() | 0;
      return (c=='x' ? r : (r&0x3|0x8)).toRadixString(16);
    }
  });
}