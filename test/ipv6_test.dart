import 'package:flutter_test/flutter_test.dart';
import 'package:netcarve/core/ipv6.dart';

void main() {
  group('Ipv6Address.parse', () {
    test('parses a full address', () {
      final addr = Ipv6Address.parse('2001:0db8:0000:0000:0000:0000:0000:0001');
      expect(addr.compressed, '2001:db8::1');
    });

    test('expands compressed forms', () {
      final addr = Ipv6Address.parse('2001:db8::1');
      expect(addr.expanded, '2001:0db8:0000:0000:0000:0000:0000:0001');
    });

    test('handles loopback and any', () {
      expect(Ipv6Address.parse('::1').type, Ipv6Type.loopback);
      expect(Ipv6Address.parse('::').type, Ipv6Type.unspecified);
    });

    test('handles embedded IPv4', () {
      final addr = Ipv6Address.parse('::ffff:192.168.1.1');
      expect(addr.expanded, '0000:0000:0000:0000:0000:ffff:c0a8:0101');
    });

    test('strips a zone index', () {
      final addr = Ipv6Address.parse('fe80::1%wlan0');
      expect(addr.type, Ipv6Type.linkLocal);
    });

    test('rejects multiple double colons', () {
      expect(() => Ipv6Address.parse('2001::db8::1'), throwsFormatException);
    });

    test('rejects too few groups without compression', () {
      expect(() => Ipv6Address.parse('2001:db8:1'), throwsFormatException);
    });

    test('rejects invalid characters', () {
      expect(() => Ipv6Address.parse('2001:db8::zzzz'), throwsFormatException);
    });
  });

  group('Ipv6Address.compressed (RFC 5952)', () {
    test('compresses the longest zero run', () {
      expect(
        Ipv6Address.parse('2001:db8:0:0:1:0:0:1').compressed,
        '2001:db8::1:0:0:1',
      );
    });

    test('does not compress a single zero group', () {
      expect(
        Ipv6Address.parse('2001:db8:0:1:1:1:1:1').compressed,
        '2001:db8:0:1:1:1:1:1',
      );
    });

    test('round-trips through expanded', () {
      const input = 'fe80::a00:27ff:fe12:3456';
      final addr = Ipv6Address.parse(input);
      expect(Ipv6Address.parse(addr.expanded).compressed, addr.compressed);
    });
  });

  group('Ipv6Address.type', () {
    test('classifies common ranges', () {
      expect(Ipv6Address.parse('fe80::1').type, Ipv6Type.linkLocal);
      expect(Ipv6Address.parse('fc00::1').type, Ipv6Type.uniqueLocal);
      expect(Ipv6Address.parse('fd12:3456::1').type, Ipv6Type.uniqueLocal);
      expect(Ipv6Address.parse('ff02::1').type, Ipv6Type.multicast);
      expect(Ipv6Address.parse('2001:db8::1').type, Ipv6Type.documentation);
      expect(Ipv6Address.parse('2606:4700::1').type, Ipv6Type.globalUnicast);
    });
  });
}
