#!/usr/bin/env bash
parent_directory=""
shopt -s nullglob
mtz_candidates=( "${parent_directory}"/*.mtz )
shopt -u nullglob
if (( ${#mtz_candidates[@]} == 0 )); then
  echo "Error: No .mtz file found in ${parent_directory}" >&2
  exit 1
elif (( ${#mtz_candidates[@]} == 1 )); then
  mtz_file="${mtz_candidates[0]}"
else
  mtz_file="$(ls -t "${parent_directory}"/*.mtz | head -n1)"
  echo "Warning: Multiple .mtz files found. Using the most recent: ${mtz_file}" >&2
fi
mkdir -p "${parent_directory}/MR-Model02-1st"
file_path="${parent_directory}/MR-Model02-1st"
cd "${file_path}"
pdb_directory_1="${file_path}/Model01i"
pdb_directory_2="${file_path}/Model02"
pdb_directory_3="${file_path}/Model03i"
finish_directory="${pdb_directory_2}/finish"
mkdir -p "${pdb_directory_1}"
mkdir -p "${pdb_directory_2}"
mkdir -p "${pdb_directory_3}"
mkdir -p "${finish_directory}"
cp "${parent_directory}/Model02-1"/*.pdb "${pdb_directory_2}"
rm -f "${pdb_directory_2}"/??????.pdb
cp "${parent_directory}/Model01-2"/Model01best.pdb "${pdb_directory_1}"
cp "${parent_directory}/Model03-1"/??????.pdb "${pdb_directory_3}"
for pdb_file_1 in "${pdb_directory_1}"/*.pdb; do
  for pdb_file_2 in "${pdb_directory_2}"/*.pdb; do
    for pdb_file_3 in "${pdb_directory_3}"/*.pdb; do
      base_name_1=$(basename "${pdb_file_1}" .pdb)
      base_name_2=$(basename "${pdb_file_2}" .pdb)
      base_name_3=$(basename "${pdb_file_3}" .pdb)
      output_directory="phaser-${base_name_1}-${base_name_2}-${base_name_3}"
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
mkdir -p "${parent_directory}/Model02-2"
mr_dir="${parent_directory}/MR-Model02-1st"
model_dir_1="${parent_directory}/Model02-1"
model_dir_2="${parent_directory}/Model02-2"
shopt -s nullglob
three_dna_candidates=( "${model_dir_1}"/3DNA-??NA )
if [ ${#three_dna_candidates[@]} -ge 1 ]; then
  three_dna_dir="${three_dna_candidates[0]}"
  if [ -f "${three_dna_dir}/bp_step.txt" ]; then
    cp -f "${three_dna_dir}/bp_step.txt" "${model_dir_2}/"
  fi
fi
shopt -u nullglob
grep -F 'TILT'  "${mr_dir}/results.txt" > "${mr_dir}/results-tilt.txt"  || :
grep -F 'ROLL'  "${mr_dir}/results.txt" > "${mr_dir}/results-roll.txt"  || :
grep -F 'TWIST' "${mr_dir}/results.txt" > "${mr_dir}/results-twist.txt" || :
: > "${mr_dir}/results-good-num.txt"
process_category () {
  local KEYWORD="$1"
  local INFILE="$2"
  local PREFIX="$3"
  [ -s "$INFILE" ] || return 0
  awk -v kw="$KEYWORD" '
    {
      s=$1; n1=$2+0; n2=$3+0;
      sub("^.*" kw, "", s);
      sub(/^[[:space:]]+/, "", s);
      sub(/[-[:space:]].*$/, "", s);
      if (s ~ /^[0-9]+$/) {
        printf "%.10f %.10f %s\n", n1, n2, s
      }
    }' "$INFILE" \
  | sort -nr -k1,1 -k2,2 | head -2 \
  | awk -v pfx="$PREFIX" '{print "bp_step_" pfx $3}' >> "${mr_dir}/results-good-num.txt"
  awk -v kw="$KEYWORD" '
    {
      s=$1; n1=$2+0; n2=$3+0;
      sub("^.*" kw, "", s);
      sub(/^[[:space:]]+/, "", s);
      sub(/[-[:space:]].*$/, "", s);
      if (s ~ /^[0-9]+$/) {
        printf "%.10f %.10f %s\n", n2, n1, s
      }
    }' "$INFILE" \
  | sort -nr -k1,1 -k2,2 | head -2 \
  | awk -v pfx="$PREFIX" '{print "bp_step_" pfx $3}' >> "${mr_dir}/results-good-num.txt"
  awk -v kw="$KEYWORD" '
    {
      s=$1; n1=$2+0; n2=$3+0;
      sub("^.*" kw, "", s);
      sub(/^[[:space:]]+/, "", s);
      sub(/[-[:space:]].*$/, "", s);
      if (s ~ /^[0-9]+$/) {
        p=n1*n2;
        printf "%.10f %s\n", p, s
      }
    }' "$INFILE" \
  | sort -nr -k1,1 | head -3 \
  | awk -v pfx="$PREFIX" '{print "bp_step_" pfx $2}' >> "${mr_dir}/results-good-num.txt"
  awk '!seen[$0]++' "${mr_dir}/results-good-num.txt" > "${mr_dir}/.results-good-num.tmp" && mv "${mr_dir}/.results-good-num.tmp" "${mr_dir}/results-good-num.txt"
}
process_category "TILT"  "${mr_dir}/results-tilt.txt"  "Tilt"
process_category "ROLL"  "${mr_dir}/results-roll.txt"  "Roll"
process_category "TWIST" "${mr_dir}/results-twist.txt" "Twist"
if [ -s "${mr_dir}/results-good-num.txt" ]; then
  shopt -s nullglob
  three_dna_dirs=( "${model_dir_1}"/3DNA-??NA )
  shopt -u nullglob
  while IFS= read -r base; do
    target_name="${base}.txt"
    copied="0"
    for d in "${three_dna_dirs[@]}"; do
      if [ -d "$d" ]; then
        found_path=$(find "$d" -maxdepth 1 -type f -name "$target_name" -print -quit)
        if [ -n "$found_path" ]; then
          cp -f "$found_path" "${model_dir_2}/"
          copied="1"
          break
        fi
      fi
    done
    [ "$copied" = "1" ] || :
  done < "${mr_dir}/results-good-num.txt"
fi
