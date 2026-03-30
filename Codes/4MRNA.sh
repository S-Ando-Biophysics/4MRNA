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

work_root="$(mktemp -d)"
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
      echo "$ans"
      return 0
    fi
    echo "Enter a positive integer."
  done
}

sync_bg_dir_to_final() {
  mkdir -p "$final_bg_dir"

  cp -af "$bg_dir"/. "$final_bg_dir"/

  find "$final_bg_dir" -maxdepth 1 -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
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
    n_models="$(ask_choice "The number of models for molecular replacement" "1,2,3")"
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
trap 'rm -f "$norm_inp"; cleanup' EXIT
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
  t="${TYPE[$idx]}"
  s="${SEQ[$idx]}"
  n="${NUM[$idx]}"
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
    out.append({
        "index": d["index"],
        "type": t,
        "sequence": seq,
        "num": int(d["num"]),
        "mw": calculate_mw(seq, t)
    })
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
  IFS=$'\t' read -r idx t s n mw <<< "$row"
  TYPE2[$idx]="$t"
  SEQ2[$idx]="$s"
  NUM2[$idx]="$n"
  MW[$idx]="$mw"
done

echo "Detected model types: $n_models"
for i in "${model_indices[@]}"; do
  echo "  Model0$i: TYPE=${TYPE2[$i]}  SEQ=${SEQ2[$i]}  NUM=${NUM2[$i]}  MW=${MW[$i]}"
done

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

for spec in "${FILES_TO_GET[@]}"; do
  url="${spec%%|*}"
  out="${spec##*|}"
  echo "Downloading: $out -> $bg_dir/$out"
  curl_get "$url" "$bg_dir/$out"
done

echo "Downloading: min.params -> $min_params_out"
curl_get "$MIN_PARAMS_URL" "$min_params_out"

linux_parent="$here"

create_model01_script="$bg_dir/01.Shell-CreatingModels-1st.sh"
[[ -f "$create_model01_script" ]] || abort "$create_model01_script not found"

sed -E -i.bak "s/^num_models=.*/num_models=$n_models/" "$create_model01_script"

models_tmp="$(mktemp)"
{
  echo "models=("
  for i in "${model_indices[@]}"; do
    seq="${SEQ2[$i]}"
    na="${TYPE2[$i]}"
    echo "  \"${i}|\${parent_directory}/Model0${i}-1|${seq}|${na}\""
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

update_shell_2nd() {
  local fname="$1"
  local model_idx="$2"

  [[ -f "$fname" ]] || return 0

  local dir_add="${linux_parent}/Model0${model_idx}-2"
  local na="${TYPE2[$model_idx]}"

  sed -E -i.bak \
    "s|^directory=.*|directory=\"${dir_add}\"|" \
    "$fname"

  sed -E -i \
    "s|^na_type=.*|na_type=\"${na}\"|" \
    "$fname"

  chmod +x "$fname"
  echo "Updated $fname"
}

[[ "$n_models" -ge 1 ]] && update_shell_2nd "$bg_dir/03.Shell-CreatingModels-2nd.sh" "1"
[[ "$n_models" -ge 2 ]] && update_shell_2nd "$bg_dir/06.Shell-CreatingModels-2nd.sh" "2"
[[ "$n_models" -ge 3 ]] && update_shell_2nd "$bg_dir/09.Shell-CreatingModels-2nd.sh" "3"

for shf in "$bg_dir"/*.sh; do
  [[ -f "$shf" ]] || continue

  sed -E -i.bak \
    's|^parent_directory\s*=.*$|parent_directory="'"${linux_parent//\//\\/}"'"|g' \
    "$shf"

  for i in "${model_indices[@]}"; do
    mw="${MW[$i]}"
    num="${NUM2[$i]}"

    perl -0777 -pe \
      's/COMPosition NUCLeic MW\s+\d+(?:\.\d+)?\s+NUM\s+'"$i"'/COMPosition NUCLeic MW '"$mw"' NUM '"$num"'/g' \
      -i "$shf"

    perl -0777 -pe \
      's/(SEARch ENSEmble \${base_name_'"$i"'} NUM )\d+/${1}'"$num"'/g' \
      -i "$shf"
  done

  chmod +x "$shf"
  echo "Updated $shf"
done

sync_bg_dir_to_final

run_mode="$(ask_choice "Please choose execution mode." "default,customize")"

if [[ "$run_mode" == "customize" ]]; then
  echo "Customize mode was selected."
  echo "Scripts have been prepared in: $final_bg_dir"
  echo "You can edit each downloaded code. Please run the edited scripts with the bash command in the numerical order."
  exit 0
fi

echo "=== Start running (in $final_bg_dir) ==="
mapfile -t ordered < <(
  cd "$final_bg_dir" &&
  find . -maxdepth 1 -type f -name '[0-9][0-9].*.sh' -printf '%f\n' | sort -V
)
for f in "${ordered[@]}"; do
  run_ordered_script "$f"
done
echo "=== All finished ==="