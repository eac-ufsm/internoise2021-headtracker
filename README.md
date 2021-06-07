# Internoise 2021: Head tracker using webcam for auralization
<p align="left">
  <a href="https://github.com/eac-ufsm/internoise2021-headtracker/releases/" target="_blank">
    <img alt="GitHub release" src="https://img.shields.io/github/v/release/eac-ufsm/internoise2021-headtracker?include_prereleases&style=flat-square">
  </a>

  <a href="https://github.com/eac-ufsm/internoise2021-headtracker/commits/master" target="_blank">
    <img src="https://img.shields.io/github/last-commit/eac-ufsm/internoise2021-headtracker?style=flat-square" alt="GitHub last commit">
  </a>

  <a href="https://github.com/eac-ufsm/internoise2021-headtracker/issues" target="_blank">
    <img src="https://img.shields.io/github/issues/eac-ufsm/internoise2021-headtracker?style=flat-square&color=red" alt="GitHub issues">
  </a>

  <a href="https://github.com/eac-ufsm/internoise2021-headtracker/blob/master/LICENSE" target="_blank">
    <img alt="LICENSE" src="https://img.shields.io/github/license/eac-ufsm/internoise2021-headtracker?style=flat-square&color=yellow">
  <a/>

</p>
<hr>

Support files for the Internoise 2021 paper "Head tracker using webcam for auralization".

## Description
**Head tracker via camera face tracking and communication via UDP protocol.**

*Built on top of the [Google's MediaPipe](https://github.com/google/mediapipe) face_mesh (python release).*

## Folder structure:
  - ```/src:``` Contains the source code for the HeadTracker as published in the paper.
  - ```/test:``` Presents auralization experiments in MATLAB using the HeadTracker.
  - ```/audios:``` The raw files for the audio examples in the paper.  
  - ```/videos:``` The images related to the head movements that produced the audios in the paper.


## System support 
|    OS   |         Support         |
|:-------:|:-----------------------:|
| Windows |   Tested on Windows 10  |
|  macOS  | Tested on v10.15 and v11.2.1 (amd_64) |
|  Linux  | Tested on Ubuntu 18.04.5 LTS          |


<br/><br/>
## Setup python environment
  - This application only requires you to run ```pip install mediapipe==0.8.3.1```. However for the sake of good practices, we recommend you create a new python enviroment and install the required libraries with:
  
  ```R
  cd internoise2021-headtracker/src/
  
  conda create --name headtracker python=3.8
  
  conda activate headtracker

  pip install -r requirements.txt
  ``` 
- MediaPipe supports Python 3.6 to 3.8.

## Using the HeadTracker
  The application can be initialized with:
  ```python
  python HeadTracker.py
  ```
  
 - **Alternatively you may use the Windows executables distributed [here](https://github.com/eac-ufsm/internoise2021-headtracker/releases/tag/1.05.23). Notice that you don't need to setup an environment, or install anything else, in order to use the ```.exe``` standalones.**

- Connect to any plataform that accepts UDP/IP connection using the address: ```IP:'127.0.0.1'```  and ```PORT:50050``` .

- In order to close the app, mouse clicking "quit the window" might not work in all operating systems, as a general rule use "Esc" to finish the process, while we work in a more elegant solution for this issue.


### Interpreting received data
The HeadTracker application currently sends to the server yaw, pitch and roll information in degrees, where downwards pitch and counterclockwise roll and yaw are denoted with negative angles, such that the full rotation is bounded between -180° and 180°, as illustrated bellow. 


<p align="center">
<img width="400px" src="https://github.com/eac-ufsm/internoise2021-headtracker/blob/main/images/coord.svg"/>
</p>
  
The sent data are strings encoded into bytes,  for e.g. if the sent/received message is: **b'-5,10,0'**,  the corresponding coordinates are **yaw**=-5°, **pitch**=10° and **roll**=0°  &#8212; depending on the application the data needs to be decoded for proper use.


### Example: reading HeadTracker output data with Matlab
Bellow you can find a snippet of how to connect to the UDP address and convert the binary data to matlab array.
``` matlab
% Open the HeadTracker application (make sure the file path is added to matlab path variables)
open('HeadTracker.exe')   

% Connect to the local server
udpr = dsp.UDPReceiver('RemoteIPAddress', '127.0.0.1',...
                       'LocalIPPort',50050); 

% Read data from the head tracker
while true   
    py_output = step(udpr);
    if ~isempty(py_output)
        data = str2num(convertCharsToStrings(char(py_output))); %#ok<*ST2NM>
        disp([' yaw:', num2str(data(1)),...
             ' pitch:', num2str(data(2)),...
             ' roll:', num2str(data(3))])
    end
end 
 
```
Other examples of the connection to matlab are posted [here](https://github.com/eac-ufsm/internoise2021-headtracker/tree/main/test).

<br/>

## Issues

 - So far the code defaults to the main camera, if you experience difficulties, you can either enable only the desired one in your system or directly select it [in the code](https://github.com/eac-ufsm/internoise2021-headtracker/blob/1f2dada96790360cbd68de936ef04852579f9a27/src/HeadTracker.py#L85) by changing the index in ```cv2.VideoCapture(0)```.

# Cite us

> D. R. Carvalho; W. D’A. Fonseca; J. Hollebon; P. H. Mareze; F. M. Fazi. Head tracker using webcam for auralization. In *50th International Congress and Exposition on Noise Control Engineering - Internoise 2021*, pages 1–12, Washington, DC, USA, Aug. 2021.

**Bibtex:**
```
@InProceedings{headtracker:2021,
  author    = {Davi Rocha Carvalho and William {\relax D'A}ndrea Fonseca and Jacob Hollebon and Paulo Henrique Mareze and Filippo Maria Fazi},
  booktitle = {{50th International Congress and Exposition on Noise Control Engineering - Internoise 2021}},
  title     = {Head tracker using webcam for auralization},
  year      = {2021},
  address   = {Washington, DC, USA},
  month     = {Aug.},
  pages     = {1--12},
}
```

