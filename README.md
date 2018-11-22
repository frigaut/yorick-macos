# yorick-macos
yorick and plugins installation scripts for macos. Something I should have done a long time ago. I have had these scripts for years, but never took the time to clean them up and publish the whole thing on github. Here it is with instructions.

## Installation

- Install Xcode from the App Store
- In Terminal: `xcode-select --install`
- Install macport (https://www.macports.org/install.php)
- Open a new terminal (your .bash_profile has been modified to include the macport PATH but you need to open a new terminal for this setting to take effect)
- Install Xquartz (https://www.xquartz.org/). That's Xorg.
- Stuff to install from macport:  
`sudo port install wget fftw-3 hdf5 libpng jpeg`
* Get yorick-macos:  
```
git clone https://github.com/frigaut/yorick-macos.git
cd yorick-macos
make yorick
(note the comment about adding a line to your .bash_profile when this command is done)
make plugins
```
* You should be done. Now you can call yorick from a terminal:  
`yorick`  
and yao:  
`yorick -i yao`
