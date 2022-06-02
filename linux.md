# Multiple gcc/g++ version control
```
sudo apt install build-essential
sudo apt -y install gcc-7 g++-7 gcc-8 g++-8 gcc-9 g++-9
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 7
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 7
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 8
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 9
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 9
sudo update-alternatives --config gcc
There are 3 choices for the alternative gcc (providing /usr/bin/gcc).

  Selection    Path            Priority   Status
------------------------------------------------------------
  0            /usr/bin/gcc-9   9         auto mode
  1            /usr/bin/gcc-7   7         manual mode
* 2            /usr/bin/gcc-8   8         manual mode
  3            /usr/bin/gcc-9   9         manual mode
Press  to keep the current choice[*], or type selection number: 
```

# link order is very strict under gcc
for example, cmake target A depends on zlib, the following cmake script works fine:
```cmake
target_link_libraries(${TARGET_NAME} A z)
```
however, if you put A before z, target A will result in undefined syntax error:
```cmake
target_link_libraries(${TARGET_NAME} z A) # will fail
```

# hide libraries symbols
There is no point to hide symbols from static libraries, just use them on sharead libraries.
```cmake
add_link_options("LINKER:--exclude-libs,ALL") # hide symbols from all static library
set(CMAKE_CUDA_VISIBILITY_PRESET hidden)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_C_VISIBILITY_PRESET hidden)
```
