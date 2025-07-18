# Programming Code Generator for 4MRNA
You can access this website via the following URL. https://s-ando-biophysics.github.io/4MRNA/


## About 4MRNA
**4MRNA** means <ins>**M**</ins>assive <ins>**M**</ins>ulti-type <ins>**M**</ins>odel <ins>**M**</ins>olecular <ins>**R**</ins>eplacement for <ins>**N**</ins>ucleic <ins>**A**</ins>cids.

Applying molecular replacement (MR) commonly used for structure determination to nucleic acids poses unique challenges that are not present for proteins. To solve these challenges, we developed a new innovative strategy called 4MRNA.

One challenge is that nucleic acids can have different 3D structures even with the same sequence, which means that models existing in the database may not be suitable as a search model.Moreover, it is empirically known that MR of nucleic acids can fail even when the search model and the target structure differ only slightly.

To address these issues, the new strategy 4MRNA includes generating a large number of diverse search models and applying them to MR.


## Instructions
### How to use the website
1. Enter the required information.

    | Required infomation | What to do |
    | :----- | :----- |
    | **Default download directory of Microsoft Edge** | Please enter the folder where files are automatically saved when using the Microsoft Edge. You can check it as follows: open the Microsoft Edge → Settings → Downloads → check the location |
    | **Working directory** | Please enter the folder where you want to run 4MRNA. |
    | **Path and name of reflection file used in 4MRNA** | Please enter the location and name of the reflection file to be used for 4MRNA. For example, if there is a file named `reflections.mtz` in `D:/Sample/Phenix`, enter `D:/Sample/Phenix/reflections.mtz`. |
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
| **Linux** | **.txt** | Please paste the code into Ubuntu and run it. Alternatively, change the file extension to `.sh` and run it using the `sh` command. |

[Note 1] The generated programming codes have only been tested on Windows PCs. 

[Note 2] [**Important**] When running the code "**Python-CreatingModels-2nd.py**", please make sure to perform the following operations.

1. As a result of running "**02.Linux-MR-1model-<ins>Model01-1</ins>st.txt**", a file named "**results.txt**" will be generated. Open this file and identify the number corresponding to the parameter (Tilt, Roll, Twist) pattern  that shows good statistical values (LLG and TFZ).
2. The files containing parameter patterns are located in a folder named something like "3DNA-ARNA" within the directory "**<ins>Model01-1</ins>**". Locate the file with the number identified in Step 1, then copy and paste them into the directory "**<ins>Model01-2</ins>**".
3. Run the code named "**03.Python-CreatingModels-2nd.py**". Subsequently, please run "**04.Linux-MR-1model-<ins>Model01-2</ins>nd.txt**".
- The above is an example for when "No. of models" is set to 1. For 2 or 3, please follow the same procedure.

### Preparation
Please install and set up the following software in advance.

| Name | URL | Priority | Remarks |
| :----- | :----- | :----- | :----- |
| **Python** | https://www.python.org/downloads/windows/ | **Required** | After installing Python, open the command prompt and run `pip install selenium`. |
| **Ubuntu** | https://apps.microsoft.com/search?query=Ubuntu | **Required** | It is necessary to turn on "**Windows Subsystem for Linux**" in the Windows settings to be able to use Linux code. |
| **Phaser** | https://phenix-online.org/download | **Required** | Even if you have already installed the Windows ver. of Phenix, you need to install the Linux command line ver. [*2] |
| **Microsoft Edge** | https://www.microsoft.com/en-us/edge | **Required** | If your computer is a Windows PC, this is included by default, so there’s no need to download it. |
| Microsoft Edge WebDriver | https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver | Required in some cases [*3] | After downloading the driver, you can use it either by specifying the file directly or by adding it to your PATH. |
| Xming | https://sourceforge.net/projects/xming/ | Required in some cases | When using Phaser, you <ins>may</ins> need to launch X server. |
| Visual Studio Code | https://code.visualstudio.com/ | Recommended | In addition, download the extension of Python. |
| Microsoft Excel | https://www.microsoft.com/en-us/microsoft-365 | Recommended  | This is useful for checking the results of molecular replacement. |

[*2] https://phenix-online.org/documentation/install-setup-run.html#command-line-installer-macos-and-linux

    # Please change the directory name and Phenix version as appropriate.
    sudo su
    cd /usr/local/bin
    mv /mnt/c/Users/name/Downloads/phenix-installer-1.21.1-5286-intel-linux-2.6-x86_64-centos6.tar.gz .
    gunzip phenix-installer-1.21.1-5286-intel-linux-2.6-x86_64-centos6.tar.gz
    tar -xvf phenix-installer-1.21.1-5286-intel-linux-2.6-x86_64-centos6.tar
    cd phenix-installer-1.21.1-5286-intel-linux-2.6-x86_64-centos6
    ./install
    cd /home/name
    vi .bashrc
    source /usr/local/phenix-1.21.1-5286/phenix_env.sh    # add to the last line

[*3] When using Selenium and WebDriver to automate the browser, you used to have to download the driver yourself, but since Selenium 4.6.0 (released on 2022-11-04), it automatically downloads the driver, so there is no need to prepare it in advance.


## Reference
- Ando, S., & Kondo, J. (2025), A new approach for nucleic acid structure determination: molecular replacement using massive multi-type models created through helical parameter adjustment. _Nucleic acids research_, in revision.
