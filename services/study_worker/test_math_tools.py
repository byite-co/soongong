import unittest
from unittest.mock import patch

from math_tools import calculate, expression, numeric, verify_answer
from solver import bounded_cas, solve, CasResult, CalculationUnavailable


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
        self.assertEqual(bounded_cas("verify", ("1/2", "0.5")), CasResult(value="verified"))
        self.assertEqual(bounded_cas("calculate", {"action": "simplify", "expression": {"number": "2"}}), CasResult(value="2"))

    @patch("solver.bounded_cas", return_value=CasResult(value="verified"))
    @patch("solver.complete", return_value={"answer": "2", "explanation": "1+1=2", "tools": []})
    @patch.dict("os.environ", {"MATH_MODEL_ID": "fixture"})
    def test_reference_never_leaks_into_generation(self, complete, _cas):
        result = solve({"text": "1+1", "document_id": "id", "revision": 2, "reference_answer": "secret-gold"})
        self.assertNotIn("secret-gold", str(complete.call_args))
        self.assertEqual(result["revision"], 2)

    def test_calculation_failure_stops_remaining_tools_model_and_verification(self):
        tool = {"action": "simplify", "expression": {"number": "2"}}
        body = {"text": "1+1", "document_id": "fixture", "revision": 1, "reference_answer": "2"}
        for error in ["tool_timeout", "tool_unavailable"]:
            for outcomes in [[CasResult(error=error)], [CasResult(value="2"), CasResult(error=error)]]:
                with self.subTest(error=error, failure_index=len(outcomes)):
                    with patch("solver.complete", return_value={"tools": [tool, tool], "answer": "2"}) as model, \
                         patch("solver.bounded_cas", side_effect=outcomes) as cas:
                        with self.assertRaises(CalculationUnavailable): solve(body)
                        self.assertEqual(model.call_count, 1)
                        self.assertEqual(cas.call_count, len(outcomes))
                        self.assertTrue(all(call.args[0] == "calculate" for call in cas.call_args_list))

    def test_normal_two_tool_loop_does_not_leak_reference(self):
        tool = {"action": "simplify", "expression": {"number": "2"}}
        with patch("solver.complete", side_effect=[{"tools": [tool, tool]},
                {"answer": "2", "explanation": "fixture", "tools": []}]) as model, \
             patch("solver.bounded_cas", side_effect=[CasResult(value="2"), CasResult(value="tool_timeout"),
                CasResult(value="verified")]) as cas, patch.dict("os.environ", {"MATH_MODEL_ID": "fixture"}):
            result = solve({"text": "1+1", "document_id": "fixture", "revision": 1, "reference_answer": "gold-marker"})
            self.assertEqual(result["verification"], "verified")
            self.assertEqual(model.call_count, 2)
            self.assertEqual(cas.call_count, 3)
            self.assertNotIn("gold-marker", str(model.call_args_list))
            # A successful mathematical result is never interpreted as an
            # error just because its text happens to equal an old sentinel.
            self.assertIn("tool_timeout", str(model.call_args))

    def test_verification_infrastructure_failure_is_inconclusive(self):
        with patch("solver.complete", return_value={"answer": "2", "explanation": "fixture"}), \
             patch("solver.bounded_cas", return_value=CasResult(error="tool_timeout")), \
             patch.dict("os.environ", {"MATH_MODEL_ID": "fixture"}):
            result = solve({"text": "1+1", "document_id": "fixture", "revision": 1, "reference_answer": "2"})
            self.assertEqual(result["verification"], "inconclusive")


if __name__ == "__main__": unittest.main()
