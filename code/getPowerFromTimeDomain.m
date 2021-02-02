function [powerFromTimeDomain,powerDataRCS] = getPowerFromTimeDomain(folderpath)
% creates a table with both power computed signals and power data from RCS
% the transformation from time domain to power is done using hann windowing
% of the latest fft interval (new and old points, depending on overlapping)
% then fft is applied and the power calculated. The magnitude of the power




% is calculated as the sum of the power of all bins in the frequency band.
% 
% input: device folder path of session
% 
% parameters
%     timeDomainSettings
%     timeDomainData
%     powerSettings  
%     fft settings: sampling rate, fft size, fft interval, han window gain (100%, 50% or 25%)
%
% output
%     powerFromTimeDomain = table(Ptd1,Ptd2,Ptd3,Ptd4)
%
% dependencies: this function relies on the matlab library https://github.com/openmind-consortium/Analysis-rcs-data
% Assumptions:
% - hann window 100%
% - no change in fft settings in data set
% 

% this wrapper function is NOT standard in the default DEMO_ProcessRCS(), https://github.com/openmind-consortium/Analysis-rcs-data
% [timeDomainSettings,timeDomainData,AccelData,powerDataRCS, powerSettings,FFTData, metaData] = DEMO_ProcessRCS(folderpath);
[combinedDataTable, debugTable, timeDomainSettings,powerSettings,...
    fftSettings,eventLogTable, metaData,stimSettingsOut,stimMetaData,stimLogSettings,...
    DetectorSettings,AdaptiveStimSettings,AdaptiveRuns_StimSettings] = DEMO_ProcessRCS(folderpath);

% create table with actual amplifier gains per channel
AmpGains = createAmplifierGainsTable(folderpath); % this function still not added to repository (juan and ro'ee to coordinate with kristin)
powerFromTimeDomain = table;
for c=1:4
    % extract input parameters
    tch = combinedDataTable.DerivedTime;
    t = seconds(tch-tch(1))/1000;
    [interval,binStart,binEnd,fftSize,fftBinsHz] = readFFTsettings(powerSettings,c);
    sr = timeDomainSettings.samplingRate;
    switch fftSize % actual fft size of device for 64, 250, 1024 fftpoints
        case 64, fftSizeActual = 62;
        case 256, fftSizeActual = 250;
        case 1024, fftSizeActual = 1000;
    end
    keych = combinedDataTable.(['TD_key',num2str(c-1)]); % next channel
    td_rcs = transformTDtoRCS(keych,AmpGains.(['Amp',num2str(c)])); % transform TD signal to rcs internal values
    overlap = 1-(sr*interval/1e3/fftSizeActual); % time window parameters
    L = fftSize; % timeWin is now named L, number of time window points
    hann_win = 0.5*(1-cos(2*pi*(0:L-1)/(L-1))); % create hann taper function, equivalent to the Hann 100% 
    stime = 1; % sample 1 of data set where window starts
    totalTimeWindows = ceil(length(td_rcs)/L/(1-overlap)); 
    counter = 1; % initialize counter
    power = zeros(1,length(totalTimeWindows)); % initialize power variable
    while counter <= totalTimeWindows % loop through time singal
        if stime+L <= length(t) % check at least one time window available before reach end signal
            X = fft(td_rcs(stime:stime+L-1)'.*hann_win,fftSize); % fft of the next window
            SSB = X(1:L/2); % from double to single sided FFT
            SSB(2:end) = 2*SSB(2:end); % scaling step 1, multiply by 2 bins 2 to end (all except DC)
            YFFT = abs(SSB/(L/2)); % scaling step 2, dividing by fft buffer size (L/2) (to be hoest i think this should be L)
            fftPower = 2*(YFFT.^2); % this factor 2 is necessary to match power values from RCS
            power(counter) = sum(fftPower(binStart:binEnd)); % note that it is not an average, but rather a sum of the power of the bins in the band
        end
        counter = counter + 1;
        stime = stime + (L - ceil(L*overlap));
    end
    powerFromTimeDomain.(['PowerCh',num2str(c)]) = power';
end

end

function [interval,binStart,binEnd,fftSize,fftBinsHz] = readFFTsettings(powerSettings,c)
    % at the moment assuming the only active Power Band is Band 0
    interval = powerSettings.fftConfig.interval; % is given in ms
    binStart = powerSettings.powerBands{1}.band0Start; % assuming 1 power band
    binStart(1) = binStart(1)+1; % value from Json file is zero based numbering (bin index 3 in Json is bin 4 in matlab)
    binEnd = powerSettings.powerBands{1}.band0Stop;
    binEnd(1) = binEnd(1)+1; % value from Json file is zero based numbering (bin index 3 in Json is bin 4 in matlab)
    fftSize = powerSettings.powerBandsInHz.fftSize;
    fftBinsHz = powerSettings.powerBandsInHz.fftBins;
end

function td_rcs = transformTDtoRCS(keych,AmpGain)
    FP_READ_UNITS_VALUE = 48644.8683623726;    % predefined value from hardware 
    lfp_mv = nan(1,length(keych))';
    lfp_mv(~isnan(keych)) = keych(~isnan(keych))-mean(keych(~isnan(keych))); % remove mean
    config_trim_ch = AmpGain; % read from device settins (see above) 
    lfpGain_ch = 250*(config_trim_ch/255);  % actual gain amplifier ch
    lfp_rcs = lfp_mv * (lfpGain_ch*FP_READ_UNITS_VALUE) / (1000*1.2); % transform to rcs units
    td_rcs = lfp_rcs;
end


function AmpGains = createAmplifierGainsTable(folderPath)
% finds the actual gain of the amplifier (Amp channel: 1,2,3,4) and output
% it in a table

% Load in DeviceSettings.json file
DeviceSettings = jsondecode(fixMalformedJson(fileread([folderPath filesep 'DeviceSettings.json']),'DeviceSettings'));
%%
% Fix format - Sometimes device settings is a struct or cell array
if isstruct(DeviceSettings)
    DeviceSettings = {DeviceSettings};
end
%%
recordCounter = 1; % Initalize counter for records in DeviceSetting
while recordCounter <= length(DeviceSettings)
    currentSettings = DeviceSettings{recordCounter};
    % Check until Factory Settings are found
    if isfield(currentSettings,'FactorySettings')
         if isfield(currentSettings.FactorySettings,'name')
            for ii=1:size(currentSettings.FactorySettings,1)
                nextName = currentSettings.FactorySettings(ii).name; 
                if strcmp(nextName,'cfg_config_data.dev.HT_sns_amp1_gain250_trim')
                    AmpGains.Amp1 = currentSettings.FactorySettings(ii).actualValue;
                elseif strcmp(nextName,'cfg_config_data.dev.HT_sns_amp2_gain250_trim')
                    AmpGains.Amp2 = currentSettings.FactorySettings(ii).actualValue;
                elseif strcmp(nextName,'cfg_config_data.dev.HT_sns_amp3_gain250_trim')
                    AmpGains.Amp3 = currentSettings.FactorySettings(ii).actualValue;
                elseif strcmp(nextName,'cfg_config_data.dev.HT_sns_amp4_gain250_trim')
                    AmpGains.Amp4 = currentSettings.FactorySettings(ii).actualValue;
                end
            end    
         end
    end
    recordCounter = recordCounter+1;
end

end