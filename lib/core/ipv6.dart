/// Pure-Dart IPv6 arithmetic using [BigInt] for the full 128-bit space.
library;

/// A parsed IPv6 address.
class Ipv6Address implements Comparable<Ipv6Address> {
  /// The address as a 128-bit unsigned integer.
  final BigInt value;

  const Ipv6Address._(this.value);

  static final BigInt _max = (BigInt.one << 128) - BigInt.one;

  /// The unspecified address `::`.
  static final Ipv6Address any = Ipv6Address._(BigInt.zero);

  /// The loopback address `::1`.
  static final Ipv6Address loopback = Ipv6Address._(BigInt.one);

  factory Ipv6Address.fromBigInt(BigInt value) {
    if (value.isNegative || value > _max) {
      throw ArgumentError.value(value, 'value', 'must fit in 128 bits');
    }
    return Ipv6Address._(value);
  }

  /// Parses an IPv6 address, supporting `::` compression and a trailing
  /// embedded IPv4 form such as `::ffff:192.168.1.1`.
  factory Ipv6Address.parse(String input) {
    var text = input.trim();
    if (text.isEmpty) {
      throw const FormatException('Empty IPv6 address.');
    }
    if (text.contains('%')) {
      // Strip a zone index (e.g. fe80::1%wlan0); the scope is not part of the
      // numeric address.
      text = text.substring(0, text.indexOf('%'));
    }

    // Embedded IPv4 (dotted-quad) at the tail.
    if (text.contains('.')) {
      final lastColon = text.lastIndexOf(':');
      if (lastColon < 0) {
        throw FormatException('Invalid embedded IPv4 in "$input".');
      }
      final v4 = Ipv4AddressLite.parse(text.substring(lastColon + 1));
      text =
          '${text.substring(0, lastColon + 1)}'
          '${(v4 >> 16).toRadixString(16)}:${(v4 & BigInt.from(0xFFFF)).toRadixString(16)}';
    }

    final doubleColon = text.indexOf('::');
    List<String> head;
    List<String> tail;
    if (doubleColon >= 0) {
      if (text.indexOf('::', doubleColon + 1) >= 0) {
        throw FormatException('Multiple "::" in "$input".');
      }
      head = _splitNonEmpty(text.substring(0, doubleColon));
      tail = _splitNonEmpty(text.substring(doubleColon + 2));
    } else {
      head = _splitNonEmpty(text);
      tail = const [];
    }

    final explicit = head.length + tail.length;
    if (explicit > 8) {
      throw FormatException('Too many groups in "$input".');
    }
    if (doubleColon < 0 && explicit != 8) {
      throw FormatException('An IPv6 address needs eight groups ("$input").');
    }

    final groups = <int>[
      ...head.map((g) => _parseGroup(g, input)),
      ...List<int>.filled(8 - explicit, 0),
      ...tail.map((g) => _parseGroup(g, input)),
    ];

    var value = BigInt.zero;
    for (final group in groups) {
      value = (value << 16) | BigInt.from(group);
    }
    return Ipv6Address._(value);
  }

  static bool isValid(String input) {
    try {
      Ipv6Address.parse(input);
      return true;
    } on FormatException {
      return false;
    }
  }

  bool operator <(Ipv6Address other) => value < other.value;
  bool operator >(Ipv6Address other) => value > other.value;

  @override
  int compareTo(Ipv6Address other) => value.compareTo(other.value);

  /// The fully expanded form with eight 4-digit groups.
  String get expanded {
    final groups = <String>[];
    var v = value;
    for (var i = 0; i < 8; i++) {
      groups.insert(
        0,
        (v & BigInt.from(0xFFFF)).toRadixString(16).padLeft(4, '0'),
      );
      v >>= 16;
    }
    return groups.join(':');
  }

  /// The canonical compressed form with the longest run of zero groups
  /// replaced by `::` (RFC 5952).
  String get compressed {
    final groups = expanded.split(':');
    var bestStart = -1;
    var bestLen = 0;
    var i = 0;
    while (i < 8) {
      if (groups[i] == '0000') {
        var j = i;
        while (j < 8 && groups[j] == '0000') {
          j++;
        }
        final len = j - i;
        if (len > bestLen) {
          bestLen = len;
          bestStart = i;
        }
        i = j;
      } else {
        i++;
      }
    }
    if (bestLen < 2) {
      return groups.map(_trimGroup).join(':');
    }
    final left = groups.sublist(0, bestStart).map(_trimGroup).join(':');
    final right = groups.sublist(bestStart + bestLen).map(_trimGroup).join(':');
    return '$left::$right';
  }

  /// The address type as classified by the leading bits.
  Ipv6Type get type {
    if (value == BigInt.zero) return Ipv6Type.unspecified;
    if (value == BigInt.one) return Ipv6Type.loopback;
    if (_matches(BigInt.from(0xFE80) << 112, 10)) return Ipv6Type.linkLocal;
    if (_matches(BigInt.from(0xFC00) << 112, 7)) return Ipv6Type.uniqueLocal;
    if (_matches(BigInt.from(0xFF00) << 112, 8)) return Ipv6Type.multicast;
    if (_matches(BigInt.from(0x20010DB8) << 96, 32)) {
      return Ipv6Type.documentation;
    }
    if (_matches(BigInt.from(0x2000) << 112, 3)) return Ipv6Type.globalUnicast;
    return Ipv6Type.reserved;
  }

  /// Whether the top [prefixBits] bits of this address match [base].
  bool _matches(BigInt base, int prefixBits) =>
      (value >> (128 - prefixBits)) == (base >> (128 - prefixBits));

  static List<String> _splitNonEmpty(String part) =>
      part.isEmpty ? const [] : part.split(':');

  static int _parseGroup(String group, String original) {
    if (group.isEmpty || group.length > 4) {
      throw FormatException('Invalid group "$group" in "$original".');
    }
    for (final unit in group.toLowerCase().codeUnits) {
      final isDigit = unit >= 0x30 && unit <= 0x39;
      final isHex = unit >= 0x61 && unit <= 0x66;
      if (!isDigit && !isHex) {
        throw FormatException('Invalid group "$group" in "$original".');
      }
    }
    return int.parse(group, radix: 16);
  }

  static String _trimGroup(String group) {
    var trimmed = group.replaceFirst(RegExp(r'^0+'), '');
    if (trimmed.isEmpty) trimmed = '0';
    return trimmed;
  }

  /// The network address for [prefix] (host bits cleared).
  Ipv6Address networkForPrefix(int prefix) {
    if (prefix < 0 || prefix > 128) {
      throw ArgumentError.value(prefix, 'prefix', 'must be between 0 and 128');
    }
    final mask = prefix == 0
        ? BigInt.zero
        : (((BigInt.one << prefix) - BigInt.one) << (128 - prefix));
    return Ipv6Address._(value & mask);
  }

  /// The last address in the block for [prefix].
  Ipv6Address lastForPrefix(int prefix) {
    final network = networkForPrefix(prefix);
    final mask = prefix == 0
        ? BigInt.zero
        : (((BigInt.one << prefix) - BigInt.one) << (128 - prefix));
    return Ipv6Address._(network.value | (_max ^ mask));
  }

  @override
  bool operator ==(Object other) =>
      other is Ipv6Address && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => compressed;
}

/// An IPv6 address category.
enum Ipv6Type {
  unspecified,
  loopback,
  linkLocal,
  uniqueLocal,
  multicast,
  documentation,
  globalUnicast,
  reserved,
}

extension Ipv6TypeLabel on Ipv6Type {
  String get label => switch (this) {
    Ipv6Type.unspecified => 'Unspecified (::)',
    Ipv6Type.loopback => 'Loopback (::1)',
    Ipv6Type.linkLocal => 'Link-local (fe80::/10)',
    Ipv6Type.uniqueLocal => 'Unique local (fc00::/7)',
    Ipv6Type.multicast => 'Multicast (ff00::/8)',
    Ipv6Type.documentation => 'Documentation (2001:db8::/32)',
    Ipv6Type.globalUnicast => 'Global unicast (2000::/3)',
    Ipv6Type.reserved => 'Reserved',
  };
}

/// A minimal 32-bit helper shared with the IPv6 parser for embedded IPv4.
class Ipv4AddressLite {
  static BigInt parse(String input) {
    final parts = input.trim().split('.');
    if (parts.length != 4) {
      throw const FormatException('Invalid embedded IPv4 address.');
    }
    var value = BigInt.zero;
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) {
        throw const FormatException('Invalid embedded IPv4 octet.');
      }
      value = (value << 8) | BigInt.from(octet);
    }
    return value;
  }
}
