#This is for Fibrosis segmentation.
################################################################################
#Aug/13/2018
#by Xiaoyuan Guo
#Any Questions, please contact me by email: xiaoyuan.guo@emory.edu
################################################################################
/labs/konglab/Fibrosis_Seg_DP_xiaoyuan/image-segmentation-keras-master/predict.py, this file is for running prediction.
Example usages are provided at the end of the file.

#Instructions of files in FCN8_fibrosis
##1.image-segmentation-keras-master.model.9 is the trained model file which is used in the prediciton file.

#Instructions of Folders in FCN8_fibrosis
##1.Models
In it, there are some model files that may be called by prediction file.

##2.Testdata
It contains some testing data images, whose size is 256X256, therefore, the original image should not be smaller than 256X256.

##3.TestdataMask
The predicted segmentation mask are stored in the folder.

####Instructions for files  in image-segmentation-keras-master folder
######1. LoadBatches.py
The file is used to arrange the image data and prepare for prediction
######2. predict.py
The file is for prediction, two kinds of prediction functions are included,namely,predict_save() and predict_return(). The predict_save() function is for prediciton and save the predicted mask to disk; while the predict_return() is for prediction and return the predicted mask to a parameter outside.

Note: detailed examples are provided in the predict.py file  
