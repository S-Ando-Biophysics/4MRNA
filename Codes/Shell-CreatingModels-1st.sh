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
# " ID | Directory | Sequence | Type of NA "
# Please enter the sequence. Only the sequence of one strand of duplex is required. The complementary strand is processed automatically.
# Please enter the type of NA. Please choose from A-DNA, B-DNA, or A-RNA.
models=(
  "1|${parent_directory}/Model01-1||"
  "2|${parent_directory}/Model02-1||"
  "3|${parent_directory}/Model03-1||"
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
  shift 2
  local values=("$@")

  : > "$outfile"

  _rec_sym() {
    local pos="$1"
    shift
    local prefix=("$@")
    local half=$(( length / 2 ))
    local odd=$(( length % 2 ))

    if (( pos == half )); then
      if (( odd == 1 )); then
        local mid
        for mid in "${values[@]}"; do
          local combo=("${prefix[@]}" "$mid")
          for ((i=${#prefix[@]}-1;i>=0;i--)); do
            combo+=("${prefix[i]}")
          done
          local IFS=,
          echo "${combo[*]}" >> "$outfile"
        done
      else
        local combo=("${prefix[@]}")
        for ((i=${#prefix[@]}-1;i>=0;i--)); do
          combo+=("${prefix[i]}")
        done
        local IFS=,
        echo "${combo[*]}" >> "$outfile"
      fi
      return
    fi

    for v in "${values[@]}"; do
      _rec_sym $((pos + 1)) "${prefix[@]}" "$v"
    done
  }

  _rec_sym 0
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
  same_sign_symmetric_generate "$n_data_lines" "$combo_file" "${values[@]}"

  local idx=0
  while IFS= read -r combo; do
    [[ -z "$combo" ]] && continue
    idx=$((idx+1))
    out="${output_dir}/bp_step_${param_name}${idx}.par"
    modify_bpstep_par "$bpstep_file" "$out" "$target_col" "$combo"
  done < "$combo_file"

  rm -f "$combo_file"

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

    find_pair fiber_model.pdb | analyze

    cleanup_analyze_files

    if [[ ! -f bp_step.par ]]; then
      echo "bp_step.par not generated"
      return 1
    fi
  )
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

      rm -f "${base}"*.geo "${base}"*.cif "${base}_minimized"*.geo "${base}_minimized"*.cif

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

main() {

  ensure_dir "$parent_directory"

  processed=0

  for line in "${models[@]}"; do

    IFS='|' read -r id directory sequence na_type <<< "$line"

    if (( processed >= num_models )); then
      break
    fi

    processed=$((processed+1))

    ensure_dir "$directory"

    if [[ -z "$sequence" || -z "$na_type" ]]; then
      echo "Model $id skipped"
      continue
    fi

    echo "Model $id start"

    get_type_settings "$na_type" "$sequence"

    if is_par_generation_done "$directory"; then
      echo "[CHECKPOINT] Model $id : bp_step.par and all .par files already prepared. Skipping preparation."
    else
      if ! build_fiber_and_analyze "$directory"; then
        continue
      fi

      bpstep_file="${directory}/bp_step.par"

      n1=$(process_parameter "$bpstep_file" "$directory" "Tilt" "$tilt_col" "${tilt_values[@]}")
      echo "$n1 Tilt files generated"

      n2=$(process_parameter "$bpstep_file" "$directory" "Roll" "$roll_col" "${roll_values[@]}")
      echo "$n2 Roll files generated"

      n3=$(process_parameter "$bpstep_file" "$directory" "Twist" "$twist_col" "${twist_values[@]}")
      echo "$n3 Twist files generated"

      mark_par_generation_done "$directory"
    fi

    rebuild_all_pars "$directory"

    organize_files "$directory"

    minimize_all_pdbs "$directory" "${parent_directory}/min.params"

    echo "Model $id finished"

  done

  echo "All finished"
}

main "$@"
