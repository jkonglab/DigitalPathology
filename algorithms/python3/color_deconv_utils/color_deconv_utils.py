import os
import sys
from argparse import ArgumentParser
import numpy as np

USE_CV = True
try:
    from cv2 import cv2
except:
    USE_CV = False
    from skimage.io import imsave
    from skimage.color import rgb2hsv
    from skimage.io import imread



class Ref:

    @staticmethod
    def get_he_ref():
        # H&E staining reference value for normalization
        # It is from the [Python](https://github.com/schaugf/HEnorm_python) code.
        #HERef = np.array([[0.5626, 0.2159],[0.7201, 0.8012],[0.4062, 0.5581]])

        #maxCRef = np.array([1.9705, 1.0308])
        img_file = "/Project/DP_Share/imageviewer/algorithms/python3/color_deconv_utils/he_ref.png"
        ref_img = read_im(img_file)
        HERef, maxCRef = custom_ref(ref_img)

        return HERef, maxCRef

    @staticmethod
    def get_ihc_ref():
        # H&E staining reference value for normalization
        # It is from the [Python](https://github.com/schaugf/HEnorm_python) code.
        #copied H&E , needs change
        img_file = "/Project/DP_Share/imageviewer/algorithms/python3/color_deconv_utils/ihc_ref.png"
        ref_img = read_im(img_file)
        HERef, maxCRef = custom_ref(ref_img)

        return HERef, maxCRef


def stain_norm(img, ref, Io=240):
    ''' Normalize staining appearence of stained images.
    Input:
        img: RGB input image, numpy array.
        ref: Reference value for normalization, tuple, (HERef, maxCRef).
    Output:
        Inorm: normalized image
    Reference: 
        A method for normalizing histology slides for quantitative analysis. M.
        Macenko et al., ISBI 2009
    '''

    HERef, maxCRef = ref
        
    # define height and width of image
    h, w, _ = img.shape

    # reshape image
    img = img.reshape((-1,3))

    _, C, maxC = od_svd(img, Io)
        
    # normalize stain concentrations
    tmp = np.divide(maxC, maxCRef)
    C2 = np.divide(C,tmp[:, np.newaxis])

    # recreate the image using the specific mixing matrix
    Inorm = np.multiply(Io, np.exp(-HERef.dot(C2)))
    Inorm[Inorm>255] = 254
    Inorm = np.reshape(Inorm.T, (h, w, 3)).astype(np.uint8) 

    return Inorm


def stain_deconv(img, ref=None, Io=240):
    ''' Deconvolute the staining appearence of stained images.
    Input:
        img: RGB input image, numpy array.
        ref: Reference value for normalization, tuple, (HERef, maxCRef). 
        If None, don't use the reference value, use the image specific value calculated from `od_svd` function.
    Output:
        H: main color 1 image
        E: main color 2 image
    Reference: 
        A method for normalizing histology slides for quantitative analysis. M.
        Macenko et al., ISBI 2009
    '''

    use_ref = False
    if ref!=None:
        HERef, maxCRef = ref
        use_ref = True

    # define height and width of image
    h, w, _ = img.shape

    # reshape image
    img = img.reshape((-1,3))

    HE, C, maxC = od_svd(img, Io)

    if use_ref:
        tmp = np.divide(maxC, maxCRef)
        HE_used = HERef
    else:
        tmp = maxC
        HE_used = HE
    C2 = np.divide(C,tmp[:, np.newaxis])

    # unmix two main color images
    H = np.multiply(Io, np.exp(np.expand_dims(-HE_used[:,0], axis=1).dot(np.expand_dims(C2[0,:], axis=0))))
    H[H>255] = 254
    H = np.reshape(H.T, (h, w, 3)).astype(np.uint8)

    E = np.multiply(Io, np.exp(np.expand_dims(-HE_used[:,1], axis=1).dot(np.expand_dims(C2[1,:], axis=0))))
    E[E>255] = 254
    E = np.reshape(E.T, (h, w, 3)).astype(np.uint8)

    return H, E


def custom_ref(img, Io=240):
    ''' Customize the reference value for normalization based on the input image.
    Input:
        img: RGB input image, numpy array.
    Output:
        HE: Reference value.
        maxC: Reference value.
    Reference: 
        A method for normalizing histology slides for quantitative analysis. M.
        Macenko et al., ISBI 2009
    '''
    # reshape image
    img = img.reshape((-1,3))

    HE, _, maxC = od_svd(img, Io)
        
    return HE, maxC


def od_svd(img, Io, alpha=1, beta=0.15):
    # calculate optical density
    OD = -np.log((img.astype(np.float)+1)/Io)

    # remove transparent pixels
    ODhat = OD[~np.any(OD<beta, axis=1)]

    # compute eigenvectors
    _, eigvecs = np.linalg.eigh(np.cov(ODhat.T))

    #project on the plane spanned by the eigenvectors corresponding to the two 
    # largest eigenvalues    
    That = ODhat.dot(eigvecs[:,1:3])

    phi = np.arctan2(That[:,1],That[:,0])

    minPhi = np.percentile(phi, alpha)
    maxPhi = np.percentile(phi, 100-alpha)

    vMin = eigvecs[:,1:3].dot(np.array([(np.cos(minPhi), np.sin(minPhi))]).T)
    vMax = eigvecs[:,1:3].dot(np.array([(np.cos(maxPhi), np.sin(maxPhi))]).T)

    # a heuristic to make the vector corresponding to hematoxylin first and the 
    # one corresponding to eosin second
    if vMin[0] > vMax[0]:
        HE = np.array((vMin[:,0], vMax[:,0])).T
    else:
        HE = np.array((vMax[:,0], vMin[:,0])).T
    # rows correspond to channels (RGB), columns to OD values
    Y = np.reshape(OD, (-1, 3)).T

    # determine concentrations of the individual stains
    C = np.linalg.lstsq(HE, Y, rcond=None)[0]
    maxC = np.array([np.percentile(C[0,:], 99), np.percentile(C[1,:],99)])

    return HE, C, maxC


# get white pixel coordinates through thresholding in the HSV color space
def hsv_get_white(img, thresh=30):
    # img, rgb color image
    if USE_CV:
        img_hsv = cv2.cvtColor(img, code=cv2.COLOR_RGB2HSV)
    else:
        img_hsv = rgb2hsv(img) * 255
    # find white pixels by thresholding on the channel 'S'
    ind = img_hsv[:,:,1]<thresh
    h, w, _ = img.shape
    mask = np.zeros((h, w)).astype(np.uint8)
    mask[ind] = 255
    return mask


def read_im(img_file):
    if USE_CV:
        img = cv2.imread(img_file)[:,:,::-1]
    else:
        img = imread(img_file)
    return img


def save_im(fname, arr):
    im_dim = len(arr.shape)
    if USE_CV:
        if im_dim == 3:
            #cv2.imwrite(fname, cv2.cvtColor(arr[:,:,::-1], cv2.COLOR_BGR2RGB))
            cv2.imwrite(fname, arr[:,:,::-1])
        else:
            #cv2.imwrite(fname, cv2.cvtColor(arr, cv2.COLOR_BGR2RGB)
            cv2.imwrite(fname, arr)
    else:
        imsave(fname, arr)


def main(args):
    # input image
    img = read_im(args.img_file)
    if (args.subparser_name == 'segment_white') | (args.subparser_name == 'sw'):
        mask = hsv_get_white(img)
        save_im(os.path.join(args.save_path, 'output_white_pixel_mask.png'), mask)
        return
    if args.ref == 'HE':
        ref = Ref.get_he_ref()
    elif args.ref == 'IHC':
        ref = Ref.get_ihc_ref()
    elif args.ref == 'Customer':
        # reference image
        try:
            rf_img = read_im(args.ref_img)
        except TypeError:
            print("The option `--ref_img` is necessary when choose `Customer` as the option `--ref`.")
        ref = custom_ref(rf_img)
    
    if (args.subparser_name == 'deconvolute') | (args.subparser_name == 'dc'):
        H, E = stain_deconv(img, ref)
        save_im(os.path.join(args.save_path, 'output_H.png'), H)
        save_im(os.path.join(args.save_path, 'output_E.png'), E)
    elif (args.subparser_name == 'normalize') | (args.subparser_name == 'nm'):
        Inorm = stain_norm(img, ref)
        save_im(os.path.join(args.save_path, 'output_norm.png'), Inorm)


def parsers():
    parser = ArgumentParser(description='Stain color deconvolution and normalization.')
    subparsers = parser.add_subparsers(title='subcommands', description='valid subcommands', help='use `python <script.py> <sub-command> -h` to access sub-command help.', dest='subparser_name')

    # color deconvolution
    parser_deconv = subparsers.add_parser('deconvolute', aliases=['dc'], help='deconvolute the two main colors. Usage: `python3 color_deconv_utils.py dc /path/of/image/to/be/processed /path/to/save/results --ref Customer --ref_img /path/of/image/as/reference`')
    parser_deconv.add_argument('img_file', metavar='ImageFile', type=str, help='the image file to be processed.')
    parser_deconv.add_argument('save_path', metavar='SavePath', type=str, help='path to save results.')
    parser_deconv.add_argument('--ref', metavar='Reference', type=str, default='None', choices=['HE', 'Customer', 'None'], help='choose the reference style for deconvoluted images, it means that the deconvoluted images will use the colors of the reference style. It has 3 options: [`HE`, `Customer`, None]. `HE` invokes the builtin H&E stained reference. `Customer` let the user to customize the reference style using another reference image file, this option requires the option `--ref_img`. The default option `None` uses no reference.')
    parser_deconv.add_argument('--ref_img', metavar='ReferenceImageFile', type=str, help='the image file to be used as the reference. This option is necessary when choose `Customer` in the option `--ref`.')

    # color noralization
    parser_norm = subparsers.add_parser('normalize', aliases=['nm'], help='normalize the image. Usage: `python3 color_deconv_utils.py nm /path/of/image/to/be/processed /path/to/save/results --ref Customer --ref_img /path/of/image/as/reference`')
    parser_norm.add_argument('img_file', metavar='ImageFile', type=str, help='the image file to be processed.')
    parser_norm.add_argument('save_path', metavar='SavePath', type=str, help='path to save results.')
    parser_norm.add_argument('--ref', metavar='Reference', type=str, default='HE', choices=['HE', 'Customer'], help='choose the reference style for normalized images, it means that the normalized images will use the colors of the reference style. It has 2 options: [`HE`, `Customer`]. The default `HE` invokes the builtin H&E stained reference. `Customer` let the user to customize the reference style using another reference image file, this option requires the option `--ref_img`')
    parser_norm.add_argument('--ref_img', metavar='ReferenceImageFile', type=str, help='the image file to be used as reference. This option is necessary when choose `Customer` in the option `--ref`.')

    # segment white areas
    parser_white_seg = subparsers.add_parser('segment_white', aliases=['sw'], help='return the white area mask. Usage: `python3 color_deconv_utils.py sw /path/of/image/to/be/processed /path/to/save/results`')
    parser_white_seg.add_argument('img_file', metavar='ImageFile', type=str, help='the image file to be processed.')
    parser_white_seg.add_argument('save_path', metavar='SavePath', type=str, help='path to save results.')

    return parser.parse_args()


if __name__ == "__main__":
    args = parsers()
    main(args)
    passcolor
    pass