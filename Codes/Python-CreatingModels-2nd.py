# ===== Set up =====
import os
import re
import shutil
import time
import pandas as pd
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# ===== Input =====
browser_type = ""
download = ""
directory = ""
na_type = ""

# ===== Adjustment for selected type =====
def make_driver():
    if browser_type.lower() == "chrome":
        return webdriver.Chrome()
    elif browser_type.lower() == "edge":
        return webdriver.Edge()
    elif browser_type.lower() == "firefox":
        return webdriver.Firefox()
    else:
        raise ValueError(f"Unsupported browser_type: {browser_type}")

if na_type == "A-DNA":
    type_xpath = '//*[@id="r2"]'
elif na_type == "B-DNA":
    type_xpath = '//*[@id="r1"]'
elif na_type == "A-RNA":
    type_xpath = '//*[@id="r3"]'
else:
    raise ValueError("Invalid na_type entered. Please enter 'A-DNA', 'B-DNA' or 'A-RNA'.")

# ===== Parameter combining process =====
os.chdir(directory)
original_folder = 'original'
os.makedirs(original_folder, exist_ok=True)
bp_step_file = 'bp_step.txt'

tilt_col = 10
roll_col = 11
twist_col = 12

header_lines = 4
files = os.listdir('.')

tilt_files = [f for f in files if 'Tilt' in f]
roll_files = [f for f in files if 'Roll' in f]
twist_files = [f for f in files if 'Twist' in f]

def extract_number(filename):
    match = re.search(r'(\d+)', filename)
    return match.group(1) if match else '0'
with open(bp_step_file, 'r') as f:
    header = [next(f) for _ in range(header_lines)]
    bp_data = pd.read_csv(f, delim_whitespace=True, header=None)

for tilt_file in tilt_files:
    for roll_file in roll_files:
        for twist_file in twist_files:
            new_filename = f'{extract_number(tilt_file)}-{extract_number(roll_file)}-{extract_number(twist_file)}.txt'
            with open(new_filename, 'w') as new_file:
                with open(bp_step_file, 'r') as original_file:
                    new_file.writelines(original_file.readlines())
            tilt_data = pd.read_csv(tilt_file, delim_whitespace=True, skiprows=header_lines, header=None)
            roll_data = pd.read_csv(roll_file, delim_whitespace=True, skiprows=header_lines, header=None)
            twist_data = pd.read_csv(twist_file, delim_whitespace=True, skiprows=header_lines, header=None)
            edited_data = pd.read_csv(new_filename, delim_whitespace=True, skiprows=header_lines, header=None)
            edited_data[tilt_col] = tilt_data.iloc[:, tilt_col].values
            edited_data[roll_col] = roll_data.iloc[:, roll_col].values
            edited_data[twist_col] = twist_data.iloc[:, twist_col].values
            with open(new_filename, 'w') as out_file:
                out_file.writelines(header)
                edited_data.to_csv(out_file, sep='\t', index=False, header=False)
bp_step_files = [f for f in files if f.startswith('bp_step')]
for file in bp_step_files:
    shutil.move(file, os.path.join(original_folder, file))

# ===== Generating models using combined parameters =====
for filename in os.listdir(directory):
    if filename.endswith(".txt") and not filename.startswith('bp_step'):
        file_path = os.path.join(directory, filename)
        driver = make_driver()
        try:
            driver.get('http://web.x3dna.org/index.php/rebuild')
            element = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.XPATH, '//*[@id="custom1"]')))
            element.click()
            element = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.XPATH, type_xpath)))
            element.click()
            file_input = WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.XPATH, '//*[@id="formdivre"]/p[6]/input')))
            file_input.send_keys(file_path)
            element = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.XPATH, '//*[@id="buildmodel"]')))
            element.click()
            download_link = WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.XPATH, '//*[@id="content"]/div[1]/div[2]/a[2]')))
            download_link.click()
            time.sleep(5)
            parameter_letters = filename[:-4]
            new_filename = f"3DNAAR-{parameter_letters}.pdb"
            source_path = os.path.join(download, 'custom_com.pdb')
            destination_path = os.path.join(download, new_filename)
            if os.path.exists(source_path):
                os.rename(source_path, destination_path)
                shutil.move(destination_path, directory)
            time.sleep(3)
        except Exception as e:
            print(f"An error occurred for file {filename}: {e}")
        finally:
            driver.quit()
        time.sleep(5)
print("finish")
