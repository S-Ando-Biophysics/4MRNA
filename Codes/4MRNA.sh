#!/usr/bin/env bash

set -euo pipefail
if ! [ -t 0 ] && [ -r /dev/tty ]; then
  exec </dev/tty
fi

abort() { echo "Error: $*" >&2; exit 1; }

here="$(pwd)"
inp="${here}/4MRNA-INP.txt"

final_bg_dir="${here}/4MRNA-Background-Codes"
min_params_out="${here}/min.params"
checkpoint_root="${final_bg_dir}/Checkpoints"
checkpoint_scripts_dir="${checkpoint_root}"
execution_mode_checkpoint="${checkpoint_root}/execution_mode.txt"
tmp_root="${final_bg_dir}/tmp"

mkdir -p "$tmp_root"
work_root="$(mktemp -d "${tmp_root}/run.XXXXXX")"
bg_dir="${work_root}/4MRNA-Background-Codes"

cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

L_MB_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-CreatingModels-1st.sh"
L_MB_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-CreatingModels-2nd.sh"
L1_01_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-1model-Model01-1st.sh"
L1_01_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-1model-Model01-2nd.sh"
L2_01_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-2model-Model01-1st.sh"
L2_01_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-2model-Model01-2nd.sh"
L2_02_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-2model-Model02-1st.sh"
L2_02_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-2model-Model02-2nd.sh"
L3_01_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-3model-Model01-1st.sh"
L3_01_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-3model-Model01-2nd.sh"
L3_02_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-3model-Model02-1st.sh"
L3_02_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-3model-Model02-2nd.sh"
L3_03_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-3model-Model03-1st.sh"
L3_03_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Shell-MR-3model-Model03-2nd.sh"
MIN_PARAMS_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/min.params"

curl_get() {
  local url="$1"
  local out="$2"
  curl -fsSL "$url" -o "$out" || abort "Failed to download: $url"
}

ask_choice() {
  local q="$1" choices="$2" ans
  IFS=',' read -r -a arr <<< "$choices"
  while :; do
    read -r -p "$q [$choices]: " ans || abort "Input ended while choosing: $q"
    for c in "${arr[@]}"; do
      [[ "$ans" == "$c" ]] && echo "$ans" && return 0
    done
    echo "Invalid input. Try again." >&2
  done
}

ask_yesno() {
  local ans
  while :; do
    read -r -p "$1 [Y/N]: " ans
    case "$ans" in
      Y|y) return 0 ;;
      N|n) return 1 ;;
    esac
    echo "Please answer Y or N."
  done
}

ask_num() {
  local ans
  while :; do
    read -r -p "$1: " ans
    if python3 - "$ans" <<'PYCHECK'
import sys, math
try:
    x = float(sys.argv[1])
    if not math.isfinite(x):
        raise ValueError
except Exception:
    sys.exit(1)
sys.exit(0)
PYCHECK
    then
      echo "$ans"
      return 0
    fi
    echo "Enter a number."
  done
}

ask_model_amount() {
  python3 - "$1" "$2" "$3" "${4:-}" 3<&0 <<'PY_AMOUNT'
import os
import re
import sys
from decimal import Decimal, InvalidOperation, ROUND_CEILING

index, na_type, sequence, specification = sys.argv[1:]
alphabet = "AUGC" if na_type == "A-RNA" else "ATGC"
sequence = "".join(c for c in sequence.upper() if c in alphabet)
if not sequence:
    raise SystemExit(f"Model0{index}: sequence must contain at least one valid base")
per_group = 3 ** (len(sequence) // 2)
total = 3 * per_group
print(f"Model0{index}: The sequence contains {len(sequence)} base pairs, "
      f"so up to {total} initial models will be created.",
      file=sys.stderr, flush=True)

def parse_amount(value):
    if value.lower() == "full":
        return "Full", total
    match = re.fullmatch(r"lite\s+(.+)", value, re.I)
    if not match:
        raise ValueError
    request = match.group(1).strip()
    if request.endswith("%"):
        number = Decimal(request[:-1])
        if not number.is_finite() or not 0 < number <= 100:
            raise ValueError
        requested = max(1, int((number * total / 100).to_integral_value(rounding=ROUND_CEILING)))
    elif re.fullmatch(r"[0-9]+", request):
        requested = int(request)
        if not 1 <= requested <= total:
            raise ValueError
    else:
        raise ValueError
    return "Lite " + request, ((requested + 2) // 3) * 3

if specification:
    try:
        amount, kept = parse_amount(specification.strip())
    except (InvalidOperation, ValueError, OverflowError):
        raise SystemExit(f"Invalid -AMOUNT{index}: use Full, Lite COUNT (1-{total}), or Lite PERCENT%")
else:
    print("Please select Full to create all models, or Lite to create a smaller, "
          "randomly selected subset.",
          file=sys.stderr, flush=True)
    with os.fdopen(3, "rb", buffering=0) as answers:
        def answer(prompt):
            print(prompt, end="", file=sys.stderr, flush=True)
            line = answers.readline()
            if not line:
                raise SystemExit("Input ended while choosing model amount")
            return line.decode("utf-8").strip()

        while True:
            choice = answer("Which option would you like to use? [Full, Lite]: ").lower()
            if choice == "full":
                amount, kept = "Full", total
                break
            if choice != "lite":
                print("Please answer Full or Lite.", file=sys.stderr)
                continue
            while True:
                request = answer(f"Model0{index}: keep percentage (e.g. 10%) or total count (1-{total}): ")
                try:
                    amount, kept = parse_amount("Lite " + request)
                    break
                except (InvalidOperation, ValueError, OverflowError):
                    print(f"Enter a percentage greater than 0 and at most 100%, or an integer from 1 to {total}.", file=sys.stderr)
            break
print(f"Model0{index}: {amount}; keeping {kept // 3} models each for "
      f"Tilt/Roll/Twist ({kept} in total).", file=sys.stderr, flush=True)
print(amount)
PY_AMOUNT
}

sync_bg_dir_to_final() {
  mkdir -p "$final_bg_dir"

  cp -Rp "$bg_dir"/. "$final_bg_dir"/

  find "$final_bg_dir" -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
}

replace_assignment() {
  local key="$1"
  local value="$2"
  local file="$3"
  local tmp

  tmp="$(mktemp "${file}.tmp.XXXXXX")"
  cp -p "$file" "$tmp"

  if ! awk -v key="$key" -v value="$value" '
    BEGIN { replaced = 0 }
    !replaced && index($0, key "=") == 1 {
      print key "=" value
      replaced = 1
      next
    }
    { print }
    END {
      if (!replaced) exit 1
    }
  ' "$file" > "$tmp"; then
    rm -f "$tmp"
    abort "Failed to update ${key} in ${file}"
  fi

  mv "$tmp" "$file"
}

shell_quote() {
  python3 - "$1" <<'PY_SHELL_QUOTE'
import shlex
import sys

print(shlex.quote(sys.argv[1]))
PY_SHELL_QUOTE
}

append_array_item() {
  local array_length="$1"
  local item="$2"

  MW_ARR[$array_length]="$item"
}

mark_newly_downloaded() {
  local file="$1"

  newly_downloaded[${#newly_downloaded[@]}]="$file"
}

was_newly_downloaded() {
  local wanted="$1"
  local downloaded

  for downloaded in "${newly_downloaded[@]}"; do
    [[ "$downloaded" == "$wanted" ]] && return 0
  done

  return 1
}

script_checkpoint_label() {
  local f="$1"
  printf '%s' "${f%.*}"
}

script_checkpoint_dir() {
  local f="$1"
  printf '%s/%s' "$checkpoint_scripts_dir" "$(script_checkpoint_label "$f")"
}

script_done_file() {
  local f="$1"
  printf '%s/done' "$(script_checkpoint_dir "$f")"
}

script_running_file() {
  local f="$1"
  printf '%s/running' "$(script_checkpoint_dir "$f")"
}

script_failed_file() {
  local f="$1"
  printf '%s/failed' "$(script_checkpoint_dir "$f")"
}

write_checkpoint_value() {
  local file="$1" value="$2" temporary
  mkdir -p "$(dirname "$file")"
  temporary="$(mktemp "${file}.tmp.XXXXXX")"
  printf '%s\n' "$value" > "$temporary"
  mv "$temporary" "$file"
}

choose_execution_mode() {
  local selected_mode display_mode
  if [[ -f "$execution_mode_checkpoint" ]]; then
    run_mode="$(cat "$execution_mode_checkpoint")"
    case "$run_mode" in
      default|customize) ;;
      *) abort "Invalid execution-mode checkpoint: $execution_mode_checkpoint" ;;
    esac
    case "$run_mode" in
      default) display_mode="Default" ;;
      customize) display_mode="Customize" ;;
    esac
    echo "[CHECKPOINT] Reusing execution mode: $display_mode"
  else
    selected_mode="$(ask_choice "Please choose execution mode." "Default,Customize")"
    case "$selected_mode" in
      Default) run_mode="default" ;;
      Customize) run_mode="customize" ;;
    esac
  fi
}

mark_script_running() {
  local f="$1" d
  d="$(script_checkpoint_dir "$f")"
  mkdir -p "$d"
  : > "$(script_running_file "$f")"
  rm -f "$(script_failed_file "$f")"
}

mark_script_done() {
  local f="$1" d
  d="$(script_checkpoint_dir "$f")"
  mkdir -p "$d"
  rm -f "$(script_running_file "$f")" "$(script_failed_file "$f")"
  : > "$(script_done_file "$f")"
}

mark_script_failed() {
  local f="$1" rc="$2" d
  d="$(script_checkpoint_dir "$f")"
  mkdir -p "$d"
  rm -f "$(script_running_file "$f")"
  printf '%s\n' "$rc" > "$(script_failed_file "$f")"
}

run_ordered_script() {
  local f="$1"
  local rc=0

  if [[ -f "$(script_done_file "$f")" ]]; then
    echo "[CHECKPOINT] $f already completed. Skipping."
    return 0
  fi

  mark_script_running "$f"

  echo "[RUN] bash   $f"
  (cd "$final_bg_dir"; bash "$f") || rc=$?

  if (( rc == 0 )); then
    mark_script_done "$f"
  else
    mark_script_failed "$f" "$rc"
    return "$rc"
  fi
}

if [[ ! -f "$inp" ]]; then
  echo "Input file '4MRNA-INP.txt' not found."
  echo "Generating it now by answering questions."
  n_models="$(ask_choice "The number of models for molecular replacement" "1,2,3")"
  declare -a TYP SEQ PHOS NUM

  for ((i=1; i<=n_models; i++)); do
    while :; do
      echo ""
      echo "Enter information of model #$i."
      TYP[$i]="$(ask_choice "Nucleic acid type" "A-DNA,B-DNA,A-RNA")"
      read -r -p "Sequence (one strand of duplex, 5'→3'): " seq_in
      SEQ[$i]="$seq_in"
      PHOS[$i]="$(ask_choice "Do you want to keep or remove the 5'-terminal phosphate group?" "Keep,Remove")"
      NUM[$i]="$(ask_num "How many copies of the model to be searched in molecular replacement")"
      echo ""
      echo "Confirm model #$i:"
      echo "-TYPE$i ${TYP[$i]}"
      echo "-SEQ$i ${SEQ[$i]}"
      echo "-5PHOS$i ${PHOS[$i]}"
      echo "-NUM$i ${NUM[$i]}"
      if ask_yesno "Is this correct?"; then
        break
      else
        echo "Let's re-enter model #$i."
      fi
    done
  done

  {
    for ((i=1; i<=n_models; i++)); do
      echo "-TYPE$i ${TYP[$i]}"
      echo "-SEQ$i ${SEQ[$i]}"
      echo "-5PHOS$i ${PHOS[$i]}"
      echo "-NUM$i ${NUM[$i]}"
      [[ $i -lt n_models ]] && echo ""
    done
  } > "$inp"

  echo ""
  echo "4MRNA-INP.txt created"
  cat "$inp"
  echo ""
  echo "Continuing…"
fi

norm_inp="$(mktemp "${work_root}/norm_inp.XXXXXX")"
perl -pe 's/\r\n?/\n/g; s/^\xEF\xBB\xBF//' "$inp" > "$norm_inp"

declare -a TYPE SEQ PHOS NUM AMOUNT
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  if [[ "$line" =~ ^-TYPE([1-3])\ ([A-Z-]+)$ ]]; then
    TYPE[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
  elif [[ "$line" =~ ^-SEQ([1-3])\ (.+)$ ]]; then
    SEQ[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
  elif [[ "$line" =~ ^-5PHOS([1-3])\ (Keep|Remove)$ ]]; then
    PHOS[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
  elif [[ "$line" =~ ^-NUM([1-3])\ (.+)$ ]]; then
    NUM[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
  elif [[ "$line" =~ ^-AMOUNT([1-3])\ (.+)$ ]]; then
    AMOUNT[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
  fi
done < "$norm_inp"

model_indices=()
for i in 1 2 3; do
  if [[ -n "${TYPE[$i]:-}" && -n "${SEQ[$i]:-}" && -n "${PHOS[$i]:-}" && -n "${NUM[$i]:-}" ]]; then
    model_indices+=("$i")
  fi
done

n_models="${#model_indices[@]}"
[[ $n_models -ge 1 && $n_models -le 3 ]] || abort "Unsupported number of models (only 1–3 are supported)"

payload='['
for idx in "${model_indices[@]}"; do
  t="${TYPE[$idx]}"
  s="${SEQ[$idx]}"
  n="${NUM[$idx]}"
  s_esc=$(printf '%s' "$s" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
  t_esc=$(printf '%s' "$t" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
  n_esc=$(printf '%s' "$n" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
  payload="${payload}{\"index\": ${idx}, \"type\": ${t_esc}, \"sequence\": ${s_esc}, \"num\": ${n_esc}},"
done
payload="${payload%,}]"

mw_result_json="$(
  PAYLOAD="$payload" python3 - <<'PY'
import os, json, re, math

def parse_num(value) -> float:
    try:
        x = float(str(value).strip())
    except Exception:
        raise ValueError(f"Invalid NUM value: {value!r}")
    if not math.isfinite(x):
        raise ValueError(f"Invalid NUM value: {value!r}")
    return x

def normalize_num(value) -> int:
    x = parse_num(value)
    return max(1, math.floor(x))

def scale_mw_by_raw_num(mw: float, value) -> float:
    x = parse_num(value)
    if 0 < x < 1:
        return round(mw * x, 2)
    return mw

def get_complement(seq: str, na_type: str) -> str:
    is_rna = (na_type == 'A-RNA')
    map_dna = {'A':'T','T':'A','G':'C','C':'G'}
    map_rna = {'A':'U','U':'A','G':'C','C':'G'}
    m = map_rna if is_rna else map_dna
    seq = seq.upper().replace(' ','')
    return ''.join(m.get(b,b) for b in seq)

def calculate_mw(seq: str, na_type: str) -> float:
    is_rna = (na_type == 'A-RNA')
    seq = re.sub(r'[^ATGCU]', '', seq.upper())
    counts = {b:0 for b in ('G','A','C','T','U')}
    for b in seq:
        if b in counts:
            counts[b] += 1
    total = counts['G'] + counts['A'] + counts['C'] + (counts['U'] if is_rna else counts['T'])
    mw = (
        counts['G'] * (363.22 if is_rna else 347.22) +
        counts['A'] * (347.22 if is_rna else 331.22) +
        counts['C'] * (323.20 if is_rna else 307.20) +
        (counts['U'] if is_rna else counts['T']) * (324.18 if is_rna else 322.21)
    )
    mw -= 18 * (total - 1) + 78.97

    comp = get_complement(seq, na_type)
    c2 = {b:0 for b in ('G','A','C','T','U')}
    for b in comp:
        if b in c2:
            c2[b] += 1
    total2 = c2['G'] + c2['A'] + c2['C'] + (c2['U'] if is_rna else c2['T'])
    mw2 = (
        c2['G'] * (363.22 if is_rna else 347.22) +
        c2['A'] * (347.22 if is_rna else 331.22) +
        c2['C'] * (323.20 if is_rna else 307.20) +
        (c2['U'] if is_rna else c2['T']) * (324.18 if is_rna else 322.21)
    )
    mw2 -= 18 * (total2 - 1) + 78.97
    return round(mw + mw2, 2)

data = json.loads(os.environ['PAYLOAD'])
out = []
for d in sorted(data, key=lambda x: x["index"]):
    t = d["type"]
    seq_raw = d["sequence"]
    if t == 'A-RNA':
        seq = ''.join(c for c in seq_raw.upper() if c in 'AUGC')
    else:
        seq = ''.join(c for c in seq_raw.upper() if c in 'ATGC')
    mw = calculate_mw(seq, t)
    out.append({
        "index": d["index"],
        "type": t,
        "sequence": seq,
        "num": normalize_num(d["num"]),
        "mw": scale_mw_by_raw_num(mw, d["num"])
    })
print(json.dumps(out))
PY
)"

declare -a MW_ARR=()
while IFS= read -r row; do
  append_array_item "${#MW_ARR[@]}" "$row"
done < <(
  PAYLOAD="$mw_result_json" python3 - <<'PY'
import os, json
for x in json.loads(os.environ['PAYLOAD']):
    print(f'{x["index"]}\t{x["type"]}\t{x["sequence"]}\t{x["num"]}\t{x["mw"]}')
PY
)

declare -a TYPE2 SEQ2 NUM2 MW
for row in "${MW_ARR[@]}"; do
  IFS=$'\t' read -r idx t s n mw <<< "$row"
  TYPE2[$idx]="$t"
  SEQ2[$idx]="$s"
  NUM2[$idx]="$n"
  MW[$idx]="$mw"
done

echo "Detected model types: $n_models"
for i in "${model_indices[@]}"; do
  echo "  Model0$i: TYPE=${TYPE2[$i]}  SEQ=${SEQ2[$i]}  5PHOS=${PHOS[$i]}  NUM=${NUM2[$i]}  MW=${MW[$i]}"
done

declare -a AMOUNT2
echo "" >&2
for i in "${model_indices[@]}"; do
  AMOUNT2[$i]="$(ask_model_amount "$i" "${TYPE2[$i]}" "${SEQ2[$i]}" "${AMOUNT[$i]:-}")"
done

amount_args=()
for i in "${model_indices[@]}"; do
  amount_args+=("$i:${AMOUNT2[$i]}")
done
python3 - "$inp" "${amount_args[@]}" <<'PY_SAVE_AMOUNT'
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

path = Path(sys.argv[1])
amounts = dict(item.split(":", 1) for item in sys.argv[2:])
original = path.read_text(encoding="utf-8-sig")
seen = set()
lines = []
for line in original.splitlines():
    match = re.match(r"^-AMOUNT([1-3])(?:\s|$)", line)
    if match and match.group(1) in amounts:
        index = match.group(1)
        if index not in seen:
            lines.append(f"-AMOUNT{index} {amounts[index]}")
            seen.add(index)
    else:
        lines.append(line)
for index, amount in amounts.items():
    if index not in seen:
        position = next((i + 1 for i, line in enumerate(lines)
                         if re.match(rf"^-NUM{index}\s", line)), len(lines))
        lines.insert(position, f"-AMOUNT{index} {amount}")
updated = "\n".join(lines) + "\n"
if updated != original:
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", newline="\n",
                                     dir=path.parent, prefix=path.name + ".", delete=False) as temporary:
        temporary.write(updated)
        temporary_path = Path(temporary.name)
    shutil.copymode(path, temporary_path)
    os.replace(temporary_path, path)
PY_SAVE_AMOUNT

mkdir -p "$bg_dir"
mkdir -p "$checkpoint_scripts_dir"

declare -a FILES_TO_GET
if [[ "$n_models" == "1" ]]; then
  FILES_TO_GET=(
    "$L_MB_1_URL|01.Shell-CreatingModels-1st.sh"
    "$L1_01_1_URL|02.Shell-MR-1model-Model01-1st.sh"
    "$L_MB_2_URL|03.Shell-CreatingModels-2nd.sh"
    "$L1_01_2_URL|04.Shell-MR-1model-Model01-2nd.sh"
  )
elif [[ "$n_models" == "2" ]]; then
  FILES_TO_GET=(
    "$L_MB_1_URL|01.Shell-CreatingModels-1st.sh"
    "$L2_01_1_URL|02.Shell-MR-2model-Model01-1st.sh"
    "$L_MB_2_URL|03.Shell-CreatingModels-2nd.sh"
    "$L2_01_2_URL|04.Shell-MR-2model-Model01-2nd.sh"
    "$L2_02_1_URL|05.Shell-MR-2model-Model02-1st.sh"
    "$L_MB_2_URL|06.Shell-CreatingModels-2nd.sh"
    "$L2_02_2_URL|07.Shell-MR-2model-Model02-2nd.sh"
  )
else
  FILES_TO_GET=(
    "$L_MB_1_URL|01.Shell-CreatingModels-1st.sh"
    "$L3_01_1_URL|02.Shell-MR-3model-Model01-1st.sh"
    "$L_MB_2_URL|03.Shell-CreatingModels-2nd.sh"
    "$L3_01_2_URL|04.Shell-MR-3model-Model01-2nd.sh"
    "$L3_02_1_URL|05.Shell-MR-3model-Model02-1st.sh"
    "$L_MB_2_URL|06.Shell-CreatingModels-2nd.sh"
    "$L3_02_2_URL|07.Shell-MR-3model-Model02-2nd.sh"
    "$L3_03_1_URL|08.Shell-MR-3model-Model03-1st.sh"
    "$L_MB_2_URL|09.Shell-CreatingModels-2nd.sh"
    "$L3_03_2_URL|10.Shell-MR-3model-Model03-2nd.sh"
  )
fi

declare -a newly_downloaded=()

for spec in "${FILES_TO_GET[@]}"; do
  url="${spec%%|*}"
  out="${spec##*|}"
  existing="${final_bg_dir}/${out}"

  if [[ -f "$existing" ]]; then
    echo "[EXISTS] $out already exists. Skipping download and update."
  else
    echo "Downloading: $out -> $bg_dir/$out"
    curl_get "$url" "$bg_dir/$out"
    mark_newly_downloaded "$out"
  fi
done

if [[ -f "$min_params_out" ]]; then
  echo "[EXISTS] min.params already exists. Skipping download."
else
  echo "Downloading: min.params -> $min_params_out"
  curl_get "$MIN_PARAMS_URL" "$min_params_out"
fi

linux_parent="$here"

create_model01_script="$bg_dir/01.Shell-CreatingModels-1st.sh"

if was_newly_downloaded "01.Shell-CreatingModels-1st.sh"; then

  cp -p "$create_model01_script" "${work_root}/$(basename "$create_model01_script").bak"
  replace_assignment "num_models" "$n_models" "$create_model01_script"

  models_tmp="$(mktemp "${work_root}/models.XXXXXX")"
  {
    echo "models=("
    for i in "${model_indices[@]}"; do
      seq="${SEQ2[$i]}"
      na="${TYPE2[$i]}"
      phosphate_action="${PHOS[$i]}"
      if grep -q '^# AMOUNT controls model selection independently of execution mode.' "$create_model01_script"; then
        echo "  \"${i}|\${parent_directory}/Model0${i}-1|${seq}|${na}|${phosphate_action}|${AMOUNT2[$i]}\""
      else
        [[ "${AMOUNT2[$i]}" == "Full" ]] ||
          abort "The downloaded creator does not support AMOUNT Lite. Update Codes/Shell-CreatingModels-1st.sh in the source repository or use the revised creator."
        echo "  \"${i}|\${parent_directory}/Model0${i}-1|${seq}|${na}|${phosphate_action}\""
      fi
    done
    echo ")"
  } > "$models_tmp"

  awk -v repl_file="$models_tmp" '
  BEGIN {
    in_models = 0
    replaced = 0
  }
  {
    if (!replaced && $0 ~ /^models=\($/) {
      while ((getline line < repl_file) > 0) print line
      close(repl_file)
      in_models = 1
      replaced = 1
      next
    }
    if (in_models) {
      if ($0 ~ /^\)$/) {
        in_models = 0
      }
      next
    }
    print
  }
  ' "$create_model01_script" > "${create_model01_script}.tmp"

  mv "${create_model01_script}.tmp" "$create_model01_script"
  rm -f "$models_tmp"

  chmod +x "$create_model01_script"
  echo "Updated $create_model01_script"
fi

update_shell_2nd() {
  local fname="$1"
  local model_idx="$2"
  local base_name

  [[ -f "$fname" ]] || return 0

  base_name="$(basename "$fname")"
  was_newly_downloaded "$base_name" || return 0

  local dir_add="${linux_parent}/Model0${model_idx}-2"
  local na="${TYPE2[$model_idx]}"
  local phosphate_action="${PHOS[$model_idx]}"

  cp -p "$fname" "${work_root}/$(basename "$fname").bak"

  replace_assignment "directory" "$(shell_quote "$dir_add")" "$fname"
  replace_assignment "na_type" "$(shell_quote "$na")" "$fname"
  replace_assignment "phosphate_action" "$(shell_quote "$phosphate_action")" "$fname"

  chmod +x "$fname"
  echo "Updated $fname"
}

[[ "$n_models" -ge 1 ]] && update_shell_2nd "$bg_dir/03.Shell-CreatingModels-2nd.sh" "1"
[[ "$n_models" -ge 2 ]] && update_shell_2nd "$bg_dir/06.Shell-CreatingModels-2nd.sh" "2"
[[ "$n_models" -ge 3 ]] && update_shell_2nd "$bg_dir/09.Shell-CreatingModels-2nd.sh" "3"

append_chainA_filter_for_model_dir() {
  local fname="$1"
  local model_dir="$2"
  local base_name

  [[ -f "$fname" ]] || return 0

  base_name="$(basename "$fname")"
  was_newly_downloaded "$base_name" || return 0

  cat >> "$fname" <<EOF

for pdb in "\${parent_directory}/${model_dir}"/*.pdb; do
  awk 'substr(\$0,22,1)=="A" || substr(\$0,1,4)!="ATOM"' "\$pdb" > "\${pdb}.tmp"
  mv "\${pdb}.tmp" "\$pdb"
done
EOF

  chmod +x "$fname"
  echo "Added chain-A filter to $fname for ${model_dir}"
}

append_chainA_filter_for_directory_var() {
  local fname="$1"
  local base_name

  [[ -f "$fname" ]] || return 0

  base_name="$(basename "$fname")"
  was_newly_downloaded "$base_name" || return 0

  cat >> "$fname" <<'EOF'

for pdb in "${directory}"/*.pdb; do
  awk 'substr($0,22,1)=="A" || substr($0,1,4)!="ATOM"' "$pdb" > "${pdb}.tmp"
  mv "${pdb}.tmp" "$pdb"
done
EOF

  chmod +x "$fname"
  echo "Added chain-A filter to $fname using directory variable"
}

num_less_than_one() {
  local value="$1"

  python3 - "$value" <<'PYCHECK'
import sys, math
try:
    x = float(str(sys.argv[1]).strip())
    if not math.isfinite(x):
        raise ValueError
except Exception:
    sys.exit(1)
sys.exit(0 if x < 1 else 1)
PYCHECK
}

for i in "${model_indices[@]}"; do
  raw_num="${NUM[$i]}"

  if num_less_than_one "$raw_num"; then
    append_chainA_filter_for_model_dir "$create_model01_script" "Model0${i}-1"

    case "$i" in
      1) append_chainA_filter_for_directory_var "$bg_dir/03.Shell-CreatingModels-2nd.sh" ;;
      2) append_chainA_filter_for_directory_var "$bg_dir/06.Shell-CreatingModels-2nd.sh" ;;
      3) append_chainA_filter_for_directory_var "$bg_dir/09.Shell-CreatingModels-2nd.sh" ;;
    esac
  fi
done

for shf in "$bg_dir"/*.sh; do
  [[ -f "$shf" ]] || continue

  shf_base="$(basename "$shf")"
  was_newly_downloaded "$shf_base" || continue

  cp -p "$shf" "${work_root}/$(basename "$shf").bak"

  replace_assignment "parent_directory" "$(shell_quote "$linux_parent")" "$shf"

  for i in "${model_indices[@]}"; do
    mw="${MW[$i]}"
    num="${NUM2[$i]}"

    perl -0777 -pe \
      's/(SEARch ENSEmble \${base_name_'"$i"'} NUM )\d+/${1}'"$num"'/g' \
      "$shf" > "${shf}.tmp"
    mv "${shf}.tmp" "$shf"
  done

  mw_args=()
  for i in "${model_indices[@]}"; do
    mw_args+=("$i:${MW[$i]}")
  done

  python3 - "$shf" "${mw_args[@]}" <<'PY_SYNC_COMPOSITION'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
mw_by_index = {}
for item in sys.argv[2:]:
    idx, mw = item.split(':', 1)
    mw_by_index[idx] = mw

lines = path.read_text().splitlines(keepends=True)

search_items = []
for line in lines:
    m = re.search(
        r'SEARch\s+ENSEmble\s+\$\{base_name_(\d+)\}\s+NUM\s+(\d+)',
        line,
    )
    if m:
        search_items.append((m.group(1), m.group(2)))

composition_re = re.compile(
    r'(COMPosition\s+NUCLeic\s+MW\s+)'
    r'\d+(?:\.\d+)?'
    r'(\s+NUM\s+)'
    r'\d+'
)

composition_count = sum(1 for line in lines if composition_re.search(line))

if search_items and composition_count != len(search_items):
    raise SystemExit(
        f"COMPosition NUCLeic lines ({composition_count}) and "
        f"SEARch ENSEmble lines ({len(search_items)}) differ in {path}"
    )

idx = 0
new_lines = []
for line in lines:
    if composition_re.search(line):
        model_idx, num = search_items[idx]
        mw = mw_by_index.get(model_idx)
        if mw is None:
            raise SystemExit(f"MW for base_name_{model_idx} is not defined in {path}")
        line = composition_re.sub(r'\g<1>' + mw + r'\g<2>' + num, line, count=1)
        idx += 1
    new_lines.append(line)

path.write_text(''.join(new_lines))
PY_SYNC_COMPOSITION

  chmod +x "$shf"
  echo "Updated $shf"
done

sync_bg_dir_to_final

first_script="$final_bg_dir/01.Shell-CreatingModels-1st.sh"
if grep -q '^# AMOUNT controls model selection independently of execution mode.' "$first_script"; then
  python3 - "$first_script" "$here" "${amount_args[@]}" <<'PY_UPDATE_AMOUNT'
import json
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
parent = Path(sys.argv[2])
amounts = dict(item.split(":", 1) for item in sys.argv[3:])
source = path.read_text(encoding="utf-8")
block = re.search(r"(?m)^models=\(\n(.*?)^\)", source, re.S)
if not block:
    raise SystemExit("Cannot find model settings in the cached model-creation script")
row_pattern = re.compile(r'(?m)^(\s*"([1-3])\|[^"\n]+)("\s*)$')
seen = set()

def update_row(match):
    index = match.group(2)
    if index not in amounts:
        return match.group(0)
    seen.add(index)
    amount = amounts[index]
    manifest = parent / f"Model0{index}-1/Lite-Par-Backup/selection.json"
    if amount.startswith("Lite ") and manifest.exists():
        saved = json.loads(manifest.read_text(encoding="utf-8"))
        if saved.get("request") is not None and saved["request"] != amount[5:]:
            raise SystemExit(f"Model0{index}: AMOUNT differs from the saved selection; use a fresh working directory")
    fields = match.group(1).split("|")
    fields = fields[:5] + [amount]
    return "|".join(fields) + match.group(3)

updated = row_pattern.sub(update_row, block.group(1))
if seen != set(amounts):
    raise SystemExit("Input models differ from the cached model settings; use a fresh working directory")
source = source[:block.start(1)] + updated + source[block.end(1):]
path.write_text(source, encoding="utf-8", newline="\n")
PY_UPDATE_AMOUNT
fi

choose_execution_mode

for i in "${model_indices[@]}"; do
  if [[ "${AMOUNT2[$i]}" == "Full" ]]; then
    [[ ! -e "$here/Model0${i}-1/Lite-Par-Backup" ]] ||
      abort "Model0${i}-1 contains a lite selection or backup. Keep its Lite amount, or use a fresh working directory for Full."
  fi
done

for i in "${model_indices[@]}"; do
  [[ "${AMOUNT2[$i]}" == "Full" ]] && continue
  first_script="$final_bg_dir/01.Shell-CreatingModels-1st.sh"
  if ! grep -q '^# AMOUNT controls model selection independently of execution mode.' "$first_script"; then
    abort "The cached model-creation script does not support AMOUNT. Use a fresh working directory, or update $first_script from Codes/Shell-CreatingModels-1st.sh while preserving your model settings."
  fi
  if [[ -f "$(script_done_file "01.Shell-CreatingModels-1st.sh")" ]]; then
    [[ -f "$here/Model0${i}-1/Lite-Par-Backup/selection.json" ]] ||
      abort "Model0${i}-1 was completed without lite selection. Use a fresh working directory to change AMOUNT."
  fi
done

if [[ "$run_mode" == "customize" ]]; then
  write_checkpoint_value "$execution_mode_checkpoint" "$run_mode"
  echo "Customize mode was selected."
  echo "Scripts have been prepared in: $final_bg_dir"
  echo "You can edit each downloaded code. Please run the edited scripts with the bash command in the numerical order."
  exit 0
fi

echo "=== Start running (in $final_bg_dir) ==="
declare -a ordered=()
for ordered_path in "$final_bg_dir"/[0-9][0-9].*.sh; do
  [[ -f "$ordered_path" ]] || continue
  ordered[${#ordered[@]}]="$(basename "$ordered_path")"
done
write_checkpoint_value "$execution_mode_checkpoint" "$run_mode"

for f in "${ordered[@]}"; do
  run_ordered_script "$f"
done
echo "=== All finished ==="
