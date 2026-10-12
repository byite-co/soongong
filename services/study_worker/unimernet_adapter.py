"""Use the public UniMERNet inference API; no GUI/demo dataset is bundled."""
from argparse import Namespace


def recognize(image, root):
    import torch
    import unimernet.tasks as tasks
    from unimernet.common.config import Config
    from unimernet.processors import load_processor

    config = Config(Namespace(cfg_path=str(root / "unimernet.yaml"), options=None))
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = tasks.setup_task(config).build_model(config).to(device).eval()
    transform = load_processor("formula_image_eval", config.config.datasets.formula_rec_eval.vis_processor.eval)
    with torch.inference_mode():
        result = model.generate({"image": transform(image).unsqueeze(0).to(device)})
    text = result["pred_str"][0]
    if not isinstance(text, str) or len(text) > 20000:
        raise ValueError("invalid_math_result")
    return text
