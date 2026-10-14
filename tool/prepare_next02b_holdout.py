"""Select a new, local-only CPE evaluation set from the verified existing ZIP.

No download, model invocation, synthetic labels or writer identity creation.
The old 60 are a diagnostic set. Freeze this selection before choosing a model.
"""
import argparse
import hashlib
import json
from pathlib import Path
import random
import zipfile

ARCHIVE_SHA256 = '9bf370b8cac868fee84835f40dec26c477430611253e3feb681356a8149a3a90'
SEED = 20261014


def select_indices(total=5921, previous=60, count=60, seed=SEED):
    if not 0 <= previous <= total or not 0 < count <= total - previous:
        raise ValueError('insufficient_unseen_rows')
    indices = list(range(previous, total))
    random.Random(seed).shuffle(indices)
    return indices


def prepare(archive, destination):
    destination = destination.resolve()
    repository = Path(__file__).resolve().parents[1]
    if destination.is_relative_to(repository):
        raise ValueError('dataset_must_be_outside_repository')
    if destination.exists():
        raise ValueError('destination_already_exists')
    with archive.open('rb') as stream:
        if hashlib.file_digest(stream, 'sha256').hexdigest() != ARCHIVE_SHA256:
            raise ValueError('archive_hash_mismatch')
    # The archive hash preserves the previously verified 5,921-row mapping.
    # Read only prior hashes and the selected candidates, not a new full audit.
    with zipfile.ZipFile(archive) as source:
        labels = source.read('UniMER-Test/cpe.txt').decode().splitlines()
        if len(labels) != 5921:
            raise ValueError('label_count_changed')
        def data(index):
            return source.read(f'UniMER-Test/cpe/{index:07d}.png')
        seen = {hashlib.sha256(data(i)).hexdigest() for i in range(60)}
        selected = []; duplicates = []
        for index in select_indices():
            raw = data(index); digest = hashlib.sha256(raw).hexdigest()
            if digest in seen:
                duplicates.append(index)
                continue
            seen.add(digest)
            selected.append((index, digest, raw))
            if len(selected) == 60:
                break
        if len(selected) != 60:
            raise ValueError('insufficient_unique_images')
        destination.mkdir(parents=True, exist_ok=False)
        rows = []
        for index, digest, raw in selected:
            target = destination / f'{index:07d}.png'
            target.write_bytes(raw)
            rows.append({'id': f'{index:07d}', 'path': str(target), 'sha256': digest,
                'ground_truth': labels[index], 'source': 'UniMER-Test/CPE',
                'source_file': f'UniMER-Test/cpe/{index:07d}.png',
                'label_file': 'UniMER-Test/cpe.txt', 'label_line': index + 1,
                'writer_id': None, 'document_id': None, 'type': 'printed',
                'split': 'next02b_new_evaluation', 'local_only': True,
                'license': 'Apache-2.0 publisher card; original per-document rights not supplied; local evaluation only'})
        manifest = destination / 'manifest.json'
        manifest.write_text(json.dumps(rows, indent=2), encoding='utf-8')
        selection = {'seed': SEED, 'archive_sha256': ARCHIVE_SHA256,
            'selected_indices': [r[0] for r in selected], 'duplicate_indices_skipped': duplicates,
            'manifest_sha256': hashlib.sha256(manifest.read_bytes()).hexdigest(),
            'printed_samples': 60, 'handwritten_samples': 0,
            'independent_writers': None, 'original_60_excluded': True,
            'selection_before_model_choice_required': True,
            'not_independent_student_generalization': True}
        (destination / 'selection.json').write_text(json.dumps(selection, indent=2), encoding='utf-8')
        return selection


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--archive', type=Path, required=True)
    parser.add_argument('--destination', type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(prepare(args.archive, args.destination), indent=2))
