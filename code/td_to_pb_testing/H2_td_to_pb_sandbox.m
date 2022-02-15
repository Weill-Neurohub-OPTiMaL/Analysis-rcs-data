%% Load in data
% just click and drag from folder
dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};
[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);


%% create masking and indexing arrays for data

% pb samples
pb_mask = ~isnan(combinedDataTable.Power_Band1);
pb_idx = find(pb_mask);

% extract power bands
pb_true = [combinedDataTable.Power_Band1(pb_mask),...
           combinedDataTable.Power_Band2(pb_mask),...
           combinedDataTable.Power_Band3(pb_mask),...
           combinedDataTable.Power_Band4(pb_mask),...
           combinedDataTable.Power_Band5(pb_mask),...
           combinedDataTable.Power_Band6(pb_mask),...
           combinedDataTable.Power_Band7(pb_mask),...
           combinedDataTable.Power_Band8(pb_mask)];
pb_time = combinedDataTable.DerivedTime(pb_mask);

%% New updated TD to PB code testing

% first just do it for the single-bin PB1 and the first bit-shift block
time_td = combinedDataTable.DerivedTime;
fs_td = timeDomainSettings.TDsettings{1,1}(1).sampleRate; %500;
interval = fftSettings.fftConfig(1,1).interval; %100;
L = fftSettings.fftConfig(1,1).size; %256;
hann_win = hannWindow(L, fftSettings.fftConfig.windowLoad);
bit_shift = str2double(fftSettings.fftConfig.bandFormationConfig(6)); %7;

% Assign the power band
center_freqs = (0:(L/2-1)) * fs_td/L;

% plot all recorded power bands against their computed estimates
pb_est = [];
ttl = cell(8,1);
for k = 1:8
    % grab the Time-Domain data and amplifier gain
    if k<3 % amp1
        data_td_mv = combinedDataTable.TD_key0;
        amp_gain = metaData.ampGains.Amp1;
    elseif k<5 % amp2
        data_td_mv = combinedDataTable.TD_key1;
        amp_gain = metaData.ampGains.Amp2;
    elseif k<7 % amp3
        data_td_mv = combinedDataTable.TD_key2;
        amp_gain = metaData.ampGains.Amp3;
    else %amp4
        data_td_mv = combinedDataTable.TD_key3;
        amp_gain = metaData.ampGains.Amp4;
    end

    % select the frequency band
    pb_band_idx = powerSettings.powerBands.indices_BandStart_BandStop(k,:);
    band_edges_hz = center_freqs(pb_band_idx);

    % compute the estimate
    % TD to FFT
    data_td_rcs = transformMVtoRCS(data_td_mv, amp_gain);
    [data_fft, time_fft] = rcs_td_to_fft(data_td_rcs, time_td, fs_td, ...
        L, interval, hann_win);
    % FFT to PB
    pbX_est = rcs_fft_to_pb(data_fft, fs_td, L, bit_shift, band_edges_hz);
    pb_est = [pb_est, pbX_est]; 

    % Assign subplot title
    ttl{k} = {['Power band ', num2str(k), ...
               ' bin indices [',num2str(pb_band_idx),']'], ...
              ['center frequencies [',num2str(band_edges_hz),'] Hz']};
end

% Plot results to compare computed and measured PB1
figure
zero_time = pb_time(1);

for k = 1:8
    subplot(4,2,k)
%     yyaxis left
    plot((pb_time - zero_time)/1000, pb_true(:,k))
%     ylim([0,8e3])
%     ylabel({'Measured PB output', '[RCS units]'})
%     yyaxis right
    hold on
    plot((time_fft - zero_time)/1000, pb_est(:,k))
%     ylim([0,8e3])
%     ylabel({'Computed PB from TD', '[RCS units]'})
    ylabel({'Power', '[RCS units]'})
    xlabel('Time [sec]')
    title(ttl{k})
    xlim([2000,2100])
end
legend({'Measured', 'Computed from TD'})



