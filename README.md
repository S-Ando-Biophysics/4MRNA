# 4MRNA

**4MRNA** = <ins>**M**</ins>assive <ins>**M**</ins>ulti-type <ins>**M**</ins>odel <ins>**M**</ins>olecular <ins>**R**</ins>eplacement for <ins>**N**</ins>ucleic <ins>**A**</ins>cids &ensp;[[About 4MRNA](https://github.com/S-Ando-Biophysics/4MRNA?tab=readme-ov-file#about-4mrna)]

### [User manual](https://cdn.jsdelivr.net/gh/S-Ando-Biophysics/4MRNA@main/Docs/4MRNA-Manual.pdf) (Latest updated: 2025-08-26)
### [Download "4MRNA.sh"](https://github.com/S-Ando-Biophysics/4MRNA/releases/latest/download/4MRNA.sh) (for Standard style of 4MRNA)
### [Website](https://s-ando-biophysics.github.io/4MRNA/)

<br>

## Instructions
There are three ways to execute 4MRNA.

| Style | Usability | Install | Customization | Target users |
| :----- | :----- | :----- | :----- | :----- |
| **Standard** | Very good | Not required | Not possible | For general users |
| **Install** | Very good | Required | Not possible | For frequent users |
| **Customizable** | Fair | Not required | Possible <sup>[*1]</sup> | For experts |

[*1] For example, you can adjust parameters by yourself to get more diverse models,or add models prepared by other methods to perform molecular replacement.

### (1) Standard style
In this style, you simply run one Shell script named "4MRNA.sh" on your computer.

<!--- Tutorial video (YouTube) - in preparation --->

#### Procedure
1. Create a new directory on your computer for executing 4MRNA. After creating it, place your reflection file (.mtz) for molecular replacement into that directory.
 
2. Download "4MRNA.sh" into the directory created in Step 1, either directly from [this URL](https://github.com/S-Ando-Biophysics/4MRNA/releases/latest/download/4MRNA.sh) or via [this website](https://s-ando-biophysics.github.io/4MRNA/).

3. Open Ubuntu/Terminal, change to the directory created in Step 1, and run `bash 4MRNA.sh` or `chmod +x 4MRNA.sh && ./4MRNA.sh`.

4. When 4MRNA finishes, a directory named "4MRNA-Results" will be created, containing up to seven candidate solutions for molecular replacement.

### (2) Install style
In this style, you install the `4MRNA` command on your computer in advance. Unlike Standard style, you do not need to download the Shell script every time. Instead, you can simply type the command `4MRNA` in Ubuntu/Terminal to run it.

<!--- Tutorial video (YouTube) - in preparation --->

#### Procedure
1. Create a new directory on your computer for executing 4MRNA. After creating it, place your reflection file (.mtz) for molecular replacement into that directory.
2. Open Ubuntu/Terminal, change to the directory created in Step 1, and run the command `4MRNA`.
3. When 4MRNA finishes, a directory named "4MRNA-Results" will be created, containing up to seven candidate solutions for molecular replacement.

#### How to install
Run the following commands in order. If the version is displayed by running the final line of code, the installation is complete.

    cd ~
    git clone https://github.com/S-Ando-Biophysics/4MRNA-Install.git
    cd 4MRNA-Install
    chmod +x install.sh
    ./install.sh
    echo 'export PATH="$HOME/4MRNA-Install/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    4MRNA version


### (3) Customizable style
In this style, you obtain some programming codes from the website. Basically, you just run them in the prescribed order, but if needed, you can edit and customize the code. 

Access [this website](https://s-ando-biophysics.github.io/4MRNA/). How to use is described on the website.

<!--- Tutorial video (YouTube) - in preparation --->

#### Procedure (almost the same as on the website)
1. Create a new directory on your computer for executing 4MRNA. After creating it, place your reflection file (.mtz) for molecular replacement into that directory.
 
2. Fill in the table on the website and click "Generate codes (Customizable style)".

3. Click "Download all codes". Then run them in the order indicated by the number at the beginning of each downloaded file.

   | Type | Extension |  How to run |
   | :----- | :----- | :----- |
   | Python | .py | Open the code with a text editor such as VS Code and run them. |
   | Shell | .sh | Run them using the `bash` command in Ubuntu/Terminal. |

4. When 4MRNA finishes, a directory named "4MRNA-Results" will be created, containing up to seven candidate solutions for molecular replacement.

## Preparation  (Latest updated: 2025-08-22)
Please install and set up the following software in advance.

### Common preparations for the three styles

| Name | Remarks |
| :----- | :----- |
| [Ubuntu](https://apps.microsoft.com/search?query=Ubuntu) | Required only for Windows. It is necessary to turn on "Windows Subsystem for Linux (WSL)" and "Virtual Machine Platform" in the Windows settings to be able to use shell scripts. Furthermore, run `sudo apt update` and `sudo apt upgrade` in Ubuntu. |
| [Phaser](https://www.ccp4.ac.uk/download) | The command `phaser` is included in CCP4. If you have not installed CCP4, please install it. <sup>[*2]</sup> |

[*2] The following steps are for Windows (Ubuntu). The procedure for macOS is similar.

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
    echo "source /usr/local/ccp4-9/bin/ccp4.setup-sh" >> ~/.bashrc
    source ~/.bashrc

### Additional preparations for <ins>(1) Standard style</ins>
Launch Ubuntu or Terminal, and run the following commands.

    pip install pandas playwright
    playwright install
    playwright install-deps

### Additional preparations for <ins>(2) Install style</ins>
Launch Ubuntu or Terminal, and run the following commands in order. If the version is displayed by running the final line of code, the installation is complete.

    # Python setup
    pip install pandas playwright
    playwright install
    playwright install-deps 

    # Installation of 4MRNA
    cd ~
    git clone https://github.com/S-Ando-Biophysics/4MRNA-Install.git
    cd 4MRNA-Install
    chmod +x install.sh
    ./install.sh
    echo 'export PATH="$HOME/4MRNA-Install/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    4MRNA version

### Additional preparations for <ins>(3) Customizable style</ins>
Access the [official website](https://www.python.org/downloads/) and install Python. After installation, open Terminal and execute the following command.

    pip install pandas playwright
    playwright install

It is recommended (though not mandatory) to download a text editor such as [Visual Studio Code](https://code.visualstudio.com/Download), which makes it easier to edit or run Python codes.

## About 4MRNA
<!--- [Explanatory video (YouTube)](https://youtu.be/WX_Rh3vtOlg) --->

4MRNA is an abbreviation for “Massive Multi-type Model Molecular Replacement for Nucleic Acids”. This is a novel method designed to enhance molecular replacement (MR) for phasing in X-ray crystallography of nucleic acids.

Applying MR, which is widely used in structure determination (phase determination), to nucleic acids presents unique challenges that are not encountered with proteins. To overcome these issues, we developed an innovative strategy termed 4MRNA.

One major difficulty is that nucleic acids can adopt different 3D structures even with the same sequence. As a result, models existing in the database may not be suitable as search models, and sequence-based structure prediction methods such as AlphaFold are also limited in applicability <sup>[1,2]</sup>. Moreover, it is empirically known that MR of nucleic acids can fail even when the search model and the target structure differ only slightly. <sup>[3]</sup> To address these issues, the new strategy 4MRNA includes creating a large number of diverse search models (= massive multi-type models) and applying them to MR.

We found that by varying three out of the twelve parameters that control the three-dimensional structures of nucleic acids according to different patterns, the resulting set of models included ones that closely matched the correct structure, thereby increasing the success rate of MR.

Building on this strategy, we employed Web 3DNA <sup>[4]</sup>, which is a web application that generates nucleic acid structural models based on parameters, to create a wide variety of models. The processes of parameter adjustment and model creation have been automated using Python. Subsequently, MR is carried out for each of the many created models. Since this operation must be repeated many times, we automated this process using Shell scripts on Linux.

[1] Bernard, C., Postic, G., Ghannay, S., & Tahi, F. (2025). Has AlphaFold3 achieved success for RNA?. _Acta crystallographica. Section D, Structural biology_, _81_(Pt 2), 49–62.

[2] Kwon D. (2025). RNA function follows form - why is it so hard to predict?. _Nature_, _639_(8056), 1106–1108.

[3] Kondo, J., Urzhumtseva, L., & Urzhumtsev, A. (2008). Patterson-guided ab initio analysis of structures with helical symmetry. _Acta crystallographica. Section D, Biological crystallography_, _64_(Pt 10), 1078–1091.

[4] Li, S., Olson, W. K., & Lu, X. J. (2019). Web 3DNA 2.0 for the analysis, visualization, and modeling of 3D nucleic acid structures. _Nucleic acids research_, 47(W1), W26–W34.

## Reference
- in preparation

## Notes 
### Miscellaneous notes
- Standard style of 4MRNA (release): https://github.com/S-Ando-Biophysics/4MRNA/releases/latest

- Install style of 4MRNA (repository): https://github.com/S-Ando-Biophysics/4MRNA-Install

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
  - Three execution styles have been introduced: Standard style, Install style, and Customizable style.  
    - The previous version corresponds to Customizable style.  
    - Standard style and Install style provide simpler ways to run 4MRNA.  
  - The website user interface has been updated to improve usability.
