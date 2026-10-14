import unittest
from ocr_evaluation import summarize,validate_split,normalize,grading_metrics

class EvaluationTests(unittest.TestCase):
    def test_timeout_and_empty_remain_denominator(self):
        rows=[{'ground_truth':'x','prediction':'x','valid':True,'seconds':1},
              {'ground_truth':'y','prediction':None,'valid':False,'error':'TimeoutError','seconds':50},
              {'ground_truth':'z','prediction':'','valid':False,'seconds':1}]
        result=summarize(rows,'math')
        self.assertEqual(result['normalized_exact_match'],1/3);self.assertEqual(result['p95_seconds'],50)
        self.assertEqual(summarize(rows,'text')['cer_without_spaces'],2/3)
    def test_no_semantic_math_rewrite(self):
        self.assertNotEqual(normalize('x^{-1}',False),normalize('x^{1}',False))
        self.assertEqual(normalize('\u1100\u1161'),normalize('가'))
    def test_missing_ids_not_invented_and_leakage_rejected(self):
        rows=[{'sha256':'a','source':'one','writer_id':None,'document_id':None,'split':'holdout'}]
        validate_split(rows);self.assertIsNone(rows[0]['writer_id'])
        for field in ['sha256','source','writer_id','document_id']:
            first={**rows[0],field:'shared'};second={**rows[0],'sha256':'b','source':'two','split':'train',field:'shared'}
            with self.assertRaises(ValueError):validate_split([first,second])
    def test_grading_unknown_and_timeout_are_not_dropped(self):
        truth=[{'page_index':0,'number':n,'mark':m} for n,m in enumerate(['correct','wrong','partial','unsolved','guessed'])]
        prediction=[{**truth[0],'mark':None},{**truth[1],'mark':'correct'}]+truth[2:]
        out=grading_metrics([{'ground_truth':truth,'prediction':prediction},{'ground_truth':truth,'prediction':None}])
        self.assertEqual(out['ground_truth_items'],10);self.assertEqual(out['coverage'],.5)
        self.assertEqual(out['per_mark']['correct']['precision'],0)
        self.assertEqual(out['per_mark']['wrong']['fn'],2)
        self.assertEqual(out['unknown_fraction'],.2)
    def test_missing_mark_class_cannot_pass_macro_f1(self):
        item={'page_index':0,'number':1,'mark':'correct'}
        self.assertIsNone(grading_metrics([{'ground_truth':[item],'prediction':[item]}])['macro_f1'])
