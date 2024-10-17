function calc_percentile(percentile, n_bins) {
	//percentile function
	//Deselect ROI
	run("Select None");
	
	//Make duplicate
	run("Duplicate...", "title=duplicate");
	selectWindow("duplicate");
	
	//Denoise
	run("Median...", "radius=2");
	
	getHistogram(values, counts, n_bins);
	bound = getHeight() * getWidth() * (percentile / 100);
	n_pixels = 0;
	for (i=0; i<n_bins - 1; ++i) {
		n_pixels += counts[i];
		if (n_pixels >= bound) {
			break;
		}
	};
	close("duplicate");
	return values[i];
}

function param_dialog() {
	//open dialog box, request params
	
	title = "Synchprocess parameters";
	Dialog.create("Synchprocess parameters");

	Dialog.addMessage("Select input file(s)", 14)
	Dialog.addMessage("Put in a directory of images if you want to run the macro on all images\nin the directory, for single images use the Image file option.");
	//ask for in_dir
	Dialog.addDirectory("Images directory", "");
	//or ask for in_file
	Dialog.addFile("Image file", "");
	
	//output dir
	Dialog.addMessage("Select output directory", 14)
	Dialog.addDirectory("Output directory", "")
	
	Dialog.addMessage("Parameters", 14)
	//choice between absolute or percentile boundaries
	Dialog.addChoice("Bound type", newArray("Percentile", "Absolute"), "Percentile");
	//ask for multiplier
	Dialog.addNumber("Pixel value multiplier", 1000000);
	//checkbox for colorscale
	Dialog.addCheckbox("Add color legend", true);
	//request LUT lower and upper percentile
	Dialog.addNumber("LUT lower bound", 20);
	Dialog.addNumber("LUT upper bound", 99.9);
	//checkbox for scalebar
	Dialog.addCheckbox("Add size bar", true)
	//request pixel size
	Dialog.addNumber("Scale (um/pixel)", 0);
	Dialog.addNumber("Scalebar width", 10); 
	//request multipliers
	Dialog.addMessage("If you add the scalebar or color legend, the macro will add black padding\nto the height and width of the image. These parameters control how much\npadding gets added (0.2 equals 20% of the original image)");
	Dialog.addNumber("Width padding", 0.2);
	Dialog.addNumber("Height padding", 0.2);
	Dialog.show();

	//readout params
	in_dir = Dialog.getString();
	in_file = Dialog.getString();
	out_dir = Dialog.getString();
	bound_type = Dialog.getChoice();
	pixel_mult = Dialog.getNumber();
	lower_bound = Dialog.getNumber();
	upper_bound = Dialog.getNumber();
	pixel_scale = Dialog.getNumber();
	color_scale = Dialog.getCheckbox();
	size_scale = Dialog.getCheckbox();
	scalebar_size = Dialog.getNumber();
	width_pad = Dialog.getNumber();
	height_pad = Dialog.getNumber();

	return newArray(bound_type, lower_bound, upper_bound, pixel_scale, color_scale, size_scale, scalebar_size, pixel_mult, in_dir, in_file, out_dir, width_pad, height_pad);
}


function process_image(filename, out_dir, bound_type, lower_bound, upper_bound, scale, add_colorbar, add_scalebar, scalebar_size, pixel_mult, width_pad, height_pad) {
	//worker function for one image
	
	//open file
	open(filename);

	//mult values
	run("Multiply...", "value=&pixel_mult");

	//set image scale
	run("Set Scale...", "distance=1 known=&scale unit=micron");
	
	//params
	bincount = 256;
	
	//set cmap
	run("Fire");

	//calculate cutoffs
	if (bound_type == "Percentile") {
		lower_val = calc_percentile(lower_bound, bincount);
		upper_val = calc_percentile(upper_bound, bincount);
		
		//set min and max for cmap lookuptable
		setMinAndMax(lower_val, upper_val);
	} else if (bound_type == "Absolute") {
		setMinAndMax(lower_bound, upper_bound);
	}
	
	//check size
	old_width = getWidth();
	old_height = getHeight();
	//resize if too small for legend
	if (old_width <= 500 || old_height <= 500) {
		limiter = Math.min(old_width, old_height);
		scale_mult = 500 / limiter;
		run("Scale...", "x=&scale_mult y=&scale_mult interpolation=None average create");
		old_width = getWidth();
		old_height = getHeight();
	} else {
		scale_mult = 1;
	}

	//resize image to add legend space
	if (add_colorbar) {
		new_width = old_width + old_width * width_pad;
	} else {
		new_width = old_width;
	}
	if (add_scalebar) {
		new_height = old_height + old_height  * height_pad;
	} else {
		new_height = old_height;
	}
	if (add_scalebar || add_colorbar) {
		run("Canvas Size...", "width=&new_width height=&new_height position=Top-Left zero"); 
	}
	
	//add color bar
	cbar_zoom = (old_width + old_height) / 1000;
	font_size_cb = 12;
	if (add_colorbar) {
		run("Calibration Bar...", "location=[Upper Right] fill=None label=White number=5 decimal=-2 font=&font_size_cb zoom=&cbar_zoom bold overlay");
	}

	//Add scale bar
	if (add_scalebar) {
		font_size_sb = floor(cbar_zoom * font_size_cb);
		run("Scale Bar...", "width=&scalebar_size font=&font_size_sb horizontal bold overlay");
	}
	
	//write out image
	saveAs("png", out_dir + File.separator + File.getNameWithoutExtension(filename));

	//close image windows
	close("*");
}


function main() {
	//process loop
	//obtain parameters
	params = param_dialog();
	setBatchMode(true);
	if (params[8] != "") {
		filenames = getFileList(params[8]);
		files = newArray(filenames.length);
		for (i = 0; i <  filenames.length; ++i) {
			files[i] = params[8] + File.separator + filenames[i];
		}
	} else if (params[9] != "") {
		files = newArray(1);
		files[1] = params[9];
	} else {
		exit("No valid input files found")
	}

	//process files in input directory
	for (i = 0; i < files.length; ++i) {
		if (endsWith(files[i], ".tif") || endsWith(files[i], ".tiff")) {
			process_image(files[i], params[10], params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[11], params[12]);
		}
	}
	setBatchMode(false);
}

main();