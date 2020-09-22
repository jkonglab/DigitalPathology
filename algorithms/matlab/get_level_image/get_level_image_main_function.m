function output = get_level_image_main_function(outputdir, inputarr)
    %extract low level images from whole slide images
    %

    %clearvars; close all; clc;%

    %code_dir = '/Users/kongj/Renal_Chapman/';
    %addpath(genpath(code_dir));

    %project_name = 'LiverFibrosis_HE_IHC_Serial';
    %rootdir = '/Users/jkong/Liver_Fibrosis/';
    %datadir = [rootdir 'data/' project_name '/'];
    inputNDPIs = inputarr;

    %inputNDPIs = {inputNDPIs.name}';
    FN = length(inputNDPIs);

    %get layer cout and other image properties
    layerCount = zeros(FN,1);

    for i = 1:FN
        type = 4;
        inputNDPI = inputNDPIs{i};
        [layerCount(i), cellstr] = openSlide_c(inputNDPI, type);
    end

    level = min(layerCount)-1;

    for i = 1:FN
        inputNDPI = inputNDPIs{i};

        file_parts = split(inputNDPI, '/');
        file_name = file_parts{end};

        %%get ROI from specific level (example 2)
        type = 1;
        outputImageThumbnail = openSlide_c(inputNDPI, level, type);
        col = size(outputImageThumbnail,2);
        row = size(outputImageThumbnail,1);
        imwrite(outputImageThumbnail, [outputdir 'low_resolution_level_' num2str(level) '_' num2str(i) '_' num2str(row) '_' num2str(col) '.tif']);
        fprintf('Extracted image: level:%d, Dim: %d x %d\n', level, col, row);
    end
    output = level;
end