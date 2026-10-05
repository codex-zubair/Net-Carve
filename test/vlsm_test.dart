import 'package:flutter_test/flutter_test.dart';
import 'package:netcarve/core/subnet.dart';
import 'package:netcarve/core/vlsm.dart';

void main() {
  group('prefixForHosts', () {
    test('maps host counts to the smallest fitting prefix', () {
      expect(prefixForHosts(1), 32);
      expect(prefixForHosts(2), 31);
      expect(prefixForHosts(3), 29);
      expect(prefixForHosts(6), 29);
      expect(prefixForHosts(14), 28);
      expect(prefixForHosts(30), 27);
      expect(prefixForHosts(62), 26);
      expect(prefixForHosts(254), 24);
      expect(prefixForHosts(1000), 22);
    });
  });

  group('VlsmPlanner.equalSplit', () {
    test('splits a /24 into four /26 blocks', () {
      final parent = SubnetCalculator.parseCidr('192.168.1.0/24');
      final plan = VlsmPlanner.equalSplit(parent, 4);
      expect(plan.allocations.length, 4);
      expect(plan.allocations.every((a) => a.prefix == 26), isTrue);
      expect(plan.allocations[0].subnet.network.dotted, '192.168.1.0');
      expect(plan.allocations[1].subnet.network.dotted, '192.168.1.64');
      expect(plan.allocations[2].subnet.network.dotted, '192.168.1.128');
      expect(plan.allocations[3].subnet.network.dotted, '192.168.1.192');
      expect(plan.freeAddresses, 0);
      expect(plan.isComplete, isTrue);
    });

    test('splits a /16 into 256 /24s without overlap', () {
      final parent = SubnetCalculator.parseCidr('10.0.0.0/16');
      final plan = VlsmPlanner.equalSplit(parent, 256);
      expect(plan.allocations.length, 256);
      expect(plan.allocations.last.subnet.broadcast.dotted, '10.0.255.255');
    });

    test('rejects non power-of-two counts', () {
      final parent = SubnetCalculator.parseCidr('10.0.0.0/24');
      expect(() => VlsmPlanner.equalSplit(parent, 3), throwsArgumentError);
    });

    test('rejects splits larger than available space', () {
      final parent = SubnetCalculator.parseCidr('10.0.0.0/31');
      expect(() => VlsmPlanner.equalSplit(parent, 4), throwsArgumentError);
    });
  });

  group('VlsmPlanner.fromHostRequirements', () {
    test('allocates variable sized blocks in descending order', () {
      final parent = SubnetCalculator.parseCidr('192.168.0.0/24');
      final plan = VlsmPlanner.fromHostRequirements(parent, const [
        HostRequirement('Engineering', 50),
        HostRequirement('Sales', 20),
        HostRequirement('Management', 10),
        HostRequirement('WAN link', 2),
      ]);

      expect(plan.isComplete, isTrue);
      // Largest requirement (50 hosts) becomes a /26 at the start.
      expect(plan.allocations.first.name, 'Engineering');
      expect(plan.allocations.first.prefix, 26);
      expect(plan.allocations.first.subnet.network.dotted, '192.168.0.0');
      // No allocation overlaps another.
      _expectNoOverlap(plan);
    });

    test('reports requirements that cannot fit', () {
      final parent = SubnetCalculator.parseCidr('10.0.0.0/25');
      final plan = VlsmPlanner.fromHostRequirements(parent, const [
        HostRequirement('A', 200),
        HostRequirement('B', 100),
      ]);
      expect(plan.unallocated, isNotEmpty);
    });

    test('a requirement larger than the parent is rejected', () {
      final parent = SubnetCalculator.parseCidr('10.0.0.0/28');
      final plan = VlsmPlanner.fromHostRequirements(parent, const [
        HostRequirement('Too big', 500),
      ]);
      expect(plan.allocations, isEmpty);
      expect(plan.unallocated.length, 1);
    });

    test('empty requirements yield an empty, complete plan', () {
      final parent = SubnetCalculator.parseCidr('10.0.0.0/24');
      final plan = VlsmPlanner.fromHostRequirements(parent, const []);
      expect(plan.allocations, isEmpty);
      expect(plan.isComplete, isTrue);
      expect(plan.freeAddresses, 256);
    });
  });
}

void _expectNoOverlap(VlsmPlan plan) {
  final ranges =
      plan.allocations
          .map((a) => [a.subnet.network.value, a.subnet.broadcast.value])
          .toList()
        ..sort((a, b) => a[0].compareTo(b[0]));
  for (var i = 1; i < ranges.length; i++) {
    expect(
      ranges[i][0] > ranges[i - 1][1],
      isTrue,
      reason: 'allocation $i overlaps its predecessor',
    );
  }
}
