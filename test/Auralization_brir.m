
clear all; clc

%% Carregar objeto sofa
path = 'bbcrdlr_all_speakers.sofa'; % download from : http://data.bbcarp.org.uk/bbcrd-brirs/sofa/
Obj = SOFAload(path, 'nochecks');
Fs = Obj.Data.SamplingRate;


%% Check if coordinates are spheric 
if strcmp(Obj.ListenerView_Type, 'cartesian')
    ListenerPos_cart = Obj.ListenerView;
    [ListenerPos_sph(:,1),ListenerPos_sph(:,2),ListenerPos_sph(:,3)] = ...
                                        cart2sph(ListenerPos_cart(:,1),...
                                                 ListenerPos_cart(:,2),...
                                                 ListenerPos_cart(:,3));
    ListenerPos_sph(:,1:2)= rad2deg(ListenerPos_sph(:,1:2));
    [ListenerPos_sph(:,1), ListenerPos_sph(:,2)] = nav2sph(-ListenerPos_sph(:,1),...
                                                      ListenerPos_sph(:,2));
    Obj.ListenerView = ListenerPos_sph;
end


%% Change from spherical sofa to spherical navigational 
listener_posi = Obj.ListenerView;
listener_posi = -sph2nav(listener_posi);
pos = listener_posi(:,1);

n_listener_pos = size(Obj.ListenerView,1);
n_source_pos = size(Obj.EmitterPosition,1);
BRIRs = permute(Obj.Data.IR, [2,4,3,1]);
n_samples = size(BRIRs,2);


%% Source position 
source_posi = Obj.EmitterPosition;
desired_spk_pos = [45, 0, 3;
                    0, 0, 3;
                  -45, 0, 3];
idx_spk_pos = dsearchn(source_posi, desired_spk_pos);


%% Carregar audio 
path_audio = '3canais.wav';
[audio, fs_audio] = audioread(path_audio);

if fs_audio ~= Obj.Data.SamplingRate
    audio = resample(audio, Obj.Data.SamplingRate, fs_audio);
end

audio = audio./max(abs(audio(:)))*.975;
n_ch_audio = size(audio,2); 

% Criar objeto DSP
samples_per_frame = 1024;
sigsrc = dsp.SignalSource(audio, samples_per_frame);
deviceWriter = audioDeviceWriter('SampleRate', Fs, "BitDepth","16-bit integer");
setup(deviceWriter, zeros(samples_per_frame, 2))


%% Abrir head tracker
addpath('..\src\output\HeadTracker\');
open('HeadTracker.exe') 
% Connect to UDP port
udpr = dsp.UDPReceiver('RemoteIPAddress', '127.0.0.1',...
                       'LocalIPPort',50050, ...
                       'ReceiveBufferSize', 18);


%% Loop de reproducao
% Criar objeto FIR 
PartitionSize = 2^nextpow2(n_samples/4);

for s=1:n_ch_audio
    firBRIR1{s} =  dsp.FrequencyDomainFIRFilter('Method', 'overlap-save',...
                                              'PartitionForReducedLatency', true,...
                                              'PartitionLength', PartitionSize );
    firBRIR2{s} =  dsp.FrequencyDomainFIRFilter('Method', 'overlap-save',...
                                              'PartitionForReducedLatency', true,...
                                              'PartitionLength', PartitionSize);
end

sz = size(firBRIR1);
nfir = numel(firBRIR1);

% Inicializar variaveis
out_l = zeros(samples_per_frame,n_ch_audio);
out_r = zeros(samples_per_frame,n_ch_audio);
out = zeros(samples_per_frame,2);
idx_changer = inf;

% Initialize head orientation
yaw = 0;    % head tracker
idx_hato = dsearchn(pos, yaw);
% BRIRs = BRIRs(:,1:8192,:,:);


% Play --------------------------------------------------------------------
release(deviceWriter) % just to make sure matlab isn't already using the device
release(sigsrc) 


while ~isDone(sigsrc)
   %%% Head tracker
    py_output = udpr();
    if ~isempty(py_output)            
        data = str2double(split(convertCharsToStrings(char(py_output)), ','));
        idx_hato = dsearchn(pos, -data(1));
    end
    
    %%%% Read audio file   
    audioIn = sigsrc(); 
    
    %%%% Apply BRIRs
    for n=1:n_ch_audio % FL, FR, RL; RR
        if idx_changer ~= idx_hato
            spk = idx_spk_pos(n);
            firBRIR1{n}.Numerator = squeeze(BRIRs(1,:,spk,idx_hato));
            firBRIR2{n}.Numerator = squeeze(BRIRs(2,:,spk,idx_hato));
            audioIn(:,n) = audioIn(:,n);
        end
        out_l(:,n) = firBRIR1{n}(audioIn(:,n));
        out_r(:,n) = firBRIR2{n}(audioIn(:,n));   
    end 
   idx_changer = idx_hato;
    %%% Output 
    out = [mean(out_l,2),...    
           mean(out_r,2)];
      
    deviceWriter(out);
end
