# ===== Set up  =====
import os
import re
import shutil
import pandas as pd
from pathlib import Path
from playwright.sync_api import sync_playwright

# ===== Input =====
directory = ""
na_type = ""

# ===== NA-type =====
if na_type == "A-DNA":
    type_xpath = '//*[@id="r2"]'
elif na_type == "B-DNA":
    type_xpath = '//*[@id="r1"]'
elif na_type == "A-RNA":
    type_xpath = '//*[@id="r3"]'
else:
    raise ValueError("Invalid na_type. Use 'A-DNA', 'B-DNA', or 'A-RNA'.")

# ===== Combinig parameters =====
if not directory:
    raise ValueError("Please set `directory` to a valid path.")

os.chdir(directory)
dir_path = Path(directory)
original_folder = dir_path / "original"
original_folder.mkdir(exist_ok=True)

bp_step_file = "bp_step.txt"
tilt_col, roll_col, twist_col = 10, 11, 12
header_lines = 4

files = os.listdir(".")
tilt_files  = [f for f in files if "Tilt"  in f]
roll_files  = [f for f in files if "Roll"  in f]
twist_files = [f for f in files if "Twist" in f]

def extract_number(filename: str) -> str:
    m = re.search(r"(\d+)", filename)
    return m.group(1) if m else "0"

with open(bp_step_file, "r", encoding="utf-8") as f:
    header = [next(f) for _ in range(header_lines)]

for t in tilt_files:
    for r in roll_files:
        for w in twist_files:
            out_txt = f"{extract_number(t)}-{extract_number(r)}-{extract_number(w)}.txt"

            with open(out_txt, "w", encoding="utf-8") as g, open(bp_step_file, "r", encoding="utf-8") as src:
                g.writelines(src.readlines())

            tilt_df  = pd.read_csv(t, sep=r'\s+', skiprows=header_lines, header=None)
            roll_df  = pd.read_csv(r, sep=r'\s+', skiprows=header_lines, header=None)
            twist_df = pd.read_csv(w, sep=r'\s+', skiprows=header_lines, header=None)
            edited = pd.read_csv(out_txt, sep=r'\s+', skiprows=header_lines, header=None)

            edited[tilt_col]  = tilt_df.iloc[:, tilt_col].values
            edited[roll_col]  = roll_df.iloc[:, roll_col].values
            edited[twist_col] = twist_df.iloc[:, twist_col].values

            with open(out_txt, "w", encoding="utf-8") as out:
                out.writelines(header)
                edited.to_csv(out, sep="\t", index=False, header=False)

for f in [f for f in os.listdir(".") if f.startswith("bp_step")]:
    shutil.move(f, original_folder / f)

# ===== Generating models using combined parameters =====
def launch_browser_with_priority(pw):

    for name in ("chromium", "firefox", "webkit"):
        try:
            return getattr(pw, name).launch(headless=True)
        except Exception:
            continue
    raise RuntimeError("No browser available. Run `playwright install` (Linux: also `playwright install-deps`).")

def build_custom_from_file(page, file_path: Path, na_option_xpath: str, save_as_path: Path) -> bool:

    page.goto("http://web.x3dna.org/index.php/rebuild", wait_until="domcontentloaded")
    page.click('xpath=//*[@id="custom1"]', timeout=20_000)           # Custom tab
    page.click(f'xpath={na_option_xpath}', timeout=20_000)           # r1/r2/r3
    page.set_input_files('xpath=//*[@id="formdivre"]/p[6]/input', str(file_path))
    page.click('xpath=//*[@id="buildmodel"]', timeout=20_000)

    try:
        with page.expect_download(timeout=120_000) as dl_info:
            page.click('xpath=//*[@id="content"]/div[1]/div[2]/a[2]', timeout=60_000)
        dl = dl_info.value
        dl.save_as(str(save_as_path))
        return True
    except Exception:
        return False

with sync_playwright() as p:
    browser = launch_browser_with_priority(p)
    context = browser.new_context(accept_downloads=True)
    page = context.new_page()

    for filename in os.listdir(directory):
        if filename.endswith(".txt") and not filename.startswith("bp_step"):
            src_txt = dir_path / filename

            parameter_letters = filename[:-4]
            out_pdb = dir_path / f"3DNAAR-{parameter_letters}.pdb"

            if build_custom_from_file(page, src_txt, type_xpath, out_pdb):
                print(f"{out_pdb.name} Downloaded")

    context.close()
    browser.close()

print("All finished")
