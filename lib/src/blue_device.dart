import 'enum_tool.dart';

/// BluetoothDevice
class BluetoothDevice {
  BluetoothDevice(this.name, this.address);

  /// printer name
  String name;

  /// printer id
  String address;

  /// radio type: 0=unknown, 1=classic, 2=BLE, 3=dual
  int type = 0;

  /// raw Android BluetoothClass.Device.Major value (0 on iOS)
  int majorClass = 0;

  /// raw Android BluetoothClass.Device value (0 on iOS)
  int deviceClass = 0;

  /// typed major device class — use this to filter by category (printer, headset, etc.)
  BluetoothMajorClass get majorClassType => EnumTool.getMajorClass(majorClass);

  /// BluetoothDevice obj from json
  factory BluetoothDevice.fromJson(Map<String, dynamic> json) {
    return BluetoothDevice(json['name'], json['address'])
      ..type = (json['type'] as int?) ?? 0
      ..majorClass = (json['majorClass'] as int?) ?? 0
      ..deviceClass = (json['deviceClass'] as int?) ?? 0;
  }

  /// BluetoothDevice obj to json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'type': type,
      'majorClass': majorClass,
      'deviceClass': deviceClass,
    };
  }
}
