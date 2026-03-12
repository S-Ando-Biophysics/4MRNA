#!/usr/bin/env bash

set -euo pipefail
if ! [ -t 0 ] && [ -r /dev/tty ]; then
  exec </dev/tty
fi
abort() { echo "Error: $*" >&2; exit 1; }

here="$(pwd)"
inp="${here}/4MRNA-INP.txt"
bg_dir="${here}/4MRNA-Background-Codes"

PY1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Python-CreatingModels-1st.py"
PY2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Python-CreatingModels-2nd.py"
L1_01_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-1model-Model01-1st.sh"
L1_01_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-1model-Model01-2nd.sh"
L2_01_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-2model-Model01-1st.sh"
L2_01_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-2model-Model01-2nd.sh"
L2_02_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-2model-Model02-1st.sh"
L2_02_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-2model-Model02-2nd.sh"
L3_01_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-3model-Model01-1st.sh"
L3_01_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-3model-Model01-2nd.sh"
L3_02_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-3model-Model02-1st.sh"
L3_02_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-3model-Model02-2nd.sh"
L3_03_1_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-3model-Model03-1st.sh"
L3_03_2_URL="https://raw.githubusercontent.com/S-Ando-Biophysics/4MRNA/main/Codes/Linux-MR-3model-Model03-2nd.sh"

curl_get() { curl -fsSL "$1" -o "$2" || abort "Failed to download: $1"; }

ask_choice() {
  local q="$1" choices="$2" ans
  IFS=',' read -r -a arr <<<"$choices"
  while :; do
    read -r -p "$q [$choices]: " ans
    for c in "${arr[@]}"; do
      [[ "$ans" == "$c" ]] && echo "$ans" && return 0
    done
    echo "Invalid input. Try again."
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

ask_int() {
  local ans
  while :; do
    read -r -p "$1: " ans
    if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans > 0 )); then
      echo "$ans"; return 0
    fi
    echo "Enter a positive integer."
  done
}

if [[ ! -f "$inp" ]]; then
  echo "Input file '4MRNA-INP.txt' not found."
  echo "Choose one of the following:"
  echo "  1) I will prepare it myself. (A template will be provided.)"
  echo "  2) I will answer questions here to generate it now."
  read -r -p "Select [1/2]: " choice
  if [[ "$choice" == "1" ]]; then
    cat > "$inp" <<'TEMPLATE'
-TYPE1 A-DNA
-SEQ1 ACGTACGTACGT
-NUM1 1

-TYPE2 B-DNA
-SEQ2 ACGTACGT
-NUM2 1

-TYPE3 A-RNA
-SEQ3 ACGU
-NUM3 1
TEMPLATE
    echo "Template written to 4MRNA-INP.txt"
    echo "Edit the file and run again:  bash 4MRNA.sh"
    exit 0
  elif [[ "$choice" == "2" ]]; then
    n_models="$(ask_choice "How many models for molecular replacement?" "1,2,3")"
    declare -A TYP SEQ NUM
    for ((i=1; i<=n_models; i++)); do
      while :; do
        echo ""
        echo "Enter information of model #$i."
        TYP[$i]="$(ask_choice "Nucleic acid type" "A-DNA,B-DNA,A-RNA")"
        read -r -p "Sequence (one strand of duplex, 5'→3'): " seq_in
        SEQ[$i]="$seq_in"
        NUM[$i]="$(ask_int "How many copies of the model to be searched in molecular replacement")"
        echo ""
        echo "Confirm model #$i:"
        echo "-TYPE$i ${TYP[$i]}"
        echo "-SEQ$i ${SEQ[$i]}"
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
        echo "-NUM$i ${NUM[$i]}"
        [[ $i -lt n_models ]] && echo ""
      done
    } > "$inp"
    echo ""
    echo "4MRNA-INP.txt created"
    cat "$inp"
    echo ""
    echo "Continuing…"
  else
    abort "Invalid selection."
  fi
fi

norm_inp="$(mktemp)"
trap 'rm -f "$norm_inp"' EXIT
perl -pe 's/\r\n?/\n/g; s/^\xEF\xBB\xBF//' "$inp" > "$norm_inp"

declare -A TYPE SEQ NUM
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  if [[ "$line" =~ ^-TYPE([1-3])\ ([A-Z-]+)$ ]]; then
    TYPE[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
  elif [[ "$line" =~ ^-SEQ([1-3])\ (.+)$ ]]; then
    SEQ[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
  elif [[ "$line" =~ ^-NUM([1-3])\ ([0-9]+)$ ]]; then
    NUM[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
  fi
done < "$norm_inp"

model_indices=()
for i in 1 2 3; do
  if [[ -n "${TYPE[$i]:-}" && -n "${SEQ[$i]:-}" && -n "${NUM[$i]:-}" ]]; then
    model_indices+=("$i")
  fi
done
n_models="${#model_indices[@]}"
[[ $n_models -ge 1 && $n_models -le 3 ]] || abort "Unsupported number of models (only 1–3 are supported)"

payload='['
for idx in "${model_indices[@]}"; do
  t="${TYPE[$idx]}"; s="${SEQ[$idx]}"; n="${NUM[$idx]}"
  s_esc=$(printf '%s' "$s" | python -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
  t_esc=$(printf '%s' "$t" | python -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
  n_esc=$(printf '%s' "$n" | python -c 'import sys,json; print(json.dumps(sys.stdin.read()))')
  payload="${payload}{\"index\": ${idx}, \"type\": ${t_esc}, \"sequence\": ${s_esc}, \"num\": ${n_esc}},"
done
payload="${payload%,}]"

mw_result_json="$(
  PAYLOAD="$payload" python - <<'PY'
import os, json, re

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
        if b in counts: counts[b]+=1
    total = counts['G']+counts['A']+counts['C']+(counts['U'] if is_rna else counts['T'])
    mw = (counts['G']*(363.22 if is_rna else 347.22) +
          counts['A']*(347.22 if is_rna else 331.22) +
          counts['C']*(323.20 if is_rna else 307.20) +
          (counts['U'] if is_rna else counts['T'])*(324.18 if is_rna else 322.21))
    mw -= 18*(total-1) + 78.97

    comp = get_complement(seq, na_type)
    c2 = {b:0 for b in ('G','A','C','T','U')}
    for b in comp:
        if b in c2: c2[b]+=1
    total2 = c2['G']+c2['A']+c2['C']+(c2['U'] if is_rna else c2['T'])
    mw2 = (c2['G']*(363.22 if is_rna else 347.22) +
           c2['A']*(347.22 if is_rna else 331.22) +
           c2['C']*(323.20 if is_rna else 307.20) +
           (c2['U'] if is_rna else c2['T'])*(324.18 if is_rna else 322.21))
    mw2 -= 18*(total2-1) + 78.97
    return round(mw+mw2, 2)

data = json.loads(os.environ['PAYLOAD'])
out = []
for d in sorted(data, key=lambda x: x["index"]):
    t = d["type"]; seq_raw = d["sequence"]
    if t == 'A-RNA':
        seq = ''.join(c for c in seq_raw.upper() if c in 'AUGC')
    else:
        seq = ''.join(c for c in seq_raw.upper() if c in 'ATGC')
    out.append({"index": d["index"], "type": t, "sequence": seq,
                "num": int(d["num"]), "mw": calculate_mw(seq, t)})
print(json.dumps(out))
PY
)"

readarray -t MW_ARR < <(
  PAYLOAD="$mw_result_json" python - <<'PY'
import os, json
for x in json.loads(os.environ['PAYLOAD']):
    print(f'{x["index"]}\t{x["type"]}\t{x["sequence"]}\t{x["num"]}\t{x["mw"]}')
PY
)

declare -A TYPE2 SEQ2 NUM2 MW
for row in "${MW_ARR[@]}"; do
  IFS=$'\t' read -r idx t s n mw <<<"$row"
  TYPE2[$idx]="$t"; SEQ2[$idx]="$s"; NUM2[$idx]="$n"; MW[$idx]="$mw"
done

echo "Detected model types: $n_models"
for i in "${model_indices[@]}"; do
  echo "  Model0$i: TYPE=${TYPE2[$i]}  SEQ=${SEQ2[$i]}  NUM=${NUM2[$i]}  MW=${MW[$i]}"
done

mkdir -p "$bg_dir"

declare -a FILES_TO_GET
if   [[ "$n_models" == "1" ]]; then
  FILES_TO_GET=(
    "$PY1_URL|01.Python-CreatingModels-1st.py"
    "$L1_01_1_URL|02.Linux-MR-1model-Model01-1st.sh"
    "$PY2_URL|03.Python-CreatingModels-2nd.py"
    "$L1_01_2_URL|04.Linux-MR-1model-Model01-2nd.sh"
  )
elif [[ "$n_models" == "2" ]]; then
  FILES_TO_GET=(
    "$PY1_URL|01.Python-CreatingModels-1st.py"
    "$L2_01_1_URL|02.Linux-MR-2model-Model01-1st.sh"
    "$PY2_URL|03.Python-CreatingModels-2nd.py"
    "$L2_01_2_URL|04.Linux-MR-2model-Model01-2nd.sh"
    "$L2_02_1_URL|05.Linux-MR-2model-Model02-1st.sh"
    "$PY2_URL|06.Python-CreatingModels-2nd.py"
    "$L2_02_2_URL|07.Linux-MR-2model-Model02-2nd.sh"
  )
else
  FILES_TO_GET=(
    "$PY1_URL|01.Python-CreatingModels-1st.py"
    "$L3_01_1_URL|02.Linux-MR-3model-Model01-1st.sh"
    "$PY2_URL|03.Python-CreatingModels-2nd.py"
    "$L3_01_2_URL|04.Linux-MR-3model-Model01-2nd.sh"
    "$L3_02_1_URL|05.Linux-MR-3model-Model02-1st.sh"
    "$PY2_URL|06.Python-CreatingModels-2nd.py"
    "$L3_02_2_URL|07.Linux-MR-3model-Model02-2nd.sh"
    "$L3_03_1_URL|08.Linux-MR-3model-Model03-1st.sh"
    "$PY2_URL|09.Python-CreatingModels-2nd.py"
    "$L3_03_2_URL|10.Linux-MR-3model-Model03-2nd.sh"
  )
fi

for spec in "${FILES_TO_GET[@]}"; do
  url="${spec%%|*}"; out="${spec##*|}"
  echo "Downloading: $out -> $bg_dir/$out"
  curl_get "$url" "$bg_dir/$out"
done

linux_parent="$here"
python_dir="$here"

py1="$bg_dir/01.Python-CreatingModels-1st.py"
[[ -f "$py1" ]] || abort "$py1 not found"

python - <<PY
import re, os
parent_directory = r"""$python_dir"""
num_models = $n_models
fn = "$py1"
s = open(fn,"r",encoding="utf-8").read()
s = re.sub(r'^parent_directory\s*=.*$', f'parent_directory = r"{parent_directory}"', s, flags=re.M)
s = re.sub(r'^num_models\s*=.*$', f'num_models = {num_models}', s, flags=re.M)
open(fn,"w",encoding="utf-8").write(s)
print(f"Updated {fn}")
PY

seq_map="{"
na_map="{"
for i in "${model_indices[@]}"; do
  seq_map+=" ${i}: \"${SEQ2[$i]}\","
  na_map+=" ${i}: \"${TYPE2[$i]}\","
done
seq_map="${seq_map%,}}"
na_map="${na_map%,}}"

model_indices_csv=$(IFS=,; echo "${model_indices[*]}")
python - <<PY
import re, os
fn = "$py1"
parent_directory = r"""$python_dir"""
model_indices = [${model_indices_csv}]
seq_map = $seq_map
na_map  = $na_map
s = open(fn,"r",encoding="utf-8").read()
def repl_block(s, idx, seq, na):
    pat = rf'{idx}:\s*\{{\s*"directory":\s*os\.path\.join\([^}}]*?"Model0{idx}-1"\),[\s\S]*?"sequence":\s*".*?",[\s\S]*?"na_type":\s*".*?"\s*\}}'
    rep = (f'{idx}: {{"directory": os.path.join(parent_directory, "Model0{idx}-1"),\n'
           f'        "sequence": "{seq}",\n'
           f'        "na_type": "{na}"}}')
    return re.sub(pat, rep, s)
for idx in model_indices:
    s = repl_block(s, idx, seq_map[idx], na_map[idx])
open(fn,"w",encoding="utf-8").write(s)
print(f"Filled model_info in {fn}")
PY

update_py2() {
  local fname="$1" model_idx="$2"
  [[ -f "$fname" ]] || return 0
  local dir_add="${python_dir}/Model0${model_idx}-2"
  local na="${TYPE2[$model_idx]}"
  python - "$fname" "$dir_add" "$na" <<'PY'
import sys, re
fn, d, na = sys.argv[1:]
s = open(fn,"r",encoding="utf-8").read()
s = re.sub(r'^directory\s*=.*$', f'directory = r"{d}"', s, flags=re.M)
s = re.sub(r'^na_type\s*=.*$', f'na_type = "{na}"', s, flags=re.M)
open(fn,"w",encoding="utf-8").write(s)
print(f"Updated {fn}")
PY
}
[[ "$n_models" -ge 1 ]] && update_py2 "$bg_dir/03.Python-CreatingModels-2nd.py" "1"
[[ "$n_models" -ge 2 ]] && update_py2 "$bg_dir/06.Python-CreatingModels-2nd.py" "2"
[[ "$n_models" -ge 3 ]] && update_py2 "$bg_dir/09.Python-CreatingModels-2nd.py" "3"

for shf in "$bg_dir"/*.sh; do
  [[ -f "$shf" ]] || continue
  sed -E -i.bak 's|^parent_directory\s*=.*$|parent_directory="'"${linux_parent//\//\\/}"'"|g' "$shf"
  for i in "${model_indices[@]}"; do
    mw="${MW[$i]}"; num="${NUM2[$i]}"
    perl -0777 -pe 's/COMPosition NUCLeic MW\s+\d+(?:\.\d+)?\s+NUM\s+'"$i"'/COMPosition NUCLeic MW '"$mw"' NUM '"$num"'/g' -i "$shf"
    perl -0777 -pe 's/(SEARch ENSEmble \${base_name_'"$i"'} NUM )\d+/${1}'"$num"'/g' -i "$shf"
  done
  chmod +x "$shf"
  echo "Updated $shf"
done

echo "=== Start running (in $bg_dir) ==="
mapfile -t ordered < <(cd "$bg_dir" && ls -1 | grep -E '^[0-9]{2}\.' | sort -V)
for f in "${ordered[@]}"; do
  case "$f" in
    *.py) echo "[RUN] python $f"; (cd "$bg_dir"; python "$f") ;;
    *.sh) echo "[RUN] bash   $f"; (cd "$bg_dir"; bash "$f") ;;
    *)    : ;;
  esac
done
echo "=== All finished ==="
