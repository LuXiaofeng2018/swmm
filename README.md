The MATLAB script was created to auto-calibrate SWMM.

The first step is to install Python2.7 and swmmtoolbox to windows-based 
computer (Python can be downloaded from the website:
https://pypi.python.org/pypi?%3Aaction=search&term=swmm&submit=search.)

To excecute this procedure, there are five necessary components: 
(1) study site topography information, (2) in-situ observations, (3) initial
parameter ranges derived from peer-reviewed literature, (4) Python code 
to extract simulation data from SWMM "*.out" file (can be download from
website https://pypi.python.org/pypi?%3Aaction=search&term=swmm&submit=search), 
and (5) SWMM command line tools for use in parallel computing applications. 

In this script ("Auto_calibration_demo_code.m", MATLAB was used as a tool 
to bring all these information together. Users need to write MATLAB code 
to generate SWMM "*.inp" files with different parameter values, then forces 
SWMM to execute with "*.inp" files and generate "*.out" and "*.rpt" files.  
Then user-specified MATLAB code forces Python to extract simulation results 
(e.g., inflow discharges in this script) from "*.out" files and compares with 
in-situ observations.

The script was only used for academic research. 

Author: Jing Wang
Email: jwang1@umd.edu
