%% Load in data
% just click and drag from folder
dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};
[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);


%% create masking and indexing arrays for data

% pb samples
pb_mask = ~isnan(combinedDataTable.Power_Band1);
pb_idx = find(pb_mask);

% extract power bands
pb1 = combinedDataTable.Power_Band1(pb_mask);
pb2 = combinedDataTable.Power_Band2(pb_mask);
pb_time = combinedDataTable.DerivedTime(pb_mask);


%% Compute power bands from time-domain data and plot against PB outputs

% first just do it for the single-bin PB1 and the first bit-shift block
data_td_mv = combinedDataTable.TD_key0;
timestamps_td = combinedDataTable.DerivedTime;
fs_td = timeDomainSettings.TDsettings{1,1}(1).sampleRate; %500;
interval = 100; %fftSettings.fftConfig(1,1).interval; %100;
L = fftSettings.fftConfig(1,1).size; %256;
amp_gain = metaData.ampGains.Amp1;
hann_win = hannWindow(L, '100% Hann');
bit_shift = str2double(fftSettings.fftConfig.bandFormationConfig(6)); %7;

% convert mV to RCS units
data_td_rcs = transformMVtoRCS(data_td_mv, amp_gain);
% compute the FFT
[data_fft, timestamps_fft] = rcs_td_to_fft(data_td_rcs, timestamps_td, ...
                                   L, interval, fs_td, amp_gain, hann_win);
% extract the power band
data_pb = rcs_fft_to_pb(data_fft, L, fs_td, hann_win, bit_shift);
bins = powerSettings.powerBands.indices_BandStart_BandStop; % [11,12]
bins_hz = powerSettings.powerBands.fftBins...
          - powerSettings.powerBands.fftBins(1);
pb1_est = sum(data_pb(:,bins(1,1):bins(1,2)), 2);
pb2_est = sum(data_pb(:,bins(2,1):bins(2,2)), 2);

% Plot the measured power band with the estimated
figure
zero_time = timestamps_fft(1);

subplot(3,1,1)
yyaxis left
plot((pb_time - zero_time)/1000, pb1)
ylim([0,1e4])
ylabel('Measured PB output [units]')
yyaxis right
plot((timestamps_fft - zero_time)/1000, pb1_est)
ylim([0,1e4])
ylabel('Computed PB from TD [units]')
xlabel('Time [sec]')
title({['Power band 1 bin indices [',num2str(bins(1,:)),']'], ...
       ['center frequencies [',num2str(bins_hz(bins(1,:))),'] Hz']})

subplot(3,1,2)
yyaxis left
plot((pb_time - zero_time)/1000, pb2)
ylim([0,4e3])
ylabel('Measured PB output [units]')
yyaxis right
plot((timestamps_fft - zero_time)/1000, pb2_est)
ylim([0,4e3])
ylabel('Computed PB from TD [units]')
xlabel('Time [sec]')
title({['Power band 2 bin indices [',num2str(bins(2,:)),']'], ...
       ['center frequencies [',num2str(bins_hz(bins(2,:))),'] Hz']})

%PB5 is on a different Time-Domain channel
data_td_mv = combinedDataTable.TD_key2;
timestamps_td = combinedDataTable.DerivedTime;
fs_td = timeDomainSettings.TDsettings{1,1}(1).sampleRate; %500;
interval = 100; %fftSettings.fftConfig(1,1).interval; %100;
L = fftSettings.fftConfig(1,1).size; %256;
amp_gain = metaData.ampGains.Amp3;
hann_win = hannWindow(L, '100% Hann');
bit_shift = str2double(fftSettings.fftConfig.bandFormationConfig(6)); %7;



subplot(3,1,2)
yyaxis left
plot((pb_time - zero_time)/1000, pb5)
ylim([0,4e3])
ylabel('Measured PB output [units]')
yyaxis right
plot((timestamps_fft - zero_time)/1000, pb5_est)
ylim([0,4e3])
ylabel('Computed PB from TD [units]')
xlabel('Time [sec]')
title({['Power band 2 bin indices [',num2str(bins(5,:)),']'], ...
       ['center frequencies [',num2str(bins_hz(bins(5,:))),'] Hz']})


%% movie writing blurb

subplot(2,1,1)
xlim([0,100])
subplot(2,1,2)
xlim([0,100])
for shift = 0:500
    subplot(2,1,1)
    xlim([0,100]+shift)
    subplot(2,1,2)
    xlim([0,100]+shift)
%     pause(0.1)
    F(shift+1) = getframe(gcf);
    drawnow
end

writerObj = VideoWriter('its_working.avi');
writerObj.FrameRate = 10;
% open the video writer
open(writerObj);
% write the frames to the video
for i=1:length(F)
    % convert the image to a frame
    frame = F(i) ;    
    writeVideo(writerObj, frame);
end
% close the writer object
close(writerObj);

