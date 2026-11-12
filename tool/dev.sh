#!/bin/zsh
# Runs a prototype with hot reload on save.
#
# Starts `flutter run` on a web server and watches the prototype's code (and
# a local prototype-hud clone, when pubspec_overrides.yaml points at one). On
# every saved .dart file it stamps the header's date and sends `flutter run`
# the hot-reload signal (SIGUSR1). Reload the browser tab once after the first
# build; after that, saves show up by themselves.
#
# Copy it to your prototype's ds/example/tool/ (next to stamp_last_update.py)
# and run it from ds/example:
#
#   zsh tool/dev.sh lib/<entry>.dart lib/<prototype>/last_update.g.dart \
#       lib/<prototype> [more folders or files to stamp]
#
#   PORT=8096 zsh tool/dev.sh ...      # another port (default 8095)
#   HUD=/path/to/prototype-hud ...     # also watch that HUD clone
set -e
cd "${0:A:h}/.."

entry="$1"
stamp_out="$2"
shift 2 || { echo "Usage: tool/dev.sh lib/<entry>.dart <stamp-out> <paths to stamp...>"; exit 1; }
stamp_paths=("$entry" "$@")

flutter="${FLUTTER:-$HOME/development/flutter/bin/flutter}"
pidfile="$(mktemp -t hud-dev-pid)"
rm -f "$pidfile"

"$flutter" run -d web-server --web-port "${PORT:-8095}" \
  -t "$entry" --pid-file "$pidfile" &
runner=$!
trap 'kill $runner 2>/dev/null; rm -f "$pidfile"' EXIT INT TERM

python3 - "$pidfile" "$stamp_out" "${HUD:+$HUD/lib}" lib -- "${stamp_paths[@]}" <<'EOF'
import os, signal, subprocess, sys, time

args = sys.argv[1:]
sep = args.index('--')
pidfile, stamp_out, *roots = args[:sep]
stamp_paths = args[sep + 1:]
roots = [r for r in roots if r and os.path.isdir(r)]
skip = os.path.basename(stamp_out)

def snapshot():
    seen = {}
    for root in roots:
        for d, _, files in os.walk(root):
            for f in files:
                if f.endswith('.dart') and f != skip:
                    p = os.path.join(d, f)
                    try:
                        seen[p] = os.path.getmtime(p)
                    except OSError:
                        pass
    return seen

last = snapshot()
print(f'[dev] watching {", ".join(roots)}', flush=True)
while True:
    time.sleep(0.7)
    now = snapshot()
    if now == last:
        continue
    changed = [p for p in now if last.get(p) != now[p]]
    last = now
    if not os.path.exists(pidfile):
        continue  # still building
    subprocess.run(
        ['python3', 'tool/stamp_last_update.py', '--out', stamp_out, *stamp_paths],
        stdout=subprocess.DEVNULL)
    try:
        os.kill(int(open(pidfile).read().strip()), signal.SIGUSR1)
        print(f'[dev] hot reload · {os.path.basename(changed[0]) if changed else ""}', flush=True)
    except (OSError, ValueError):
        pass
EOF
