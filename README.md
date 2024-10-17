# Synchrotron_macros
A set of imagej macros for the analysis of synchrotron images

# Installation guide
- Download the macro you want to use
- In Imagej, go to Plugins -> Macros -> Install...
- Select the downloaded macro file
- Run the macro through Plugins -> Macros -> "macro name"

# Available macros
## Synchprocesser
The synchprocesser macro can process one or multiple synchrotron images  
### Parameters:
**Images directory**: input directory holding multiple images.\*  
**Image file**: input image.\*  
*Only supply one of the input types.
**Output directory**: the output folder for the processed image(s).  

**Pixel value multiplier**: Multiplies all values in the image with this value. When set to 10^6 (the default) it changes the values from the synchrotrons default output of g/cm2 to μm/cm2.  
**Bound type**: If set to "Percentile" the LUT lower and upper boundaries are set to the corresponding pixel percentile value. If set to "Absolute" the LUT lower and upper boundary will instead be set to the exact values entered.  

**Add color legend**: Checkbox, if ticked adds a color legend to the image. The legend is put in a black padded area, the size of which gets controlled by **Width padding**.
**LUT lower bound**: The lower boundary for the lookuptable.  
**LUT upper bound**: The upper boundary for the lookuptable. 

**Add size bar**: Checkbox, if ticked adds a scalebar to the image.  
**Scale (μm/pixel)**: The scale of the image in μm per pixel.\*  
**Scalebar width**: The amount of μm the scalebar should be wide.\*  
*Only matters if **Add size bar** is ticked.  

**Width padding**: The padding added for the colorbar (Only matters if **Add color legend** is ticked).    
**Height padding**: The padding added for the scalebar (Only matters if **Add size bar** is ticked).  


## Make\_rgb
Will document at later point. 
