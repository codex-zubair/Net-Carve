# NetCarve

**Subnet & CIDR Calculator** — a free, ad-free, fully offline networking utility for
network engineers, cloud architects and DevOps teams, built by
**Across Cloud LLC**.

NetCarve performs precise IPv4/IPv6 subnet math and VLSM planning entirely on your
device using integer binary arithmetic. It requests **no internet permission**, contains
**no ads and no trackers**, and works in air-gapped data centres where network access is
restricted.

[![CI](https://github.com/codex-zubair/Net-Carve/actions/workflows/ci.yml/badge.svg)](https://github.com/codex-zubair/Net-Carve/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-2DD4BF.svg)](LICENSE)

---

## Why NetCarve

| | |
|---|---|
| **Offline by design** | Performs zero network requests and declares no `INTERNET` permission. |
| **Ad-free & tracker-free** | No advertising SDKs, no analytics, no telemetry. |
| **Exact math** | Every value is derived from integer bit operations — correct for every prefix length. |
| **Engineer-first UI** | Instant results, binary bit view, copy-to-clipboard on every value. |
| **Open source** | Complete, unminified source under the MIT license, as a showcase of production-grade native software. |

---

## Features

### IPv4 Subnet Calculator
- Accepts an IPv4 address or full CIDR notation (e.g. `10.20.30.40/20`).
- Instant, on-keystroke results with no server round-trip.
- Computes **network address, broadcast address, subnet mask, wildcard mask,
  first/last usable host, gateway, and total/usable host counts**.
- Correct handling of the special cases:
  - `/0` — full address space
  - `/31` — point-to-point link (RFC 3021, 2 usable addresses)
  - `/32` — single host route
- Address classification: classful class (A–E), **private (RFC 1918)**, loopback,
  link-local, multicast, carrier-grade NAT (RFC 6598), documentation ranges, and
  reserved/not-globally-routable flags.
- Alternative representations in **binary (bit-grouped) and hexadecimal**.
- **Reverse DNS** (`in-addr.arpa`) generation.
- Visual **binary bit view** that shades network bits vs. host bits against the mask.

### VLSM Planner
- **Equal split** — divide a parent block into 2/4/8/… subnets.
- **By hosts** — allocate right-sized subnets from a list of host requirements,
  placed largest-first and aligned to their own size boundary so no two blocks ever
  overlap.
- Reports block size, mask, usable range and host count for every allocation.
- Flags requirements that cannot fit and shows remaining free addresses and
  utilisation percentage.

### IPv6 Explorer
- Parses full, compressed, and embedded-IPv4 forms (e.g. `::ffff:192.168.1.1`).
- **Canonical compression** with longest-zero-run `::` per RFC 5952.
- Fully expanded 128-bit form.
- Address-type classification: unspecified, loopback, link-local (`fe80::/10`),
  unique local (`fc00::/7`), multicast (`ff00::/8`), documentation
  (`2001:db8::/32`), and global unicast (`2000::/3`).
- Interactive prefix slider (`/0`…`/128`) that shows the block's network and
  last address.

### Quality-of-life
- **Quick presets** for common cloud/VPC blocks.
- **Copy-to-clipboard** on every displayed value.
- **Local History** — save calculated blocks; browse, reload, delete, or clear.
  Stored only on-device; never uploaded.
- **About** screen with the *“View our Clean Code on GitHub”* showcase button,
  privacy policy link, and contact.

---

## Architecture

NetCarve is deliberately structured so the networking engine is pure, testable Dart
with no Flutter dependency. This is the part of the codebase enterprise reviewers
read first.

```
lib/
  core/            Pure Dart — no Flutter imports
    ipv4.dart        Ipv4Address: parse, validate, formats, classification
    subnet.dart      SubnetCalculator: network/broadcast/mask/hosts
    vlsm.dart        VlsmPlanner: equal splits & host-requirement allocation
    ipv6.dart        Ipv6Address: BigInt 128-bit parse, compress, classify
    app_info.dart    Brand constants, links
  services/
    history_service.dart   On-device SharedPreferences history
  state/
    calculator_state.dart  ChangeNotifier UI state
  screens/         Home, VLSM, IPv6, History, About, RootShell
  widgets/         Brand, BinaryView, shared UI primitives
  theme/           AppTheme (dark instrument-panel design system)
```

### Engine highlights
- IPv4 values are unsigned 32-bit integers (`int`), so masking is a single
  bitwise AND.
- IPv6 values are `BigInt` to span the full 128-bit space.
- VLSM places subnets largest-first with size-aligned allocation, which provably
  prevents overlap.
- RFC 3021 `/31` and `/32` host-count semantics are handled explicitly.

---

## Testing

The engine is covered by an exhaustive unit-test suite plus widget smoke tests.

```bash
flutter test
```

Coverage includes:
- IPv4 parsing (valid, invalid, boundaries, whitespace), formatting, classification,
  ordering, and 32-bit wraparound arithmetic.
- Subnet calculation for `/0`, `/24`, `/20`, `/26`, `/31`, `/32`, invalid prefixes,
  and CIDR text normalisation.
- VLSM equal splits, host-requirement allocation, non-overlap guarantees, and
  out-of-space handling.
- IPv6 parsing, RFC 5952 compression, zone-index stripping, embedded IPv4, and
  address classification.
- Widget smoke tests that boot the app and compute a subnet.

CI runs `dart format`, `flutter analyze`, `flutter test`, and a release AAB build
on every push (`.github/workflows/ci.yml`).

---

## Build & Release

Requirements: Flutter stable, Android SDK (min SDK 23).

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Release signing reads `android/key.properties` (git-ignored). Create your own
keystore before publishing:

```bash
keytool -genkeypair -v -keystore android/netcarve-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias netcarve
```

Regenerate the launcher icon and splash from source art:

```bash
python3 tool/generate_icons.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## Privacy

NetCarve collects no data and makes no network requests. See the full
[Privacy Policy](https://codex-zubair.github.io/Net-Carve/privacy-policy/).

---

## License

Released under the [MIT License](LICENSE). © 2026 Across Cloud LLC.