import argparse
import json
from pathlib import Path

import yaml

parser = argparse.ArgumentParser(description="Load a PPTD project as one JSON document.")
parser.add_argument("manifest", type=Path, help="Path to the project's .pptd manifest")
manifest_path = parser.parse_args().manifest.expanduser().resolve()
root = manifest_path.parent
m = yaml.safe_load(manifest_path.read_text(encoding="utf-8"))
pages = []
for rel in m["pages"]:
    p = yaml.safe_load((root / rel).read_text(encoding="utf-8"))
    p["pagePath"] = rel
    pages.append(p)
print(json.dumps({**m, "version": "v2", "pages": pages}, ensure_ascii=False))
