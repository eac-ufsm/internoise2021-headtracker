clear all;  clc; close all 
% addpath(genpath(pwd))
% DAVI ROCHA CARVALHO MAY/2021 - Eng. Acustica @UFSM 
% Test binaural rendering using webcam head tracker and HATO influence

% MATLAB R2020b
%% Load HRTFs
% DOWNLOAD FABIAN HRTFs: https://depositonce.tu-berlin.de/handle/11303/6153
path = dir('HRTFs\FABIAN_HRIR_measured_HATO_*.sofa');
for k = 1:size(path, 1)
    Obj{k} = SOFAload([path(k).folder, filesep, path(k).name], 'nochecks');
    temp = regexp(path(k).name, '\d+', 'match'); % extract HATO value
    HATO(k,1) = str2num(cell2mat(temp)); 
end

Fs = Obj{k}.Data.SamplingRate;

% Change from spherical to navigational coordinates 
HATO = -sph2nav(HATO);
sourcePositions = Obj{k}.SourcePosition(:, 1:2);
sourcePositions(:,1) = sph2nav(sourcePositions(:,1));

%% Load audio 
[heli,originalSampleRate] = audioread('Heli_16ch_ACN_SN3D.wav'); % ja vem com o matlab 
heli = 12*heli(:,1); % keep only one channel

if originalSampleRate ~= Fs
    heli = resample(heli,sampleRate,originalSampleRate);
end

%% Audio to DSP object
sigsrc = dsp.SignalSource(heli, ...
    'SamplesPerFrame',512, ...
    'SignalEndAction','Cyclic repetition');
deviceWriter = audioDeviceWriter('SampleRate', Fs);


%% Define FIR filters
FIR = cell(1,2);
FIR{1} = dsp.FIRFilter('NumeratorSource','Input port');
FIR{2} = dsp.FIRFilter('NumeratorSource','Input port');


%% Start Head Tracker from binaries
open('HeadTracker.exe') 

%% Start head tracker from python code
% Alternativelly you can call the python script src/HeadTracker.py as long
% as you have setup the correct environment

% Define path to the python environment
% executable = 'C:\Users\rdavi\anaconda3\envs\headtracker\python'; %#ok<*UNRCH>
% executionMode = 'OutOfProcess'; % otherwise will not run in parallel
% pe = pyenv('Version',executable,'ExecutionMode',executionMode);
% 
% if count(py.sys.path,'') == 0 % Adicionar path para 'variaveis ambiente caso num exista
%     insert(py.sys.path,int32(0),'');
% end
% p = gcp(); % needs to run in parallel in order to allow the audio loop to start
% parfeval(p, @py.HeadTracker.processing, 0); % Oh yeah!!

% A third option would be to start the python script manually outside matlab.
% From our experiments the mostconvenient and fastest initiallization time
% was achieved with the binaries in HeadTracker.rar

%% Connect to UDP port
udpr = dsp.UDPReceiver('RemoteIPAddress', '127.0.0.1',...
                       'LocalIPPort',50050, ...
                       'ReceiveBufferSize', 18);

%% Configs
% Set the source position
s_azim = 0; % source azimuth
s_elev = 0; % source elevation
% Initiaalize head orientation
pitch = 0;  % head tracker
yaw = 0;    % head tracker
% Find corresponding hrtf index
idx_hrtf_pos = dsearchn(sourcePositions, [s_azim, s_elev]);
idx_hato_pos = dsearchn(HATO, yaw);
% Obtain a pair of HRTFs at the desired position.
HRIR = squeeze(Obj{idx_hato_pos}.Data.IR(idx_hrtf_pos,:,:));
release(deviceWriter) % just to make sure matlab isn't already using the device
release(sigsrc)

% Signal length (it plays in a loop, so you can set whatever)
max_time = 10; 

% Plot configs
ax = figure(1);
cla()
color_yaw = [0 0.4470 0.7410];
color_pitch = [0.8500 0.3250 0.0980];
props_yaw = {'LineStyle','none','Marker','o','MarkerEdge',color_yaw,'MarkerSize',5, ...
                         'MarkerFaceColor', color_yaw};
props_pitch = {'LineStyle','none','Marker','o','MarkerEdge',color_pitch,'MarkerSize',5, ...
 'MarkerFaceColor', color_pitch};
ylim([-80, 80])
xlim([0 max_time])
xlabel('Time (s)')
ylabel('Angle (°)')

line([0,max_time], [0, 0], 'color', 'b'); hold on 

% Change background color (for chroma key)
% set(gca, 'color', [0 1 0])
% set(gcf, 'color', [0 1 0])
% set(gca,'XColor','b','YColor','b');


%% START AURALIZATION
tic
while toc < max_time
    pause(0)

    % Ler orientação atual do HeadTracker.
    py_output = step(udpr);
    
    if ~isempty(py_output)
        data = str2num(convertCharsToStrings(char(py_output))); %#ok<*ST2NM>
        yaw = data(1);
        pitch = data(2);
%         roll = data(3);
        idx_hato_pos = dsearchn(HATO, yaw);
        idx_hrtf_pos = dsearchn(sourcePositions, [s_azim + yaw, s_elev + pitch]);       
        % Obtain a pair of HRTFs at the desired position.
        HRIR = squeeze(Obj{idx_hato_pos}.Data.IR(idx_hrtf_pos,:,:));
        
        % Plot real time coordinates
        x = toc;
        line([x,x],[yaw,yaw], props_yaw{:}); % yaw plot
%         line([x,x],[pitch,pitch], props_pitch{:}); % pitch plot
    end     
    % Read audio from file   
    audioIn = sigsrc();      
    % Apply HRTFs
    audioFiltered(:,1) = FIR{1}(audioIn, HRIR(1,:)); % Left
    audioFiltered(:,2) = FIR{2}(audioIn, HRIR(2,:)); % Right    
    deviceWriter(squeeze(audioFiltered));                
end
release(sigsrc)
release(deviceWriter)
