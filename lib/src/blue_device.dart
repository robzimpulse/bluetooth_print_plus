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

  /// raw Android bond state: 10=none, 11=bonding, 12=bonded (0 on iOS)
  int bondState = 10;

  /// whether this device is currently connected through this plugin
  bool isConnected = false;

  /// typed major device class — use this to filter by category (printer, headset, etc.)
  BluetoothMajorClass get majorClassType => EnumTool.getMajorClass(majorClass);

  /// typed bond/pair state
  PairState get pairStateType => EnumTool.getPairState(bondState);

  /// BluetoothDevice obj from json
  factory BluetoothDevice.fromJson(Map<String, dynamic> json) {
    return BluetoothDevice(json['name'], json['address'])
      ..type = (json['type'] as int?) ?? 0
      ..majorClass = (json['majorClass'] as int?) ?? 0
      ..deviceClass = (json['deviceClass'] as int?) ?? 0
      ..bondState = (json['bondState'] as int?) ?? 10
      ..isConnected = (json['isConnected'] as bool?) ?? false;
  }

  /// BluetoothDevice obj to json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'type': type,
      'majorClass': majorClass,
      'deviceClass': deviceClass,
      'bondState': bondState,
      'isConnected': isConnected,
    };
  }
}
