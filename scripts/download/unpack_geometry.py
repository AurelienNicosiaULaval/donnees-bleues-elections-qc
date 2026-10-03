"""Extract complete shapefile families to safe ASCII paths, with a member manifest."""
import csv, pathlib, sys, zipfile
archive, destination = map(pathlib.Path, sys.argv[1:3])
destination.mkdir(parents=True, exist_ok=True)
records, families = [], {}
with zipfile.ZipFile(archive) as package:
    for info in package.infolist():
        path = pathlib.PurePosixPath(info.filename)
        if path.is_absolute() or '..' in path.parts:
            raise ValueError('Unsafe archive path')
        if path.suffix.lower() not in ('.shp', '.shx', '.dbf', '.prj', '.cpg'):
            continue
        family = str(path.with_suffix(''))
        families.setdefault(family, len(families) + 1)
        name = f'layer_{families[family]}{path.suffix.lower()}'
        (destination / name).write_bytes(package.read(info))
        records.append({'file': name, 'original_member': info.filename})
with (destination / 'members.csv').open('w', newline='', encoding='utf-8') as output:
    writer = csv.DictWriter(output, fieldnames=['file', 'original_member'])
    writer.writeheader(); writer.writerows(records)
