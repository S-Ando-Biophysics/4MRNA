# Programming Code Generator for 4MRNA
You can access this website via the following URL. https://s-ando-biophysics.github.io/4MRNA/


## About 4MRNA
**4MRNA** means <ins>**M**</ins>assive <ins>**M**</ins>ulti-type <ins>**M**</ins>odel <ins>**M**</ins>olecular <ins>**R**</ins>eplacement for <ins>**N**</ins>ucleic <ins>**A**</ins>cids.

Applying molecular replacement (MR) commonly used for structure determination to nucleic acids poses unique challenges that are not present for proteins. To solve these challenges, we developed a new innovative strategy called 4MRNA.

One challenge is that nucleic acids can have different 3D structures even with the same sequence, which means that models existing in the database may not be suitable as a search model. Moreover, it is empirically known that MR of nucleic acids can fail even when the search model and the target structure differ only slightly. To address these issues, the new strategy 4MRNA includes generating a large number of diverse search models and applying them to MR.

There is a web application called Web 3DNA that generates structural models based on parameters that control the three-dimensional structure of nucleic acids. We have discovered a strategy for adjusting these parameters to improve the success rate of MR. Based on this strategy, we decided to use Web 3DNA to create a wide variety of models. The processes of parameter adjustment and model creation have been automated using Python. Subsequently, MR is performed for each of the many models created. Since this operation needs to be repeated many times, we automated this process using shell scripts on Linux.

## Instructions
### How to use the website
1. Enter the required information.

    | Required infomation | What to do |
    | :----- | :----- |
    | **Browser** | Please select your browser from Google Chrome, Microsoft Edge, or Firefox. |
    | **Default download directory of selected browser** | Please enter the folder where files are automatically saved when using the selected browser above. |
    | **Working directory** | Please enter the folder where you want to run 4MRNA. |
    | **Path and name of reflection file used in 4MRNA** | Please enter the location and name of the reflection file to be used for 4MRNA. For example, if there is a file named `reflections.mtz` in `D:\Sample\Phenix`, enter `D:\Sample\Phenix\reflections.mtz`. |
    | **No. of models** | Please select how many types of models you want to create. For example, in the case of a double-stranded molecule that contains loop regions, you divide it into several sections (stems) by avoiding the loop regions, and then you create models for each section. When dividing it into two stem sections, please select “2” here. |
    | **Type** | Please select the type of nucleic acid from A-form DNA, B-form DNA or A-form RNA. |
    | **Sequence of one strand of duplex** | Please enter the base sequence of the model (duplex) you want to create. Only the sequence of one strand of duplex is required. The complementary strand is processed automatically. |
    | **MW** | The molecular weight is calculated from the input sequence, including the complementary sequence. If necessary, you can modify it by yourself. |
    | **No. in AU** | Please enter how many of the models are contained in the asymmetric unit of the crystal. [*1]  |

   [*1] The calculation is done using the Matthews coefficient etc.

3. Click the button labeled "**Generate codes**". This will generate Python and Linux code.

4. Click the button labeled "**Download this code**" or "**Download all codes**" to save the generated code.

5. Please run the codes in the order indicated by the number at the beginning of each downloaded file. To run these codes, follow the instructions below.

### How to run generated programming codes

| Type | Extension |  How to run |
| :----- | :----- | :----- |
| **Python** | **.py** | Please open the code in a text editor like VS Code and run it. |
| **shell scripts** | **.txt** | Please paste the code into Ubuntu or Terminal and run it. Alternatively, change the file extension to `.sh` and run it using the `bash` command. |

[Note] When running the code "**Python-CreatingModels-2nd.py**", please make sure to perform the following operations.

1. As a result of running "**02.Linux-MR-1model-<ins>Model01-1</ins>st.txt**", a file named "**results.txt**" will be generated. Open this file and identify the number corresponding to the parameter (Tilt, Roll, Twist) pattern  that shows good statistical values (LLG and TFZ).
2. The files containing parameter patterns are located in a folder named something like "3DNA-ARNA" within the directory "**<ins>Model01-1</ins>**". Locate the file with the number identified in Step 1, then copy and paste them into the directory "**<ins>Model01-2</ins>**".
3. Run the code named "**03.Python-CreatingModels-2nd.py**". Subsequently, please run "**04.Linux-MR-1model-<ins>Model01-2</ins>nd.txt**".
- The above is an example for when "No. of models" is set to 1. For 2 or 3, please follow the same procedure.

### Preparation
Please install and set up the following software in advance.

| Name | URL | Priority | Remarks |
| :----- | :----- | :----- | :----- |
| **Python** | https://www.python.org/downloads/ | **Required** | After installing Python, open the command prompt and run `pip install selenium pandas`. |
| Visual Studio Code | https://code.visualstudio.com/ | Recommended | In addition, download the extension of Python. |
| **Ubuntu** | https://apps.microsoft.com/search?query=Ubuntu | **Required on Windows** | It is necessary to turn on "**Windows Subsystem for Linux**" in the Windows settings to be able to use shell scripts. |
| **Phaser** | https://www.ccp4.ac.uk/download | **Required** | The command "phaser" is included in CCP4. If you have not installed CCP4, please install it. [*2] |
| **Google Chrome** | https://www.google.com/chrome/ | **Required** | Either Google Chrome, Microsoft Edge, Firefox, or Safari is required. |
| **Microsoft Edge** | https://www.microsoft.com/en-us/edge | **Required** | Either Google Chrome, Microsoft Edge, Firefox, or Safari is required. |
| **Firefox** | https://www.firefox.com/en-US/browsers/desktop/ | **Required** | Either Google Chrome, Microsoft Edge, Firefox, or Safari is required. |
| **Safari** |  | **Required** | Either Google Chrome, Microsoft Edge, Firefox, or Safari is required. For Safari, enable "**Allow Remote Automation**" in the developer settings. |
| ChromeDriver | https://sites.google.com/chromium.org/driver/ | Required in some cases [*3] | [WebDriver for Google Chrome] After downloading the driver, you can use it either by specifying the file directly or by adding it to your PATH. |
| Microsoft Edge WebDriver | https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver | Required in some cases [*3] | [WebDriver for Microsoft Edge] After downloading the driver, you can use it either by specifying the file directly or by adding it to your PATH. |
| geckodriver | https://github.com/mozilla/geckodriver | Required in some cases [*3] | [WebDriver for Firefox] After downloading the driver, you can use it either by specifying the file directly or by adding it to your PATH. |
| Xming | https://sourceforge.net/projects/xming/ | Required in some cases | When using Phaser, you <ins>may</ins> need to launch X server. |
| Microsoft Excel | https://www.microsoft.com/en-us/microsoft-365 | Recommended  | This is useful for checking the results of molecular replacement. |

[*2] The following steps are for Windows (Ubuntu). The procedure for macOS is similar.

    # Please change the directory name and Phenix version as appropriate.
    # Assume that "ccp4-9.0.010-linux64.tar.gz" has been downloaded to "C:\Users\name\Downloads".
    sudo su
    cd /usr/local
    mkdir ccp4
    cd ccp4
    mv /mnt/c/Users/name/Downloads/ccp4-9.0.010-linux64.tar.gz .
    gunzip ccp4-9.0.010-linux64.tar.gz
    tar -xvf ccp4-9.0.010-linux64.tar
    ./ccp4-9.0-setup    # If an error occurs due to a missing library being displayed, install it using apt install <library-name> and run this command again.
    cd /opt/xtal/ccp4-9.0
    ./BINARY.setup
    exit
    cd /home/name
    vi .bashrc
    source /opt/xtal/ccp4-9.0/bin/ccp4.setup-sh    # Please add to the last line.

[*3] When using Selenium and Webdriver to automate the browser, you used to have to download the driver yourself, but since Selenium 4.6.0 (released on 2022-11-04), it automatically downloads the driver, so there is no need to prepare it in advance.

## Supported environment
### This website (Programming Code Generator for 4MRNA)

| | Windows | macOS | Linux (Rocky Linux) |
| :-----: | :-----: | :-----: | :-----: |
| **Google Chrome** | 〇 |  | 〇 |
| **Microsoft Edge** | 〇 |  | 〇 |
| **Firefox** | 〇 |  | 〇 | 
| **Safari** | - |  | -| 

[Note] Since it is published using GitHub Pages, this website itself (having the code generation) is, in principle, compatible with all major operating systems and browsers.

### Generated Programming Codes (Python)

| | Windows | macOS | Linux (Rocky Linux) |
| :-----: | :-----: | :-----: | :-----: |
| **Google Chrome** | 〇 |  | 〇 |
| **Microsoft Edge** | 〇 |  | 〇 |
| **Firefox** | 〇 |  | 〇 | 
| **Safari** | - |  | -| 

### Generated Programming Codes (shell)

| Windows (Windows Subsystem for Linux; Ubuntu) | macOS | Linux (Rocky Linux) |
| :-----: | :-----: | :-----: |
| 〇 |  | 〇 |

## Reference
- Ando, S., & Kondo, J. (2025), A new approach for nucleic acid structure determination: molecular replacement using massive multi-type models created through helical parameter adjustment. _Nucleic acids research_, in revision.
