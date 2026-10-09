#!/usr/bin/env bash
set -euo pipefail

parent_directory="$(pwd)"

# ====================================================================================================
# User settings
# ====================================================================================================

# Number of models
# Please enter 1-3 basically.
num_models=1

# Information of models
# " ID | Directory | Sequence | Type of NA | 5'-terminal phosphate | AMOUNT "
# Please enter the sequence. Only the sequence of one strand of duplex is required.
# The complementary strand is processed automatically.
# Please enter the type of NA. Please choose from A-DNA, B-DNA, or A-RNA.
# Please choose Keep or Remove for the 5'-terminal phosphate group.
# AMOUNT is Full, Lite COUNT, or Lite PERCENT% (e.g. Lite 100 or Lite 10%).
models=(
  "1|${parent_directory}/Model01-1|||Keep|Full"
  "2|${parent_directory}/Model02-1|||Keep|Full"
  "3|${parent_directory}/Model03-1|||Keep|Full"
)

# ====================================================================================================

header_lines=4

ensure_dir() {
  mkdir -p "$1"
}

cleanup_analyze_files() {
  rm -f *.out *.dat *.r3d *.scr \
        stacking.pdb hstacking.pdb bestpairs.pdb hel_regions.pdb \
        auxiliary.par bp_helical.par cf_7methods.par
}

cleanup_rebuild_files() {
  rm -f Atomic*.pdb ref_frames.dat
}

checkpoint_dir_for_model() {
  local directory="$1"
  printf '%s/Checkpoints' "$directory"
}

checkpoint_file_after_par_generation() {
  local directory="$1"
  printf '%s/all_par_files_generated.done' "$(checkpoint_dir_for_model "$directory")"
}

mark_par_generation_done() {
  local directory="$1"
  local cpdir
  cpdir="$(checkpoint_dir_for_model "$directory")"
  mkdir -p "$cpdir"
  : > "$(checkpoint_file_after_par_generation "$directory")"
}

is_par_generation_done() {
  local directory="$1"
  [[ -f "$(checkpoint_file_after_par_generation "$directory")" ]]
}

same_sign_symmetric_generate() {

  local length="$1"
  local outfile="$2"
  local param_name="$3"
  shift 3
  local values=("$@")

  : > "$outfile"

  # Number of independent positions under the symmetry constraint.
  #
  # If the RNA/DNA sequence length is n:
  #
  #   n odd  : 3^((n-1)/2)
  #   n even : 3^(n/2)
  #
  # Since "length" here is the number of base-pair steps (n-1),
  # the number of independent positions is ceil(length/2).
  local independent_positions=$(( (length + 1) / 2 ))
  local value_count=${#values[@]}

  local total_combinations=1
  local calc_i

  for ((calc_i=0; calc_i<independent_positions; calc_i++)); do
    total_combinations=$((total_combinations * value_count))
  done

  local generated=0
  local next_report=5

  echo "${param_name}: generating ${total_combinations} parameter combinations..." >&2

  _rec_sym() {

    local pos="$1"
    shift

    local prefix=("$@")
    local half=$(( length / 2 ))
    local odd=$(( length % 2 ))

    local i
    local v
    local mid
    local percent

    if (( pos == half )); then

      if (( odd == 1 )); then

        for mid in "${values[@]}"; do

          local combo=("${prefix[@]}" "$mid")

          for ((i=${#prefix[@]}-1; i>=0; i--)); do
            combo+=("${prefix[i]}")
          done

          local IFS=,
          echo "${combo[*]}" >> "$outfile"

          generated=$((generated + 1))

          if (( total_combinations > 0 )); then

            percent=$((generated * 100 / total_combinations))

            if (( percent >= next_report || generated == total_combinations )); then

              echo "${param_name}: ${generated}/${total_combinations} parameter combinations generated (${percent}%)" >&2

              while (( next_report <= percent )); do
                next_report=$((next_report + 5))
              done

            fi
          fi
        done

      else

        local combo=("${prefix[@]}")

        for ((i=${#prefix[@]}-1; i>=0; i--)); do
          combo+=("${prefix[i]}")
        done

        local IFS=,
        echo "${combo[*]}" >> "$outfile"

        generated=$((generated + 1))

        if (( total_combinations > 0 )); then

          percent=$((generated * 100 / total_combinations))

          if (( percent >= next_report || generated == total_combinations )); then

            echo "${param_name}: ${generated}/${total_combinations} parameter combinations generated (${percent}%)" >&2

            while (( next_report <= percent )); do
              next_report=$((next_report + 5))
            done

          fi
        fi

      fi

      return
    fi

    for v in "${values[@]}"; do
      _rec_sym $((pos + 1)) "${prefix[@]}" "$v"
    done
  }

  _rec_sym 0

  echo "${param_name}: parameter combination generation completed." >&2
}

modify_bpstep_par() {

  local input_file="$1"
  local output_file="$2"
  local target_col="$3"
  local adjustments_csv="$4"

  awk -v hdr="$header_lines" -v col="$target_col" -v adj_csv="$adjustments_csv" '
    BEGIN{
      n = split(adj_csv, adj, ",")
      OFS=" "
    }
    NR<=hdr{print; next}
    {
      idx=NR-hdr
      if(idx<=n && NF>=col){
        val=$col+adj[idx]
        $col=sprintf("%.2f",val)
      }
      print
    }
  ' "$input_file" > "$output_file"
}

process_parameter() {

  local bpstep_file="$1"
  local output_dir="$2"
  local param_name="$3"
  local target_col="$4"
  shift 4
  local values=("$@")

  local n_data_lines
  n_data_lines=$(tail -n +"$((header_lines + 1))" "$bpstep_file" | wc -l)

  local combo_file="${output_dir}/.${param_name}_combos.tmp"

  # Generate parameter combinations.
  # Progress is reported to stderr inside same_sign_symmetric_generate().
  same_sign_symmetric_generate \
    "$n_data_lines" \
    "$combo_file" \
    "$param_name" \
    "${values[@]}"

  # Count the actual number of generated combinations.
  local total
  total=$(wc -l < "$combo_file")
  total=$(echo "$total" | tr -d '[:space:]')

  echo "${param_name}: generating ${total} parameter files..." >&2

  local idx=0
  local percent=0
  local next_report=5
  local out

  while IFS= read -r combo; do

    [[ -z "$combo" ]] && continue

    idx=$((idx + 1))

    out="${output_dir}/bp_step_${param_name}${idx}.par"

    modify_bpstep_par \
      "$bpstep_file" \
      "$out" \
      "$target_col" \
      "$combo"

    if (( total > 0 )); then

      percent=$((idx * 100 / total))

      if (( percent >= next_report || idx == total )); then

        echo "${param_name}: ${idx}/${total} parameter files generated (${percent}%)" >&2

        while (( next_report <= percent )); do
          next_report=$((next_report + 5))
        done

      fi
    fi

  done < "$combo_file"

  rm -f "$combo_file"

  echo "${param_name}: parameter file generation completed." >&2
  echo "$idx"
}

get_type_settings() {

  local na_type="$1"
  local sequence="$2"

  seq_processed=""
  fiber_args=()
  std_type=""
  out_folder=""
  file_prefix=""

  tilt_col=11
  roll_col=12
  twist_col=13

  tilt_values=()
  roll_values=()
  twist_values=()

  case "$na_type" in

    "A-DNA")
      seq_processed="${sequence//U/T}"
      fiber_args=(-a "-seq=${seq_processed}")
      std_type="ADNA"
      out_folder="3DNA-ADNA"
      file_prefix="3DNAAD"
      tilt_values=(-5.24 0 5.24)
      roll_values=(-10.24 0 10.24)
      twist_values=(-9.76 0 9.76)
    ;;

    "B-DNA")
      seq_processed="${sequence//U/T}"
      fiber_args=(-b "-seq=${seq_processed}")
      std_type="BDNA"
      out_folder="3DNA-BDNA"
      file_prefix="3DNABD"
      tilt_values=(-6.66 0 6.66)
      roll_values=(-10.82 0 10.82)
      twist_values=(-11.44 0 11.44)
    ;;

    "A-RNA")
      seq_processed="${sequence//T/U}"
      fiber_args=(-rna "-seq=${seq_processed}")
      std_type="RNA"
      out_folder="3DNA-ARNA"
      file_prefix="3DNAAR"
      tilt_values=(-5.24 0 5.24)
      roll_values=(-10.24 0 10.24)
      twist_values=(-9.76 0 9.76)
    ;;

  esac
}

build_fiber_and_analyze() {

  local directory="$1"

  (
    cd "$directory"

    fiber "${fiber_args[@]}" fiber_model.pdb

    echo "fiber_model.pdb generated"

    echo "Running find_pair and analyze..."

    find_pair fiber_model.pdb | analyze

    cleanup_analyze_files

    if [[ ! -f bp_step.par ]]; then
      echo "bp_step.par not generated"
      return 1
    fi

    echo "3DNA analysis completed. bp_step.par generated."
  )
}

# AMOUNT controls model selection independently of execution mode.
select_lite_pars() {
  local amount_selection="${2:-Full}"
  if [[ "$amount_selection" == "Full" ]]; then
    if [[ -e "$1/Lite-Par-Backup" ]]; then
      echo "Cannot use Full with an existing Lite backup. Use a fresh working directory." >&2
      return 1
    fi
    return 0
  fi

  python3 - "$1" "$out_folder" "$file_prefix" "$amount_selection" <<'PY_LITE'
import hashlib
import json
import os
import re
import secrets
import sys
from decimal import Decimal, InvalidOperation, ROUND_CEILING
from pathlib import Path

directory = Path(sys.argv[1])
organized = directory / sys.argv[2]
prefix = sys.argv[3]
backup = directory / "Lite-Par-Backup"
manifest = backup / "selection.json"
parameters = ("Tilt", "Roll", "Twist")

def fail(message):
    raise SystemExit("Lite selection: " + message)

def candidates(folder, parameter):
    return sorted(p for p in folder.glob(f"bp_step_{parameter}*.par")
                  if re.fullmatch(rf"bp_step_{parameter}[0-9]+\.par", p.name)
                  and p.is_file() and not p.is_symlink())

if manifest.exists():
    plan = json.loads(manifest.read_text(encoding="utf-8"))
    if plan.get("version") not in (1, 2):
        fail(f"unsupported selection manifest: {manifest}")
    if plan.get("request") is not None and sys.argv[4] != "Lite " + plan["request"]:
        fail("AMOUNT differs from the saved selection; use a fresh working directory")
    print(f"[LITE CHECKPOINT] Reusing selection in {manifest}", flush=True)
else:
    if any(candidates(organized, p) for p in parameters) or any(directory.glob(prefix + "*.pdb")):
        fail("models have already been rebuilt or organized without a selection manifest. "
             "Use a fresh working directory.")
    if backup.exists():
        fail(f"backup exists without a manifest: {backup}. Preserve it and use a fresh working directory.")
    groups = {p: candidates(directory, p) for p in parameters}
    if any(not files for files in groups.values()):
        fail(f"expected Tilt, Roll and Twist .par files in {directory}")
    if len({len(files) for files in groups.values()}) != 1:
        fail("Tilt, Roll and Twist candidate counts must match for an equal split")
    total = sum(len(files) for files in groups.values())
    seed = os.environ.get("FOURMRNA_LITE_SEED")
    if seed is None:
        seed = str(secrets.randbits(128))
    if not seed:
        fail("FOURMRNA_LITE_SEED must not be empty")
    print(f"[LITE] {directory}: seed={seed}", flush=True)
    match = re.fullmatch(r"Lite\s+(.+)", sys.argv[4])
    if not match:
        fail("AMOUNT must be Full, Lite COUNT or Lite PERCENT%")
    answer = match.group(1).strip()
    try:
        if answer.endswith("%"):
            value = Decimal(answer[:-1].strip())
            if not value.is_finite() or not 0 < value <= 100:
                raise ValueError
            keep = max(1, int((value * total / 100).to_integral_value(rounding=ROUND_CEILING)))
        elif re.fullmatch(r"[0-9]+", answer):
            keep = int(answer)
            if not 1 <= keep <= total:
                raise ValueError
        else:
            raise ValueError
    except (InvalidOperation, ValueError, OverflowError):
        fail(f"invalid AMOUNT; use Lite COUNT (1-{total}) or Lite PERCENT%")
    requested_total = keep
    share = (requested_total + 2) // 3
    allocation = {p: share for p in parameters}
    keep = share * 3
    plan = {"version": 2, "seed": seed, "request": answer,
            "total": total, "requested_total": requested_total,
            "keep_total": keep, "allocation": allocation, "groups": {}}
    print(f"[LITE] Keeping {keep}/{total} parameter models: "
          + ", ".join(f"{p}={allocation[p]}" for p in parameters), flush=True)
    for parameter, files in groups.items():
        # Seeded hash ordering is deterministic across Python versions and
        # independent of directory enumeration order and other model groups.
        ranked = sorted(files, key=lambda p: (
            hashlib.sha256((seed + "\0" + parameter + "\0" + p.name).encode("utf-8")).digest(),
            p.name))
        selected = {p.name for p in ranked[:allocation[parameter]]}
        plan["groups"][parameter] = {
            "total": len(files), "kept": sorted(selected),
            "moved": sorted(p.name for p in files if p.name not in selected),
        }
    backup.mkdir()
    temporary = backup / "selection.json.tmp"
    temporary.write_text(json.dumps(plan, indent=2) + "\n", encoding="utf-8")
    temporary.replace(manifest)

# The plan is persisted before moving anything. A restart finishes pending moves
# from that same plan, without resampling or overwriting a backup file.
for parameter in parameters:
    group = plan["groups"][parameter]
    for name in group["kept"] + group["moved"]:
        if not re.fullmatch(rf"bp_step_{parameter}[0-9]+\.par", name):
            fail(f"invalid file name in {manifest}")
    expected = set(group["kept"] + group["moved"])
    actual = {p.name for folder in (directory, organized, backup)
              for p in candidates(folder, parameter)}
    if actual != expected:
        fail(f"{parameter} files differ from the saved selection; use a fresh working directory")
    for name in group["kept"]:
        if not (directory / name).is_file() and not (organized / name).is_file():
            fail(f"selected file is missing: {name}")
    for name in group["moved"]:
        source, destination = directory / name, backup / name
        if destination.exists():
            if source.exists():
                fail(f"both source and backup exist for {name}; refusing to overwrite")
        elif source.is_file():
            source.rename(destination)
        else:
            fail(f"excluded file is missing: {name}")
    print(f"[LITE] {parameter}: keeping {len(group['kept'])}/{group['total']}; "
          f"{len(group['moved'])} files in {backup}", flush=True)
PY_LITE
}

rebuild_all_pars() {

  local directory="$1"

  (
    cd "$directory"

    shopt -s nullglob

    for f in bp_step_*.par; do

      base=$(basename "$f" .par)
      suffix=${base#bp_step_}
      suffix=$(echo "$suffix" | tr '[:lower:]' '[:upper:]')

      pdb="${file_prefix}${suffix}.pdb"

      if [[ -f "$pdb" ]]; then
        echo "$pdb already exists. Skipping rebuild for $f"
        continue
      fi

      x3dna_utils cp_std "$std_type"

      rebuild -atomic "$f" "$pdb"

      cleanup_rebuild_files

      echo "$pdb generated"

    done

    shopt -u nullglob
  )
}

organize_files() {

  local directory="$1"

  ensure_dir "${directory}/${out_folder}"

  (
    cd "$directory"

    shopt -s nullglob

    for f in bp_step*.par; do
      mv "$f" "${out_folder}/"
    done

    shopt -u nullglob

    if [[ -f fiber_model.pdb ]]; then
      mv fiber_model.pdb "${file_prefix}.pdb"
    fi
  )
}

minimize_all_pdbs() {

  local directory="$1"
  local min_params_file="$2"

  (
    cd "$directory"

    ensure_dir "Before-Phenix"

    shopt -s nullglob

    for pdb in *.pdb; do

      [[ "$pdb" == *_minimized.pdb ]] && continue

      if [[ -f "Before-Phenix/$pdb" ]]; then
        echo "$pdb already minimized before. Skipping."
        continue
      fi

      base="${pdb%.pdb}"
      minimized_pdb="${base}_minimized.pdb"

      phenix.geometry_minimization "$pdb" "$min_params_file"

      rm -f "${base}"*.geo "${base}"*.cif \
            "${base}_minimized"*.geo "${base}_minimized"*.cif

      mv "$pdb" "Before-Phenix/$pdb"

      if [[ -f "$minimized_pdb" ]]; then

        mv "$minimized_pdb" "$pdb"

        echo "$pdb minimized"

      else

        echo "Minimization failed for $pdb"

      fi

    done

    shopt -u nullglob
  )
}

remove_5prime_phosphate_atoms() {

  local directory="$1"

  (
    cd "$directory"

    shopt -s nullglob

    for pdb in *.pdb; do

      tmp="${pdb}.remove_5phos.tmp"

      awk '
      function trim(value) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        return value
      }
      {
        record = substr($0, 1, 6)

        if (record == "ATOM  " || record == "HETATM") {
          chain = substr($0, 22, 1)
          residue = substr($0, 23, 5)

          if (!(chain in first_residue)) {
            first_residue[chain] = residue
          }

          atom = trim(substr($0, 13, 4))

          if (residue == first_residue[chain] && \
              (atom == "P" || atom == "OP1" || atom == "OP2")) {
            next
          }
        }

        print
      }
      ' "$pdb" > "$tmp"

      mv "$tmp" "$pdb"
      echo "Removed 5'-terminal P, OP1, and OP2 atoms from each chain in $pdb"

    done

    shopt -u nullglob
  )
}

main() {

  ensure_dir "$parent_directory"

  processed=0

  for line in "${models[@]}"; do

    IFS='|' read -r id directory sequence na_type phosphate_action amount_selection <<< "$line"

    if (( processed >= num_models )); then
      break
    fi

    processed=$((processed + 1))

    ensure_dir "$directory"

    if [[ -z "$sequence" || -z "$na_type" ]]; then
      echo "Model $id skipped"
      continue
    fi

    case "$phosphate_action" in
      Keep|Remove) ;;
      *)
        echo "Model $id has an invalid 5'-terminal phosphate setting: $phosphate_action (expected Keep or Remove)" >&2
        return 1
        ;;
    esac

    echo "Model $id start"

    get_type_settings "$na_type" "$sequence"

    if is_par_generation_done "$directory"; then

      echo "[CHECKPOINT] Model $id : bp_step.par and all .par files already prepared. Skipping preparation."

    else

      if ! build_fiber_and_analyze "$directory"; then
        continue
      fi

      bpstep_file="${directory}/bp_step.par"

      n1=$(process_parameter \
        "$bpstep_file" \
        "$directory" \
        "Tilt" \
        "$tilt_col" \
        "${tilt_values[@]}")

      echo "$n1 Tilt parameter files generated"

      n2=$(process_parameter \
        "$bpstep_file" \
        "$directory" \
        "Roll" \
        "$roll_col" \
        "${roll_values[@]}")

      echo "$n2 Roll parameter files generated"

      n3=$(process_parameter \
        "$bpstep_file" \
        "$directory" \
        "Twist" \
        "$twist_col" \
        "${twist_values[@]}")

      echo "$n3 Twist parameter files generated"

      mark_par_generation_done "$directory"

    fi

    select_lite_pars "$directory" "${amount_selection:-Full}"

    rebuild_all_pars "$directory"

    organize_files "$directory"

    minimize_all_pdbs \
      "$directory" \
      "${parent_directory}/min.params"

    if [[ "$phosphate_action" == "Remove" ]]; then
      remove_5prime_phosphate_atoms "$directory"
    fi

    echo "Model $id finished"

  done

  echo "All finished"
}

main "$@"
