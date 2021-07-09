function Obj = sofaResample(Obj, Fs)
% Muda resolução aparente de objeto SOFA para valor especificado

% Davi R. Carvalho @UFSM - Engenharia Acustica - Junho/2021

%   Input Parameters:
%    Obj:        Objeto de HRTFs SOFA a ser modificado 
%    Fs:         Taxa de amostragem Objetivo

%   Output Parameters:
%     Obj:   Objeto de HRTFs SOFA com a taxa de amostragem Fs
%
% Matlab R2020b
%% Resample
Fs_sofa = Obj.Data.SamplingRate;

%% Check if upsampling is necessary first
factor = 4;
if Fs>Fs_sofa && Fs/Fs_sofa<factor || ... % do upsampling first 
        Fs<Fs_sofa && Fs_sofa/Fs<factor
    Fs_up = Fs_sofa*factor;
    IR_upsample = resample_this(Obj.Data.IR, Fs_sofa, Fs_up);
    IR = resample_this(IR_upsample, Fs_up, Fs);  
else % just do the resample already
    IR = resample_this(Obj.Data.IR, Fs_sofa, Fs);
end

%% Output
Obj.Data.IR = IR;
% update sampling rate
Obj.Data.SamplingRate = Fs;
Obj = SOFAupdateDimensions(Obj);
end


%--------------------------------------------------------------------------
function IR = resample_this(X, Fs_in, Fs_out)
    [p,q] = rat(Fs_out / Fs_in, 0.0001);
    normFc = .965 / max(p,q);
    order = 256 * max(p,q);
    beta = 12;
    %%% Cria um filtro via Least-square linear-phase FIR filter design
    lpFilt = firls(order, [0 normFc normFc 1],[1 1 0 0]);
    lpFilt = lpFilt .* kaiser(order+1,beta)';
    lpFilt = lpFilt / sum(lpFilt);
    lpFilt = p * lpFilt;

    % Initializar matriz
    N_pos = size(X, 1);
    N_ch = size(X, 2);
    N_samples = ceil((Fs_out/Fs_in) * size(X, 3)); % length after resample

    % Permute IR dims
    sz = size(X);
    dimorder = length(sz):-1:1;
    X = permute(X, dimorder);
    
    % Actual Resample
    IR = resample(X, p, q, lpFilt);

    IR = IR.* q/p; % check scaling
    
    % make sure signal length is not odd
    if rem(size(IR,1), 2) ~= 0
       str = 'IR(end';
       for k = 1:length(sz)-1 % (variable dimension size)
          str =  [str ', :'];
       end
       str = [str, ') = [];'];
       eval(str);
    end
    IR = permute(IR, dimorder);
end



