import 'ipv4.dart';

/// The result of calculating a single CIDR block.
///
/// All addresses are derived with integer bit math — no floating point and no
/// look-up shortcuts — so results are exact for every prefix length `0`…`32`.
class SubnetInfo {
  /// The original network address (host bits cleared).
  final Ipv4Address network;

  /// The prefix length (`0`…`32`).
  final int prefix;

  /// The subnet mask, e.g. `255.255.255.0` for `/24`.
  final Ipv4Address netmask;

  /// The inverse mask used by ACLs, e.g. `0.0.0.255`.
  final Ipv4Address wildcard;

  /// The highest address in the block.
  final Ipv4Address broadcast;

  /// The first host usable for assignment.
  final Ipv4Address? firstHost;

  /// The last host usable for assignment.
  final Ipv4Address? lastHost;

  /// Total number of addresses in the block (including network + broadcast).
  final int totalAddresses;

  /// Number of assignable hosts.
  final int usableHosts;

  const SubnetInfo({
    required this.network,
    required this.prefix,
    required this.netmask,
    required this.wildcard,
    required this.broadcast,
    required this.firstHost,
    required this.lastHost,
    required this.totalAddresses,
    required this.usableHosts,
  });

  /// Whether the block is a single host route (`/32`).
  bool get isHostRoute => prefix == 32;

  /// Whether the block is a point-to-point link (`/31`, RFC 3021).
  bool get isPointToPoint => prefix == 31;

  /// The range as `network/broadcast` text.
  String get range => '${network.dotted} - ${broadcast.dotted}';

  /// The block in CIDR notation, e.g. `192.168.1.0/24`.
  String get cidr => '${network.dotted}/$prefix';
}

/// A pure, stateless subnet calculator.
///
/// Every method is deterministic and side-effect free.
class SubnetCalculator {
  const SubnetCalculator._();

  /// Calculates the block that contains [address] under [prefix].
  ///
  /// [address] may be any host address inside the block; the network is found
  /// by masking off the host bits.
  static SubnetInfo calculate(Ipv4Address address, int prefix) {
    _checkPrefix(prefix);

    final mask = prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
    final networkValue = address.value & mask;
    final broadcastValue = networkValue | (~mask & 0xFFFFFFFF);

    final network = Ipv4Address.fromInt(networkValue);
    final broadcast = Ipv4Address.fromInt(broadcastValue);
    final total = broadcastValue - networkValue + 1;

    // RFC 3021: /31 is a point-to-point link with two usable addresses, and a
    // /32 is a single host route. Both special cases intentionally deviate from
    // the classic "total - 2" formula.
    int usable;
    Ipv4Address? firstHost;
    Ipv4Address? lastHost;
    if (prefix >= 31) {
      usable = total;
      firstHost = network;
      lastHost = broadcast;
    } else {
      usable = total - 2;
      firstHost = Ipv4Address.fromInt(networkValue + 1);
      lastHost = Ipv4Address.fromInt(broadcastValue - 1);
    }

    return SubnetInfo(
      network: network,
      prefix: prefix,
      netmask: Ipv4Address.fromInt(mask),
      wildcard: Ipv4Address.fromInt(~mask & 0xFFFFFFFF),
      broadcast: broadcast,
      firstHost: firstHost,
      lastHost: lastHost,
      totalAddresses: total,
      usableHosts: usable,
    );
  }

  /// Calculates the block directly from CIDR text such as `10.0.0.1/8`.
  static SubnetInfo parseCidr(String cidr) {
    final trimmed = cidr.trim();
    final slash = trimmed.indexOf('/');
    if (slash < 0) {
      throw const FormatException('CIDR must include a "/prefix".');
    }
    final addressPart = trimmed.substring(0, slash);
    final prefixPart = trimmed.substring(slash + 1);
    if (prefixPart.isEmpty) {
      throw const FormatException('Missing prefix length.');
    }
    final prefix = int.tryParse(prefixPart);
    if (prefix == null) {
      throw FormatException('Prefix "$prefixPart" is not a number.');
    }
    return calculate(Ipv4Address.parse(addressPart), prefix);
  }

  /// The default gateway convention: the first host in the block.
  static Ipv4Address? gatewayFor(SubnetInfo info) => info.firstHost;

  static void _checkPrefix(int prefix) {
    if (prefix < 0 || prefix > 32) {
      throw ArgumentError.value(prefix, 'prefix', 'must be between 0 and 32');
    }
  }
}
