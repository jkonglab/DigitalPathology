#!/usr/local/bin/julia
Pkg.add("Images")
using Images

# Sort out command line arguments
nargs = length(ARGS)
nargs < 3 ? error("Missing one or more input arguments") : false

inpath = ARGS[1]    # input file path
outpath = ARGS[2]   # output file path
fn = ARGS[3]     	# method name
tile_x = ARGS[4]		# x
tile_y = ARGS[5]		# y
width = ARGS[6]		# width
height = ARGS[7]		# height

if nargs > 7
    opt = ARGS[8:end]
else
    opt = []
end

# Check paths and load image
isfile(inpath) ? true: error("Input path does not exist")
isfile(outpath) ? error("Output file already exists") : false
isdir(dirname(outpath)) ? true: error("Output directory does not exist")

img = Float64.(channelview(load(inpath)))

# Execute function
if fn == "color_decon"
    isempty(opt) ? error("Missing deconvolution array"): false

    include("color_decon/ColorDecon.jl")
    A = Float64.(eval(parse(opt[1]))).'
    result = ColorDecon.color_decon(A, img)
    save(outpath, result)
else
    error("Function name not recognized")
end
