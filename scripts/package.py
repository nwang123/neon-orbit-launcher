#!/usr/bin/env python3
"""Package a built .app without Finder metadata or local paths."""
from pathlib import Path
import hashlib
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
app = Path(sys.argv[1]).resolve()
if not (app / 'Contents/MacOS/NeonOrbit').is_file():
    raise SystemExit('Expected a built Neon Orbit.app')
out = root / 'downloads'
out.mkdir(exist_ok=True)
archive = out / 'NeonOrbit-2.1.0-macOS-arm64.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as bundle:
    for path in sorted(app.rglob('*')):
        if path.is_file() and path.name != '.DS_Store':
            bundle.write(path, Path('Neon Orbit.app') / path.relative_to(app))
(out / 'SHA256SUMS').write_text(''.join(hashlib.sha256(item.read_bytes()).hexdigest() + '  ' + item.name + '\n' for item in sorted(out.glob('*.zip'))))
print(archive)
