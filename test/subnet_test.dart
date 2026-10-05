import 'package:flutter_test/flutter_test.dart';
import 'package:netcarve/core/ipv4.dart';
import 'package:netcarve/core/subnet.dart';

void main() {
  group('SubnetCalculator.calculate', () {
    test('calculates a classic /24', () {
      final info = SubnetCalculator.calculate(
        Ipv4Address.parse('192.168.1.10'),
        24,
      );
      expect(info.network.dotted, '192.168.1.0');
      expect(info.broadcast.dotted, '192.168.1.255');
      expect(info.netmask.dotted, '255.255.255.0');
      expect(info.wildcard.dotted, '0.0.0.255');
      expect(info.firstHost!.dotted, '192.168.1.1');
      expect(info.lastHost!.dotted, '192.168.1.254');
      expect(info.usableHosts, 254);
      expect(info.totalAddresses, 256);
    });

    test('masks host bits to derive the network', () {
      final info = SubnetCalculator.calculate(
        Ipv4Address.parse('10.20.30.40'),
        20,
      );
      expect(info.network.dotted, '10.20.16.0');
      expect(info.broadcast.dotted, '10.20.31.255');
      expect(info.netmask.dotted, '255.255.240.0');
      expect(info.usableHosts, 4094);
    });

    test('handles /0', () {
      final info = SubnetCalculator.calculate(Ipv4Address.parse('8.8.8.8'), 0);
      expect(info.network.dotted, '0.0.0.0');
      expect(info.broadcast.dotted, '255.255.255.255');
      expect(info.netmask.dotted, '0.0.0.0');
      expect(info.totalAddresses, 0x100000000);
    });

    test('handles /31 as a point-to-point link (RFC 3021)', () {
      final info = SubnetCalculator.calculate(
        Ipv4Address.parse('10.0.0.1'),
        31,
      );
      expect(info.isPointToPoint, isTrue);
      expect(info.usableHosts, 2);
      expect(info.firstHost!.dotted, '10.0.0.0');
      expect(info.lastHost!.dotted, '10.0.0.1');
    });

    test('handles /32 as a host route', () {
      final info = SubnetCalculator.calculate(
        Ipv4Address.parse('203.0.113.7'),
        32,
      );
      expect(info.isHostRoute, isTrue);
      expect(info.usableHosts, 1);
      expect(info.network.dotted, '203.0.113.7');
      expect(info.broadcast.dotted, '203.0.113.7');
    });

    test('rejects invalid prefixes', () {
      expect(
        () => SubnetCalculator.calculate(Ipv4Address.parse('10.0.0.1'), 33),
        throwsArgumentError,
      );
      expect(
        () => SubnetCalculator.calculate(Ipv4Address.parse('10.0.0.1'), -1),
        throwsArgumentError,
      );
    });

    test('gateway is the first host', () {
      final info = SubnetCalculator.parseCidr('10.0.0.0/24');
      expect(SubnetCalculator.gatewayFor(info)!.dotted, '10.0.0.1');
    });
  });

  group('SubnetCalculator.parseCidr', () {
    test('parses valid CIDR text', () {
      final info = SubnetCalculator.parseCidr('172.16.0.0/12');
      expect(info.prefix, 12);
      expect(info.cidr, '172.16.0.0/12');
    });

    test('normalises a host address to its network', () {
      final info = SubnetCalculator.parseCidr('192.168.1.200/26');
      expect(info.network.dotted, '192.168.1.192');
      expect(info.broadcast.dotted, '192.168.1.255');
      expect(info.usableHosts, 62);
    });

    test('rejects missing slash', () {
      expect(
        () => SubnetCalculator.parseCidr('10.0.0.0'),
        throwsFormatException,
      );
    });

    test('rejects a non-numeric prefix', () {
      expect(
        () => SubnetCalculator.parseCidr('10.0.0.0/abc'),
        throwsFormatException,
      );
    });

    test('rejects an out-of-range prefix', () {
      expect(
        () => SubnetCalculator.parseCidr('10.0.0.0/33'),
        throwsArgumentError,
      );
    });
  });
}
