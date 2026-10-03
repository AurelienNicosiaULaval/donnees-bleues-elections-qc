"""Decode an explicitly identified legacy encoding; never modify the raw source."""
import pathlib, sys
source,destination,encoding=sys.argv[1:4]
text=pathlib.Path(source).read_bytes().decode(encoding,errors='strict')
pathlib.Path(destination).write_text(text,encoding='utf-8')
