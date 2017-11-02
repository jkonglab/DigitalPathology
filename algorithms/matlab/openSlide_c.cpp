#include "mex.h"

#if !defined(STDIO)
#define STDIO
#include <stdio.h>
#endif

#if !defined(STDLIB)
#define STDLIB
#include <stdlib.h>
#endif

#if !defined(MATH)
#define MATH
#include <math.h>
#endif

#if !defined(UTILITY)
#define UTILITY
#include "utility.h"
#endif



#include <openslide.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <inttypes.h>
#include <stdint.h>

#include <dirent.h>
#include <string.h>
#include <stdbool.h>
#include <sys/time.h>
#include <ctype.h>


#include <vector>
#include <utility>
#include <string>

using namespace std;
#define PRId64 "lld"

//mex -I/opt/local/include/openslide/ -L/opt/local/lib -lopenslide openSlide_c.cpp

int getDimension(char* inputNDPI, int32_t level, int* dim_array) {
    
    openslide_t *osr;
    int64_t width, height;
    
    if ((osr = openslide_open (inputNDPI))==NULL)
    {
        printf("open the whole slide image %s error\n", inputNDPI);
        exit(1);
    }
    
    //openslide_get_level_dimensions(osr,0,&width, &height);
    openslide_get_level_dimensions(osr,level,&width, &height);
    openslide_close(osr);
    
    dim_array[0] = width;
    dim_array[1] = height;
    dim_array[2] = (long)3;
    
    printf("%s:\n level=%d: width=%d, height=%d, depth=%d\n", inputNDPI, level, dim_array[0], dim_array[1], dim_array[2]);
    return 1;
}


int getRegionImage(char *inputNDPI, unsigned char *ROI, long SX, long SY, long width, long height, int32_t level){
    int dim[3];
    openslide_t *osr;
    uint32_t *buf;
    int64_t i=0, row=0, col=0;
    
    //getDimension(inputNDPI, 0, dim);
    getDimension(inputNDPI, level, dim);
    
    if (SX < 0) SX = 0;
    if (SY < 0) SY = 0;
    
    if ((SX/pow(2, level)+width)>dim[0]) {perror("(SX+width) > dim[0]"); return 0;} //modified on Mar 11, 2016
    if ((SY/pow(2, level)+height)>dim[1]) {perror("(SY+height) > dim[0]"); return 0;} //modified on Mar 11, 2016
    
    printf("level:%d\t SX:%ld\t width:%ld\t dim[0]:%d\n",level,SX,width,dim[0]);
    printf("level:%d\t SY:%ld\t height:%ld\t dim[1]:%d\n",level,SY,height,dim[1]);
    
    
    if(openslide_detect_vendor(inputNDPI) == NULL){
        perror("Image format is not supported by openSlide 3.4.0");
        return 0;
    }
    
    
    osr = openslide_open(inputNDPI);
    if(osr == NULL) {
        return 0;
    }
    
    
    // assign memory for writing binary information
    buf = (uint32_t *) malloc(width * height * 4 );
    
    //openslide_read_region(osr, buf, SX, SY, 0, width, height);
    openslide_read_region(osr, buf, SX, SY, level, width, height);
    
    //printf("%s_%" PRId64 "_%" PRId64 "_%" PRId64 "_%" PRId64 "\n", inputNDPI, SX, SY, width,height);
    printf("%s_%ld_%ld_%ld_%ld\n", inputNDPI, SX, SY, width,height);
    
    //printf("%s_%lld_%lld_%lld_%lld\n", inputNDPI, SX, SY, width,height);
    for (i = 0; i< width * height; i++) {
        uint32_t val = buf[i];
        row = floor( i / width);
        col = i - row*width;
        //printf("row:%d \t col:%d \t R=%d,G=%d,B=%d\n", row, col, ((val >> 16) & 0xFF), ((val >> 8) & 0xFF), ((val >> 0) & 0xFF));
        ROI[height*col+row] = ((val >> 16) & 0xFF);
        ROI[height*width+height*col+row] = ((val >> 8) & 0xFF);
        ROI[height*width*2+height*col+row] = ((val >> 0) & 0xFF);
    }
    
    //for (i = 0; i< width * height; i++) printf("ROI[%d]=%d\n",i,ROI[i+width*height*1]);
    
    free(buf);
    
    return 1;
}



int getThumbnailWSI_getSize(char *inputNDPI, int length, int64_t *thumb_width, int64_t *thumb_height, int64_t *w, int64_t *h){
    openslide_t *osr;
    int32_t layer_count,validlayer;
    int64_t width, height, i, size, temp;
    
    
    if (openslide_detect_vendor(inputNDPI) == NULL)
    {
        printf("can't open image %s\n", inputNDPI);
        exit(1);
    }
    
    if ((osr = openslide_open (inputNDPI))==NULL)
    {
        printf("open the whole slide image %s error\n", inputNDPI);
        exit(1);
    }
    
    layer_count = openslide_get_level_count(osr);
    for(i = layer_count-1;i>=0;i--)
    {
        validlayer = i;
        openslide_get_level_dimensions(osr, validlayer, &width, &height);
        temp = width<height?width:height;//make sure that even the smaller one is larger than length
        if(temp>=length)//this layer can be used for extracting thumbnail
            break;
        printf("%" PRId64 " layer is not valide\n",i);
		//printf("%lld layer is not valide\n",i);

    }
    if(temp<length)//if the length is too large, even larger than the width or height, which means we can not get this one, just make it smaller
        length=temp;
    
    openslide_close(osr);
    
    //printf("Layer:%d for %s is %" PRId64 "x%" PRId64 " pixels\n", validlayer, inputNDPI, width, height);
    
	*w = width;
    *h = height;
    temp = width>height?width:height;
    temp /= length;
    width /= temp;
    height /= temp;
    
	//printf("The generating thumbnail for %s is %" PRId64 "x%" PRId64 " pixels\n", inputNDPI, width, height);

    *thumb_width = width;
    *thumb_height = height;
    
   
	printf("The generating thumbnail for %s is %" PRId64 "x%" PRId64 " pixels\n", inputNDPI, *thumb_width, *thumb_height);

	return validlayer;
    
}


int getThumbnailWSI_getThumbnailWSI(char *inputNDPI, unsigned char *ROI, int layer){
    openslide_t *osr;
    int64_t width, height, i, row, col;
    uint32_t *buf, val;
    
    
    if (openslide_detect_vendor(inputNDPI) == NULL)
    {
        printf("can't open image %s\n", inputNDPI);
        exit(1);
    }
    
    if ((osr = openslide_open (inputNDPI))==NULL)
    {
        printf("open the whole slide image %s error\n", inputNDPI);
        exit(1);
    }
    
    
    openslide_get_level_dimensions(osr, layer, &width, &height);
    
    //printf("width:%d \t height:%d\n",width, height);
    
    buf = (uint32_t *) malloc(width * height * 4 );
    
    openslide_read_region(osr, buf, 0, 0, layer, width, height);
    if (openslide_get_error(osr)) {
        printf("%s\n", openslide_get_error(osr));
        return false;
    }
    openslide_close(osr);
   
   
    for (i = 0; i< width * height; i++) {
        val = buf[i];
        row = floor( i / width);
        col = i - row*width;
        //printf("row:%d \t col:%d \t R=%d,G=%d,B=%d\n", row, col, ((val >> 16) & 0xFF), ((val >> 8) & 0xFF), ((val >> 0) & 0xFF));
        ROI[height*col+row] = ((val >> 16) & 0xFF);
        ROI[height*width+height*col+row] = ((val >> 8) & 0xFF);
        ROI[height*width*2+height*col+row] = ((val >> 0) & 0xFF);
    }
    
    //for (i = 0; i< width * height; i++) printf("ROI[%d]=%d\n",i,ROI[i+width*height*1]);
    
    free(buf);
    
    return 1;
}
            


void getProperties(char *inputNDPI, int &layer_count, vector< pair<string, string> > &p){
    openslide_t *osr;
    const char * const *property_names;
    const char *name, *value;
    
    
    if (openslide_detect_vendor(inputNDPI) == NULL)
    {
        printf("can't open image %s\n", inputNDPI);
        exit(1);
    }
    
    if ((osr = openslide_open (inputNDPI))==NULL)
    {
        printf("open the whole slide image %s error\n", inputNDPI);
        exit(1);
    }
    
    property_names = openslide_get_property_names(osr);
    while (*property_names) {
        name = *property_names;
        value = openslide_get_property_value(osr, name);
        printf("%s -> %s \n", name, value);
        
        p.push_back(make_pair(string(name), string(value)));
        
        property_names++;
    }
    
    
    //const char* comment = openslide_get_comment(osr);
    //printf("comments: %s\n", comment);
    
    layer_count = openslide_get_level_count(osr);
    
    openslide_close(osr);
}




void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
    int type, number_dims, dim_array[3], validlayer=0, length=0;
    long x=0, y=0;
    int64_t	width, height, thumb_width, thumb_height, *temp;
    int32_t *temp_int32, level=0;
    char * inputNDPI = mxArrayToString(prhs[0]);
    unsigned char * image, *buf;
    
    vector< pair<string, string> > property;
    vector< pair<string, string> >::const_iterator curr, end;
    mxArray *cell_array_ptr, *string_array_ptr;
    mwIndex index;
    
    mexUnlock();
    
    type = mxGetScalar(prhs[nrhs-1]);
    switch (type) {
        case 1:
            number_dims=3;
            
            if (nrhs==7) {
                x = mxGetScalar(prhs[1]);
                y = mxGetScalar(prhs[2]);
                width = mxGetScalar(prhs[3]);
                height = mxGetScalar(prhs[4]);
                level = mxGetScalar(prhs[5]);
                
                dim_array[0] = height; //NOTE: number of row defined by mxSetDimensions
                dim_array[1] = width;//NOTE: //number of col defined by mxSetDimensions
                dim_array[2] = 3;

            }
            else if (nrhs==6){
                x = mxGetScalar(prhs[1]);
                y = mxGetScalar(prhs[2]);
                width = mxGetScalar(prhs[3]);
                height = mxGetScalar(prhs[4]);
                
                dim_array[0] = height; //NOTE: number of row defined by mxSetDimensions
                dim_array[1] = width;//NOTE: //number of col defined by mxSetDimensions
                dim_array[2] = 3;
            }
            else if (nrhs==3){
                level = (int32_t) mxGetScalar(prhs[1]);
                getDimension(inputNDPI, level, dim_array); //Note: return from getDimension() dim_array: width, height, depth
                
                dim_array[2] = dim_array[0];
                dim_array[0] = dim_array[1];
                dim_array[1] = dim_array[2];
                dim_array[2] = 3;
                
                height = dim_array[0];
                width = dim_array[1];
            }
            else {mexErrMsgTxt("input parameters are wrong for type==1.");}
            
            
            plhs[0] = mxCreateNumericArray(0,0,mxUINT8_CLASS,mxREAL);
            mxSetDimensions(plhs[0], (const int *) dim_array, number_dims);
            mxSetData(plhs[0], mxMalloc(sizeof(unsigned char)*width*height*3));
            image = (unsigned char *) mxGetPr(plhs[0]);
            
            getRegionImage(inputNDPI, image, x, y, width, height, level);
            
            //for(int i=0; i<height; i++)
            //    for(int j=0; j<width; j++)
            //        printf("row:%d \t col:%d \tR=%d,G=%d,B=%d\n", i,j,image[height*j+i], image[height*width+height*j+i], image[height*width*2+height*j+i]);
            
            
            break;

        case 2:
            number_dims=1;
            if (nrhs > 2) level = mxGetScalar(prhs[1]);
            
            getDimension(inputNDPI, level, dim_array);
            plhs[0] = mxCreateDoubleScalar(dim_array[0]);
            plhs[1] = mxCreateDoubleScalar(dim_array[1]);
            
            break;
        
        case 3:
            number_dims=3;
            length = mxGetScalar(prhs[1]);
            validlayer = getThumbnailWSI_getSize(inputNDPI, length, &thumb_width, &thumb_height, &width, &height);
            
            //printf("validlayer:%d \t width(thumbnail):%d \t height(thumbnail):%d \n", validlayer, thumb_width,thumb_height);
            //printf("validlayer:%d \t width:%d \t height:%d \n", validlayer, width, height);
            printf("validlayer:%d \t width(thumbnail):%lld \t height(thumbnail):%lld \n", validlayer, thumb_width,thumb_height);
            printf("validlayer:%d \t width:%lld \t height:%lld \n", validlayer, width, height);
            
            plhs[0] = mxCreateNumericArray(0,0,mxUINT8_CLASS,mxREAL);
            dim_array[0]=height; //number of row defined by mxSetDimensions
            dim_array[1]=width;//number of col defined by mxSetDimensions
            dim_array[2]=3;
            mxSetDimensions(plhs[0], (const int *) dim_array, number_dims);
            mxSetData(plhs[0], mxMalloc(sizeof(unsigned char)*dim_array[0]*dim_array[1]*dim_array[2]));
            image = (unsigned char *) mxGetPr(plhs[0]);
            //printf("number of element:%d\n",mxGetNumberOfElements(plhs[0]));
            
            getThumbnailWSI_getThumbnailWSI(inputNDPI, image, validlayer);

            plhs[1] = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);
            temp = (int64_t *) mxGetData(plhs[1]);
            *temp = thumb_height;
            
            plhs[2] = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);
            temp = (int64_t *) mxGetData(plhs[2]);
            *temp = thumb_width;
            
            break;
        
        case 4:
            
            getProperties(inputNDPI, validlayer, property);
            
            plhs[0] = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
            temp_int32 = (int32_t *) mxGetData(plhs[0]);
            *temp_int32 = validlayer;
            
            number_dims = 2;
            dim_array[0] = (int) property.size();
            dim_array[1] = 2;
            cell_array_ptr = mxCreateCellArray((mwSize)number_dims,(const mwSize *)dim_array);
            plhs[1] = cell_array_ptr;
            
            for(curr=property.begin(), end = property.end(), index=0; curr != end; curr++, index++){
                printf("Name:%s\t Value:%s\n", curr->first.c_str(), curr->second.c_str());
                string_array_ptr = mxCreateString(curr->first.c_str());
                mxSetCell(cell_array_ptr,index,string_array_ptr);
                string_array_ptr = mxCreateString(curr->second.c_str());
                mxSetCell(cell_array_ptr,index+dim_array[0],string_array_ptr);
            }
            
            
            break;
        
        default:
            mexErrMsgTxt("value of variable <type> is wrong.");
            break;
    }
    
    
    return;
}