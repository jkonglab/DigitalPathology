function [intensity, colorStainImages] = ColorDeconvolution_FullNewVer(I, M, stains)

%Aug 8, 2013: 1) correct errors in the original implementation
%             2) output color image for each stain
%
%Deconvolves multiple stains from RGB image I, given stain matrix 'M'.
%inputs:
%I - an MxNx3 RGB image in uint8 form range [0 - 255].
%M - a 3x3 matrix containing the color vectors in columns. For two stain images
%    the third column is zero.  Minumum two nonzero columns required.
%stains - a logical 3-vector indicating which output channels to produce.
%           Each element corresponds to the respective column of M.  Helps
%           reduce memory footprint when only one output stain is required.
%output:
%intensity - an MxNxsum(stains) intensity image in uint8 form range [0 - 255].  Each
%         channel is a stain intensity.  Channels are ordered same as
%         columns of 'M'.

%example inputs:
% M =[0.650 0.072 0;  %H&E 2 color matrix
%  0.704 0.990 0;
%  0.286 0.105 0];
%M = [0.29622945 0.47740915 0.72805583; %custom user H&E
%     0.82739717 0.7787432 0.001;
%    0.4771394  0.40698838 0.6855175];
%
%    Hemat  DAB  red_marker
%M = [0.650 0.368 0.103;...   %Red
%     0.704 0.570 0.696;...   %Green
%     0.286 0.731 0.711];     %Blue

for i = 1:3 %normalize stains
   if(norm(M(:,i), 2))
       M(:,i) = M(:,i)/norm(M(:,i));
   end
end

if(norm(M(:,3), 2) == 0) %only two colors specified
   if ((M(1,1)^2 + M(1,2)^2) > 1)
       M(1,3) = 0;
   else
       M(1,3) = sqrt(1 - (M(1,1)^2 + M(1,2)^2));
   end
  
   if ((M(2,1)^2 + M(2,2)^2) > 1)
       M(2,3) = 0;
   else
       M(2,3) = sqrt(1 - (M(2,1)^2 + M(2,2)^2));
   end
  
   if ((M(3,1)^2 + M(3,2)^2) > 1)
       M(3,3) = 0;
   else
       M(3,3) = sqrt(1 - (M(3,1)^2 + M(3,2)^2));
   end
  
   M(:,3) = M(:,3)/norm(M(:,3));
end


Q = inv(M);
%DELETE%Q = single(Q(logical(stains),:));

%convert from intensity to Optical Density (OD)
y_OD =deconvolution_normalize(single(im2vec(I)));

%Amount of stains
C = Q * y_OD;

%convert from OD to intensity
channels = deconvolution_denormalize(C);

%reshape back to an image
m = size(I,1); n = size(I,2);
intensity = uint8(zeros(m, n, sum(stains)));
for i = 1:sum(stains)
   intensity(:,:,i) = reshape(uint8(channels(i,:)), [m n]);
end

%generate color image associated with individual stains
colorStainImages = cell(1, sum(stains));
for i = 1:sum(stains)
   temp = uint8(zeros(m, n, sum(stains)));
   
   stain_OD = M(:,i)*C(i,:);
   stain_RGB = deconvolution_denormalize(stain_OD);
   
   temp(:,:,1) = reshape(uint8(stain_RGB(1,:)), [m n]);
   temp(:,:,2) = reshape(uint8(stain_RGB(2,:)), [m n]);
   temp(:,:,3) = reshape(uint8(stain_RGB(3,:)), [m n]);
   
   colorStainImages{i} = temp;
end



end

function vec = im2vec(I)
%converts color image to 3 x MN matrix

M = size(I,1);
N = size(I,2);

if(size(I,3) == 3)
    vec = [I(1:M*N); I(M*N+1:2*M*N); I(2*M*N+1:3*M*N)];
elseif(size(I,3) == 1)
    vec = [I(:)];
else
    vec = [];
end

vec = double(vec);

end


function normalized = deconvolution_normalize(data)
%Normalize raw color values according to Rufriok and Johnston's color
%deconvolution scheme.
%data - 3 x N matrix of raw color vectors (type double or single)
%normalized - 3 x N matrix of normalized color vectors (type double or
%single)

%normalized = -(255*log((data + 1)/255))/log(255); %not necessary to normalize to 0~255

normalized = (-1)*log( (data+eps)/255 );

end

function denormalized = deconvolution_denormalize(data)
%de-normalize raw color values according to Rufriok and Johnston's color
%deconvolution scheme.
%data - 3 x N matrix of raw color vectors (type double or single)
%denormalized - 3 x N matrix of normalized color vectors (type double or
%single)

%denormalized = exp(-(data - 255)*log(255)/255); %old implementation

denormalized = exp(-data)*255;

end
