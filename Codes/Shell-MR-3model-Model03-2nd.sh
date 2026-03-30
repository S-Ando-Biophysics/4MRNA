#!/usr/bin/env bash
parent_directory="$(pwd)"
shopt -s nullglob
mtz_candidates=( "${parent_directory}"/*.mtz )
shopt -u nullglob
if (( ${#mtz_candidates[@]} == 0 )); then echo "Error: No .mtz file found in ${parent_directory}" >&2; exit 1; elif (( ${#mtz_candidates[@]} == 1 )); then mtz_file="${mtz_candidates[0]}"; else mtz_file="$(ls -t "${parent_directory}"/*.mtz | head -n1)"; echo "Warning: Multiple .mtz files found. Using the most recent: ${mtz_file}" >&2; fi
mkdir -p "${parent_directory}/MR-Model03-2nd"
file_path="${parent_directory}/MR-Model03-2nd"
cd "${file_path}"
pdb_directory_1="${file_path}/Model01i"
pdb_directory_2="${file_path}/Model02i"
pdb_directory_3="${file_path}/Model03"
finish_directory="${pdb_directory_3}/finish"
checkpoint_dir="${file_path}/Checkpoints"
mkdir -p "${pdb_directory_1}"
mkdir -p "${pdb_directory_2}"
mkdir -p "${pdb_directory_3}"
mkdir -p "${finish_directory}"
mkdir -p "${checkpoint_dir}"

checkpoint_file_for_base_triplet() {
  local base_name_1="$1"
  local base_name_2="$2"
  local base_name_3="$3"
  printf '%s/%s-%s-%s.done' "$checkpoint_dir" "$base_name_1" "$base_name_2" "$base_name_3"
}

cp "${parent_directory}/Model03-2"/*.pdb "${pdb_directory_3}"
cp "${parent_directory}/Model01-2"/Model01best.pdb "${pdb_directory_1}"
cp "${parent_directory}/Model02-2"/Model02best.pdb "${pdb_directory_2}"
for pdb_file_1 in "${pdb_directory_1}"/*.pdb; do
  for pdb_file_2 in "${pdb_directory_2}"/*.pdb; do
    for pdb_file_3 in "${pdb_directory_3}"/*.pdb; do
      base_name_1=$(basename "${pdb_file_1}" .pdb)
      base_name_2=$(basename "${pdb_file_2}" .pdb)
      base_name_3=$(basename "${pdb_file_3}" .pdb)
      output_directory="phaser-${base_name_1}-${base_name_2}-${base_name_3}"
      checkpoint_file="$(checkpoint_file_for_base_triplet "$base_name_1" "$base_name_2" "$base_name_3")"

      if [ -f "$checkpoint_file" ]; then
        echo "[CHECKPOINT] ${base_name_1}-${base_name_2}-${base_name_3} already attempted. Skipping."
        continue
      fi
      
      mkdir -p "${output_directory}"
      phaser <<EOF
TITLe ${base_name_1}-${base_name_2}-${base_name_3}
MODE MR_AUTO
HKLIn ${mtz_file}
ENSEmble ${base_name_1} PDB ${pdb_file_1} IDENtity 80
ENSEmble ${base_name_2} PDB ${pdb_file_2} IDENtity 80
ENSEmble ${base_name_3} PDB ${pdb_file_3} IDENtity 80
COMPosition NUCLeic MW 1000 NUM 1
COMPosition NUCLeic MW 2000 NUM 2
COMPosition NUCLeic MW 3000 NUM 3
SEARch ENSEmble ${base_name_1} NUM 1
SEARch ENSEmble ${base_name_2} NUM 2
SEARch ENSEmble ${base_name_3} NUM 3
EOF
      mv PHASER.sol PHASER.1.mtz PHASER.1.pdb "${output_directory}/"
      cp "${pdb_file_1}" "${finish_directory}/"
      : > "$checkpoint_file"
    done
  done
done
llg_extracted="./extracted_data_LGG.txt"
llg_output_file="./TopLLG.txt"
: > "$llg_extracted"; : > "$llg_output_file"
for folder_path in ./phaser-*/; do
  phaser_sol="${folder_path}PHASER.sol"
  [ -f "$phaser_sol" ] || continue
  folder_name=$(awk 'NR==1{print $2; exit}' "$phaser_sol")
  solu_set_line=$(awk '/SOLU SET/ {print; exit}' "$phaser_sol")
  [ -n "$solu_set_line" ] || continue
  result=$(echo "$solu_set_line" | awk '{sep=""; for(i=1;i<=NF;i++){ if($i ~ /LLG=/){ gsub(/[^0-9.]/,"",$i); printf "%s%s", sep, $i; sep=","; }} printf "\n"}')
  [ -n "$result" ] || continue
  printf '\n%s\n%s\n' "$folder_name" "$result" >> "$llg_extracted"
  max_value=$(echo "$result" | awk -F',' '{max=$1; for(i=2;i<=NF;i++) if($i>max) max=$i; print max}')
  printf '\n%s,%s\n' "$folder_name" "$max_value" >> "$llg_output_file"
done
tfz_extracted="./extracted_data_TFZ.txt"
tfz_output_file="./TopTFZ.txt"
: > "$tfz_extracted"; : > "$tfz_output_file"
for folder_path in ./phaser-*/; do
  phaser_sol="${folder_path}PHASER.sol"
  [ -f "$phaser_sol" ] || continue
  folder_name=$(awk 'NR==1{print $2; exit}' "$phaser_sol")
  solu_set_line=$(awk '/SOLU SET/ {print; exit}' "$phaser_sol")
  [ -n "$solu_set_line" ] || continue
  result=$(echo "$solu_set_line" | awk '{sep=""; for(i=1;i<=NF;i++){ if($i ~ /TFZ=/){ gsub(/[^0-9.]/,"",$i); printf "%s%s", sep, $i; sep=","; }} printf "\n"}')
  [ -n "$result" ] || continue
  printf '\n%s\n%s\n' "$folder_name" "$result" >> "$tfz_extracted"
  max_value=$(echo "$result" | awk -F',' '{max=$1; for(i=2;i<=NF;i++) if($i>max) max=$i; print max}')
  printf '\n%s,%s\n' "$folder_name" "$max_value" >> "$tfz_output_file"
done
{ printf 'Model TopLLG TopTFZ\n'; awk -F',' 'NR==FNR{llg[$1]=$2; next} {print $1, llg[$1], $2}' OFS=' ' TopLLG.txt TopTFZ.txt; } > "${file_path}/results.txt"
results_src="${file_path}/results.txt"
results_pick="${file_path}/4MRNA-results.txt"
results_dir="${parent_directory}/4MRNA-Results"
mkdir -p "${results_dir}"
: > "${results_pick}"
if [ -f "${results_src}" ]; then
  awk '$2 ~ /^-?[0-9.]+$/ && $3 ~ /^-?[0-9.]+$/ {
    printf "%s %g %g\n",$1,$2+0,$3+0
  }' "${results_src}" \
    | sort -k2,2nr -k3,3nr | head -2 >> "${results_pick}"
  awk '$2 ~ /^-?[0-9.]+$/ && $3 ~ /^-?[0-9.]+$/ {
    printf "%s %g %g\n",$1,$2+0,$3+0
  }' "${results_src}" \
    | sort -k3,3nr -k2,2nr | head -2 >> "${results_pick}"
  awk '$2 ~ /^-?[0-9.]+$/ && $3 ~ /^-?[0-9.]+$/ {
    p=($2+0)*($3+0);
    printf "%g\t%s %g %g\n",p,$1,$2+0,$3+0
  }' "${results_src}" \
    | sort -k1,1nr | head -3 | cut -f2- >> "${results_pick}"
  awk '!seen[$0]++' "${results_pick}" > "${file_path}/.4mrna_tmp.txt" \
    && mv "${file_path}/.4mrna_tmp.txt" "${results_pick}"
fi
if [ -s "${results_pick}" ]; then
  while read -r name val1 val2; do
    while IFS= read -r -d '' d; do
      cp -R "$d" "${results_dir}/"
    done < <(find "${file_path}" -mindepth 1 -maxdepth 1 -type d -name "*${name}*" -print0)
  done < "${results_pick}"
fi
if [ -f "${results_pick}" ]; then
  cp -f "${results_pick}" "${results_dir}/"
fi
