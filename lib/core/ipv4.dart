/// Pure-Dart IPv4 arithmetic.
///
/// This file contains no Flutter imports on purpose: the networking engine is
/// platform-independent and can be unit-tested on its own. Every value is
/// represented as an unsigned 32-bit integer stored in a Dart `int`.
library;

/// A parsed IPv4 address.
///
/// Instances are immutable and compare by numeric value.
class Ipv4Address implements Comparable<Ipv4Address> {
  /// The address as an unsigned 32-bit integer (`0` … `4294967295`).
  final int value;

  const Ipv4Address._(this.value);

  /// The lowest possible address, `0.0.0.0`.
  static const Ipv4Address zero = Ipv4Address._(0);

  /// Builds an address from a raw 32-bit integer.
  factory Ipv4Address.fromInt(int value) {
    if (value < 0 || value > 0xFFFFFFFF) {
      throw ArgumentError.value(value, 'value', 'must fit in 32 bits');
    }
    return Ipv4Address._(value);
  }

  /// Parses dotted-quad text such as `192.168.1.10`.
  ///
  /// Throws [FormatException] when the text is not a valid IPv4 address.
  factory Ipv4Address.parse(String input) {
    final parts = input.trim().split('.');
    if (parts.length != 4) {
      throw FormatException('An IPv4 address needs four octets.', input);
    }
    var value = 0;
    for (final part in parts) {
      if (part.isEmpty || part.length > 3) {
        throw FormatException('Invalid octet "$part".', input);
      }
      for (final unit in part.codeUnits) {
        if (unit < 0x30 || unit > 0x39) {
          throw FormatException('Invalid octet "$part".', input);
        }
      }
      final octet = int.parse(part);
      if (octet > 255) {
        throw FormatException('Octet "$part" is greater than 255.', input);
      }
      value = (value << 8) | octet;
    }
    return Ipv4Address._(value);
  }

  /// Returns `true` if [input] can be parsed as an IPv4 address.
  static bool isValid(String input) {
    try {
      Ipv4Address.parse(input);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// Adds [delta] to the address, clamped to the 32-bit space.
  Ipv4Address operator +(int delta) =>
      Ipv4Address._((value + delta) & 0xFFFFFFFF);

  bool operator <(Ipv4Address other) => value < other.value;
  bool operator >(Ipv4Address other) => value > other.value;
  bool operator <=(Ipv4Address other) => value <= other.value;
  bool operator >=(Ipv4Address other) => value >= other.value;

  @override
  int compareTo(Ipv4Address other) => value.compareTo(other.value);

  /// The dotted-quad form, e.g. `192.168.1.10`.
  String get dotted =>
      '${(value >> 24) & 0xFF}.'
      '${(value >> 16) & 0xFF}.'
      '${(value >> 8) & 0xFF}.'
      '${value & 0xFF}';

  /// The 32-bit binary form, e.g. `11000000.10101000.00000001.00001010`.
  String get binary =>
      '${_octet(value >> 24)}.'
      '${_octet(value >> 16)}.'
      '${_octet(value >> 8)}.'
      '${_octet(value)}';

  /// The hexadecimal form, e.g. `C0A8010A`.
  String get hex => value.toRadixString(16).toUpperCase().padLeft(8, '0');

  /// The reverse-DNS name (in-addr.arpa) for this address.
  String get reverseDns =>
      '${(value & 0xFF)}.${(value >> 8) & 0xFF}.'
      '${(value >> 16) & 0xFF}.${(value >> 24) & 0xFF}.in-addr.arpa';

  /// The IANA/RIR allocation class of the address.
  AddressClass get addressClass {
    final first = (value >> 24) & 0xFF;
    if (first == 0) return AddressClass.unspecified;
    if (first < 128) return AddressClass.a;
    if (first < 192) return AddressClass.b;
    if (first < 224) return AddressClass.c;
    if (first < 240) return AddressClass.d;
    return AddressClass.e;
  }

  /// Whether the address belongs to a private (RFC 1918) range.
  bool get isPrivate =>
      isInRange(0x0A000000, 0x0AFFFFFF) ||
      isInRange(0xAC100000, 0xAC1FFFFF) ||
      isInRange(0xC0A80000, 0xC0A8FFFF);

  /// Whether the address is loopback (`127.0.0.0/8`).
  bool get isLoopback => isInRange(0x7F000000, 0x7FFFFFFF);

  /// Whether the address is link-local (`169.254.0.0/16`).
  bool get isLinkLocal => isInRange(0xA9FE0000, 0xA9FEFFFF);

  /// Whether the address is multicast (`224.0.0.0/4`).
  bool get isMulticast => isInRange(0xE0000000, 0xEFFFFFFF);

  /// Whether the address is in the Carrier-Grade NAT block (`100.64.0.0/10`).
  bool get isShared => isInRange(0x64400000, 0x647FFFFF);

  /// Whether the address is in a documentation range (`192.0.2.0/24`,
  /// `198.51.100.0/24`, `203.0.113.0/24`).
  bool get isDocumentation =>
      isInRange(0xC0000200, 0xC00002FF) ||
      isInRange(0xC6336400, 0xC63364FF) ||
      isInRange(0xCB007100, 0xCB0071FF);

  /// Whether the address is reserved / not globally routable.
  bool get isReserved =>
      isPrivate ||
      isLoopback ||
      isLinkLocal ||
      isMulticast ||
      isShared ||
      isDocumentation ||
      isInRange(0xF0000000, 0xFFFFFFFF) ||
      isInRange(0x00000000, 0x00FFFFFF);

  /// Whether this address sits inside the inclusive range [start, end].
  bool isInRange(int start, int end) => value >= start && value <= end;

  /// The first-octet value (network class helper).
  int get firstOctet => (value >> 24) & 0xFF;

  String _octet(int shift) => ((shift & 0xFF)).toRadixString(2).padLeft(8, '0');

  @override
  bool operator ==(Object other) =>
      other is Ipv4Address && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => dotted;
}

/// The historical classful address classification.
enum AddressClass { a, b, c, d, e, unspecified }

extension AddressClassLabel on AddressClass {
  String get label => switch (this) {
    AddressClass.a => 'Class A',
    AddressClass.b => 'Class B',
    AddressClass.c => 'Class C',
    AddressClass.d => 'Class D (multicast)',
    AddressClass.e => 'Class E (reserved)',
    AddressClass.unspecified => 'Unspecified / this-network',
  };
}
