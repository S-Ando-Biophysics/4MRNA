#!/usr/bin/env bash

parent_directory="" 

mtz_files=( "${parent_directory}"/*.mtz )
if [ ${#mtz_files[@]} -eq 0 ]; then
  echo "Error: No .mtz file found in ${parent_directory}" >&2
  exit 1
elif [ ${#mtz_files[@]} -gt 1 ]; then
  echo "Error: Multiple .mtz files found in ${parent_directory}:" >&2
  printf '  %s\n' "${mtz_files[@]}" >&2
  exit 1
fi
mtz_file="${mtz_files[0]}"

mkdir -p "${parent_directory}/MR-Model01-2nd"
file_path="${parent_directory}/MR-Model01-2nd"
cd "${file_path}" || exit 1

pdb_directory_1="${file_path}/Model01"
finish_directory="${pdb_directory_1}/finish"
mkdir -p "${pdb_directory_1}" "${finish_directory}"

cp "${parent_directory}/Model01-2"/*.pdb "${pdb_directory_1}" 2>/dev/null || true

for pdb_file_1 in "${pdb_directory_1}"/*.pdb; do
  [ -f "${pdb_file_1}" ] || continue
  base_name_1=$(basename "${pdb_file_1}" .pdb)
  output_directory="phaser-${base_name_1}"
  mkdir -p "${output_directory}"
  phaser <<EOF 2>&1 | tee "${output_directory}/phaser.log"
TITLe ${base_name_1}
MODE MR_AUTO
HKLIn ${mtz_file}
ENSEmble ${base_name_1} PDB ${pdb_file_1} IDENtity 80
COMPosition NUCLeic MW 1000 NUM 1
SEARch ENSEmble ${base_name_1} NUM 1
EOF
  [ -f PHASER.sol ]   && mv PHASER.sol   "${output_directory}/"
  [ -f PHASER.1.mtz ] && mv PHASER.1.mtz "${output_directory}/"
  [ -f PHASER.1.pdb ] && mv PHASER.1.pdb "${output_directory}/"
  cp "${pdb_file_1}" "${finish_directory}/"
done

llg_extracted="./extracted_data_LGG.txt"
llg_output_file="./TopLLG.txt"
: > "$llg_extracted"; : > "$llg_output_file"

for folder_path in ./phaser-*/; do
  [ -d "$folder_path" ] || continue
  phaser_sol="${folder_path}PHASER.sol"
  [ -f "$phaser_sol" ] || continue
  folder_name=$(awk 'NR==1{print $2; exit}' "$phaser_sol")
  solu_set_line=$(awk '/SOLU SET/ {print; exit}' "$phaser_sol")
  [ -n "$solu_set_line" ] || continue
  result=$(echo "$solu_set_line" | awk '{
    sep="";
    for(i=1;i<=NF;i++){
      if($i ~ /LLG=/){
        gsub(/[^0-9.]/,"",$i);
        printf "%s%s", sep, $i;
        sep=",";
      }
    }
    printf "\n"
  }')
  [ -n "$result" ] || continue
  printf '\n%s\n%s\n' "$folder_name" "$result" >> "$llg_extracted"
  max_value=$(echo "$result" | awk -F',' '{max=$1; for(i=2;i<=NF;i++) if($i>max) max=$i; print max}')
  printf '\n%s,%s\n' "$folder_name" "$max_value" >> "$llg_output_file"
done

tfz_extracted="./extracted_data_TFZ.txt"
tfz_output_file="./TopTFZ.txt"
: > "$tfz_extracted"; : > "$tfz_output_file"

for folder_path in ./phaser-*/; do
  [ -d "$folder_path" ] || continue
  phaser_sol="${folder_path}PHASER.sol"
  [ -f "$phaser_sol" ] || continue
  folder_name=$(awk 'NR==1{print $2; exit}' "$phaser_sol")
  solu_set_line=$(awk '/SOLU SET/ {print; exit}' "$phaser_sol")
  [ -n "$solu_set_line" ] || continue
  result=$(echo "$solu_set_line" | awk '{
    sep="";
    for(i=1;i<=NF;i++){
      if($i ~ /TFZ=/){
        gsub(/[^0-9.]/,"",$i);
        printf "%s%s", sep, $i;
        sep=",";
      }
    }
    printf "\n"
  }')
  [ -n "$result" ] || continue
  printf '\n%s\n%s\n' "$folder_name" "$result" >> "$tfz_extracted"
  max_value=$(echo "$result" | awk -F',' '{max=$1; for(i=2;i<=NF;i++) if($i>max) max=$i; print max}')
  printf '\n%s,%s\n' "$folder_name" "$max_value" >> "$tfz_output_file"
done

{
  printf 'Model TopLLG TopTFZ\n'
  awk -F',' 'NR==FNR{llg[$1]=$2; next} {print $1, llg[$1], $2}' OFS=' ' TopLLG.txt TopTFZ.txt
} > "${file_path}/results.txt"
