function output = generate_registered_images_main_function(outputdir, inputs)

    files = inputs{1};
    nIms = length(files);

    landmarks_file = inputs{2};

    r = split(files{1}, "/");
    file_name = r{end};
    r = split(file_name, "_");
    level = str2num(r{5});

    %% Set Global Reference Image
    if ~exist('refIdx','var')
        refIdx = floor(nIms/2);
    end
    if (refIdx < 1) || (refIdx > nIms)
        refIdx = floor(nIms/2);
    end

    tmatrices = cell(1,nIms-1);
    trgtMatched = cell(1,nIms-1);
    refMatched = cell(1,nIms-1);

    %%check if the landmarks file exists
    %%read target points and ref points for each pair from file
    fid = fopen(landmarks_file);
    
    isNotEmpty = false;
    trgtPoints = zeros(1,2);
    refPoints = zeros(1,2);

    i = 0;
    fIdx = 1;
    while true
        tline = fgetl(fid);
        if ~ischar(tline);
            break; 
        end%end of file

        arr = split(tline, ',');%split by comma
        arr2 = str2double(arr');
        trgt_idx = int8(arr2(1));

        if trgt_idx ~= fIdx
            i = 0;
            tPoints = SURFPoints(trgtPoints);
            rPoints = SURFPoints(refPoints);
            [tmatrices{fIdx}, trgtMatched{fIdx}, refMatched{fIdx}] = estimateGeometricTransform(tPoints, rPoints, 'similarity');
            fIdx = fIdx+1;
            trgtPoints = zeros(1,2);
            refPoints = zeros(1,2);
        else
            i = i+1;
            trgtPoints(i,:) = str2double([arr(2), arr(3)]);
            refPoints(i,:) = str2double([arr(4), arr(5)]);
        end
    end
    
    tPoints = SURFPoints(trgtPoints);
    rPoints = SURFPoints(refPoints);            
    [tmatrices{fIdx}, trgtMatched{fIdx}, refMatched{fIdx}] = estimateGeometricTransform(tPoints, rPoints, 'similarity');

    save([outputdir, sprintf('/openSlide_Landmark_L%02d_transforms.mat', level)], 'tmatrices', 'trgtMatched', 'refMatched');
        
    %% Apply Transformations
    regStack = stackReg(files, tmatrices, refIdx);

    %% Save Registered Images
    for i = 1:nIms
        %k = strfind(files{i},'_');
        s = strfind(files{i},'/');
        %output_name = files{i}(s(end)+1:k(end)-1);
        output_name = files{i}(s(end)+1:end);
        
        e = strfind(output_name, '');
        if ~isempty(e)
            output_name = output_name(1: e(1)-1);
        end
        imwrite(regStack{i}, sprintf('%s/reg_%s',outputdir, output_name));
    end
    output = 1;
end