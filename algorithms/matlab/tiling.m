function result = tiling(image_path, run_folder, tiling_factor)
   addpath('.')
   info = imfinfo(image_path);
   width = info.Width;
   height = info.Height;
   reduced_width = width/tiling_factor;
   reduced_height = height/tiling_factor;
   x_coordinates = csvread(strcat(run_folder,'/x_coordinates.csv'))*reduced_width/100;
   y_coordinates = csvread(strcat(run_folder,'/y_coordinates.csv'))*reduced_height/100;
   hit_coordinates = {};
   for i=1:reduced_width
       for j=1:reduced_height
           in_polygon = inpolygon(i,j,x_coordinates,y_coordinates);
           if in_polygon
               hit_coordinates{end+1} = strcat(int2str((i-1)*tiling_factor),',',int2str((j-1)*tiling_factor));
               hit_coordinates{end+1} = strcat(int2str((i-1)*tiling_factor),',',int2str(j*tiling_factor));
               hit_coordinates{end+1} = strcat(int2str(i*tiling_factor),',',int2str((j-1)*tiling_factor));
               hit_coordinates{end+1} = strcat(int2str(i*tiling_factor),',',int2str(j*tiling_factor));
           end
       end
   end
   hit_coordinates = unique(hit_coordinates);
   dlmwrite(strcat(run_folder,'/tiles_to_analyze.json'),jsonencode(hit_coordinates),'');
end
