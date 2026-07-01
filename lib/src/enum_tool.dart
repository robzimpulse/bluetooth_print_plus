/// BlueState
enum BlueState { blueOn, blueOff }

/// ConnectState
enum ConnectState { connected, disconnected }

/// PairState — mirrors Android BluetoothDevice bond constants (10/11/12).
/// On iOS, pairing is OS-managed; this state is never emitted.
enum PairState { none, bonding, bonded }

/// Major Bluetooth device class — mirrors BluetoothClass.Device.Major on Android.
/// Always [unknown] on iOS (CoreBluetooth does not expose device class).
enum BluetoothMajorClass {
  misc,          // 0x0000
  computer,      // 0x0100
  phone,         // 0x0200
  networking,    // 0x0300
  audioVideo,    // 0x0400 — headsets, speakers, headphones
  peripheral,    // 0x0500 — keyboards, mice
  imaging,       // 0x0600 — printers, scanners, cameras
  wearable,      // 0x0700
  toy,           // 0x0800
  health,        // 0x0900
  uncategorized, // 0x1F00
  unknown,
}

/// Rotation
enum Rotation { r_0, r_90, r_180, r_270 }

/// BarCodeType
enum BarCodeType {
  c_128,
  c_39,
  c_93,
  c_ITF,
  c_UPCA,
  c_UPCE,
  c_CODABAR,
  c_EAN8,
  c_EAN13,
}

/// EscTextStyle
enum EscTextStyle { default_, bold, underline, boldAndUnderline }

/// EscFontSize
enum EscFontSize {
  default_,
  size1,
  size2,
  size3,
  size4,
  size5,
  size6,
  size7,
}

/// HriPosition
enum HriPosition { none, above, below, aboveAndBelow }

/// Alignment
enum Alignment { left, center, right }

/// EnumTool
class EnumTool {
  /// getRotation
  static int getRotation(Rotation rotation) {
    switch (rotation) {
      case Rotation.r_0:
        return 0;
      case Rotation.r_90:
        return 90;
      case Rotation.r_180:
        return 180;
      case Rotation.r_270:
        return 270;
    }
  }

  /// getCodeType
  static String getCodeType(BarCodeType codeType) {
    switch (codeType) {
      case BarCodeType.c_128:
        return "128";
      case BarCodeType.c_39:
        return "39";
      case BarCodeType.c_93:
        return "93";
      case BarCodeType.c_ITF:
        return "ITF";
      case BarCodeType.c_UPCA:
        return "UPCA";
      case BarCodeType.c_UPCE:
        return "UPCE";
      case BarCodeType.c_CODABAR:
        return "CODABAR";
      case BarCodeType.c_EAN8:
        return "EAN8";
      case BarCodeType.c_EAN13:
        return "EAN13";
    }
  }

  /// getEscTextStyle
  static int getEscTextStyle(EscTextStyle style) {
    switch (style) {
      case EscTextStyle.default_:
        return 0x0;
      case EscTextStyle.bold:
        return 0x08;
      case EscTextStyle.underline:
        return 0x80;
      case EscTextStyle.boldAndUnderline:
        return 0x88;
    }
  }

  /// getEscFontSize
  static int getEscFontSize(EscFontSize size) {
    switch (size) {
      case EscFontSize.default_:
        return 0;
      case EscFontSize.size1:
        return 1;
      case EscFontSize.size2:
        return 2;
      case EscFontSize.size3:
        return 3;
      case EscFontSize.size4:
        return 4;
      case EscFontSize.size5:
        return 5;
      case EscFontSize.size6:
        return 6;
      case EscFontSize.size7:
        return 7;
    }
  }

  /// getHri
  static int getHri(HriPosition position) {
    switch (position) {
      case HriPosition.none:
        return 0;
      case HriPosition.above:
        return 1;
      case HriPosition.below:
        return 2;
      case HriPosition.aboveAndBelow:
        return 3;
    }
  }

  /// getAlignment
  static int getAlignment(Alignment alignment) {
    switch (alignment) {
      case Alignment.left:
        return 0;
      case Alignment.center:
        return 1;
      case Alignment.right:
        return 2;
    }
  }

  /// getMajorClass — maps a raw Android BluetoothClass.Device.Major int to [BluetoothMajorClass].
  static BluetoothMajorClass getMajorClass(int value) {
    switch (value) {
      case 0x0000: return BluetoothMajorClass.misc;
      case 0x0100: return BluetoothMajorClass.computer;
      case 0x0200: return BluetoothMajorClass.phone;
      case 0x0300: return BluetoothMajorClass.networking;
      case 0x0400: return BluetoothMajorClass.audioVideo;
      case 0x0500: return BluetoothMajorClass.peripheral;
      case 0x0600: return BluetoothMajorClass.imaging;
      case 0x0700: return BluetoothMajorClass.wearable;
      case 0x0800: return BluetoothMajorClass.toy;
      case 0x0900: return BluetoothMajorClass.health;
      case 0x1F00: return BluetoothMajorClass.uncategorized;
      default: return BluetoothMajorClass.unknown;
    }
  }
}
