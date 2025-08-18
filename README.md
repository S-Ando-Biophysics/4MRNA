# Programming Code Generator for 4MRNA
You can access this website via the following URL. https://s-ando-biophysics.github.io/4MRNA/

## About 4MRNA
**4MRNA** means <ins>**M**</ins>assive <ins>**M**</ins>ulti-type <ins>**M**</ins>odel <ins>**M**</ins>olecular <ins>**R**</ins>eplacement for <ins>**N**</ins>ucleic <ins>**A**</ins>cids.

Applying molecular replacement (MR) commonly used for structure determination to nucleic acids poses unique challenges that are not present for proteins. To solve these challenges, we developed a new innovative strategy called 4MRNA.

One challenge is that nucleic acids can have different 3D structures even with the same sequence, which means that models existing in the database may not be suitable as a search model. Moreover, it is empirically known that MR of nucleic acids can fail even when the search model and the target structure differ only slightly. To address these issues, the new strategy 4MRNA includes generating a large number of diverse search models and applying them to MR.

There is a web application called Web 3DNA [*] that generates structural models based on parameters that control the 3D structure of nucleic acids. We have discovered a strategy for adjusting these parameters to improve the success rate of MR. 

Based on this strategy, we decided to use Web 3DNA to create a wide variety of models. The processes of parameter adjustment and model creation have been automated using Python. Subsequently, MR is performed for each of the many models created. Since this operation needs to be repeated many times, we automated this process using Shell scripts on Linux.

[*] Li, S., Olson, W. K., & Lu, X. J. (2019). Web 3DNA 2.0 for the analysis, visualization, and modeling of 3D nucleic acid structures. _Nucleic acids research_, 47(W1), W26–W34.

## Instructions

### !! Announcement !!
Last Updated: **2025-08-18**
(The program has been updated. A revised version of the manual is scheduled to be released on August 19, 2025.)

### User manual
Please refer to the user manual.

- [English Version (Latest update: 2025-08-01)](https://github.com/S-Ando-Biophysics/4MRNA/blob/main/Docs/4MRNA%20User%20Manual%20English%20Version.pdf)
- [Japanese Version (Latest update: 2025-08-01) ](https://github.com/S-Ando-Biophysics/4MRNA/blob/main/Docs/4MRNA%20User%20Manual%20Japanese%20Version.pdf)

### How to use the website
1. Enter the required information.

    | Required infomation | What to do |
    | :----- | :----- |
    | **Browser** | Please select your browser from Google Chrome, Microsoft Edge, Firefox, or Safari. |
    | **Default download directory of selected browser** | Please enter the folder where files are automatically saved when using the selected browser above. |
    | **Working directory** | Please enter the folder where you want to run 4MRNA. |
    | **Path and name of reflection file used in 4MRNA** | Please enter the location and name of the reflection file to be used for 4MRNA. For example, if there is a file named `reflections.mtz` in `D:\Sample\Phenix`, enter `D:\Sample\Phenix\reflections.mtz`. |
    | **No. of models** | Please select how many types of models you want to create. [*1] |
    | **Type** | Please select the type of nucleic acid from A-form DNA, B-form DNA or A-form RNA. |
    | **Sequence of one strand of duplex** | Please enter the base sequence of the model (duplex) you want to create. Only the sequence of one strand of duplex is required. The complementary strand is processed automatically. |
    | **MW** | The molecular weight is calculated from the input sequence, including the complementary sequence. |
    | **No. in AU** | Please enter how many of the models are contained in the asymmetric unit of the crystal. [*2]  |

   [*1] For example, in the case of a double-stranded molecule that contains loop regions, you divide it into several sections (stems) by avoiding the loop regions, and then you create models for each section. When dividing it into two stem sections, please select “2” here.
   
   [*2] The calculation is done using the Matthews coefficient etc. Please refer to my [other repository](https://github.com/S-Ando-Biophysics/Cal-Nm) and [calculator website](https://s-ando-biophysics.github.io/Cal-Nm/).

3. Click the button labeled "**Generate codes**". This will generate Python codes and Shell scripts.

4. Click the button labeled "**Download this code**" or "**Download all codes**" to save the generated code.

5. Please run the codes in the order indicated by the number at the beginning of each downloaded file. To run these codes, follow the instructions below.

### How to run generated programming codes

| Type | Extension |  How to run |
| :----- | :----- | :----- |
| **Python** | **.py** | Please open the code in a text editor like VS Code and run it. |
| **Shell** | **.txt** | Please paste the code into Ubuntu or Terminal and run it. |

### Preparation
Please install and set up the following software in advance.

| Name | URL | Priority | Remarks |
| :----- | :----- | :----- | :----- |
| **Python** | https://www.python.org/downloads/ | **Required** | After installing Python, open the command prompt and run `pip install selenium pandas`. |
| Visual Studio Code (VS Code) | https://code.visualstudio.com/ | Recommended | In addition, download the extension of Python. |
| **Ubuntu** | https://apps.microsoft.com/search?query=Ubuntu | **Required on Windows** | It is necessary to turn on "**Windows Subsystem for Linux (WSL)**" and **Virtual Machine Platform** in the Windows settings to be able to use shell scripts. |
| **Phaser** | https://www.ccp4.ac.uk/download | **Required** | The command "phaser" is included in CCP4. If you have not installed CCP4, please install it. [*3] |
| Web browser |  | Required | Either **Google Chrome**, **Microsoft Edge**, **Firefox**, or **Safari** is required. It is required, but as it is usually pre-installed on computers, you normally do not need to prepare it yourself. For Safari, enable "**Allow Remote Automation**" in the developer settings. |
| Microsoft Excel | https://www.microsoft.com/en-us/microsoft-365 | Recommended  | This is useful for checking the results of molecular replacement. |

[*3] The following steps are for Windows (Ubuntu). The procedure for macOS is similar.

    # Please change the directory name and CCP4 version as appropriate.
    # Assume that "ccp4-9.0.010-linux64.tar.gz" has been downloaded to "C:\Users\name\Downloads".
    sudo su
    cd /usr/local
    mv /mnt/c/Users/name/Downloads/ccp4-9.0.010-linux64.tar.gz .
    gunzip ccp4-9.0.010-linux64.tar.gz
    tar -xvf ccp4-9.0.010-linux64.tar
    cd ccp4-9
    ./BINARY.setup
    exit
    cd /home/name
    vi .bashrc
    source /usr/local/ccp4-9/bin/ccp4.setup-sh    # Please add to the last line.


## Supported environment

|  | Operating system | Browser |
| :----- | :----- | :----- |
| **This website** | Windows, macOS, Linux (Rocky Linux) | Google Chrome, Microsoft Edge, Firefox, Safari |
| **Generated Python codes** | Windows, macOS, Linux (Rocky Linux) | Google Chrome, Microsoft Edge, Firefox, Safari |
| **Generated Shell scripts** | Windows (WSL; Ubuntu), macOS, Linux (Rocky Linux) | - |

## Release Notes
- **2025-08-01** The beta version has been released.
- **2025-08-18** The official version has been released. In the beta version, manual steps were required between code blocks, but in the official version, these steps have been eliminated.

## Reference
- Ando, S., & Kondo, J. (2025), A new approach for nucleic acid structure determination: molecular replacement using massive multi-type models created through helical parameter adjustment. _Nucleic acids research_, in revision.
