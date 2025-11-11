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

	Dialog.addHelp("https://github.com/Chizz98/Synchrotron_macros/tree/main")
	Dialog.addMessage("Select input file(s)", 14);
	Dialog.addMessage("Put in a directory of images if you want to run the macro on all images\nin the directory, for single images use the Image file option.");
	//ask for in_dir
	Dialog.addDirectory("Images directory", "");
	//or ask for in_file
	Dialog.addFile("Image file", "");
	
	//output dir
	Dialog.addMessage("Select output directory", 14);
	Dialog.addDirectory("Output directory", "")
	
	Dialog.addMessage("Parameters", 14);
	Dialog.addMessage("Output units", 13);
	//ask for multiplier DEPRECATED, SET TO CONVERT TO MICROGRAM BY DEFAULT
	//Dialog.addNumber("Pixel value multiplier", 1000000);
	//ask for output unit
	Dialog.addChoice("Legend units", newArray("microgram/cm2", "microgram/gram", "microgram/gram (tomography)"), "microgram/gram");
	//ask for sample thickness
	Dialog.addNumber("Sample thickness (micron)", 300);
	//ask for sample density
	Dialog.addNumber("Sample density (g/cm3)", 0.8);
	
	Dialog.addMessage("False color boundary settings", 13);
	//choice between absolute or percentile boundaries
	Dialog.addChoice("Bound type", newArray("Percentile", "Absolute"), "Percentile");
	//request LUT lower and upper percentile
	Dialog.addNumber("LUT lower bound", 20);
	Dialog.addNumber("LUT upper bound", 99.9);

	Dialog.addMessage("Legend settings", 13);
	//checkbox for colorscale
	Dialog.addCheckbox("Add color legend", true);
	Dialog.addNumber("Decimal places (-2 for automatic formatting)", 0)

	//checkbox for scalebar
	Dialog.addCheckbox("Add size bar", true);

	Dialog.addMessage("Set pixel size and units for scalebar sizing.", 11);
	//request pixel size
	Dialog.addString("Unit", "millimeter");
	Dialog.addNumber("Units per pixel", 0);
	Dialog.addNumber("Scalebar width", 5); 
	//request multipliers
	Dialog.addMessage("If you add the scalebar or color legend, the macro will add black padding\nto the height and width of the image. These parameters control how much\npadding gets added (0.2 equals 20% of the original image)", 11);
	Dialog.addNumber("Width padding", 0.2);
	Dialog.addNumber("Height padding", 0.2);
	Dialog.show();

	//readout params
	in_dir = Dialog.getString();
	in_file = Dialog.getString();
	out_dir = Dialog.getString();
	pixel_mult = 1000000;
	output_units = Dialog.getChoice();
	sample_thickness = Dialog.getNumber();
	sample_density = Dialog.getNumber();
	bound_type = Dialog.getChoice();
	lower_bound = Dialog.getNumber();
	upper_bound = Dialog.getNumber();
	color_scale = Dialog.getCheckbox();
	scale_decimals = Dialog.getNumber();
	size_scale = Dialog.getCheckbox();
	scale_unit = Dialog.getString();
	pixel_scale = Dialog.getNumber();
	scalebar_size = Dialog.getNumber();
	width_pad = Dialog.getNumber();
	height_pad = Dialog.getNumber();

	return newArray(bound_type, lower_bound, upper_bound, pixel_scale, color_scale, size_scale, scalebar_size, pixel_mult, in_dir, in_file, out_dir, width_pad, height_pad, scale_unit, output_units, sample_thickness, sample_density, scale_decimals);
}


function process_image(filename, out_dir, bound_type, lower_bound, upper_bound, scale, add_colorbar, add_scalebar, scalebar_size, pixel_mult, width_pad, height_pad, scale_unit, output_units, sample_thickness, sample_density, scale_decimals) {
	//worker function for one image
	
	//open file
	open(filename);

	//mult values
	run("Multiply...", "value=&pixel_mult");

	//unit conversion logic
	if (output_units == "microgram/gram") {
		thickness_cm = sample_thickness * 1e-4;
		pixel_unit_mult = 1 / (sample_density * thickness_cm);
		run("Multiply...", "value=&pixel_unit_mult");
	} else if (output_units == "microgram/gram (tomography)") {
		print("tomo_test");
		pixel_unit_mult = 1 / sample_density;
	}
	
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

	//set image scale
	run("Set Scale...", "distance=scale_mult known=&scale unit=&scale_unit");

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
		run("Calibration Bar...", "location=[Upper Right] fill=None label=White number=5 decimal=&scale_decimals font=&font_size_cb zoom=&cbar_zoom bold overlay");
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
		exit("No valid input files found");
	}

	if (!File.exists(params[10])) {
		 File.makeDirectory(params[10]);
	}
	
	//process files in input directory
	for (i = 0; i < files.length; ++i) {
		if (endsWith(files[i], ".tif") || endsWith(files[i], ".tiff")) {
			process_image(files[i], params[10], params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[11], params[12], params[13], params[14], params[15], params[16], params[17]);
		}
	}
	setBatchMode(false);
}

main();