function [imArray] = stackReg(unreg,tmatrices,refIdx)
%STACKREG Applies transformations to a stack of images
%   This funciton applies an array of transformation matrices to an unrigistered
%   stack of images

%% Check Input
nIms = length(unreg);

%read in unreg if not a stack of images
if iscellstr(unreg)
    imArray = cell(1,nIms);
    for i = 1:length(unreg)
        imArray{i} = imread(unreg{i});
    end
    clear unreg;
elseif iscell(unreg)
    imArray = unreg;
    clear unreg;
else
  error('unreg is neither an cell array of images nor file paths');
end

%% Apply Transforms

%create empty stack based on reference image dimensions
outputView = imref2d(size(imArray{refIdx}(:,:,1)));
dIdx = 1:nIms;

%create combined transforms and apply
for i = 1:nIms
    tmatrix = affine2d();
    while(dIdx(i) < refIdx)
        %apply forward transformation
        tmatrix.T = tmatrix.T*tmatrices{dIdx(i)}.T;
        dIdx(i) = dIdx(i)+1;
    end
    while(dIdx(i) > refIdx)
        %apply inverse transformation
        tinv = invert(tmatrices{dIdx(i)-1});
        tmatrix.T = tmatrix.T*tinv.T;
        dIdx(i) = dIdx(i)-1;
    end
    imArray{i} = imwarp(imArray{i},tmatrix,'OutputView',outputView, 'FillValue', [225 223 226]);
end
end

