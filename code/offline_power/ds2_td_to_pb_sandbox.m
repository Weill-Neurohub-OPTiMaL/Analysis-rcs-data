%% Load in data
% just click and drag from folder
dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};
[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);


%% create masking and indexing arrays for data

% fft samples
fft_mask = cellfun(@length, combinedDataTable.FFT_FftOutput) > 1;
fft_idx = find(fft_mask);

% extract fft array, convert to internal units, and convert to power
fft = combinedDataTable.FFT_FftOutput(fft_mask);
fft = cell2mat(cellfun(@transpose, fft, 'UniformOutput', false));
fft = transformMVtoRCS(fft, metaData.ampGains.Amp1);
fft = 4 * (fft.^2);
fft_time = combinedDataTable.DerivedTime(fft_mask);

% pb samples
pb_mask = ~isnan(combinedDataTable.Power_Band1);
pb_idx = find(pb_mask);

% extract power bands
pb1 = combinedDataTable.Power_Band1(pb_mask);
pb2 = combinedDataTable.Power_Band2(pb_mask);
pb_time = combinedDataTable.DerivedTime(pb_mask);

fft_bins_actual = powerSettings.powerBands.fftBins ...
                  - powerSettings.powerBands.fftBins(1);


%% Compute power bands from time-domain data and plot against PB outputs

% first just do it for the single-bin PB1 and the first bit-shift block
data_td_mv = combinedDataTable.TD_key0;
timestamps_td = combinedDataTable.DerivedTime;
fs_td = timeDomainSettings.TDsettings{1,1}(1).sampleRate; %250
interval = fftSettings.fftConfig(1,1).interval; %500
L = fftSettings.fftConfig(1,1).size; %1024;
amp_gain = metaData.ampGains.Amp1;
hann_win = hannWindow(L, '100% Hann');
bit_shift = str2double(fftSettings.fftConfig.bandFormationConfig(6)); % 7

bins = powerSettings.powerBands.indices_BandStart_BandStop(1:2,:); 

% convert mV to RCS units
data_td_rcs = transformMVtoRCS(data_td_mv, amp_gain);
% compute the FFT
[data_fft, timestamps_fft] = rcs_td_to_fft(data_td_rcs, timestamps_td, ...
                                   L, interval, fs_td, amp_gain, hann_win);
% extract the power bands
data_pb = rcs_fft_to_pb(data_fft, L, fs_td, hann_win, bit_shift);
pb1_est = data_pb(:,bins(1,1));
pb2_est = data_pb(:,bins(2,1));

% Plot the measured power band with the estimated
figure
zero_time = timestamps_fft(1);

subplot(2,1,1)
yyaxis left
plot(pb_time - zero_time, pb1)
ylabel('Measured PB output [units]')
yyaxis right
plot(timestamps_fft - zero_time, pb1_est)
ylabel('Computed PB from TD [units]')
xlabel('Time [sec]')

subplot(2,1,2)
yyaxis left
plot(pb_time - zero_time, pb2)
ylabel('Measured PB output [units]')
yyaxis right
plot(timestamps_fft - zero_time, pb2_est)
ylabel('Computed PB from TD [units]')
xlabel('Time [sec]')


%% Calculate predicted PB's from FFT outputs and compare to actual
% this is done without separating the bit-shift blocks

% pull out FFT-based estimate and scale them according to the shift
% parameter used in each block
bit_shift = str2double(fftSettings.fftConfig.bandFormationConfig(6)); % 7
shift_scale = 2^(8-bit_shift);
fft_shifted = floor(fft / shift_scale);
bins = powerSettings.powerBands.indices_BandStart_BandStop(1,:); % [11,12]
% pb2_true_rescaled = pb2 * inverse_gains;

figure
subplot(2,1,1)
title({'Power band 1',...
       'bin indices [83,83], center frequencies [20.02, 20.02] Hz'})
yyaxis left
plot((pb_time-pb_time(1))/1000, pb1)
ylim([4e4, 5e4])
% ylim([3.76e5, 3.82e5])
% ylim([0, quantile(pb1_true_rescaled,0.98)])
ylabel('Measured PB output [units]')
yyaxis right
plot((fft_time-pb_time(1))/1000, fft_shifted(:,bins(1)))
ylim([4e4, 5e4])
% ylim([3.76e5, 3.82e5])
ylabel('Calculated PB from FFT [units]')
xlabel('Time [s]')

subplot(2,1,2)
title('Diff plot')
yyaxis left
plot((pb_time(2:end)-pb_time(1))/1000, diff(pb1))
ylim([-7e3, 7e3])
ylabel({'Change in measured', 'PB output [units/sample]'})
yyaxis right
plot((fft_time(2:end)-pb_time(1))/1000, diff(fft_shifted(:,bins(1))))
ylim([-7e3, 7e3])
ylabel({'Change in calculated', 'PB from FFT [units/sample]'})
xlabel('Time [s]')


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

writerObj = VideoWriter('myVideo.avi');
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