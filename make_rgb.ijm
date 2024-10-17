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
	title = "RGB generator parameters";
	Dialog.create(title);

	//get files
	Dialog.addFile("Red", ".");
	//choice between absolute or percentile boundaries
	Dialog.addChoice("Bound type", newArray("Percentile", "Absolute"), "Percentile");
	//request LUT lower and upper percentile
	Dialog.addNumber("LUT lower bound", 20);
	Dialog.addNumber("LUT upper bound", 99.9);
	
	Dialog.addFile("Green", ".");
	//choice between absolute or percentile boundaries
	Dialog.addChoice("Bound type", newArray("Percentile", "Absolute"), "Percentile");
	//request LUT lower and upper percentile
	Dialog.addNumber("LUT lower bound", 20);
	Dialog.addNumber("LUT upper bound", 99.9);
	
	Dialog.addFile("Blue", ".");
	//choice between absolute or percentile boundaries
	Dialog.addChoice("Bound type", newArray("Percentile", "Absolute"), "Percentile");
	//request LUT lower and upper percentile
	Dialog.addNumber("LUT lower bound", 20);
	Dialog.addNumber("LUT upper bound", 99.9);

	//get_out_dir
	Dialog.addDirectory("Outdirectory", ".")
	
	//show
	Dialog.show();

	r_bound_type = Dialog.getChoice();
	r_lower_bound = Dialog.getNumber();
	r_upper_bound = Dialog.getNumber();
	g_bound_type = Dialog.getChoice();
	g_lower_bound = Dialog.getNumber();
	g_upper_bound = Dialog.getNumber();
	b_bound_type = Dialog.getChoice();
	b_lower_bound = Dialog.getNumber();
	b_upper_bound = Dialog.getNumber();
	red_fn = Dialog.getString();
	green_fn = Dialog.getString();
	blue_fn = Dialog.getString();
	outdir = Dialog.getString();
	return newArray(red_fn, green_fn, blue_fn, r_bound_type, r_lower_bound, r_upper_bound, 
	g_bound_type, g_lower_bound, g_upper_bound, b_bound_type, b_lower_bound, b_upper_bound, outdir);
}

function main() {
	//mainloop
	params = param_dialog();
	setBatchMode(true);

	filenames = newArray(3)
	
	for (i = 0; i < 3; i++) {
		//open file
		open(params[i]);

		//set filename
		splitpath = split(params[i],"/");
		filename = splitpath[splitpath.length - 1];
		filenames[i] = filename;

		//mult values
		run("Multiply...", "value=1000000.000");

		//calculate cutoffs
		bincount = 10000;
		bound_type = params[i * 3 + 3];
		lower_bound = params[i * 3 + 4];
		upper_bound = params[i * 3 + 5];
		if (bound_type == "Percentile") {
			lower_val = calc_percentile(lower_bound, bincount);
			upper_val = calc_percentile(upper_bound, bincount);
			
			//set min and max for cmap lookuptable
			setMinAndMax(lower_val, upper_val);
		} else if (bound_type == "Absolute") {
			setMinAndMax(lower_bound, upper_bound);
		}
	}

	//create stack
	run("Merge Channels...", "c1=["+ filenames[0] + "] c2=[" + filenames[1] + "] c3=[" + filenames[2] + "] create keep");
	
	//set color
	run("RGB Color");

	//create outfilename
	outdir = params[params.length - 1];
	red_split = split(filenames[0], "_");
	green_split = split(filenames[1], "_");
	blue_split = split(filenames[2], "_");
	scan_no = red_split[1];
	red_elem = red_split[2];
	red_elem = split(red_elem, "-");
	red_elem = red_elem[0];
	green_elem = green_split[2];
	green_elem = split(green_elem, "-");
	green_elem = green_elem[0];
	blue_elem = blue_split[2];
	blue_elem = split(blue_elem, "-");
	blue_elem = blue_elem[0];

	out_filename = scan_no + "_" + red_elem + "_" + green_elem + "_" + blue_elem
	
	//write out image
	saveAs("png", outdir + File.separator + out_filename);
}

main();
