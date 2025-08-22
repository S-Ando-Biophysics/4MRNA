# 4MRNA

**4MRNA** = <ins>**M**</ins>assive <ins>**M**</ins>ulti-type <ins>**M**</ins>odel <ins>**M**</ins>olecular <ins>**R**</ins>eplacement for <ins>**N**</ins>ucleic <ins>**A**</ins>cids &ensp;[[About 4MRNA](https://github.com/S-Ando-Biophysics/4MRNA?tab=readme-ov-file#about-4mrna)]

### [User manual](https://github.com/S-Ando-Biophysics/4MRNA/blob/main/Docs/4MRNA-Manual.pdf) (Latest update: in preparation)
### [Website](https://s-ando-biophysics.github.io/4MRNA/)
### [Release (Standard style)](https://github.com/S-Ando-Biophysics/4MRNA/releases/latest)


<br>

## Instructions
There are three ways to execute 4MRNA.

### (1) Standard style
In this style, you simply run one Shell script named `4MRNA.sh` on your computer.

<!--- Tutorial video (YouTube) - in preparation --->

#### Procedure
1. Create a new directory on your computer for running `4MRNA.sh`. After creating it, place your reflection file (.mtz) for molecular replacement into that directory.
 
2. Download `4MRNA.sh` into the directory created in Step 1, either directly from [this URL](https://github.com/S-Ando-Biophysics/4MRNA/releases/latest/download/4MRNA.sh) or via [this website](https://s-ando-biophysics.github.io/4MRNA/).

3. Open Ubuntu/Terminal, change to the directory created in Step 1, and run `bash 4MRNA.sh` or `chmod +x 4MRNA.sh && ./4MRNA.sh`.

4. When 4MRNA finishes, a directory named `4MRNA-Results` will be created, containing up to seven candidate solutions for molecular replacement.

### (2) Customizable style
In this style, you obtain some programming codes from the website. Basically, you just run them in the prescribed order, but if needed, you can edit and customize the code. 

Access [this website](https://s-ando-biophysics.github.io/4MRNA/). How to use is described on the website.

<!--- Tutorial video (YouTube) - in preparation --->

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


<!--- Tutorial video (YouTube) - in preparation --->


## Preparation
Please install and set up the following software in advance.

| Name | Priority | Remarks |
| :----- | :----- | :----- |
| [Python](https://www.python.org/downloads/) | Required | After installation, run `pip install pandas playwright`, `playwright install`, and `playwright install-deps`. |
| [VS&nbsp;Code](https://code.visualstudio.com/Download) | Recommended | In addition, download the extension of Python. |
| [Ubuntu](https://apps.microsoft.com/search?query=Ubuntu) | Required on Windows | It is necessary to turn on "Windows Subsystem for Linux (WSL)" and "Virtual Machine Platform" in the Windows settings to be able to use shell scripts. Furthermore, run `sudo apt update` and `sudo apt upgrade` in Ubuntu. |
| [Phaser](https://www.ccp4.ac.uk/download) | Required | The command `phaser` is included in CCP4. If you have not installed CCP4, please install it. <sup>[*1]</sup> |

[*1] The following steps are for Windows (Ubuntu). The procedure for macOS is similar.

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


## About 4MRNA
[Explanatory video (YouTube)](https://youtu.be/WX_Rh3vtOlg)

Applying molecular replacement (MR) commonly used for structure determination to nucleic acids poses unique challenges that are not present for proteins. To solve these challenges, we developed a new innovative strategy called 4MRNA.

One challenge is that nucleic acids can have different 3D structures even with the same sequence, which means that models existing in the database may not be suitable as a search model. Moreover, it is empirically known that MR of nucleic acids can fail even when the search model and the target structure differ only slightly. To address these issues, the new strategy 4MRNA includes generating a large number of diverse search models and applying them to MR.

There is a web application called Web 3DNA <sup>[*2]</sup> that generates structural models based on parameters that control the 3D structure of nucleic acids. We have discovered a strategy for adjusting these parameters to improve the success rate of MR. 

Based on this strategy, we decided to use Web 3DNA to create a wide variety of models. The processes of parameter adjustment and model creation have been automated using Python. Subsequently, MR is performed for each of the many models created. Since this operation needs to be repeated many times, we automated this process using Shell scripts on Linux.

[*2] Li, S., Olson, W. K., & Lu, X. J. (2019). Web 3DNA 2.0 for the analysis, visualization, and modeling of 3D nucleic acid structures. _Nucleic acids research_, 47(W1), W26–W34.

## Reference
- in preparation

## Notes 
### Miscellaneous notes
- The Japanese version of user manual is available [here](https://github.com/S-Ando-Biophysics/4MRNA/blob/main/Docs/4MRNA-Manual.pdf).

- The calculation of "No. of AU" (the number of molecules in the asymmetric unit) is done using the Matthews coefficient etc. Please refer to the [other repository](https://github.com/S-Ando-Biophysics/Cal-Nm) and [calculator website](https://s-ando-biophysics.github.io/Cal-Nm/).

### Supported environment
- **Operating system**: Windows <sup>[*3]</sup>, macOS, Linux (Rocky Linux)
 
- **Browser**: Google Chrome, Microsoft Edge, Firefox, Safari

  [*3] Shell scripts were executed in Windows Subsystem for Linux (WSL) with Ubuntu.

### Changelog
- **2025-07-08**  The beta version has been released.

- **2025-08-01** The official version has been released.

- **2025-08-18** Minor Update:
  - The Linux code has been revised, enabling smoother use of 4MRNA.

- **2025-08-22**  Major Update: 
  - The stability of the Python code has been enhanced.  
  - The processing speed of the Python code has been improved.  
  - Two execution styles have been introduced: Standard style and Customizable style.  
    - The previous version corresponds to Customizable style.  
    - Standard style provides a simpler way to run 4MRNA.  
  - The website user interface has been updated to improve usability.
