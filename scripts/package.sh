#!/usr/bin/env bash
# Requires SUSHI and Python 3. Examples are deliberately outside package/ root.
set -euo pipefail
cd "$(dirname "$0")/.."

# Build the contract in a scratch copy with FSHOnly: true. In website mode
# SUSHI leaves fields such as version to the IG Publisher, which would
# change the package's contents.
build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
mkdir "$build/input"
cp -R input/fsh "$build/input/fsh"
grep -q '^FSHOnly: false$' sushi-config.yaml
sed 's/^FSHOnly: false$/FSHOnly: true/' sushi-config.yaml > "$build/sushi-config.yaml"
sushi build "$build"
export SUSHI_RESOURCES="$build/fsh-generated/resources"

python3 - <<'PY'
import gzip
import json
import os
from pathlib import Path
import re
import shutil
import tarfile

root = Path.cwd()
config = (root / "sushi-config.yaml").read_text()
version = re.search(r"^version:\s*([^\s#]+)", config, re.MULTILINE).group(1)
package = root / "output/package/package"
if package.parent.exists():
    shutil.rmtree(package.parent)
(package / "example").mkdir(parents=True)

def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")

write_json(package / "package.json", {
    "name": "ls.moh.bonolo.cdu",
    "version": version,
    "fhirVersions": ["4.0.1"],
    "type": "IG",
    "canonical": "http://fhir.health.gov.ls/bonolo-cdu",
    "dependencies": {"hl7.fhir.r4.core": "4.0.1"},
})
conformance = {"StructureDefinition", "CodeSystem", "ValueSet"}
examples = {"Patient", "MedicationRequest", "Task", "Bundle", "Organization", "Location"}
indexes = {package: [], package / "example": []}
for source in sorted(Path(os.environ["SUSHI_RESOURCES"]).glob("*.json")):
    resource = json.loads(source.read_text())
    resource_type = resource["resourceType"]
    if resource_type in conformance:
        target = package
    elif resource_type in examples:
        target = package / "example"
    else:
        raise ValueError(f"Unclassified resource: {source.name} ({resource_type})")
    shutil.copyfile(source, target / source.name)
    indexes[target].append({
        "filename": source.name,
        **{key: resource.get(key) for key in
           ("resourceType", "id", "url", "version", "kind", "type")},
    })
assert indexes[package] and indexes[package / "example"], "SUSHI output is empty"
for folder, files in indexes.items():
    write_json(folder / ".index.json", {"index-version": 1, "files": files})

# Stable tar metadata makes rebuilding the pinned package reproducible.
archive = root / f"output/ls.moh.bonolo.cdu-{version}.tgz"
with archive.open("wb") as output:
    with gzip.GzipFile(filename="", mode="wb", fileobj=output, mtime=0) as compressed:
        with tarfile.open(fileobj=compressed, mode="w") as tar:
            for path in [package, *sorted(package.rglob("*"))]:
                info = tar.gettarinfo(str(path), str(path.relative_to(package.parent)))
                info.uid = info.gid = info.mtime = 0
                info.uname = info.gname = ""
                info.mode = 0o755 if path.is_dir() else 0o644
                if path.is_file():
                    with path.open("rb") as content:
                        tar.addfile(info, content)
                else:
                    tar.addfile(info)
print(f"Packaged {len(indexes[package])} conformance resources and "
      f"{len(indexes[package / 'example'])} examples: {archive}")
PY
