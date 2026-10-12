#!/usr/bin/env bash
# Run from the same working directory as 4MRNA.sh.
# Requires Bash, Python 3, and an initialized Phenix environment.
# Source: https://github.com/S-Ando-Biophysics/4MRNA/blob/main/Codes/4MRNA.sh
# Refine CLI: https://phenix-online.org/documentation/reference/refinement
set -euo pipefail
command -v python3 >/dev/null 2>&1 || { echo 'Error: python3 is required.' >&2; exit 1; }
python3 - "$@" <<'PY'
import argparse
import json
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from decimal import Decimal, InvalidOperation
from pathlib import Path


def fail(message):
    raise SystemExit('Error: ' + message)


parser = argparse.ArgumentParser(
    description='Select the best 4MRNA candidate and run phenix.refine.',
    epilog='Additional Phenix arguments or parameter files may be supplied after --.')
parser.add_argument('--results-dir', default='4MRNA-Results')
parser.add_argument('--mtz', help='Original reflection MTZ (including existing R-free flags). '
                    'Default: the sole *.mtz in the current working directory.')
parser.add_argument('--output-dir', default='after-4MRNA-Results',
                    help='Parent for a new, unique refinement run directory.')
parser.add_argument('--dry-run', action='store_true', help='Print selection and command without running or writing files.')
parser.add_argument('--generate-r-free', action='store_true',
                    help='Ask Phenix to generate R-free flags if absent; use only for data without an existing test set.')
arguments = sys.argv[1:]
if '--' in arguments:
    boundary = arguments.index('--')
    extra = arguments[boundary + 1:]
    arguments = arguments[:boundary]
else:
    extra = []
args = parser.parse_args(arguments)
# Parameter files are resolved before changing the working directory.
extra = [str(Path(value).resolve()) if Path(value).is_file() else value for value in extra]
results_dir = Path(args.results_dir).resolve()
if not results_dir.is_dir():
    fail(f'Results directory not found: {results_dir}')
txt_files = sorted(results_dir.glob('*.txt'))
if not txt_files:
    fail(f'No result .txt files found in {results_dir}')


def natural_key(name):
    # Case-sensitive natural order, independent of locale; Model2 precedes Model10.
    return tuple((1, int(part)) if part.isdigit() else (0, part)
                 for part in re.split(r'(\d+)', name))


scores = {}
sources = {}
number = re.compile(r'[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\Z')
for path in txt_files:
    with path.open(encoding='utf-8-sig') as handle:
        for line_no, line in enumerate(handle, 1):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            fields = line.split()
            if fields == ['Model', 'TopLLG', 'TopTFZ'] or fields == ['Model', 'LLG', 'TFZ']:
                continue
            if len(fields) != 3 or not all(number.fullmatch(x) for x in fields[1:]):
                fail(f'Malformed result row: {path}:{line_no}: {line}')
            name, llg_text, tfz_text = fields
            if name in ('.', '..') or '/' in name or '\\' in name:
                fail(f'Invalid model name at {path}:{line_no}: {name}')
            try:
                score = Decimal(llg_text), Decimal(tfz_text)
            except InvalidOperation:
                fail(f'Invalid numeric score at {path}:{line_no}')
            if not all(value.is_finite() for value in score):
                fail(f'Non-finite score at {path}:{line_no}')
            if name in scores and scores[name] != score:
                fail(f'Conflicting scores for {name} in result files.')
            scores[name] = score
            sources.setdefault(name, []).append(f'{path}:{line_no}')
if not scores:
    fail('No candidates with numeric LLG and TFZ scores.')
qualified = [name for name, (llg, tfz) in scores.items() if llg >= 100 and tfz >= 8]
if qualified:
    rule = '1: LLG >= 100 and TFZ >= 8; TFZ descending, LLG descending, name ascending'
    best = min(qualified, key=lambda name: (-scores[name][1], -scores[name][0], natural_key(name), name))
else:
    # The requested rule does not specify ties in the product: use name order.
    rule = '2: LLG * TFZ descending; name ascending for equal products'
    best = min(scores, key=lambda name: (-scores[name][0] * scores[name][1], natural_key(name), name))
llg, tfz = scores[best]
model = results_dir / ('phaser-' + best) / 'PHASER.1.pdb'
if not model.is_file() or model.stat().st_size == 0:
    fail(f'Selected candidate PDB missing or empty: {model}')
if args.mtz:
    mtz = Path(args.mtz).resolve()
else:
    mtz_files = sorted(Path.cwd().glob('*.mtz'))
    if len(mtz_files) != 1:
        fail(f'Found {len(mtz_files)} MTZ files in the working directory; specify the original reflection data with --mtz.')
    mtz = mtz_files[0].resolve()
if not mtz.is_file() or mtz.stat().st_size == 0:
    fail(f'Reflection MTZ missing or empty: {mtz}')
cmd = ['phenix.refine', str(model), str(mtz), 'output.prefix=best_refine']
if args.generate_r_free:
    cmd.append('xray_data.r_free_flags.generate=True')
cmd.extend(extra)
print(f'Best model: {best}\nLLG: {llg}\nTFZ: {tfz}\nLLG * TFZ: {llg * tfz}\nRule: {rule}', flush=True)
print('Command: ' + shlex.join(cmd), flush=True)
if args.dry_run:
    print('Dry run: no refinement or output files created.')
    sys.exit(0)
if shutil.which('phenix.refine') is None:
    fail('phenix.refine not found. Initialize your Phenix environment before running this script.')
output_parent = Path(args.output_dir).resolve()
output_parent.mkdir(parents=True, exist_ok=True)
run_dir = Path(tempfile.mkdtemp(prefix='refine-', dir=output_parent))
summary = {
    'model': best, 'llg': str(llg), 'tfz': str(tfz), 'llg_times_tfz': str(llg * tfz),
    'rule': rule, 'candidate_count': len(scores), 'qualified_count': len(qualified),
    'result_rows': sources[best], 'pdb': str(model), 'mtz': str(mtz), 'command': cmd,
}
summary_path = run_dir / 'selection.json'
summary_path.write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
print(f'Output directory: {run_dir}', flush=True)
with (run_dir / 'phenix-refine.log').open('w', encoding='utf-8') as log:
    process = subprocess.Popen(cmd, cwd=run_dir, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, text=True, errors='replace')
    for line in process.stdout:
        log.write(line)
        log.flush()
        print(line, end='', flush=True)
    return_code = process.wait()
summary['exit_code'] = return_code
summary_path.write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
if return_code:
    print(f'Error: phenix.refine exited with status {return_code}. See {run_dir / "phenix-refine.log"}', file=sys.stderr)
    sys.exit(return_code if return_code > 0 else 128 - return_code)
print(f'Refinement completed: {run_dir}')
PY
