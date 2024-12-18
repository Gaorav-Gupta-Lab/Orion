var underscore_name = "";
var number_name = "";
var dir = "";
var dest_directory = "";
var previous_nRows = 0;
var active_channels = newArray(4);

//FUNCTION LIST
// run gaussian subtraction on duplicated images
function runGaussianSubtraction(window) {
	selectWindow(window);
	run("Duplicate...", "title=1");
	selectWindow(window);
	run("Duplicate...", "title=2");
	selectWindow("2");
	run("Gaussian Blur...", "sigma=2");
	selectWindow("1");
	run("Gaussian Blur...", "sigma=1");
	imageCalculator("Subtract create", "1","2");
	selectWindow(window);
	close();
	selectWindow("1");
	close();
	selectWindow("2");
	close();
}

// rename image window
function renameWindow(old_name, new_name){
	selectWindow(old_name);
	rename(new_name);
}

function lastCharacterNumeric(str) {
    if (lengthOf(str) == 0) return false;  // Handle empty string
    
    code = charCodeAt(str, lengthOf(str) - 1);  // Get ASCII of last character
    return (code >= 48 && code <= 57);  // Check if it's a number (0-9)
}

// truncate file_name using specified delimiter
function truncate(name, delimiter){
	if (delimiter == ".") {
		return substring(name, 0, indexOf(name, "."));
	}
	if (delimiter == "_") {
		return substring(name, 0, lastIndexOf(name, "_") + 1);
	} else {
	return name;
	}
}

// generate binary mask using threshold (necessary?)
function generateMaximaMask(i){
	// I think this might be what is acting up when running on entire directory
	setAutoThreshold("Default dark");
	setThreshold(i, 65535, "raw");
	setOption("BlackBackground", true);
	run("Convert to Mask");
}

// set processing size for image (8- or 16-bit)
function setProcessingSize(){
	Dialog.create("Choose an Option");
	Dialog.addChoice("Processing size:", newArray("8-bit", "16-bit"));
	Dialog.show();
	return Dialog.getChoice();
}

// set number of images to process at a time when using MaskDirectory macro
function setBatchSize(){
	Dialog.create("Choose Image Batch Size");
	Dialog.addNumber("Batch Size", 20);
	Dialog.show();
	return Dialog.getNumber();
}

function setMaskThreshold(target){
	Dialog.create("Choose threshold for " + target + " processing");
	Dialog.addNumber("Threshold", 50);
	Dialog.show();
	return Dialog.getNumber();
}

// confirmation to ensure that the final results table includes the necessary measurements
function confirmStartup(){
	Dialog.create("Before Running...");
	Dialog.addMessage("It is highly recommended to process a single image separately before running the macro.\n" +
	"Ensure the measurements table includes RawIntDen.\n" +
	"DO NOT save the image in the same directory at the end of processing in order to keep the directory clean for MaskDirectory macro.\n" +
	"Proceed?");
	Dialog.show();
}

function setChannels(){
	Dialog.create("Channel selection");

	Dialog.addMessage("Select Imaged Channels");
	// Add checkboxes with labels
	Dialog.addCheckbox("Halo", true);
	Dialog.addCheckbox("RAD51", false);
	Dialog.addCheckbox("Edu", false);
	Dialog.addCheckbox("DAPI", true);
	
	// Show the dialog and capture the user's response
	Dialog.show();
	
	// Retrieve the values of the checkboxes
	halo_active = Dialog.getCheckbox();
	rad51_active = Dialog.getCheckbox();
	edu_active = Dialog.getCheckbox();
	dapi_active = Dialog.getCheckbox();
	
	if (!dapi_active) {
		exit("DAPI channel required for macro, quitting...");
	}
	return newArray(halo_active, rad51_active, edu_active);
}

//MACROS
macro "CloseAll [F9]"{
	close("*");
	run("Close All");
}

// For masking individual images one at a time
macro "MaskSingleImageW/Channels"{
	confirmStartup();
	file_path = File.openDialog("Choose Image");
	dir = File.getDirectory(file_path);
	
	file_name = File.getName(file_path);
	
	underscore_name = truncate(file_name, "_", 1);
	number_name = truncate(file_name, ".", 0);
	print(number_name);
	if(!lastCharacterNumeric(number_name)){
		print("Not numeric" + number_name);
		number_name = number_name + "9";
	}
	if(lastCharacterNumeric(number_name){
		print("Numeric" + number_name);
	}
	dest_directory = dir + number_name + "/";
	File.makeDirectory(dir + number_name);
	
	active_channels = setChannels();
	halo_active = active_channels[0];
	rad51_active = active_channels[1];
	edu_active = active_channels[2];
	
	processing_size = setProcessingSize();
	thresh = setMaskThreshold();
	
	
	open(file_path);
	run(processing_size);
	
	source_file = dir + file_name;
	dest_file = dest_directory + file_name;			
	file_renamed = File.rename(source_file, dest_file);
	
	run("Stack to Images");
	
	// rename windows for readability
	if(!edu_active && !rad51_active){
		renameWindow(underscore_name + "-0001", number_name + "-Halo");
		renameWindow(underscore_name + "-0002", number_name + "-DAPI");
	}
	
	else if(edu_active && !rad51_active){
		renameWindow(underscore_name + "-0001", number_name + "-Halo");
		renameWindow(underscore_name + "-0002", number_name + "-Edu");
		renameWindow(underscore_name + "-0003", number_name + "-DAPI");
	}
	
	else if (!edu_active && rad51_active) {
		renameWindow(underscore_name + "-0001", number_name + "-Halo");
		renameWindow(underscore_name + "-0002", number_name + "-RAD51");
		renameWindow(underscore_name + "-0003", number_name + "-DAPI");
	}
	
	else if (edu_active && rad51_active) {
		renameWindow(underscore_name + "-0001", number_name + "-DAPI");
		renameWindow(underscore_name + "-0002", number_name + "-Edu");
		renameWindow(underscore_name + "-0003", number_name + "-Halo");
		renameWindow(underscore_name + "-0004", number_name + "-RAD51");
	}
	
	runGaussianSubtraction(number_name + "-Halo");
	// before thresholding, save result of gaussian subtraction
	selectWindow("Result of 1");
	saveAs("Tiff", dest_directory + number_name + "_halo_pre_threshold");
	
	generateMaximaMask(thresh);
	
	saveAs("Tiff", dest_directory + number_name + "_halo_post_threshold");
	
	if(rad51_active){
		runGaussianSubtraction(number_name + "-RAD51");
		selectWindow("Result of 1");
		saveAs("Tiff", dest_directory + number_name + "_rad51_pre_threshold");
		
		generateMaximaMask(thresh);
		
		saveAs("Tiff", dest_directory + number_name + "_rad51_post_threshold");
	}
	
	selectWindow(number_name + "-DAPI");
	resetMinAndMax();
	setAutoThreshold("Default dark");
}

// for masking an entire directory at once, only images can be in the selected directory for it to work
macro "MaskDirectoryW/Channels" {
	confirmStartup();
    dir = getDirectory("Choose a Directory");
    list = getFileList(dir);

	active_channels = setChannels();
	halo_active = active_channels[0];
	rad51_active = active_channels[1];
	edu_active = active_channels[2];

    processing_size = setProcessingSize();
    images_per_batch = setBatchSize();
    halo_thresh = setMaskThreshold("halo");
    if (rad51_active) {
    	rad51_thresh = setMaskThreshold("rad51");
    }
	current_batch_count = 0;
	current_batch_loop = 1;
	total_batch_loops = round(list.length / images_per_batch);

    for (i = 0; i < list.length; i++) {
        file_path = dir + list[i];
        file_name = File.getName(file_path);

		if(File.isDirectory(file_path)){
			continue;
		}

        underscore_name = truncate(file_name, "_");
        number_name = truncate(file_name, ".");
        dest_directory = dir + number_name + "/";
        File.makeDirectory(dir + number_name);
        
        open(file_path);
        run(processing_size);
        
        source_file = dir + file_name;
        dest_file = dest_directory + file_name;
        file_renamed = File.rename(source_file, dest_file);
        
        if (!file_renamed) {
            print("File not successfully renamed");
        }

        run("Stack to Images");
		if(!edu_active && !rad51_active){
		renameWindow(underscore_name + "-0001", number_name + "-Halo");
		renameWindow(underscore_name + "-0002", number_name + "-DAPI");
		}
		
		else if(edu_active && !rad51_active){
			renameWindow(underscore_name + "-0001", number_name + "-Halo");
			renameWindow(underscore_name + "-0002", number_name + "-Edu");
			renameWindow(underscore_name + "-0003", number_name + "-DAPI");
		}
		
		else if (!edu_active && rad51_active) {
			renameWindow(underscore_name + "-0001", number_name + "-Halo");
			renameWindow(underscore_name + "-0002", number_name + "-RAD51");
			renameWindow(underscore_name + "-0003", number_name + "-DAPI");
		}
		
		else if (edu_active && rad51_active) {
			renameWindow(underscore_name + "-0001", number_name + "-DAPI");
			renameWindow(underscore_name + "-0002", number_name + "-Edu");
			renameWindow(underscore_name + "-0003", number_name + "-Halo");
			renameWindow(underscore_name + "-0004", number_name + "-RAD51");
		}
        
        runGaussianSubtraction(number_name + "-Halo");

        selectWindow("Result of 1");
        saveAs("Tiff", dest_directory + number_name + "_halo_pre_threshold");

        generateMaximaMask(halo_thresh);
        
        saveAs("Tiff", dest_directory + number_name + "_halo_post_threshold");
        
        if(rad51_active){
			runGaussianSubtraction(number_name + "-RAD51");
			selectWindow("Result of 1");
			saveAs("Tiff", dest_directory + number_name + "_rad51_pre_threshold");
			
			generateMaximaMask(rad51_thresh);
			
			saveAs("Tiff", dest_directory + number_name + "_rad51_post_threshold");
		}

        
        selectWindow(number_name + "-DAPI");
        resetMinAndMax();
        setAutoThreshold("Default dark");
        
        current_batch_count++;

        if (current_batch_count == images_per_batch) {
    		run("Tile");
    		run("Threshold...");
            waitForUser("Currently on batch: " + current_batch_loop + " out of " + total_batch_loops + "\nClick OK to continue with the next batch.");
		    current_batch_loop++;
            current_batch_count = 0;
        }
    }
    run("Tile");
    run("Threshold...");
}


macro "CountFoci [F3]" {
	current_window = getTitle();
	dash_index = lastIndexOf(current_window, "-");
	number_name = substring(current_window, 0, dash_index);
	dest_directory = dir + number_name + "/";
	
	halo_active = active_channels[0];
	rad51_active = active_channels[1];
	edu_active = active_channels[2];
	
	run("Analyze Particles...", "size=200-Infinity show=Outlines exclude include overlay add");
	close();
	saveAs("Tiff", dest_directory + number_name + "_nucleiROI");
	close();
	 
	// count halo foci
	selectWindow(number_name + "_halo_post_threshold.tif");
	run("From ROI Manager");
	run("Find Maxima...", "prominence=10 strict exclude output=[Single Points]");
	roiManager("Show All without labels");
	rename("Current Maxima" + number_name);
	roiManager("Measure");
	
	selectWindow(number_name + "_halo_post_threshold.tif");
	close();
	selectWindow("Current Maxima" + number_name);
	close();
	
	nRows = nResults;
	for (i = 0; i < nRows; i++) {
	    raw_intensity = getResult("RawIntDen", i);
	    foci_count = round(raw_intensity / 255);
	    setResult("NumFoci_Halo", i, foci_count);
	}
	
	updateResults();
	saveAs("Results", dest_directory + number_name + "_halo_results.csv");
	close("Results");

	
	// count RAD51 foci
	if (rad51_active) {
		selectWindow(number_name + "_rad51_post_threshold.tif");
		run("From ROI Manager");
		run("Find Maxima...", "prominence=10 strict exclude output=[Single Points]");
		roiManager("Show All without labels");
		rename("Current Maxima" + number_name);
		roiManager("Measure");
		
		selectWindow(number_name + "_rad51_post_threshold.tif");
		close();
		selectWindow("Current Maxima" + number_name);
		close();
	}
	
	nRows = nResults;
	for (i = 0; i < nRows; i++) {
	    raw_intensity = getResult("RawIntDen", i);
	    foci_count = round(raw_intensity / 255);
	    setResult("NumFoci_RAD51", i, foci_count);
	}

	
	updateResults();
	saveAs("Results", dest_directory + number_name + "_rad51_results.csv");
	close("Results");
	
	// count edu positive cells
	if(edu_active){
		selectWindow(number_name + "-Edu");
		resetMinAndMax();
		// run("Auto Threshold", "method=Minimum white");
		setAutoThreshold("Minimum dark no-reset");
		run("Convert to Mask");
	
		run("From ROI Manager");
		roiManager("measure");
		selectWindow(number_name + "-Edu");
		close();
	}
	nRows = nResults;
	for (i = 0; i < nRows; i++) {
	    raw_intensity = getResult("RawIntDen", i);
	    above_threshold = raw_intensity > 1;
	    setResult("EduPos", i, above_threshold);
	}

	saveAs("Results", dest_directory + number_name + "_edu_results.csv");
	
	if (isOpen("Results")) {
		close("Results");
	}
	if (isOpen("ROI Manager")){
		close("ROI Manager");
	}
}

macro "RunThresholdTest" {
	file_path = File.openDialog("Choose Image");
	dir = File.getDirectory(file_path);
	
	file_name = File.getName(file_path);
	
	underscore_name = truncate(file_name, "_", 1);
	number_name = truncate(file_name, ".", 0);
	dest_directory = dir + number_name + "/";
	File.makeDirectory(dir + number_name);
	
	open(file_path);
	run("16-bit");
	
	source_file = dir + file_name;
	dest_file = dest_directory + file_name;			
	file_renamed = File.rename(source_file, dest_file);
	
	run("Stack to Images");
	
	renameWindow(underscore_name + "-0001", number_name + "-Halo");
	renameWindow(underscore_name + "-0002", number_name + "-DAPI");
	
	runGaussianSubtraction(number_name + "-Halo");

	selectWindow("Result of 1");
	saveAs("Tiff", dest_directory + number_name + "_pre_threshold");
	for (i = 10; i <= 100; i+=10) {
		selectWindow(number_name + "_pre_threshold.tif");
		run("Duplicate...", "title=dupe");
		generateMaximaMask(i);
		saveAs("Tiff", dest_directory + number_name + "_post_threshold" + i);
	}
	selectWindow(number_name + "-DAPI");
	resetMinAndMax();
	setAutoThreshold("Default dark");
	
	run("Analyze Particles...", "size=200-Infinity show=Outlines exclude include overlay add");
	close();
	saveAs("Tiff", dest_directory + number_name + "_nucleiROI");
	close();
	for (i = 10; i <= 100; i+=10) {
		selectWindow(number_name + "_post_threshold" + i + ".tif");
		run("From ROI Manager");
		run("Find Maxima...", "prominence=10 strict exclude output=[Single Points]");
		roiManager("Show All without labels");
		rename("Current Maxima" + number_name);
		roiManager("Measure");
		selectWindow(number_name + "_post_threshold" + i + ".tif");
		close();
		selectWindow("Current Maxima" + number_name);
		close();
		
		current_nRows = nResults; // Get number of rows in Results table
    	for (r = previous_nRows; r < current_nRows; r++) {
        	setResult("Threshold", r, i);
	        raw_intensity = getResult("RawIntDen", r);
	        foci_count = raw_intensity / 255;
	        setResult("NumFoci", r, foci_count);
	    }
	    updateResults();
	    previous_nRows = current_nRows;
	}
	
	selectWindow(number_name + "_pre_threshold.tif");
	close();
	
	saveAs("Results", dest_directory + number_name + "_halo_results.csv");
	if (isOpen("Results")) {
		close("Results");
	}
	if (isOpen("ROI Manager")){
		close("ROI Manager");
	}
}	
	
