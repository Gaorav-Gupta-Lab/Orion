# ORION - Foci Counting and Analysis System
### ORIONco <i>(ORIONcompanion)</i> is a Python-based tool designed to gather and combine CSV files generated from FIJI's ORION macro suite. The application helps streamline and automate the process of analyzing data from multiple directories where foci counting results are stored.
---
### Features
- Collects CSV files from different directories that share the same file names.
- Automatically checks directories and files to ensure the proper structure.
- Prompts the user with confirmation dialogs before executing actions to avoid accidental overwrites or errors.
- Designed to work in tandem with the ORION macro suite for FIJI, making data gathering and analysis from foci images more efficient.

## Requirements
### Python Dependencies
- pathlib
- pandas
- re
- tkinter
- datetime
- shutil

### FIJI and ORION Macro Suite
FIJI (ImageJ) must be installed.<br>
The ORION macro suite should be configured and used within FIJI to generate the necessary CSV files containing foci counting data.

## Usage
<strong>Step 1: Generate CSV Files with FIJI ORION Macro Suite</strong><br>
Use the ORION macro suite within FIJI to count foci in your image sets.<br>
Ensure there are only image files in the directory if MaskDirectory is to be used.<br>
The CountFoci macro will generate CSV files containing the foci counting data for each image. Macro suite currently only works on .ome.tif files, it will not work with .tif files.<br>

<strong>Step 2: Organize Your Directories</strong><br>
Make sure that the CSV files generated by FIJI's ORION macro are stored in separate directories, with each directory containing: 
- original image file
- pre- and post-threshold images
- nucleiROI image
- results.csv file.

<strong>Step 3: Run ORIONco Python Script</strong><br>
The script will prompt you to select directories that contain the CSV files.<br>
After selecting, it will validate the directories and confirm if the files are ready to be combined.
Once confirmed, the script will merge the CSV files and output the combined data.
The script will output a CombinedResults directory containing CSV files with data from the selected directory, grouping samples with the same name into the same csvs.

---
### Contributing
If you would like to contribute to this project, feel free to open an issue or submit a pull request. All suggestions and improvements are welcome.

### License
This project is licensed under the MIT License - see the LICENSE file for details.

### Contact
For any inquiries, you can reach out to the developer at: pguerra@unc.edu
