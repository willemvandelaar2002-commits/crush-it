"""Run the real Luau event rules/controller with a deterministic service mock.

python3 tools/factory-events/run_offline.py --luau /path/to/luau
This checks logic and cosmetic geometry, not Studio rendering/replication.
"""
import argparse
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", required=True)
    parser.add_argument("--geometry", type=Path)
    args = parser.parse_args()
    source = (ROOT / "tools/crusher-icons/geometry_mock.luau").read_text()
    source += (Path(__file__).with_name("services_mock.luau")).read_text()
    paths = list((ROOT / "src/shared").glob("*.luau"))
    paths += [ROOT / "src/server/FactoryEvents.luau", ROOT / "src/client/FactoryEventVisuals.luau"]
    source += "\nlocal loaders={}\n"
    source += "\nrequire=function(m) assert(m,'missing module reference');if not modules[m.Name] then modules[m.Name]=assert(loaders[m.Name],m.Name)() end;return modules[m.Name] end\n"
    for path in paths:
        name = path.stem
        source += f'\nnamed(shared,"{name}")\nloaders.{name}=function()\nlocal script={{Parent=shared}}\n'
        source += path.read_text() + "\nend\n"
    specs = ["FactoryEvents", "CrusherRules", "CrusherRows", "Fusion", "FactoryProgression", "DailySpin"]
    for name in specs:
        path = ROOT / f"src/server/Tests/{name}.spec.luau"
        source += f"\nlocal spec_{name}=(function()\n" + path.read_text() + "\nend)()\n"
        source += f'local result_{name}=spec_{name}();print("PASS|{name}|"..result_{name}.passed)\n'
    source += Path(__file__).with_name("controller_scenarios.luau").read_text()
    source += Path(__file__).with_name("visual_scenarios.luau").read_text()
    source += Path(__file__).with_name("client_setup.luau").read_text()
    source += "\nlocal eventScript=(function()\nlocal script=clientScript\n" + (ROOT / "src/client/FactoryEvent.client.luau").read_text() + "\nend)()\n"
    source += Path(__file__).with_name("client_scenarios.luau").read_text()
    with tempfile.TemporaryDirectory() as directory:
        entry = Path(directory) / "factory-events.luau"
        entry.write_text(source)
        result = subprocess.run([args.luau, str(entry)], text=True, capture_output=True)
    geometry = []
    for line in result.stdout.splitlines():
        if line.startswith("GEOMETRY|"):
            fields = line.split("|")
            if fields[1] == "MODEL":
                geometry.append(dict(id=fields[2], name=fields[2], rarity="Event", parts=[]))
            else:
                geometry[-1]["parts"].append(dict(name=fields[2], kind=fields[3], shape=fields[4],
                    position=list(map(float, fields[5].split(","))), size=list(map(float, fields[6].split(","))),
                    rotation=list(map(float, fields[7].split(","))), color=list(map(float, fields[8].split(","))), material=fields[9]))
        else:
            print(line)
    if result.returncode:
        print(result.stderr)
        raise SystemExit(result.returncode)
    if args.geometry:
        args.geometry.parent.mkdir(parents=True, exist_ok=True)
        args.geometry.write_text(json.dumps(geometry))


if __name__ == "__main__":
    main()
