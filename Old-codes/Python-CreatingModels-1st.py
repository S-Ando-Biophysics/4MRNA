# ===== Set up =====
import os
import time
import itertools
import shutil
from pathlib import Path
from typing import Dict, List, Tuple
from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout, Browser

# ===== Input =====
parent_directory = ""

num_models = 1

model_info: Dict[int, Dict[str, str]] = {
    1: {"directory": os.path.join(parent_directory, "Model01-1"),
        "sequence": "",
        "na_type": ""},
    2: {"directory": os.path.join(parent_directory, "Model02-1"),
        "sequence": "",
        "na_type": ""},
    3: {"directory": os.path.join(parent_directory, "Model03-1"),
        "sequence": "",
        "na_type": ""},
}

# ===== Definition =====
def same_sign_symmetric(combo: Tuple[float, ...]) -> bool:
    mid = len(combo) // 2
    return all(combo[idx] == combo[-idx - 1] for idx in range(mid))

def generate_same_sign_symmetric_combinations(adjustments: List[float], length: int) -> List[Tuple[float, ...]]:
    return [c for c in itertools.product(adjustments, repeat=length) if same_sign_symmetric(c)]

def process_file(input_file: Path, output_dir: Path, param_index: int, adjustments: List[float], param_name: str) -> int:
    with input_file.open("r", encoding="utf-8") as f:
        lines = f.readlines()
    header = lines[:4]
    data_lines = lines[4:]
    symmetric_combinations = generate_same_sign_symmetric_combinations(adjustments, len(data_lines))
    for idx, combo in enumerate(symmetric_combinations, 1):
        output_lines = header.copy()
        for line, adjustment in zip(data_lines, combo):
            parts = line.split()
            if len(parts) > param_index:
                try:
                    value = float(parts[param_index])
                    parts[param_index] = f"{value + adjustment:.2f}"
                    output_lines.append(" ".join(parts) + "\n")
                except ValueError:
                    output_lines.append(line)
            else:
                output_lines.append(line)
        out_path = output_dir / f"bp_step_{param_name}{idx}.txt"
        with out_path.open("w", encoding="utf-8") as out_f:
            out_f.writelines(output_lines)
    return len(symmetric_combinations)

def ensure_dir(p: Path) -> None:
    p.mkdir(parents=True, exist_ok=True)

def get_type_settings(na_type: str, sequence: str):
    if na_type == "A-DNA":
        type_button_xpath = '//*[@id="main"]/div[2]/table[1]/tbody/tr[3]/td[4]/input'
        seq_processed = sequence.replace("U", "T")
        form_button_xpaths = ['//*[@id="formdiv"]/form/input[5]']  # single step
        build_option_xpath = '//*[@id="r2"]'
        adjustments_dict = {
            "Tilt": (10, [-5.24, 0, 5.24]),
            "Roll": (11, [-10.24, 0, 10.24]),
            "Twist": (12, [-9.76, 0, 9.76])
        }
        out_folder = "3DNA-ADNA"
        file_prefix = "3DNAAD"
    elif na_type == "B-DNA":
        type_button_xpath = '//*[@id="main"]/div[2]/table[1]/tbody/tr[4]/td[4]/input'
        seq_processed = sequence.replace("U", "T")
        form_button_xpaths = ['//*[@id="formdiv"]/form/input[5]']
        build_option_xpath = '//*[@id="r1"]'
        adjustments_dict = {
            "Tilt": (10, [-6.66, 0, 6.66]),
            "Roll": (11, [-10.82, 0, 10.82]),
            "Twist": (12, [-11.44, 0, 11.44])
        }
        out_folder = "3DNA-BDNA"
        file_prefix = "3DNABD"
    else:  # A-RNA
        type_button_xpath = '//*[@id="main"]/div[2]/table[1]/tbody/tr[2]/td[4]/input'
        seq_processed = sequence.replace("T", "U")
        form_button_xpaths = [
            '//*[@id="formdiv"]/form/p[4]/input',
            '//*[@id="formdiv"]/form/input[5]'
        ]
        build_option_xpath = '//*[@id="r3"]'
        adjustments_dict = {
            "Tilt": (10, [-5.24, 0, 5.24]),
            "Roll": (11, [-10.24, 0, 10.24]),
            "Twist": (12, [-9.76, 0, 9.76])
        }
        out_folder = "3DNA-ARNA"
        file_prefix = "3DNAAR"
    return seq_processed, type_button_xpath, build_option_xpath, form_button_xpaths, adjustments_dict, out_folder, file_prefix

def launch_browser_with_priority(pw) -> Browser:
    last_err = None
    for name in ("chromium", "firefox", "webkit"):
        try:
            return getattr(pw, name).launch(headless=True)
        except Exception as e:
            last_err = e
            continue
    raise RuntimeError("No supported browsers are available. Install one with `playwright install`.") from last_err

def obtain_ideal_model_and_bpstep(page, directory: Path, seq_processed: str,
                                  type_button_xpath: str, form_button_xpaths: List[str]) -> None:

    page.goto('http://web.x3dna.org/index.php/rebuild', wait_until="domcontentloaded")
    page.click('xpath=//*[@id="headnav5"]', timeout=20_000)
    page.click(f'xpath={type_button_xpath}', timeout=20_000)
    page.fill('xpath=//*[@id="pdbid"]', seq_processed, timeout=20_000)

    for btn in form_button_xpaths:
        page.click(f'xpath={btn}', timeout=180_000)

    with page.expect_download(timeout=120_000) as dl_info:
        page.click('xpath=//*[@id="content"]/div[1]/div[2]/a[2]', timeout=60_000)
    dl = dl_info.value
    fiber_model_path = directory / "fiber_model.pdb"
    dl.save_as(str(fiber_model_path))
    print("fiber_model.pdb Downloaded")

    page.click('xpath=//*[@id="headnav1"]', timeout=20_000)
    page.wait_for_timeout(1000)
    page.set_input_files('xpath=//*[@id="file"]', str(fiber_model_path))
    page.click('xpath=//*[@id="main"]/div[2]/table/tbody/tr/td[3]/form/input[2]', timeout=60_000)

    with page.expect_download(timeout=120_000) as dl2_info:
        page.click('xpath=//*[@id="content"]/div[3]/table[2]/tbody/tr/td/p[1]/a[2]', timeout=30_000)
    dl2 = dl2_info.value
    dl2.save_as(str(directory / "bp_step.txt"))
    print("bp_step.txt Downloaded")

def build_custom_from_bpstep(page, file_path: Path, build_option_xpath: str,
                             save_as_path: Path) -> bool:

    page.goto('http://web.x3dna.org/index.php/rebuild', wait_until="domcontentloaded")
    page.click('xpath=//*[@id="custom1"]', timeout=20_000)
    page.click(f'xpath={build_option_xpath}', timeout=20_000)
    page.set_input_files('xpath=//*[@id="formdivre"]/p[6]/input', str(file_path))
    page.click('xpath=//*[@id="buildmodel"]', timeout=20_000)

    try:
        with page.expect_download(timeout=120_000) as dl_info:
            page.click('xpath=//*[@id="content"]/div[1]/div[2]/a[2]', timeout=60_000)
        dl = dl_info.value
        dl.save_as(str(save_as_path))
        print(f"{save_as_path.name} Downloaded")
        return True
    except PWTimeout:
        return False

# ===== Process =====
def main():
    if not parent_directory:
        return 

    with sync_playwright() as p:
        browser = launch_browser_with_priority(p)
        context = browser.new_context(accept_downloads=True)
        page = context.new_page()

        for i in range(1, num_models + 1):

            directory = Path(model_info[i]["directory"])
            sequence = (model_info[i]["sequence"] or "").strip()
            na_type = (model_info[i]["na_type"] or "").strip()
            ensure_dir(directory)

            if not sequence or na_type not in ["A-DNA", "B-DNA", "A-RNA"]:
                continue

            print(f"Model {i} Start")

            (seq_processed,
             type_button_xpath,
             build_option_xpath,
             form_button_xpaths,
             adjustments_dict,
             out_folder,
             file_prefix) = get_type_settings(na_type, sequence)

            # Fiber + Analysis
            try:
                obtain_ideal_model_and_bpstep(
                    page=page,
                    directory=directory,
                    seq_processed=seq_processed,
                    type_button_xpath=type_button_xpath,
                    form_button_xpaths=form_button_xpaths
                )
            except Exception:
                pass 

            bp_step_path = directory / "bp_step.txt"
            if not bp_step_path.exists():
                print(f"Model {i} Finished")
                continue

            # Editing helical parameters
            for param, (index, adjustments) in adjustments_dict.items():
                num_files = process_file(bp_step_path, directory, index, adjustments, param)
                print(f"{num_files} files for {param} in model {i} were Generated")

            # Rebuild
            for filename in os.listdir(directory):
                if filename.startswith("bp_step_") and filename.endswith(".txt"):
                    file_path = directory / filename
                    try:
                        parameter_letters = filename[8:-4].upper()
                        new_filename = f"{file_prefix}{parameter_letters}.pdb"
                        save_as_path = directory / new_filename
                        ok = build_custom_from_bpstep(
                            page=page,
                            file_path=file_path,
                            build_option_xpath=build_option_xpath,
                            save_as_path=save_as_path
                        )
                        if ok:
                            time.sleep(0.2) 
                    except Exception:
                        pass 

            # Organizing files
            fiber_model_src = directory / "fiber_model.pdb"
            if fiber_model_src.exists():
                dest_path = directory / f"{file_prefix}.pdb"
                try:
                    if dest_path.exists():
                        dest_path.unlink()
                    fiber_model_src.rename(dest_path)
                except Exception:
                    pass

            out_folder_path = directory / out_folder
            ensure_dir(out_folder_path)
            for fn in os.listdir(directory):
                if fn.startswith("bp_step") and fn.endswith(".txt"):
                    shutil.move(str(directory / fn), str(out_folder_path / fn))

            print(f"Model {i} Finished")

        context.close()
        browser.close()
        print("All finished")

if __name__ == "__main__":
    main()
