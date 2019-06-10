import numpy as np
import matplotlib.pyplot as plt

def draw_images(images,
                nx=1,
                ny=1,
                axes=None,
                *args,
                **kwargs):
    """
    Draw multiple images. This function conveniently draw multiple images side
    by side.
    Parameters
    ----------
    x : List of images
        - Array  [ nx*ny , px, py ]
        - Array  [ nx*ny , px, py , 3]
        - Array  [ nx*ny , px, py , 4]
    nx : number of images to be ploted along the x axis (default = 1)
    ny : number of images to be ploted along the y axis (default = 1)
    px : number of pixel along the x axis (If the images are vectors)
    py : number of pixel along the y axis (If the images are vectors)
    axes : axes
    """
    import warnings
    ndim = len(images.shape)
    nimg = images.shape[0]

    if ndim == 1:
        raise ValueError('Wrong data shape')
    elif ndim == 2:
        images = np.expand_dims(np.expand_dims(images, axis=0), axis=3)
    elif ndim == 3:
        images = np.expand_dims(images, axis=3)
    elif ndim > 4:
        raise ValueError('The input contains too many dimensions')

    px, py, c = images.shape[1:]

    images_tmp = images.reshape([nimg, px, py, c])
    mat = np.zeros([nx * px, ny * py, c])
    for j in range(ny):
        for i in range(nx):
            if i + j * nx >= nimg:
                warnings.warn("Not enough images to tile the entire area!")
                break
            mat[i * px:(i + 1) * px, j * py:(
                j + 1) * py] = images_tmp[i + j * nx, ]
    # make lines to separate the different images
    xx = []
    yy = []
    for j in range(1, ny):
        xx.append([py * j, py * j])
        yy.append([0, nx * px - 1])
    for j in range(1, nx):
        xx.append([0, ny * py - 1])
        yy.append([px * j, px * j])

    if axes is None:
        axes = plt.gca()
    if c==1:
        mat = mat[:,:,0]
    axes.imshow(mat, *args, **kwargs)
#     for x, y in zip(xx, yy):
#         axes.plot(x, y, color='r', linestyle='-', linewidth=2)
    axes.get_xaxis().set_visible(False)
    axes.get_yaxis().set_visible(False)
    return axes