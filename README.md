# 4MRNA

**4MRNA** = <ins>**M**</ins>assive <ins>**M**</ins>ulti-type <ins>**M**</ins>odel <ins>**M**</ins>olecular <ins>**R**</ins>eplacement for <ins>**N**</ins>ucleic <ins>**A**</ins>cids &ensp;[[About 4MRNA](https://github.com/S-Ando-Biophysics/4MRNA?tab=readme-ov-file#about-4mrna)]

### [Official website](https://sites.google.com/view/sa-4mrna)
### [User manual](https://cdn.jsdelivr.net/gh/S-Ando-Biophysics/4MRNA@main/Docs/4MRNA-Manual.pdf) (Latest updated: 2025-09-11)

<br>

## Instructions
There are two modes to execute 4MRNA.

| Style | Usability | Customization | Target users |
| :----- | :----- | :----- | :----- |
| **Default** | Very good | Not possible | For general users |
| **Customize** | Fair | Possible <sup>[*]</sup> | For experts |

[*] For example, you can adjust parameters by yourself to get more diverse models,or add models prepared by other methods to perform molecular replacement.

### Procedure (Default mode)
1. Create a new directory on your computer for executing 4MRNA. After creating it, place your reflection file (.mtz) for molecular replacement into that directory.
2. Open Ubuntu/Terminal, change to the directory created in Step 1, and run the command `4MRNA`.
3. When prompted to choose the execution mode, select "default".
4. When 4MRNA finishes, a directory named "4MRNA-Results" will be created, containing up to seven candidate solutions for molecular replacement.

### Procedure (Customize mode)
1. Create a new directory on your computer for executing 4MRNA. After creating it, place your reflection file (.mtz) for molecular replacement into that directory.
2. Open Ubuntu/Terminal, change to the directory created in Step 1, and run the command `4MRNA`.
3. When prompted to choose the execution mode, select "customize".
4. You can edit each downloaded code.
5. Please run the edited scripts with the `bash` command on Ubuntu/Terminal in the order indicated by the number at the beginning of each file.
6. When 4MRNA finishes, a directory named "4MRNA-Results" will be created, containing up to seven candidate solutions for molecular replacement.

### How to install

    cd ~
    git clone https://github.com/S-Ando-Biophysics/4MRNA-Install.git
    cd 4MRNA-Install
    chmod +x install.sh
    ./install.sh
    echo 'export PATH="$HOME/4MRNA-Install/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc

### Additional preparation
In addition, please install and set up the following external software in advance.

| Name | Remarks |
| :----- | :----- |
| [Ubuntu](https://apps.microsoft.com/search?query=Ubuntu) | Required only for Windows. It is necessary to turn on "Windows Subsystem for Linux (WSL)" and "Virtual Machine Platform" in the Windows settings to be able to use shell scripts. Furthermore, run `sudo apt update` and `sudo apt upgrade` in Ubuntu. |
| [3DNA](http://forum.x3dna.org/site-announcements/download-instructions/) | Please download and install 3DNA from the official website. |
| [Phaser](https://www.ccp4.ac.uk/download) | The command `phaser` is included in CCP4. If you have not installed CCP4, please install it. |

#### 3DNA
The following steps are for Windows (WSL, Ubuntu). The procedure for macOS and Linux is similar.

    # Please change the directory name and 3DNA version as appropriate.
    # Assume that "x3dna-v2.4-linux-64bit.tar.gz" has been downloaded to "C:\Users\name\Downloads".
    sudo apt update
    sudo apt install ruby
    sudo su
    cd /usr/local
    mv /mnt/c/Users/name/Downloads/x3dna-v2.4-linux-64bit.tar.gz .
    tar pzxvf x3dna-v2.4-linux-64bit.tar.gz
    cd x3dna-v2.4/bin
    ./x3dna_setup
    exit
    echo "export X3DNA=/usr/local/x3dna-v2.4" >> ~/.bashrc
    echo "export PATH=$X3DNA/bin:$PATH" >> ~/.bashrc
    source ~/.bashrc

#### Phaser
The following steps are for Windows (WSL, Ubuntu). The procedure for macOS and Linux is similar.

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

## About 4MRNA
<!--- [Explanatory video (YouTube)](https://youtu.be/WX_Rh3vtOlg) --->

- 4MRNA is an abbreviation for “Massive Multi-type Model Molecular Replacement for Nucleic Acids”. This is a novel method designed to enhance molecular replacement (MR) for phasing in X-ray crystallography of nucleic acids.

- Applying MR, which is widely used in structure determination (phase determination), to nucleic acids presents unique challenges that are not encountered with proteins. To overcome these issues, we developed an innovative strategy termed 4MRNA.

- One major difficulty is that nucleic acids can adopt different 3D structures even with the same sequence. As a result, models existing in the database may not be suitable as search models, and sequence-based structure prediction methods such as AlphaFold are also limited in applicability <sup>[1,2]</sup>. Moreover, it is empirically known that MR of nucleic acids can fail even when the search model and the target structure differ only slightly. <sup>[3]</sup> To address these issues, the new strategy 4MRNA includes creating a large number of diverse search models (= massive multi-type models) and applying them to MR.

- We found that by varying three out of the twelve parameters that control the three-dimensional structures of nucleic acids according to different patterns, the resulting set of models included ones that closely matched the correct structure, thereby increasing the success rate of MR.

- Building on this strategy, we employed 3DNA <sup>[4]</sup>, which is a software that generates nucleic acid structural models based on parameters, to create a wide variety of models. The processes of parameter adjustment and model creation have been automated using Shell scripts. Subsequently, MR is carried out for each of the many created models. Since this operation must be repeated many times, we also automated this process using Shell scripts.

[1] Bernard, C., Postic, G., Ghannay, S., & Tahi, F. (2025). Has AlphaFold3 achieved success for RNA?. _Acta crystallographica. Section D, Structural biology_, _81_(Pt 2), 49–62.

[2] Kwon D. (2025). RNA function follows form - why is it so hard to predict?. _Nature_, _639_(8056), 1106–1108.

[3] Kondo, J., Urzhumtseva, L., & Urzhumtsev, A. (2008). Patterson-guided ab initio analysis of structures with helical symmetry. _Acta crystallographica. Section D, Biological crystallography_, _64_(Pt 10), 1078–1091.

[4] Lu, X. J., & Olson, W. K. (2008). 3DNA: a versatile, integrated software system for the analysis, rebuilding and visualization of three-dimensional nucleic-acid structures. _Nature protocols_, _3_(7), 1213–1227.


## Reference
- in preparation

## Bug Report Form
If you find a bug, please let me know using [this form](https://forms.gle/Hx2tvWkXbstV8JEUA).

## Notes
### Supported environment
- **Operating system**: Windows (Windows Subsystem for Linux; WSL), macOS, Linux (Rocky Linux)

### License information
- 4MRNA itself is distributed under the [MIT License](./LICENSE).
<!--- - However, the logo files included in the "[Icons](./Icons)" directory are copyright © 2025 [みかん快速 (Mikan Kaisoku)](https://potofu.me/0range2000). They are <ins>**not**</ins> covered by the MIT License. Do not use, modify, reproduce, or redistribute these logo files beyond private purposes without explicit permission from the copyright holder.--->
- However, please comply with the licenses of the external resources and libraries. A summary of these dependencies is provided in "[DEPENDENCIES.txt](./DEPENDENCIES.txt)".

### Miscellaneous notes
- Install style of 4MRNA (repository): https://github.com/S-Ando-Biophysics/4MRNA-Install

- The calculation of "No. of AU" (the number of molecules in the asymmetric unit) is done using the Matthews coefficient etc. Please refer to the [other repository](https://github.com/S-Ando-Biophysics/Cal-Nm) and [calculator website](https://s-ando-biophysics.github.io/Cal-Nm/).

### Changelog
- **2025-07-08**  The beta version (v0.0) has been released.

- **2025-08-01** The official version (v1.0) has been released.

- **2025-08-18** Minor Update (v1.1)
  - The Shelle scripts have been revised, enabling smoother use of 4MRNA.

- **2025-08-22** Minor Update (v1.2)
  - The stability of the Python codes have been enhanced.  
  - The processing speed of the Python codes have been improved.  
  - Three execution styles have been introduced: Standard style, Install style, and Customizable style.  
    - The previous version corresponds to Customizable style.  
    - Standard style and Install style provide simpler ways to run 4MRNA.  
  - The website user interface has been updated to improve usability.

- **2026-03-12** Major Update (v2.0)

