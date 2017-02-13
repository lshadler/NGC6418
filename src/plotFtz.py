from astropy.utils.data import download_file
from astropy.io import fits
import numpy as np
import matplotlib.pyplot as plt
import sys

SAMPLE_FILE = "../../CapstoneData/pps/P0782940101PNS003IMAGE_1000.FTZ"
NBINS = 1000


def main():
    if len(sys.argv) != 2:
        print("ERROR: Please Specify File...")
        sys.exit()
    
    print("File used: ", sys.argv[1])
    image_file = sys.argv[1]

    hdu_list = fits.open(image_file)
    hdu_list.info()

    image_data = fits.getdata(image_file)
    print(image_data)
    print(np.shape(image_data))
    
    plt.figure()
    plt.imshow(image_data, cmap='gray')
    plt.colorbar()  
    #plt.figure()
    #histogram = plt.hist(np.nonzero(image_data[1,:]), 1000)
    plt.show()
if __name__ == '__main__':
    main()
