import unittest
from unittest.mock import patch

from math_tools import calculate, expression, numeric, verify_answer
from solver import bounded_cas, solve


class MathTests(unittest.TestCase):
    def test_exact_arithmetic_and_equation(self):
        self.assertEqual(str(numeric("0.5")), "1/2")
        polynomial = {"op": "add", "args": [{"op": "pow", "args": [{"symbol": "x"}, {"number": "2"}]}, {"number": "-4"}]}
        self.assertEqual(calculate({"action": "solve", "expression": polynomial}), "{-2, 2}")

    def test_code_and_resource_amplification_are_rejected(self):
        for value in ["__import__('os')", "1/0", "10**999999", "nan"]:
            with self.assertRaises(ValueError): numeric(value)
        with self.assertRaises(ValueError): expression({"op": "pow", "args": [{"number": "2"}, {"number": "999"}]})
        with self.assertRaises(ValueError): expression({"symbol": "__class__"})

    def test_verification_means_matching_supplied_numeric_reference_only(self):
        self.assertEqual(verify_answer(None, "2"), "inconclusive")
        self.assertEqual(verify_answer("1/2", "0.5"), "verified")
        self.assertEqual(verify_answer("2", "3"), "contradicted")
        self.assertEqual(verify_answer("x^2", "2"), "unsupported")

    def test_real_isolated_cas_process(self):
        self.assertEqual(bounded_cas("verify", ("1/2", "0.5")), "verified")
        self.assertEqual(bounded_cas("calculate", {"action": "simplify", "expression": {"number": "2"}}), "2")

    @patch("solver.bounded_cas", return_value="verified")
    @patch("solver.complete", return_value={"answer": "2", "explanation": "1+1=2", "tools": []})
    @patch.dict("os.environ", {"MATH_MODEL_ID": "fixture"})
    def test_reference_never_leaks_into_generation(self, complete, _cas):
        result = solve({"text": "1+1", "document_id": "id", "revision": 2, "reference_answer": "secret-gold"})
        self.assertNotIn("secret-gold", str(complete.call_args))
        self.assertEqual(result["revision"], 2)


if __name__ == "__main__": unittest.main()
