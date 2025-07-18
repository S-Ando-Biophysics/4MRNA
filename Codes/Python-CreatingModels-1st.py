# ===== Set up =====
import os
import time
import shutil
import itertools
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# ===== Input =====
browser_type = ""
download = ""
parent_directory = ""
num_models = 1

# Enter the sequence and the type of nucleic acid (na_type). The na_type is "A-DNA", "B-DNA" or "A-RNA".
model_info = {
    1: {"directory": os.path.join(parent_directory, "Model01-1"),
        "sequence": "AACCAA",
        "na_type": "A-DNA"},
    2: {"directory": os.path.join(parent_directory, "Model02-1"), 
        "sequence": "", 
        "na_type": ""},
    3: {"directory": os.path.join(parent_directory, "Model03-1"), 
        "sequence": "", 
        "na_type": ""},
}

# ===== Web driver =====
def make_driver():
    if browser_type.lower() == "chrome":
        return webdriver.Chrome()
    elif browser_type.lower() == "edge":
        return webdriver.Edge()
    elif browser_type.lower() == "firefox":
        return webdriver.Firefox()
    else:
        raise ValueError(f"Unsupported browser_type: {browser_type}")

# ===== Do =====
for i in range(1, num_models + 1):

    # ----- Information -----
    directory = model_info[i]["directory"]
    sequence = model_info[i]["sequence"].strip()
    na_type = model_info[i]["na_type"].strip()

    os.makedirs(directory, exist_ok=True)

    # ----- Validation -----
    if not download:
        print(f"Download directory is not configured. Skipping model {i}.")
        continue
    if not parent_directory:
        print(f"Working directory is not configured. Skipping model {i}.")
        continue
    if not sequence:
        print(f"Sequence for model {i} is not provided. Skipping.")
        continue
    if na_type not in ["A-DNA", "B-DNA", "A-RNA"]:
        print(f"Invalid the type for model {i}. Skipping.")
        continue

    # ----- Adjustment for selected type -----
    if na_type == "A-DNA":
        type_button_xpath = '//*[@id="main"]/div[2]/table[1]/tbody/tr[3]/td[4]/input'
        seq_processed = sequence.replace("U", "T")
        form_button_xpath = '//*[@id="formdiv"]/form/input[5]'
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
        form_button_xpath = '//*[@id="formdiv"]/form/input[5]'
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
        form_button_xpath_1 = '//*[@id="formdiv"]/form/p[4]/input'
        form_button_xpath_2 = '//*[@id="formdiv"]/form/input[5]'
        build_option_xpath = '//*[@id="r3"]'
        adjustments_dict = {
            "Tilt": (10, [-5.24, 0, 5.24]),
            "Roll": (11, [-10.24, 0, 10.24]),
            "Twist": (12, [-9.76, 0, 9.76])
        }
        out_folder = "3DNA-ARNA"
        file_prefix = "3DNAAR"

    # ----- Obtaining helical parameters of the ideal model -----
    driver = make_driver()
    try:
        driver.get('http://web.x3dna.org/index.php/rebuild')
        element = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, '//*[@id="headnav5"]'))
        )
        element.click()
        element = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, type_button_xpath))
        )
        element.click()
        element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, '//*[@id="pdbid"]'))
        )
        element.clear()
        element.send_keys(seq_processed)
        if na_type == "A-RNA":
            element = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, form_button_xpath_1))
            )
            element.click()
            element = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.XPATH, form_button_xpath_2))
            )
            element.click()
        else:
            element = WebDriverWait(driver, 180).until(
                EC.element_to_be_clickable((By.XPATH, form_button_xpath))
            )
            element.click()
        time.sleep(10)
        element = WebDriverWait(driver, 60).until(
            EC.element_to_be_clickable((By.XPATH, '//*[@id="content"]/div[1]/div[2]/a[2]'))
        )
        element.click()
        element = WebDriverWait(driver, 30).until(
            EC.element_to_be_clickable((By.XPATH, '//*[@id="headnav1"]'))
        )
        element.click()
        time.sleep(5)
        fiber_model_path = os.path.join(download, 'fiber_model.pdb')
        file_input = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, '//*[@id="file"]'))
        )
        file_input.send_keys(fiber_model_path)
        element = WebDriverWait(driver, 180).until(
            EC.element_to_be_clickable((By.XPATH, '//*[@id="main"]/div[2]/table/tbody/tr/td[3]/form/input[2]'))
        )
        element.click()
        time.sleep(10)
        element = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, '//*[@id="content"]/div[3]/table[2]/tbody/tr/td/p[1]/a[2]'))
        )
        element.click()
        time.sleep(5)
    except Exception as e:
        print(f"Error obtaining ideal model for model {i}: {e}")
    finally:
        driver.quit()

    # ----- Move bp_step.txt -----
    bp_step_src = os.path.join(download, 'bp_step.txt')
    if os.path.exists(bp_step_src):
        shutil.move(bp_step_src, directory)
    else:
        print(f"bp_step.txt not found for model {i}. Continuing to next step.")

    # ----- Editing 3 helical parameters -----
    def same_sign_symmetric(combo):
        mid = len(combo) // 2
        return all(combo[idx] == combo[-idx - 1] for idx in range(mid))

    def generate_same_sign_symmetric_combinations(adjustments, length):
        return [combo for combo in itertools.product(adjustments, repeat=length) if same_sign_symmetric(combo)]

    def process_file(input_file, output_dir, param_index, adjustments, param_name):
        with open(input_file, 'r') as f:
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
                        output_lines.append(' '.join(parts) + '\n')
                    except ValueError:
                        output_lines.append(line)
                else:
                    output_lines.append(line)
            output_file = os.path.join(output_dir, f"bp_step_{param_name}{idx}.txt")
            with open(output_file, 'w') as out_f:
                out_f.writelines(output_lines)
        return len(symmetric_combinations)

    input_file = os.path.join(directory, 'bp_step.txt')
    for param, (index, adjustments) in adjustments_dict.items():
        num_files = process_file(input_file, directory, index, adjustments, param)
        print(f"Generated {num_files} files for {param} in model {i}.")

    # ----- Generating models using modified parameters -----
    for filename in os.listdir(directory):
        if filename.startswith("bp_step_") and filename.endswith(".txt"):
            file_path = os.path.join(directory, filename)
            driver = make_driver()
            try:
                driver.get('http://web.x3dna.org/index.php/rebuild')
                element = WebDriverWait(driver, 10).until(
                    EC.element_to_be_clickable((By.XPATH, '//*[@id="custom1"]'))
                )
                element.click()
                element = WebDriverWait(driver, 10).until(
                    EC.element_to_be_clickable((By.XPATH, build_option_xpath))
                )
                element.click()
                file_input = WebDriverWait(driver, 10).until(
                    EC.presence_of_element_located((By.XPATH, '//*[@id="formdivre"]/p[6]/input'))
                )
                file_input.send_keys(file_path)
                element = WebDriverWait(driver, 10).until(
                    EC.element_to_be_clickable((By.XPATH, '//*[@id="buildmodel"]'))
                )
                element.click()
                download_link = WebDriverWait(driver, 20).until(
                    EC.element_to_be_clickable((By.XPATH, '//*[@id="content"]/div[1]/div[2]/a[2]'))
                )
                download_link.click()
                time.sleep(5)

                # Rename the downloaded custom model files
                parameter_letters = filename[8:-4].upper()
                new_filename = f"{file_prefix}{parameter_letters}.pdb"
                source_path = os.path.join(download, 'custom_com.pdb')
                destination_path = os.path.join(download, new_filename)
                if os.path.exists(source_path):
                    os.rename(source_path, destination_path)
                    shutil.move(destination_path, directory)
                else:
                    print(f"Custom model file not found for model {i}, file {filename}.")
                time.sleep(5)
            except Exception as e:
                print(f"Error processing file {filename} for model {i}: {e}")
            finally:
                driver.quit()

    # ----- Organizing files -----
    fiber_model_src = os.path.join(download, 'fiber_model.pdb')
    if os.path.exists(fiber_model_src):
        new_filename = f"{file_prefix}.pdb"
        renamed_in_download = os.path.join(download, new_filename)
        try:
            os.rename(fiber_model_src, renamed_in_download)
            dest_path = os.path.join(directory, new_filename)
            shutil.move(renamed_in_download, dest_path)
            print(f"Moved ideal model as {new_filename} to {directory}")
        except Exception as e:
            print(f"Error moving fiber_model.pdb for model {i}: {e}")
    else:
        print(f"No fiber_model.pdb found for model {i}, skipping move.")

    out_folder_path = os.path.join(directory, out_folder)
    os.makedirs(out_folder_path, exist_ok=True)
    for filename in os.listdir(directory):
        if filename.startswith("bp_step") and filename.endswith(".txt"):
            shutil.move(os.path.join(directory, filename), os.path.join(out_folder_path, filename))
    print(f"Completed processing for model {i}.")

print("All process finished.")
