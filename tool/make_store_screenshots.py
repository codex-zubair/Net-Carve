#!/usr/bin/env python3
"""Generate Play Store phone screenshots (1080x1920) as HTML mockups and render
them with headless Brave/Chromium.

These faithfully mirror the in-app design system so the store listing matches
the real product. When a device is connected you can instead capture true
screenshots with tool/capture_screenshots.sh.
"""
import subprocess
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store_assets" / "screenshots"
OUT.mkdir(parents=True, exist_ok=True)

BRAVE = shutil.which("brave") or shutil.which("chromium") or shutil.which("google-chrome")

HEAD = """<!DOCTYPE html><html><head><meta charset="utf-8"/><style>
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1080px;height:1920px;overflow:hidden}
body{background:#0B1120;font-family:'DejaVu Sans','Segoe UI',Roboto,sans-serif;color:#E8EEF9}
.screen{width:1080px;height:1920px;padding:64px 48px 0;position:relative;display:flex;flex-direction:column}
.statusbar{display:flex;justify-content:space-between;font-size:30px;color:#94A3B8;margin-bottom:20px;padding:0 8px}
.hdr{display:flex;align-items:center;justify-content:space-between;margin-bottom:36px}
.brand{display:flex;align-items:center;gap:20px}
.logo{width:78px;height:78px;border-radius:22px;background:linear-gradient(135deg,#2DD4BF,#60A5FA);display:flex;align-items:center;justify-content:center}
.wordmark{font-size:46px;font-weight:800;letter-spacing:-1px}
.offline{display:flex;align-items:center;gap:10px;background:#141B2E;border:2px solid #23304D;border-radius:40px;padding:14px 24px;font-size:24px;color:#94A3B8;font-weight:600}
.offline .dot{color:#2DD4BF}
.card{background:#141B2E;border:2px solid #23304D;border-radius:28px;padding:34px;margin-bottom:26px}
.label{color:#94A3B8;font-size:26px;font-weight:600;margin-bottom:18px}
.section{color:#64748B;font-size:24px;font-weight:800;letter-spacing:2.5px;margin:14px 0 20px}
.field{background:#0E1526;border:2px solid #23304D;border-radius:22px;padding:30px 28px;display:flex;align-items:center;gap:20px}
.field .mono{font-family:'DejaVu Sans Mono',monospace;font-size:38px;font-weight:700}
.btn{background:#2DD4BF;color:#070B15;border-radius:22px;padding:30px;text-align:center;font-size:32px;font-weight:800;margin-top:24px}
.chips{display:flex;gap:16px;flex-wrap:wrap}
.chip{background:#1C2540;border:2px solid #23304D;border-radius:20px;padding:18px 28px;font-size:26px;color:#E8EEF9}
.big{font-family:'DejaVu Sans Mono',monospace;font-size:56px;font-weight:800;color:#2DD4BF}
.sub{color:#94A3B8;font-size:26px;margin-top:10px}
.badges{display:flex;gap:14px;flex-wrap:wrap;margin-top:26px}
.badge{font-size:24px;font-weight:700;padding:12px 22px;border-radius:14px}
.badge.p{color:#FBBF24;background:rgba(251,191,36,.12);border:2px solid rgba(251,191,36,.4)}
.badge.c{color:#2DD4BF;background:rgba(45,212,191,.12);border:2px solid rgba(45,212,191,.4)}
.badge.b{color:#60A5FA;background:rgba(96,165,250,.12);border:2px solid rgba(96,165,250,.4)}
.badge.v{color:#A78BFA;background:rgba(167,139,250,.12);border:2px solid rgba(167,139,250,.4)}
.row{display:flex;justify-content:space-between;padding:22px 0;border-bottom:2px solid #23304D}
.row:last-child{border-bottom:none}
.row .k{color:#94A3B8;font-size:28px}
.row .v{font-family:'DejaVu Sans Mono',monospace;font-size:28px;font-weight:600}
.stats{display:flex;text-align:center}
.stats .s{flex:1}
.stats .num{font-family:'DejaVu Sans Mono',monospace;font-size:44px;font-weight:800;color:#2DD4BF}
.stats .lab{color:#64748B;font-size:22px;margin-top:8px}
.bits{display:flex;gap:6px;margin-top:8px}
.bits .b{flex:1;height:46px;border-radius:6px;background:rgba(45,212,191,.16);border:2px solid rgba(45,212,191,.4)}
.bits .b.h{background:rgba(100,116,139,.12);border-color:rgba(100,116,139,.35)}
.nav{position:absolute;bottom:0;left:0;right:0;height:150px;background:#070B15;border-top:2px solid #23304D;display:flex;align-items:center;justify-content:space-around;padding-bottom:18px}
.nav .item{display:flex;flex-direction:column;align-items:center;gap:8px;color:#64748B;font-size:20px}
.nav .item.on{color:#2DD4BF}
.nav .ico{width:52px;height:52px;border-radius:14px;background:#1C2540;display:flex;align-items:center;justify-content:center;font-size:28px}
.nav .on .ico{background:rgba(45,212,191,.18)}
.alloc{background:#141B2E;border:2px solid #23304D;border-radius:24px;padding:28px;margin-bottom:22px}
.alloc .top{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px}
.alloc .name{font-size:30px;font-weight:800}
.alloc .cidr{font-family:'DejaVu Sans Mono',monospace;font-size:32px;font-weight:700;color:#2DD4BF}
.alloc .meta{color:#94A3B8;font-size:24px;margin-top:10px;display:flex;justify-content:space-between}
.tip{background:rgba(45,212,191,.10);border:2px solid rgba(45,212,191,.4);border-radius:20px;padding:26px;font-size:24px;color:#94A3B8;line-height:1.5}
.select{background:#1C2540;border:2px solid #2DD4BF;border-radius:20px;padding:20px 34px;font-size:26px;color:#2DD4BF;font-weight:700}
.selrow{display:flex;gap:16px;margin-bottom:24px}
.hist{display:flex;align-items:center;gap:22px;background:#141B2E;border:2px solid #23304D;border-radius:24px;padding:26px;margin-bottom:20px}
.hist .ic{width:70px;height:70px;border-radius:18px;background:rgba(45,212,191,.14);display:flex;align-items:center;justify-content:center;font-size:32px;color:#2DD4BF}
.hist .hc{font-family:'DejaVu Sans Mono',monospace;font-size:32px;font-weight:700}
.hist .ht{color:#64748B;font-size:22px;margin-top:6px}
</style></head><body>"""

S4 = """<div class="screen">
  <div class="statusbar"><span>9:41</span><span>&#9679; &#9679; &#9679; &#9679;</span></div>
  <div class="hdr">
    <div class="brand"><div class="logo">{LOGO}</div><div class="wordmark">NetCarve</div></div>
    <div class="offline"><span class="dot">&#10003;</span> Offline &amp; Ad-free</div>
  </div>
  <div class="card">
    <div class="big">172.16.0.0/20</div>
    <div class="sub">Network block  &middot;  /20</div>
    <div class="badges">
      <div class="badge p">Private (RFC 1918)</div>
      <div class="badge c">Class B</div>
    </div>
  </div>
  <div class="section">ADDRESS DETAILS</div>
  <div class="card">
    <div class="row"><span class="k">Network</span><span class="v">172.16.0.0</span></div>
    <div class="row"><span class="k">Broadcast</span><span class="v">172.16.15.255</span></div>
    <div class="row"><span class="k">Subnet mask</span><span class="v">255.255.240.0</span></div>
    <div class="row"><span class="k">Wildcard</span><span class="v">0.0.15.255</span></div>
    <div class="row"><span class="k">First host</span><span class="v">172.16.0.1</span></div>
    <div class="row"><span class="k">Last host</span><span class="v">172.16.15.254</span></div>
  </div>
  <div class="section">CAPACITY</div>
  <div class="card"><div class="stats">
    <div class="s"><div class="num">4,094</div><div class="lab">Usable hosts</div></div>
    <div class="s"><div class="num">4,096</div><div class="lab">Total addrs</div></div>
    <div class="s"><div class="num">/20</div><div class="lab">Prefix</div></div>
  </div></div>
  {NAV_CALC}
</div>"""

S5 = """<div class="screen">
  <div class="statusbar"><span>9:41</span><span>&#9679; &#9679; &#9679; &#9679;</span></div>
  <div class="hdr"><div class="wordmark">VLSM Planner</div></div>
  <div class="sub" style="margin-bottom:26px">Carve a parent block into right-sized subnets.</div>
  <div class="selrow">
    <div class="select">Equal split</div>
    <div class="chip">By hosts</div>
  </div>
  <div class="card">
    <div class="label">Number of subnets</div>
    <div class="field"><span class="mono">4</span></div>
    <div class="chips" style="margin-top:22px">
      <div class="chip">2</div><div class="chip">4</div><div class="chip">8</div>
      <div class="chip">16</div><div class="chip">32</div>
    </div>
  </div>
  <div class="section">PLAN &middot; 4 SUBNETS &middot; 100% USED</div>
  <div class="alloc"><div class="top"><span class="name">Subnet 1</span><span class="badge b">/26</span></div>
    <div class="cidr">192.168.1.0/26</div>
    <div class="meta"><span>Mask 255.255.255.192</span><span>62 hosts</span></div></div>
  <div class="alloc"><div class="top"><span class="name">Subnet 2</span><span class="badge b">/26</span></div>
    <div class="cidr">192.168.1.64/26</div>
    <div class="meta"><span>Mask 255.255.255.192</span><span>62 hosts</span></div></div>
  <div class="alloc"><div class="top"><span class="name">Subnet 3</span><span class="badge b">/26</span></div>
    <div class="cidr">192.168.1.128/26</div>
    <div class="meta"><span>Mask 255.255.255.192</span><span>62 hosts</span></div></div>
  {NAV_VLSM}
</div>"""

S6 = """<div class="screen">
  <div class="statusbar"><span>9:41</span><span>&#9679; &#9679; &#9679; &#9679;</span></div>
  <div class="hdr"><div class="wordmark">IPv6 Explorer</div></div>
  <div class="sub" style="margin-bottom:26px">Parse, canonicalise and classify 128-bit addresses.</div>
  <div class="card">
    <div class="label">IPv6 address</div>
    <div class="field"><span class="mono">2001:db8:85a3::8a2e:370:7334</span></div>
    <div style="display:flex;align-items:center;gap:24px;margin-top:30px">
      <span class="badge c">/64</span>
      <div style="flex:1;height:14px;background:#1C2540;border-radius:8px;position:relative">
        <div style="position:absolute;left:0;top:0;bottom:0;width:50%;background:#2DD4BF;border-radius:8px"></div>
        <div style="position:absolute;left:50%;top:-10px;width:34px;height:34px;border-radius:50%;background:#2DD4BF;transform:translateX(-50%)"></div>
      </div>
    </div>
    <div class="chips" style="margin-top:26px">
      <div class="chip">/48</div><div class="chip">/56</div>
      <div class="select" style="padding:18px 28px">/64</div><div class="chip">/96</div>
    </div>
  </div>
  <div class="section">ADDRESS</div>
  <div class="card">
    <div class="row"><span class="k">Compressed</span><span class="v">2001:db8:85a3::8a2e:370:7334</span></div>
    <div class="row"><span class="k">Type</span><span class="v">Documentation</span></div>
  </div>
  <div class="section">BLOCK BOUNDARIES</div>
  <div class="card">
    <div class="row"><span class="k">Network</span><span class="v">2001:db8:85a3::/64</span></div>
    <div class="row"><span class="k">Last address</span><span class="v">2001:db8:85a3:0:ffff:ffff:ffff:ffff</span></div>
  </div>
  {NAV_V6}
</div>"""

S7 = """<div class="screen">
  <div class="statusbar"><span>9:41</span><span>&#9679; &#9679; &#9679; &#9679;</span></div>
  <div class="hdr"><div class="wordmark">History</div></div>
  <div class="sub" style="margin-bottom:30px">Saved on this device only.</div>
  <div class="hist"><div class="ic">&#9636;</div><div><div class="hc">10.0.0.0/16</div><div class="ht">2 min ago</div></div></div>
  <div class="hist"><div class="ic">&#9636;</div><div><div class="hc">192.168.1.0/24</div><div class="ht">1 h ago</div></div></div>
  <div class="hist"><div class="ic">&#9636;</div><div><div class="hc">172.16.0.0/20</div><div class="ht">3 h ago</div></div></div>
  <div class="hist"><div class="ic">&#9636;</div><div><div class="hc">203.0.113.7/32</div><div class="ht">1 d ago</div></div></div>
  <div class="hist"><div class="ic">&#9636;</div><div><div class="hc">10.10.10.0/30</div><div class="ht">2 d ago</div></div></div>
  <div class="tip" style="margin-top:20px">NetCarve keeps a short history on your device. Nothing is ever uploaded, and clearing it removes it permanently.</div>
  {NAV_HIST}
</div>"""

S8 = """<div class="screen">
  <div class="statusbar"><span>9:41</span><span>&#9679; &#9679; &#9679; &#9679;</span></div>
  <div style="text-align:center;margin-top:20px">
    <div class="logo" style="margin:0 auto 24px">{LOGO}</div>
    <div class="wordmark" style="font-size:60px">NetCarve</div>
    <div class="sub">Subnet &amp; CIDR Calculator</div>
    <div class="chip" style="display:inline-block;margin-top:22px">v1.0.0 &middot; by Across Cloud LLC</div>
  </div>
  <div style="background:linear-gradient(135deg,rgba(45,212,191,.14),rgba(96,165,250,.10));border:2px solid rgba(45,212,191,.35);border-radius:28px;padding:34px;margin-top:44px">
    <div style="font-size:34px;font-weight:800;margin-bottom:14px">&#9733; View our clean code</div>
    <div style="color:#94A3B8;font-size:26px;line-height:1.5;margin-bottom:24px">The complete, unminified source for NetCarve is open on GitHub.</div>
    <div class="btn" style="margin-top:0">View our Clean Code on GitHub</div>
  </div>
  <div class="section" style="margin-top:34px">WHY NETCARVE</div>
  <div class="card">
    <div class="row"><span class="k">&#128225; Completely offline</span><span class="v" style="font-family:inherit;color:#2DD4BF">&#10003;</span></div>
    <div class="row"><span class="k">&#128683; No ads, no trackers</span><span class="v" style="font-family:inherit;color:#2DD4BF">&#10003;</span></div>
    <div class="row"><span class="k">&#9889; Exact binary math</span><span class="v" style="font-family:inherit;color:#2DD4BF">&#10003;</span></div>
    <div class="row"><span class="k">&#9638; VLSM planner</span><span class="v" style="font-family:inherit;color:#2DD4BF">&#10003;</span></div>
  </div>
</div>"""

LOGO = ('<svg width="46" height="46" viewBox="0 0 48 48" fill="none">'
        '<rect x="6" y="6" width="36" height="36" rx="9" stroke="#0B1120" stroke-width="5"/>'
        '<line x1="24" y1="11" x2="24" y2="37" stroke="#0B1120" stroke-width="4.5" stroke-linecap="round"/>'
        '<line x1="11" y1="24" x2="37" y2="24" stroke="#0B1120" stroke-width="4.5" stroke-linecap="round"/>'
        '</svg>')

NAV = ('<div class="nav">'
       '<div class="item {C}"><div class="ico">&#9636;</div>Calc</div>'
       '<div class="item {V}"><div class="ico">&#9638;</div>VLSM</div>'
       '<div class="item {I}"><div class="ico">&#9673;</div>IPv6</div>'
       '<div class="item {H}"><div class="ico">&#8635;</div>History</div>'
       '<div class="item {A}"><div class="ico">&#8505;</div>About</div>'
       '</div>')


def nav(active):
    return NAV.format(
        C="on" if active == "c" else "", V="on" if active == "v" else "",
        I="on" if active == "i" else "", H="on" if active == "h" else "",
        A="on" if active == "a" else "")


PAGES = [
    ("04_calculator_result", S4, "c"),
    ("05_vlsm_planner", S5, "v"),
    ("06_ipv6_explorer", S6, "i"),
    ("07_history", S7, "h"),
    ("08_about_showcase", S8, "a"),
]

# Aspect ratio required: longest side / shortest side <= 2. 1080x1920 = 1.78. OK.


def main():
    if not BRAVE:
        print("No Brave/Chromium found.")
        return 1
    for name, body, active in PAGES:
        html = HEAD + body.replace("{LOGO}", LOGO).replace(
            "{NAV_CALC}", nav(active)
        ).replace("{NAV_VLSM}", nav(active)).replace(
            "{NAV_V6}", nav(active)
        ).replace("{NAV_HIST}", nav(active)) + "</body></html>"
        hpath = OUT / f"{name}.html"
        hpath.write_text(html)
        png = OUT / f"{name}.png"
        subprocess.run(
            [BRAVE, "--headless", "--disable-gpu", "--no-sandbox",
             "--hide-scrollbars", "--force-device-scale-factor=1",
             "--window-size=1080,1920", f"--screenshot={png}",
             f"file://{hpath}"],
            check=True, capture_output=True, timeout=120)
        print(f"  {name}.png: {png.stat().st_size} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())