"""Exit successfully only when the latest retained JSON explicitly states finality."""
import csv
import json
import sys
from pathlib import Path

def results_are_final(directory=Path('.')):
    index = directory/'data/snapshots/results_2026/index.csv'
    if not index.exists():
        return False
    with index.open(encoding='utf-8') as stream:
        rows = list(csv.DictReader(stream))
    if not rows:
        return False
    latest = max(rows, key=lambda row: row['observed_at'])
    with (directory/latest['raw_file']).open(encoding='utf-8-sig') as stream:
        payload = json.load(stream)
    return payload.get('statistiques', {}).get('isResultatsFinaux') is True

if __name__ == '__main__':
    sys.exit(0 if results_are_final() else 1)
