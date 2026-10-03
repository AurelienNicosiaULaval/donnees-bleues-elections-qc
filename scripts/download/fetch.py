"""Verified-TLS fallback for a platform's Python certificate store; no TLS bypass."""
import json, ssl, sys, urllib.request
url, destination = sys.argv[1:3]
request = urllib.request.Request(url, headers={'User-Agent': 'DonneesBleues-ElectionsQC/0.1 (+https://github.com/AurelienNicosiaULaval/donnees-bleues-elections-qc)'})
with urllib.request.urlopen(request, timeout=120, context=ssl.create_default_context()) as response:
    with open(destination, 'wb') as output:
        while True:
            block = response.read(1024 * 1024)
            if not block: break
            output.write(block)
    print(json.dumps({'status': response.status, 'last_modified': response.headers.get('Last-Modified'), 'etag': response.headers.get('ETag')}))
