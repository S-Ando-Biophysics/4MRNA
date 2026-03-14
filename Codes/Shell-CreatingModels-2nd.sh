#!/usr/bin/env bash
set -euo pipefail

parent_directory="$(pwd)"

# ====================================================================================================
# User settings
# ====================================================================================================

directory="${parent_directory}/Model01-2"
na_type="A-DNA"    # Please enter the type of NA. Please choose from A-DNA, B-DNA, or A-RNA.

# ====================================================================================================

case "$na_type" in
  "A-DNA")
    std_type="ADNA"
    file_prefix="3DNAAD"
    ;;
  "B-DNA")
    std_type="BDNA"
    file_prefix="3DNABD"
    ;;
  "A-RNA")
    std_type="RNA"
    file_prefix="3DNAAR"
    ;;
  *)
    echo "Invalid na_type. Use 'A-DNA', 'B-DNA', or 'A-RNA'." >&2
    exit 1
    ;;
esac

if [[ -z "$directory" || ! -d "$directory" ]]; then
  echo "Please set directory to a valid path." >&2
  exit 1
fi

cd "$directory"

original_folder="${directory}/original"
mkdir -p "$original_folder"

bp_step_file="bp_step.par"

tilt_col=11
roll_col=12
twist_col=13
header_lines=4

if [[ ! -f "$bp_step_file" ]]; then
  echo "${bp_step_file} not found in ${directory}" >&2
  exit 1
fi

extract_number() {
  local filename="$1"
  local num
  num=$(printf '%s\n' "$filename" | grep -oE '[0-9]+' | head -n 1 || true)
  if [[ -n "$num" ]]; then
    printf '%s\n' "$num"
  else
    printf '0\n'
  fi
}

cleanup_rebuild_files() {
  rm -f Atomic*.pdb ref_frames.dat
}

combine_par_files() {
  local base_file="$1"
  local tilt_file="$2"
  local roll_file="$3"
  local twist_file="$4"
  local out_file="$5"

  awk \
    -v hdr="$header_lines" \
    -v tilt_col="$tilt_col" \
    -v roll_col="$roll_col" \
    -v twist_col="$twist_col" \
    -v tiltfile="$tilt_file" \
    -v rollfile="$roll_file" \
    -v twistfile="$twist_file" \
    -v basefile="$base_file" \
    '
    FILENAME == tiltfile {
      if (FNR > hdr) {
        t[FNR - hdr] = $tilt_col
      }
      next
    }

    FILENAME == rollfile {
      if (FNR > hdr) {
        r[FNR - hdr] = $roll_col
      }
      next
    }

    FILENAME == twistfile {
      if (FNR > hdr) {
        w[FNR - hdr] = $twist_col
      }
      next
    }

    FILENAME == basefile {
      if (FNR <= hdr) {
        print
      } else {
        idx = FNR - hdr
        if (idx in t) { $tilt_col = t[idx] }
        if (idx in r) { $roll_col = r[idx] }
        if (idx in w) { $twist_col = w[idx] }
        print
      }
      next
    }
    ' \
    "$tilt_file" "$roll_file" "$twist_file" "$base_file" \
    > "$out_file"
}

minimize_all_pdbs() {
  local target_directory="$1"
  local min_params_file="$2"

  (
    cd "$target_directory"

    mkdir -p "Before-Phenix"

    shopt -s nullglob

    for pdb in *.pdb; do
      [[ "$pdb" == *_minimized.pdb ]] && continue

      base="${pdb%.pdb}"
      minimized_pdb="${base}_minimized.pdb"

      phenix.geometry_minimization "$pdb" "$min_params_file"

      rm -f "${base}"*.geo "${base}"*.cif "${base}_minimized"*.geo "${base}_minimized"*.cif

      if [[ -f "$minimized_pdb" ]]; then
        mv "$pdb" "Before-Phenix/$pdb"
        mv "$minimized_pdb" "$pdb"
        echo "${pdb} minimized"
      else
        echo "Minimization failed for ${pdb}" >&2
      fi
    done

    shopt -u nullglob
  )
}

shopt -s nullglob

tilt_files=( *Tilt*.par )
roll_files=( *Roll*.par )
twist_files=( *Twist*.par )

if (( ${#tilt_files[@]} == 0 )); then
  echo "No Tilt files found." >&2
  exit 1
fi
if (( ${#roll_files[@]} == 0 )); then
  echo "No Roll files found." >&2
  exit 1
fi
if (( ${#twist_files[@]} == 0 )); then
  echo "No Twist files found." >&2
  exit 1
fi

for t in "${tilt_files[@]}"; do
  for r in "${roll_files[@]}"; do
    for w in "${twist_files[@]}"; do

      tnum=$(extract_number "$t")
      rnum=$(extract_number "$r")
      wnum=$(extract_number "$w")

      out_par="${tnum}-${rnum}-${wnum}.par"

      combine_par_files "$bp_step_file" "$t" "$r" "$w" "$out_par"

      echo "${out_par} generated"
    done
  done
done

for f in bp_step*; do
  [[ -e "$f" ]] || continue
  mv "$f" "$original_folder/"
done

for f in *.par; do
  [[ -e "$f" ]] || continue

  base="${f%.par}"
  out_pdb="${file_prefix}-${base}.pdb"

  x3dna_utils cp_std "$std_type"
  rebuild -atomic "$f" "$out_pdb"
  cleanup_rebuild_files

  echo "${out_pdb} generated"
done

minimize_all_pdbs "$directory" "${parent_directory}/min.params"

shopt -u nullglob

echo "All finished"