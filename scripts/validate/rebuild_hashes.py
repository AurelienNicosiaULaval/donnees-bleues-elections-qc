"""Compare rebuilt CSV payloads and GeoJSON; exclude changing GIS container metadata."""
import argparse
import csv
import gzip
import hashlib
import json
from pathlib import Path

def hashes():
    records = {}
    for path in sorted(Path('data/processed').rglob('*')):
        if not path.is_file() or not str(path).endswith(('.csv', '.csv.gz', '.geojson')):
            continue
        digest = hashlib.sha256()
        opener = gzip.open if path.suffix == '.gz' else open
        with opener(path, 'rb') as stream:
            for chunk in iter(lambda: stream.read(1024*1024), b''):
                digest.update(chunk)
        records[str(path)] = digest.hexdigest()
    return records

parser = argparse.ArgumentParser()
parser.add_argument('--record', type=Path)
parser.add_argument('--compare', type=Path)
args = parser.parse_args()
current = hashes()
if args.record:
    args.record.write_text(json.dumps(current, indent=2),encoding='utf-8')
elif args.compare:
    previous = json.loads(args.compare.read_text(encoding='utf-8'))
    rows = [{'artifact':name, 'baseline_sha256':previous.get(name), 'rebuilt_sha256':current.get(name),
             'identical_payload': previous.get(name) == current.get(name)}
            for name in sorted(previous.keys() | current.keys())]
    with Path('metadata/reproducibility_check.csv').open('w',encoding='utf-8',newline='') as stream:
        writer = csv.DictWriter(stream,fieldnames=list(rows[0]),lineterminator='\n')
        writer.writeheader()
        writer.writerows(rows)
    if any(not row['identical_payload'] for row in rows):
        raise SystemExit('Reconstruction différente : voir metadata/reproducibility_check.csv')
    print(f'{len(rows)} CSV et GeoJSON reproduits à contenu identique.')
else:
    parser.error('Choisir --record ou --compare')
