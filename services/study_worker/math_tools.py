"""Bounded symbolic tools. Build SymPy objects from a whitelist AST, never eval.

The model can request arithmetic/solve/differentiate, not Python execution.
Only numeric CSAT answers are verified against an independently supplied gold.
"""
import re

NUMBER = re.compile(r"-?(?:0|[1-9][0-9]{0,8})(?:\.[0-9]{1,8})?(?:/[1-9][0-9]{0,8})?\Z")


def numeric(value):
    import sympy as s
    if not isinstance(value, str) or not NUMBER.fullmatch(value):
        raise ValueError("unsupported_number")
    pieces = value.split("/")
    return s.Rational(pieces[0]) / (s.Integer(pieces[1]) if len(pieces) == 2 else 1)


def expression(node, budget=None, depth=0):
    import sympy as s
    if budget is None: budget = [80]
    budget[0] -= 1
    if budget[0] < 0 or depth > 12 or not isinstance(node, dict):
        raise ValueError("expression_too_large")
    if set(node) == {"number"}: return numeric(node["number"])
    if set(node) == {"symbol"} and node["symbol"] in {"x", "y", "t", "n"}:
        return s.Symbol(node["symbol"], real=True)
    if set(node) != {"op", "args"} or not isinstance(node["args"], list) or not 1 <= len(node["args"]) <= 8:
        raise ValueError("invalid_expression")
    args = [expression(arg, budget, depth + 1) for arg in node["args"]]
    op = node["op"]
    if op == "add": return s.Add(*args)
    if op == "mul": return s.Mul(*args)
    if op == "pow" and len(args) == 2 and args[1].is_Integer and -12 <= args[1] <= 12:
        return s.Pow(*args)
    functions = {"sin": s.sin, "cos": s.cos, "sqrt": s.sqrt, "abs": s.Abs}
    if op in functions and len(args) == 1: return functions[op](args[0])
    raise ValueError("unsupported_expression")


def calculate(request):
    import sympy as s
    if not isinstance(request, dict) or set(request) - {"action", "expression", "variable"}:
        raise ValueError("invalid_tool")
    expr = expression(request.get("expression"))
    variable = request.get("variable", "x")
    if variable not in {"x", "y", "t", "n"}: raise ValueError("invalid_variable")
    symbol = s.Symbol(variable, real=True)
    action = request.get("action")
    if action == "simplify": result = s.simplify(expr)
    elif action == "differentiate": result = s.diff(expr, symbol)
    elif action == "solve": result = s.solveset(expr, symbol, domain=s.S.Reals)
    else: raise ValueError("unsupported_tool")
    text = str(result)
    if len(text) > 4000: raise ValueError("result_too_large")
    return text


def verify_answer(reference, answer):
    if not reference: return "inconclusive"
    try:
        gold, candidate = numeric(reference.strip()), numeric(answer.strip())
    except (ValueError, AttributeError):
        return "unsupported"
    # Math-Verify sees ONLY LaTeX generated from our numeric grammar. Raw
    # student/model strings never reach its general expression parser.
    import sympy as s
    from math_verify import LatexExtractionConfig, parse, verify
    config = [LatexExtractionConfig()]
    gold_parsed = parse("$" + s.latex(gold) + "$", extraction_config=config)
    answer_parsed = parse("$" + s.latex(candidate) + "$", extraction_config=config)
    if not gold_parsed or not answer_parsed: return "inconclusive"
    return "verified" if verify(gold_parsed, answer_parsed) else "contradicted"
