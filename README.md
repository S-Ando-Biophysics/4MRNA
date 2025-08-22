# 4MRNA
**4MRNA** = <ins>**M**</ins>assive <ins>**M**</ins>ulti-type <ins>**M**</ins>odel <ins>**M**</ins>olecular <ins>**R**</ins>eplacement for <ins>**N**</ins>ucleic <ins>**A**</ins>cids.

### User manual (Latest update: )
### [Release](https://github.com/S-Ando-Biophysics/4MRNA/releases/latest)
### [Website](https://s-ando-biophysics.github.io/4MRNA/)

<br>

## Instructions
There are three ways to execute 4MRNA.

### (1) Standard style
In this style, you simply run one Shell script named `4MRNA.sh` on your computer.
#### Procedure
1. Create a new directory on your computer for running `4MRNA.sh`. After creating it, place your reflection file (.mtz) for molecular replacement into that directory.
 
2. Download `4MRNA.sh` into the directory created in Step 1, either directly from [this URL](https://github.com/S-Ando-Biophysics/4MRNA/releases/latest/download/4MRNA.sh) or via [this website](https://s-ando-biophysics.github.io/4MRNA/).

3. Open Ubuntu/Terminal, change to the directory created in Step 1, and run `bash 4MRNA.sh` or `chmod +x 4MRNA.sh && ./4MRNA.sh`.

4. When 4MRNA finishes, a directory named `4MRNA-Results` will be created, containing up to seven candidate solutions for molecular replacement.

### (2) Customizable style
In this style, you obtain some programming codes from the website. Basically, you just run them in the prescribed order, but if needed, you can edit and customize the code. 

Access [this website](https://s-ando-biophysics.github.io/4MRNA/). How to use is described on the website.

#### Procedure (almost the same as on the website)
1. Create a new directory on your computer for running 4MRNA. After creating it, place your reflection file (.mtz) for molecular replacement into that directory.
 
2. Fill in the table on the website and click "Generate codes (Customizable style)".

3. Click "Download all codes". Then run them in the order indicated by the number at the beginning of each downloaded file.

   | Type | Extension |  How to run |
   | :----- | :----- | :----- |
   | Python | .py | Open the code with a text editor such as VS Code and run them. |
   | Shell | .sh | Run them using the `bash` command in Ubuntu/Terminal. |

4. When 4MRNA finishes, a directory named `4MRNA-Results` will be created, containing up to seven candidate solutions for molecular replacement.

### (3) Install style



<!---
### How to Use (Summarized Version of the User Manual)
Tutorial video (YouTube) - in preparation

1. Create a folder to run 4MRNA and place one reflection file (.mtz) in it.

2. Enter the required information.

    | Required&nbsp;infomation | What to do |
    | :----- | :----- |
    | **Working&nbsp;directory** | Please enter the folder where you want to run 4MRNA. |
    | **No.&nbsp;of&nbsp;models** | Please select how many types of models you want to create. [*1] |
    | **Type** | Please select the type of nucleic acid from A-form DNA, B-form DNA or A-form RNA. |
    | **Sequence&nbsp;of&nbsp;one&nbsp;strand&nbsp;of&nbsp;duplex** | Please enter the base sequence of the model (duplex) you want to create. Only the sequence of one strand of duplex is required. The complementary strand is processed automatically. |
    | **MW** | The molecular weight is calculated from the input sequence, including the complementary sequence. |
    | **No.&nbsp;in&nbsp;AU** | Please enter how many of the models are contained in the asymmetric unit of the crystal. [*2]  |

   [*1] For example, in the case of a double-stranded molecule that contains loop regions, you divide it into several sections (stems) by avoiding the loop regions, and then you create models for each section. When dividing it into two stem sections, please select “2” here.
   
   [*2] The calculation is done using the Matthews coefficient etc. Please refer to my [other repository](https://github.com/S-Ando-Biophysics/Cal-Nm) and [calculator website](https://s-ando-biophysics.github.io/Cal-Nm/).

3. Click the button labeled "**Generate codes**". This will generate Python codes and Shell scripts.

4. Click the button labeled "**Download this code**" or "**Download all codes**" to save the generated code.

5. Please run the codes in the order indicated by the number at the beginning of each downloaded file. The table below shows how to run each type of code.

    | Type | Extension |  How to run |
    | :----- | :----- | :----- |
    | **Python** | **.py** | Please open the code in a text editor like Visual Studio Code and run it. |
    | **Shell** | **.sh** | Please open Ubuntu or Terminal and run `bash <code-name>.sh`. |


### Preparation
Please install and set up the following software in advance.

| Name | Priority | Remarks |
| :----- | :----- | :----- |
| **[Python](https://www.python.org/downloads/)** | **Required** | After installing Python, open the command prompt and run `pip install pandas playwright` and `playwright install`. |
| [Visual&nbsp;Studio&nbsp;Code](https://code.visualstudio.com/Download) | Recommended | In addition, download the extension of Python. |
| **[Ubuntu](https://apps.microsoft.com/search?query=Ubuntu)** | **Required on Windows** | It is necessary to turn on "**Windows Subsystem for Linux (WSL)**" and **Virtual Machine Platform** in the Windows settings to be able to use shell scripts. |
| **[Phaser](https://www.ccp4.ac.uk/download)** | **Required** | The command "phaser" is included in CCP4. If you have not installed CCP4, please install it. [*3] |
| Web&nbsp;browser | Required | Either **Google Chrome**, **Microsoft Edge**, **Firefox**, or **Safari** is required. It is required, but as it is usually pre-installed on computers, you normally do not need to prepare it yourself. For Safari, enable "**Allow Remote Automation**" in the developer settings. |
| [Microsoft&nbsp;Excel](https://www.microsoft.com/en-us/microsoft-365) | Recommended | This is useful for checking the results of molecular replacement. |

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


### Supported Environment

|  | Operating system | Browser |
| :----- | :----- | :----- |
| **This website** | Windows, macOS, Linux (Rocky Linux) | Google Chrome, Microsoft Edge, Firefox, Safari |
| **Generated Python codes** | Windows, macOS, Linux (Rocky Linux) | Google Chrome, Microsoft Edge, Firefox, Safari |
| **Generated Shell scripts** | Windows (WSL; Ubuntu), macOS, Linux (Rocky Linux) | - |

### Release Notes
- **2025-07-08** The beta version has been released.
- **2025-08-01** The official version has been released.
- **2025-08-18** Updata: 
  - The Linux code has been revised, enabling smoother use of 4MRNA.
- **2025-08-21** Update:
  - The website user interface has been updated to improve usability.
  - The stability of Python code has been enhanced.
  - The processing speed of the Python code has been improved.

## About 4MRNA
[Explanatory video (YouTube)](https://youtu.be/WX_Rh3vtOlg)

**4MRNA** means <ins>**M**</ins>assive <ins>**M**</ins>ulti-type <ins>**M**</ins>odel <ins>**M**</ins>olecular <ins>**R**</ins>eplacement for <ins>**N**</ins>ucleic <ins>**A**</ins>cids.

Applying molecular replacement (MR) commonly used for structure determination to nucleic acids poses unique challenges that are not present for proteins. To solve these challenges, we developed a new innovative strategy called 4MRNA.

One challenge is that nucleic acids can have different 3D structures even with the same sequence, which means that models existing in the database may not be suitable as a search model. Moreover, it is empirically known that MR of nucleic acids can fail even when the search model and the target structure differ only slightly. To address these issues, the new strategy 4MRNA includes generating a large number of diverse search models and applying them to MR.

There is a web application called Web 3DNA [*] that generates structural models based on parameters that control the 3D structure of nucleic acids. We have discovered a strategy for adjusting these parameters to improve the success rate of MR. 

Based on this strategy, we decided to use Web 3DNA to create a wide variety of models. The processes of parameter adjustment and model creation have been automated using Python. Subsequently, MR is performed for each of the many models created. Since this operation needs to be repeated many times, we automated this process using Shell scripts on Linux.

[*] Li, S., Olson, W. K., & Lu, X. J. (2019). Web 3DNA 2.0 for the analysis, visualization, and modeling of 3D nucleic acid structures. _Nucleic acids research_, 47(W1), W26–W34.

## Reference
- in preparation

--->
