function output = global_machine_L_main_function(outputdir, inputarr)

    try
        %   This script performs global intensity-based or feature-based registration on a set of sequentially named image files
        %   Dependencies: featureTransform, intensityTransform, stackReg
        %close all; clearvars; clc;

        %% Parameters
        %level = 7;
        %project_name = 'LiverFibrosis_HE_IHC_Serial';
        %commondir = ['/Users/jkong/Liver_Fibrosis/result/' project_name];
        %rootdir = sprintf('%s/openSlide_level_%02d/', commondir, level);
        %disp(inputarr);
        correctedMatchedFeaturePoints_TF = false;
        ext = 'tif';

        %switch between intensity-based registration and feature-based registration
        %[options: intensity or feature]
        regmode = 'feature';

        %% Get Files
        %files = dir([rootdir '*.' ext]);
        %dirIdx = [files.isdir];
        %rootdir = outputdir;
        files = inputarr;
        r = split(files{1}, "/");
        file_name = r{end};
        r = split(file_name, "_");
        level = str2num(r{3});

        %result_dir = sprintf('%s/openSlide_global_surf_Landmark_L%02d/',outputdir, level);
        result_file = sprintf('%s/openSlide_global_surf_Landmark_L%02d.json',outputdir,level);

        nIms = length(files);

        if nIms < 1
            error('Not enough input images');
        end

        files = sort(files);

        %% Set Global Reference Image
        if ~exist('refIdx','var')
            refIdx = floor(nIms/2);
        end
        if (refIdx < 1) || (refIdx > nIms)
            refIdx = floor(nIms/2);
        end

        %% Compute Pairwise Transformations
        %if exist([result_dir, sprintf('openSlide_Landmark_L%02d_transforms.mat', level)], 'file')==0
        %create cell array to hold pairwise transformation matrices and %loop through image pairs and compute transformation matrix
        tmatrices = cell(1,nIms-1);
        trgtMatched = cell(1,nIms-1);
        refMatched = cell(1,nIms-1);
        for i = 1:nIms-1
            fprintf('rigid registration for\n %s and\n %s\n',files{i},files{i+1});
            switch lower(regmode)
                case 'intesnity'
                    tmatrices{i} = intensityTransform(files{i},files{i+1});
                case 'feature'
                    [trgtMatched{i}, refMatched{i}] = featureTransform(files{i},files{i+1}, result_file, i, correctedMatchedFeaturePoints_TF);
                otherwise
                    error('Unexpected registration mode for rigid.');
            end
        end
    catch exception
        fprintf(getReport(exception))
    end
    output = 1;
end