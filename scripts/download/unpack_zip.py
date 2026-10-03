"""Extract CSV members to ASCII paths, preserving the original ZIP member label."""
import csv, hashlib, pathlib, sys, zipfile
archive, destination = map(pathlib.Path, sys.argv[1:3])
destination.mkdir(parents=True, exist_ok=True)
records = []
with zipfile.ZipFile(archive) as package:
    for info in package.infolist():
        path = pathlib.PurePosixPath(info.filename)
        if path.is_absolute() or '..' in path.parts:
            raise ValueError('Unsafe archive path')
        if path.suffix.lower() not in ('.csv','.xls','.xlsx','.txt'):
            continue
        name = 'member_' + hashlib.sha256(info.filename.encode('utf-8')).hexdigest()[:16] + path.suffix.lower()
        (destination / name).write_bytes(package.read(info))
        records.append({'file': name, 'original_member': info.filename})
with (destination / 'members.csv').open('w', newline='', encoding='utf-8') as output:
    writer = csv.DictWriter(output, fieldnames=['file', 'original_member'])
    writer.writeheader(); writer.writerows(records)
