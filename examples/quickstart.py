"""Run from the repository root with pandas and geopandas installed."""
from pathlib import Path
import pandas as pd
import geopandas as gpd
root = Path('.')
candidates = pd.read_csv(root/'data/processed/candidates.csv',dtype={'district_id':'string'},encoding='utf-8')
latest = candidates.groupby('source_id')['observed_at'].transform('max')
candidates = candidates.loc[candidates['observed_at'].eq(latest)]
counts = candidates.groupby('district_id').size().rename('n_candidates').reset_index()
geometry = gpd.read_file(root/'data/processed/geography/districts_2026.gpkg')
joined = geometry.merge(counts,on='district_id',validate='one_to_one')
assert len(joined)==127
print(counts.describe())
# Préserver les éditions de carte lors de toute comparaison historique.
