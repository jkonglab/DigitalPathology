function output = dicom2jpg(image, input)    
    [X,MAP]=dicomread(image);
    image8 = uint8(255 * mat2gray(X));
    
    [filepath,name,ext] = fileparts(image);
    new_name = image;
    
    if ext == '.dcm'
        new_name = strcat(filepath,'/',name);
    end
    
    if(input==1)
    imwrite(image8,strcat(new_name, '.bmp'), 'bmp');% Save Image as bmp format
    elseif(input==2)
    imwrite(image8,strcat(new_name, '.jpg'), 'jpg');% Save Image as Jpeg format
    elseif(input==3)
    imwrite(image8,strcat(new_name, '.tiff'), 'tiff');% Save Image as tiff format
    elseif(input==4)
    imwrite(image8,strcat(new_name, '.gif'), 'gif');% Save Image as gif format
    elseif(input==5)
    imwrite(image8,strcat(new_name, '.png'), 'png');% Save Image as png format
    else
        disp('Unknown image format name.');
    end
    output = true;
end