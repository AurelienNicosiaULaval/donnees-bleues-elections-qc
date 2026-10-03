import csv
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('finality', 'scripts/download/results_final.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class FinalityTest(unittest.TestCase):
    def test_explicit_finality_only(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            folder = root/'data/snapshots/results_2026'
            folder.mkdir(parents=True)
            self.assertFalse(module.results_are_final(root))
            with (folder/'index.csv').open('w') as stream:
                writer = csv.DictWriter(stream,fieldnames=['observed_at','raw_file'])
                writer.writeheader()
                writer.writerow({'observed_at':'2026-10-06T00:00:00Z','raw_file':'data/snapshots/results_2026/test.json'})
            for flag in (False, None, 'true', 1, True):
                (folder/'test.json').write_text(json.dumps({'statistiques':{'isResultatsFinaux':flag,'nbBureauVote':10,'nbBureauVoteRempli':10}}))
                self.assertEqual(module.results_are_final(root), flag is True)

if __name__ == '__main__':
    unittest.main()
