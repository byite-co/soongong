"""Use the public UniMERNet inference API; no GUI/demo dataset is bundled."""
import os


def load(root):
    os.environ['HF_HUB_OFFLINE'] = '1'
    os.environ['TRANSFORMERS_OFFLINE'] = '1'
    os.environ['HF_DATASETS_OFFLINE'] = '1'
    os.environ['NO_ALBUMENTATIONS_UPDATE'] = '1'
    import torch
    from omegaconf import OmegaConf
    from unimernet.models.unimernet.unimernet import UniMERModel
    from unimernet.processors import load_processor
    # The packaged Config helper resolves a non-packaged demo YAML. Build the
    # documented tiny configuration explicitly with checked, local paths only.
    config = OmegaConf.create({'model_config':{'model_name':str(root/'model'),'max_seq_len':1536},
      'tokenizer_config':{'path':str(root/'model')},'load_pretrained':True,
      'pretrained':str(root/'model/unimernet_tiny.pth')})
    torch.set_num_threads(4)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = UniMERModel.from_config(config).to(device).eval()
    transform = load_processor('formula_image_eval', OmegaConf.create({'image_size':[192,672]}))
    return model, transform, device


def recognize(image, root, engine=None):
    import torch
    model, transform, device = engine or load(root)
    with torch.inference_mode():
        result = model.generate({"image": transform(image).unsqueeze(0).to(device)})
    text = result["pred_str"][0]
    if not isinstance(text, str) or len(text) > 20000:
        raise ValueError("invalid_math_result")
    return text
