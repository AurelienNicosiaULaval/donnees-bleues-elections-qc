"""Extract the fixed 2025 financial summary grid. Review hashes unlock local tables.
Run financial_documents.py --ocr-summary first. Unreviewed OCR is never promoted.
"""
import csv, hashlib, io, pathlib, re, subprocess
root=pathlib.Path('.')
m=next(x for x in csv.DictReader(open('metadata/acquisition_manifest.csv')) if '2025-recapitulation-revenus' in x['url'])
folder=root/'data/interim/financial'/(m['sha256']+'_ocr')
metrics=['contributions_cad','memberships_cad','political_activities_cad','public_funding_cad','electoral_reimbursements_cad','other_income_cad','total_income_cad','total_expenses_cad']
bounds=[.332,.438,.51,.586,.668,.744,.825,.91,.995]
rows=[];entity=None
for img in sorted(folder.glob('page-*.png')):
    output=subprocess.run(['tesseract',str(img),'stdout','-l','fra','--psm','6','tsv'],check=True,capture_output=True,text=True).stdout
    words=list(csv.DictReader(io.StringIO(output),delimiter='\t'));width=int(words[0]['width']);height=int(words[0]['height']);words=[w for w in words if w['text'].strip()]
    lines={}
    for w in words:lines.setdefault((w['block_num'],w['par_num'],w['line_num']),[]).append(w)
    ordered=sorted(lines.values(),key=lambda ws:min(int(w['top']) for w in ws))
    need_name=False
    for ws in ordered:
        text=' '.join(w['text'] for w in ws)
        if text=='LE PARTI':need_name=True;continue
        if need_name:
            name=' '.join(w['text'] for w in ws if int(w['left'])/width<.3)
            if name:entity=name;need_name=False
        if not text.startswith('TOTAL DE L') or entity is None:continue
        values=[];raws=[]
        for a,b in zip(bounds[:-1],bounds[1:]):
            value=' '.join(w['text'] for w in ws if a <= (int(w['left'])+int(w['width'])/2)/width < b)
            raws.append(value)
            digits=re.sub(r'\s','',value)
            values.append(int(digits) if re.fullmatch(r'-?\d+',digits) else 'NA')
        rec=dict(entity_name_source=entity,financial_year=2025,source_page=int(img.stem.split('-')[-1]),**dict(zip(metrics,values)))
        rec['review_hash']=hashlib.sha256((m['sha256']+'|'+str(rec)).encode()).hexdigest()
        rec.update({k:m[k] for k in ['source_id','snapshot_id','observed_at','retrieved_at']});rec['source_updated_at']='NA';rec['data_status']='unreviewed_ocr_summary';rec['value_tokens_source']=';'.join(raws)
        rows.append(rec)
if rows:
    with open(root/'data/interim/financial/summary_2025_draft.csv','w',newline='') as out:
        writer=csv.DictWriter(out,list(rows[0]));writer.writeheader();writer.writerows(rows)
    allowed=set()
    review=root/'metadata/financial_summary_review.csv'
    if review.exists():allowed={r['review_hash'] for r in csv.DictReader(review.open()) if r['review_status']=='visually_verified'}
    approved=[dict(r,data_status='official_summary_visually_verified') for r in rows if r['review_hash'] in allowed]
    if approved:
        with open(root/'data/interim/financial/summary_2025_reviewed.csv','w',newline='') as out:
            writer=csv.DictWriter(out,list(approved[0]));writer.writeheader();writer.writerows(approved)
print('Draft rows:',len(rows),'reviewed:',len(approved) if rows else 0)
for r in rows:print(r['source_page'],r['entity_name_source'],r['total_income_cad'],r['total_expenses_cad'])
