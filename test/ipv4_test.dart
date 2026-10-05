import 'package:flutter_test/flutter_test.dart';
import 'package:netcarve/core/ipv4.dart';

void main() {
  group('Ipv4Address.parse', () {
    test('parses a normal dotted-quad', () {
      final address = Ipv4Address.parse('192.168.1.10');
      expect(address.dotted, '192.168.1.10');
      expect(address.value, 0xC0A8010A);
    });

    test('parses boundaries', () {
      expect(Ipv4Address.parse('0.0.0.0').value, 0);
      expect(Ipv4Address.parse('255.255.255.255').value, 0xFFFFFFFF);
    });

    test('trims surrounding whitespace', () {
      expect(Ipv4Address.parse('  10.0.0.1 ').dotted, '10.0.0.1');
    });

    test('rejects wrong octet counts', () {
      expect(() => Ipv4Address.parse('1.2.3'), throwsFormatException);
      expect(() => Ipv4Address.parse('1.2.3.4.5'), throwsFormatException);
    });

    test('rejects out-of-range octets', () {
      expect(() => Ipv4Address.parse('256.0.0.1'), throwsFormatException);
      expect(() => Ipv4Address.parse('10.0.0.999'), throwsFormatException);
    });

    test('rejects non-numeric octets', () {
      expect(() => Ipv4Address.parse('10.0.0.a'), throwsFormatException);
      expect(() => Ipv4Address.parse('10..0.1'), throwsFormatException);
      expect(() => Ipv4Address.parse('10.0.0.-1'), throwsFormatException);
    });

    test('isValid mirrors parse', () {
      expect(Ipv4Address.isValid('8.8.8.8'), isTrue);
      expect(Ipv4Address.isValid('8.8.8'), isFalse);
    });
  });

  group('representations', () {
    test('binary pads each octet to 8 bits', () {
      expect(
        Ipv4Address.parse('192.168.1.10').binary,
        '11000000.10101000.00000001.00001010',
      );
      expect(
        Ipv4Address.parse('0.0.0.1').binary,
        '00000000.00000000.00000000.00000001',
      );
    });

    test('hex is upper-case and zero padded', () {
      expect(Ipv4Address.parse('192.168.1.10').hex, 'C0A8010A');
      expect(Ipv4Address.parse('0.0.0.1').hex, '00000001');
    });

    test('reverse DNS reverses the octets', () {
      expect(
        Ipv4Address.parse('192.168.1.10').reverseDns,
        '10.1.168.192.in-addr.arpa',
      );
    });
  });

  group('classification', () {
    test('detects classes', () {
      expect(Ipv4Address.parse('10.0.0.1').addressClass, AddressClass.a);
      expect(Ipv4Address.parse('172.16.0.1').addressClass, AddressClass.b);
      expect(Ipv4Address.parse('192.168.1.1').addressClass, AddressClass.c);
      expect(Ipv4Address.parse('224.0.0.1').addressClass, AddressClass.d);
      expect(Ipv4Address.parse('240.0.0.1').addressClass, AddressClass.e);
    });

    test('detects RFC 1918 private ranges', () {
      expect(Ipv4Address.parse('10.0.0.1').isPrivate, isTrue);
      expect(Ipv4Address.parse('172.16.5.5').isPrivate, isTrue);
      expect(Ipv4Address.parse('172.32.5.5').isPrivate, isFalse);
      expect(Ipv4Address.parse('192.168.0.1').isPrivate, isTrue);
      expect(Ipv4Address.parse('8.8.8.8').isPrivate, isFalse);
    });

    test('detects loopback, link-local, multicast and shared', () {
      expect(Ipv4Address.parse('127.0.0.1').isLoopback, isTrue);
      expect(Ipv4Address.parse('169.254.10.1').isLinkLocal, isTrue);
      expect(Ipv4Address.parse('224.0.0.1').isMulticast, isTrue);
      expect(Ipv4Address.parse('100.64.1.1').isShared, isTrue);
      expect(Ipv4Address.parse('8.8.8.8').isReserved, isFalse);
    });
  });

  group('ordering and arithmetic', () {
    test('compares numerically', () {
      expect(
        Ipv4Address.parse('10.0.0.1') < Ipv4Address.parse('10.0.0.2'),
        isTrue,
      );
      expect(
        Ipv4Address.parse('10.0.0.2') >= Ipv4Address.parse('10.0.0.2'),
        isTrue,
      );
    });

    test('addition wraps within 32 bits', () {
      expect((Ipv4Address.parse('0.0.0.255') + 1).dotted, '0.0.1.0');
      expect((Ipv4Address.parse('255.255.255.255') + 1).dotted, '0.0.0.0');
    });

    test('equality is by value', () {
      expect(
        Ipv4Address.parse('10.0.0.1') == Ipv4Address.parse('10.0.0.1'),
        isTrue,
      );
      expect(
        Ipv4Address.parse('10.0.0.1').hashCode,
        Ipv4Address.parse('10.0.0.1').hashCode,
      );
    });
  });
}
