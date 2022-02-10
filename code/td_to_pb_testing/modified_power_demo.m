close all
clear all
clc

%% Testing datasets
% This code has been tested with a set of datasets under
% ~/Box/UCSF-RCS_Test_Datasets_Analysis-rcs-data-Code/../Power/...
% Access to this folder is managed and restricted to UCSF employees under
% (https://ucsf.box.com/s/bolhachjv80rhywa5h0r9peo73mz3003)
%
% This example code can be run with a benchotp dataset that is shared for any user under
% https://ucsf.box.com/s/9bte1t8s4il7rr0ot4egwsae1exl5y7i

%% This code assumes you have run ProcessRCS and/or DEMO_LoadRCS.m
% Select file
[fileName,pathName] = uigetfile('AllDataTables.mat');

% Load file
disp('Loading selected .mat file')
load([pathName fileName])

% Create unified table with selected data streams -- use timeDomain data as
% time base
dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};
[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);

%% Example how to compare streamed power from device and 'off line' calculated power, given
% - predefined fftSettings
% - predefined powerSettings

% Comparing 'off line' power data with the RCS streamed for default fft and power settings
if ~isempty(powerSettings)
    
    % Here we get the power calculated 'off-line' using the time domain
    % for each power channel that have been streamed
    [combinedPowerTable, powerTablesBySetting] = getPowerFromTimeDomain(combinedDataTable,fftSettings(1,:), powerSettings(2,:), metaData,2); 
    idxPowerCalc = ~isnan(combinedPowerTable.Power_Band1);
    idxPowerRCS = ~isnan(combinedDataTable.Power_Band1);
    
    % plot the result, comparing actual Streamed power with 'off line'
    figure, hold on, legend show, set(gca,'FontSize',20)       
    title('RC+S band power: on-board vs off-line comparison')
    band = powerSettings.powerBands(2).fftBins(2) ...
           - powerSettings.powerBands(2).fftBins(1);
    yyaxis left
    y = combinedDataTable.(['Power_Band',num2str(1)])(idxPowerRCS);
    plot(combinedDataTable.localTime(idxPowerRCS),...
                y,...
                'Marker','*','MarkerSize',1,'Linewidth',1,...
                'DisplayName',['on-board, band(Hz) = ',num2str(band)])
    ylim([0 quantile(y, 0.98)])
                        
%     plot(combinedPowerTable.localTime(idxPowerCalc),...
%                 combinedPowerTable.(['Power_Band',num2str(1)])(idxPowerCalc),...
%                 'Marker','o','MarkerSize',5,'LineWidth',2,...
%                 'DisplayName',['Calculated Power Band, Bins(Hz) = ',powerSettings.powerBands(1).powerBinsInHz{1}])                 
    
    % Here we calculate equivalent power series from a selected
    % time domain channel (1, 2, 3 or 4) for a chosen power band [X,Y]Hz
    [newPowerFromTimeDomain, newSettings] = calculateNewPower(combinedDataTable, fftSettings(1,:), powerSettings(2,:), metaData, 1, [5 6]);
    idxPowerNewCalc = ~isnan(newPowerFromTimeDomain.calculatedPower);  
    
    % plot the result
    bin_indices = newSettings.powerSettings.powerBands.indices_BandStart_BandStop;
    band = newSettings.powerSettings.powerBands.fftBins(bin_indices) ...
           - newSettings.powerSettings.powerBands.fftBins(1);
    yyaxis right
    y = newPowerFromTimeDomain.calculatedPower(idxPowerNewCalc);
    plot(newPowerFromTimeDomain.localTime(idxPowerNewCalc),...
                y,...
                'Marker','o','MarkerSize',1,'LineWidth',2,...
                'DisplayName',['off-line, band(Hz) = ',num2str(band)])
    ylim([0 quantile(y, 0.98)])
            
    ylabel('Power (millivolts^2)')
end

%% Example how to create a power output just based on time domain signal and desired fft and power settings, e.g.
% provided power was not sense and/or streame and/or you want to define
% power band limits given a different fftSize than default used during recording session

% Reset powerSettings to avoid table
powerSettings = [];
newfftSettings = fftSettings;
% take default sampling rate - a must
currentTDsampleRate = fftSettings.TDsampleRates;    

% Choose new fft parameters and frequency band between these options
% fft interval: 50 to 50000 ms
% fft size: 64, 256, 1024      
% windowLoad ('100% Hann', '50% Hann', '25% Hann')
% freqBand:[0 to samplingRate/2]
newfftSettings.fftConfig.interval = 50;
newfftSettings.fftConfig.size = 256;
newfftSettings.fftConfig.windowLoad = '100% Hann';
freqBand = [20, 23];

% Determine fftBins
numBins = newfftSettings.fftConfig.size/2;
binWidth = (currentTDsampleRate/2)/numBins;
lowerBins = (0:numBins-1)*binWidth;
fftBins = lowerBins + binWidth/2;          % Bin center

% Create a powerSettings structure based on chosen parameters   
powerSettings.fftConfig.interval = newfftSettings.fftConfig.interval;
powerSettings.fftConfig.size = newfftSettings.fftConfig.size;
powerSettings.powerBands.fftBins = fftBins;

% Determine indeces of frquency bins corresponsing and add to power settings structure
idxBinsA = find(powerSettings.powerBands.fftBins>freqBand(1));
idxBinsB = find(powerSettings.powerBands.fftBins<freqBand(2));
powerSettings.powerBands.indices_BandStart_BandStop(1,1) = idxBinsA(1);
powerSettings.powerBands.indices_BandStart_BandStop(1,2) = idxBinsB(end);

% Calculate equivalent device power given the new fft and power settings
[newPower, newSettings] = calculateNewPower(combinedDataTable, newfftSettings, powerSettings, metaData, 1, freqBand);
idxPowerNewCalc = ~isnan(newPower.calculatedPower);    

% Plot the results
% figure, hold on, legend show, set(gca,'FontSize',15)                     
plot(newPower.localTime(idxPowerNewCalc),...
        newPower.calculatedPower(idxPowerNewCalc),...
        'Marker','s','MarkerSize',1,'LineWidth',2,...
        'DisplayName',['off-line, band(Hz) = ',newSettings.powerSettings.powerBands.powerBinsInHz])
    
% END: remember this are only examples of use
% If you find errors while using this code or want to help further develop
% it, feel free to contact juan.ansoromeo@ucsf.edu or juan.anso@gmail.com