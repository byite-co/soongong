"""Pinned PP-OCR generations; local directories only, no fallback download."""
import json
import os
import re


def load(root, *, cpu_threads=4):
    if type(cpu_threads) is not int or cpu_threads not in (1, 2, 4):
        raise ValueError('invalid_cpu_threads')
    os.environ['PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK'] = 'True'
    os.environ['HF_HUB_OFFLINE'] = '1'
    os.environ['TRANSFORMERS_OFFLINE'] = '1'
    manifest = json.loads((root / 'models.lock.json').read_text())
    generation = 'PP-OCRv5' if manifest['revision'].startswith('paddle-v5-') else 'PP-OCRv3'
    from paddleocr import PaddleOCR
    return PaddleOCR(lang='korean', ocr_version=generation,
        text_detection_model_name=generation+'_mobile_det',
        text_recognition_model_name='korean_'+generation+'_mobile_rec',
        text_detection_model_dir=str(root/'detection'),
        text_recognition_model_dir=str(root/'korean'),
        use_doc_orientation_classify=False, use_doc_unwarping=False,
        use_textline_orientation=False, device='cpu', cpu_threads=cpu_threads,
        enable_mkldnn=False)


def recognize(image, engine):
    import numpy as np
    result = next(iter(engine.predict(np.asarray(image))))
    blocks=[]
    for text, score, poly in zip(result['rec_texts'],result['rec_scores'],result['rec_polys'],strict=True):
        points=np.asarray(poly)
        box=[float(points[:,0].min()/image.width),float(points[:,1].min()/image.height),
             float(points[:,0].max()/image.width),float(points[:,1].max()/image.height)]
        blocks.append({'text':str(text),'confidence':float(score),'box':[max(0.,min(1.,x)) for x in box]})
    return sorted(blocks,key=lambda b:(b['box'][1],b['box'][0]))


def grading(image, blocks, page_index):
    """Candidate question association + red-ink geometric proposals.

    This is a measurable baseline, not a calibrated classifier. All proposals
    require explicit user confirmation; absent/ambiguous ink is mark=null.
    In particular absence never means correct/unsolved. No confidence invented.
    """
    import cv2
    import numpy as np
    pixels=np.asarray(image)
    red=((pixels[:,:,0].astype(int)>pixels[:,:,1].astype(int)+45) &
         (pixels[:,:,0].astype(int)>pixels[:,:,2].astype(int)+45)).astype('uint8')*255
    count, labels, stats, _=cv2.connectedComponentsWithStats(red,8)
    components=[]
    for index in range(1,count):
        x,y,w,h,area=map(int,stats[index])
        if area<12 or w<5 or h<5: continue
        components.append((x,y,w,h,(labels[y:y+h,x:x+w]==index).astype('uint8')*255))
    items=[]; seen=set()
    for block in blocks:
        match=re.match(r'^\s*(\d{1,6})(?:[.)\s]|$)',block['text'])
        if not match: continue
        number=int(match[1]); box=block['box']
        if number in seen: raise ValueError('ambiguous_question_number')
        seen.add(number); x=box[0]*image.width; y=(box[1]+box[3])*image.height/2
        near=[c for c in components if abs(c[1]+c[3]/2-y)<=max(c[3],(box[3]-box[1])*image.height)
              and -image.width*.04<=x-(c[0]+c[2]/2)<=image.width*.16]
        mark=None
        if len(near)==1:
            _,_,w,h,mask=near[0]
            contours,hierarchy=cv2.findContours(mask,cv2.RETR_CCOMP,cv2.CHAIN_APPROX_SIMPLE)
            if hierarchy is not None and any(v[3]>=0 for v in hierarchy[0]):
                outer=max(contours,key=cv2.contourArea)
                corners=cv2.approxPolyDP(outer,.045*cv2.arcLength(outer,True),True)
                if len(corners)==3: mark='partial'
                elif len(corners)>=5 and .55<w/h<1.8: mark='correct'
            else:
                # Both diagonals must cross; no filled blob/unchecked rectangle.
                small=cv2.resize(mask,(21,21),interpolation=cv2.INTER_NEAREST)>0
                diagonal=sum(small[i,max(0,i-2):min(21,i+3)].any() for i in range(21))/21
                reverse=sum(small[i,max(0,18-i):min(21,23-i)].any() for i in range(21))/21
                if diagonal>.8 and reverse>.8 and small.mean()<.6: mark='wrong'
        items.append({'number':number,'mark':mark,'confidence':None,'box':box,'needs_review':True})
    if len(items)>500: raise ValueError('result_too_large')
    return {'index':page_index,'items':items}
