%% Load in data - all data tables

dataStreams = {timeDomainData, AccelData, PowerData, FFTData, ...
               AdaptiveData};
[combinedDataTable] = createCombinedTable(dataStreams,...
                                          unifiedDerivedTimes, metaData);


%% Create masking and indexing arrays for data

% pb samples
pb_mask = ~isnan(combinedDataTable.Power_Band1);

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


%% Compute offline estimates of each recorded PB channel

% Assign all the inputs. These could be the inputs for a wrapper function.
time_td = combinedDataTable.DerivedTime;
fs_td = timeDomainSettings.TDsettings{1,1}(1).sampleRate;
interval = fftSettings.fftConfig(1,1).interval;
L = fftSettings.fftConfig(1,1).size;
hann_win = hannWindow(L, fftSettings.fftConfig.windowLoad);
bit_shift = str2double(fftSettings.fftConfig.bandFormationConfig(6));

% Calculate the actual center frequencies for all FFT bins
center_freqs = (0:(L/2-1)) * fs_td/L;

% Iterate over all recorded PB's and compute their offline estimates
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


%% Plot results to compare computed and measured PB's

figure
zero_time = pb_time(1);

for k = 1:8
    subplot(4,2,k)
    plot((pb_time - zero_time)/1000, pb_true(:,k))
    hold on
    plot((time_fft - zero_time)/1000, pb_est(:,k))
    ylabel({'Power', '[RCS units]'})
    xlabel('Time [sec]')
    title(ttl{k})
    xlim([2000,2100])
    ylim([0, quantile(pb_est(:,k), 0.99)])
end
legend({'Measured', 'Computed from TD'})


