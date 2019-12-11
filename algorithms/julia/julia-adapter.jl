#!/usr/local/bin/julia
using Pkg
Pkg.add("Images")
Pkg.add("ImageMagick")
using Images
using ImageMagick

# Sort out command line arguments
nargs = length(ARGS)
nargs < 3 ? error("Missing one or more input arguments") : false

inpath = ARGS[1]    # input file path
outpath = ARGS[2]   # output file path
fn = ARGS[3]         # method name
tile_x = ARGS[4]        # x
tile_y = ARGS[5]        # y
width = ARGS[6]        # width
height = ARGS[7]        # height

if nargs > 7
    opt = ARGS[8:end] #end member size
else
    opt = []
end

# Check paths and load image
isfile(inpath) ? true : error("Input path does not exist")
isfile(outpath) ? error("Output file already exists") : false
isdir(dirname(outpath)) ? true : error("Output directory does not exist")

img = Float64.(channelview(load(inpath)))

# Execute function
if fn == "color_decon"
    isempty(opt) ? error("Missing end member size") : false

    include("color_decon/ColorDecon.jl")
    result = ColorDecon.color_decon(opt, img)
    save(outpath, result)
else
    error("Function name not recognized")
end
