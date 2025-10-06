class DeviceInfo {
  final String name;
  final String ip;
  final String mac;
  final int upstream;
  final int downstream;
  final bool internetAccess;
  final bool storageAccess;

  DeviceInfo({
    required this.name,
    required this.ip,
    required this.mac,
    required this.upstream,
    required this.downstream,
    required this.internetAccess,
    required this.storageAccess,
  });

  @override
  String toString() {
    return '$name | $ip | $mac | ↑$upstream ↓$downstream | Inet:$internetAccess Stg:$storageAccess';
  }
}

class TempleUserInfo {
  String sendLightPower = "--";
  String receiveLightPower = "--";
  String workVoltage = "--";
  String workCorrect = "--";
  String temperature = "--";
  String verificationStatus = "--";

  TempleUserInfo();
}

class NetworkInterfaceInfo {
  final String name;
  final String connectionType;
  final String status;
  final String ip;
  final String dns1;
  final String dns2;

  NetworkInterfaceInfo({
    required this.name,
    required this.connectionType,
    required this.status,
    required this.ip,
    required this.dns1,
    required this.dns2,
  });

  @override
  String toString() {
    return '$name [$connectionType] - $status\nIP: $ip\nDNS1: $dns1\nDNS2: $dns2';
  }
}