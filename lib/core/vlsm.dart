import 'ipv4.dart';
import 'subnet.dart';

/// The strategy used to divide a parent block.
enum VlsmMode {
  /// Split the block into a fixed number of equally sized subnets.
  equalSplit,

  /// Allocate subnets sized to fit a list of required host counts.
  hostRequirements,
}

/// A single allocation produced by the VLSM engine.
class VlsmAllocation {
  final String name;
  final SubnetInfo subnet;

  const VlsmAllocation({required this.name, required this.subnet});

  String get cidr => subnet.cidr;
  int get prefix => subnet.prefix;
}

/// The outcome of a VLSM plan, including any requests that could not fit.
class VlsmPlan {
  final SubnetInfo parent;
  final List<VlsmAllocation> allocations;
  final List<String> unallocated;

  const VlsmPlan({
    required this.parent,
    required this.allocations,
    required this.unallocated,
  });

  /// Total addresses consumed by the plan.
  int get allocatedAddresses =>
      allocations.fold(0, (sum, a) => sum + a.subnet.totalAddresses);

  /// Free addresses remaining in the parent block.
  int get freeAddresses => parent.totalAddresses - allocatedAddresses;

  /// Utilisation of the parent block as a fraction (`0.0`…`1.0`).
  double get utilisation => allocatedAddresses / parent.totalAddresses;

  bool get isComplete => unallocated.isEmpty;
}

/// The smallest number of host bits that can hold [hosts] usable addresses.
///
/// Accounts for the network and broadcast addresses for prefixes shorter than
/// `/31`; `/31` and `/32` are treated per RFC 3021.
int prefixForHosts(int hosts) {
  if (hosts <= 0) return 32;
  if (hosts == 1) return 32;
  if (hosts == 2) return 31;
  var size = 2;
  var prefix = 31;
  while (size - 2 < hosts && prefix > 0) {
    prefix--;
    size <<= 1;
  }
  return prefix;
}

/// A deterministic, pure VLSM (Variable Length Subnet Mask) planner.
///
/// Subnets are placed in descending size order so that no block ever overlaps
/// another, and addresses are aligned to their own size boundary.
class VlsmPlanner {
  const VlsmPlanner._();

  /// Splits [parent] into [count] equally sized subnets.
  static VlsmPlan equalSplit(SubnetInfo parent, int count) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'must be at least 1');
    }
    if (!_isPowerOfTwo(count)) {
      throw ArgumentError.value(
        count,
        'count',
        'must be a power of two for equal splits',
      );
    }
    final extraBits = _log2(count);
    final newPrefix = parent.prefix + extraBits;
    if (newPrefix > 32) {
      throw ArgumentError(
        'Cannot split a /${parent.prefix} into '
        '$count subnets — not enough address space.',
      );
    }

    final blockSize = 1 << (32 - newPrefix);
    final allocations = <VlsmAllocation>[];
    for (var i = 0; i < count; i++) {
      final start = parent.network.value + (i * blockSize);
      final info = SubnetCalculator.calculate(
        Ipv4Address.fromInt(start),
        newPrefix,
      );
      allocations.add(VlsmAllocation(name: 'Subnet ${i + 1}', subnet: info));
    }
    return VlsmPlan(
      parent: parent,
      allocations: allocations,
      unallocated: const [],
    );
  }

  /// Allocates subnets for each requested host count, largest first.
  static VlsmPlan fromHostRequirements(
    SubnetInfo parent,
    List<HostRequirement> requirements,
  ) {
    // Sort a copy descending by size, keeping the caller's list untouched.
    final sorted = [...requirements]
      ..sort((a, b) => b.hosts.compareTo(a.hosts));

    final allocations = <VlsmAllocation>[];
    final unallocated = <String>[];
    var cursor = parent.network.value;
    final parentEnd = parent.broadcast.value;

    for (final requirement in sorted) {
      final prefix = prefixForHosts(requirement.hosts);
      if (prefix < parent.prefix) {
        unallocated.add(
          '${requirement.name} (needs /$prefix, '
          'larger than parent /${parent.prefix})',
        );
        continue;
      }
      final blockSize = 1 << (32 - prefix);
      // Align the cursor up to the next multiple of the block size.
      final aligned = _alignUp(cursor, blockSize);
      final blockEnd = aligned + blockSize - 1;
      if (aligned > parentEnd || blockEnd > parentEnd) {
        unallocated.add(
          '${requirement.name} (needs ${requirement.hosts} hosts — no space left)',
        );
        continue;
      }
      final info = SubnetCalculator.calculate(
        Ipv4Address.fromInt(aligned),
        prefix,
      );
      allocations.add(VlsmAllocation(name: requirement.name, subnet: info));
      cursor = blockEnd + 1;
    }

    return VlsmPlan(
      parent: parent,
      allocations: allocations,
      unallocated: unallocated,
    );
  }

  static int _alignUp(int value, int alignment) {
    if (alignment <= 1) return value;
    final remainder = value % alignment;
    if (remainder == 0) return value;
    return value + (alignment - remainder);
  }

  static bool _isPowerOfTwo(int value) => (value & (value - 1)) == 0;

  static int _log2(int value) {
    var count = 0;
    var v = value;
    while (v > 1) {
      v >>= 1;
      count++;
    }
    return count;
  }
}

/// A named request for a subnet able to hold [hosts] usable addresses.
class HostRequirement {
  final String name;
  final int hosts;

  const HostRequirement(this.name, this.hosts);
}
