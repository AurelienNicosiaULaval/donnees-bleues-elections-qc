"""Retain digital financial cells locally; OCR drafts never count as validated values.
Requires pdftotext. Optional --ocr-summary uses pdftoppm and tesseract (fra).
The public inventory contains counts and checksums, not document text or personal data.
"""
import csv, gzip, hashlib, pathlib, re, subprocess, sys
root = pathlib.Path('.')
read = lambda p: list(csv.DictReader(p.open(encoding='utf-8')))
sources = {r['source_id']: r for r in read(root/'metadata/source_catalog.csv')}
manifest = {r['source_id']: r for r in read(root/'metadata/acquisition_manifest.csv')}
folder = root/'data/interim/financial'; folder.mkdir(parents=True,exist_ok=True)
fields = ['source_id','snapshot_id','observed_at','retrieved_at','source_updated_at','data_status','document_title','document_url','financial_year_source','source_page','source_line','line_label_source','source_numeric_column','value_source','value_numeric']
inventory=[]
number=re.compile(r'^\(?-?(?:\d{1,3}(?:[ \u00a0]\d{3})+|\d+)(?:[,.]\d{1,2})?\)?(?:\s*\$)?$')
with gzip.open(folder/'financial_source_cells.csv.gz','wt',encoding='utf-8',newline='') as out:
    writer=csv.DictWriter(out,fields);writer.writeheader()
    for sid,m in manifest.items():
        s=sources[sid];pdf=root/m['raw_file']
        if s['group'] not in ('finance','expenses','pre_election') or s['format']!='PDF' or not pdf.exists():continue
        textfile=folder/(m['sha256']+'.txt')
        status=subprocess.run(['pdftotext','-layout',str(pdf),str(textfile)],capture_output=True)
        if status.returncode:inventory.append(dict(source_id=sid,sha256=m['sha256'],pages=0,numeric_cells=0,status='pdf_text_failed'));continue
        text=textfile.read_text(encoding='utf-8');pages=text.split('\f');count=0
        for page,content in enumerate(pages,1):
            for linenum,line in enumerate(content.splitlines(),1):
                cells=re.split(r'\s{2,}',line.strip());label=cells[0] if cells else ''
                if not label or number.match(label):continue
                for col,cell in enumerate(cells[1:],1):
                    if not number.fullmatch(cell):continue
                    raw=cell;value=re.sub(r'[\s$()]','',cell).replace(',','.')
                    if '(' in cell:value='-'+value.lstrip('-')
                    writer.writerow(dict(source_id=sid,snapshot_id=m['snapshot_id'],observed_at=m['observed_at'],retrieved_at=m['retrieved_at'],source_updated_at='NA',data_status='unreviewed_text_extraction',document_title=s['titre'],document_url=s['url'],financial_year_source=re.search(r'20\d{2}',s['url']).group() if re.search(r'20\d{2}',s['url']) else 'NA',source_page=page,source_line=linenum,line_label_source=label,source_numeric_column=col,value_source=raw,value_numeric=value));count+=1
        ocr_status='not_requested'
        if '--ocr-summary' in sys.argv and 'recapitulation-revenus' in s['url'] and '2025/' in s['url']:
            images=folder/(m['sha256']+'_ocr');images.mkdir(exist_ok=True)
            if not list(images.glob('page-*.png')): subprocess.run(['pdftoppm','-r','200','-png',str(pdf),str(images/'page')],check=True,capture_output=True)
            for img in sorted(images.glob('page-*.png')):
                if not img.with_suffix('.txt').exists(): subprocess.run(['tesseract',str(img),str(img.with_suffix('')),'-l','fra','--psm','6'],check=True,capture_output=True)
            ocr_status='draft_requires_visual_review'
        inventory.append(dict(source_id=sid,sha256=m['sha256'],pages=len(pages)-int(not pages[-1].strip()),numeric_cells=count,status='digital_cells_require_semantic_review' if count else 'scanned_or_no_numeric_cells',ocr_status=ocr_status))
with (root/'metadata/financial_extraction_inventory.csv').open('w',encoding='utf-8',newline='') as out:
    writer=csv.DictWriter(out,['source_id','sha256','pages','numeric_cells','status','ocr_status']);writer.writeheader();writer.writerows(inventory)
print(len(inventory),'financial documents assessed; values retained locally.')
