%% Function Name: data_fft = rcs_td_to_fft(data_td, L, interval, fs_td, amp_gain)
%
% Description: Converts data in units of mV to the internal unit 
% representation used on the RC+S device.
%
% Inputs:
%     data_td : (num_samples, num_channels) array, or transpose
%         Data, either time-domain or FFT amplitude, given in units of mV.
%         If a two dimensional array is given, the result will be returned
%         in the same shape.
%     L : int, 
%         Parameter indicating the channel gain represented by the
%         cfg_config_data.dev.HT_sns_ampX_gain250_trim value in the
%         DeviceSettings.json file, or the metaData.ampGains OpenMind
%         output.
%     interval : int, 
%         Parameter indicating the channel gain represented by the
%         cfg_config_data.dev.HT_sns_ampX_gain250_trim value in the
%         DeviceSettings.json file, or the metaData.ampGains OpenMind
%         output.
%     fs_td : int, 
%         Parameter indicating the channel gain represented by the
%         cfg_config_data.dev.HT_sns_ampX_gain250_trim value in the
%         DeviceSettings.json file, or the metaData.ampGains OpenMind
%         output.
%
% Author: Tanner Chas Dixon, tanner.dixon@ucsf.edu
% Date: February 3, 2022
%---------------------------------------------------------

function [data_fft, timestamps] = rcs_td_to_fft(data_td, timestamps, L, ...
                                       interval, fs_td, amp_gain, hann_win)

% The actual FFT uses a smaller number of actual time-domain samples and
% zero-pads the remainder
switch L
    case 64
        L_non_zero = 62;
    case 256
        L_non_zero = 250;
    case 1024
        L_non_zero = 1000;
end

% Linearly interpolate over nan-values
nan_mask = isnan(data_td);
idx = 1:numel(data_td);
data_td(nan_mask) = interp1(idx(~nan_mask), data_td(~nan_mask), ...
    idx(nan_mask));
% data_td = transformMVtoRCS(data_td, amp_gain);

% Select all FFT window edges
mean_window_shift = interval*fs_td/1000;
num_windows = floor((length(data_td)-L)/mean_window_shift)...
    + 1;
window_stops = ceil((0:num_windows-1)*mean_window_shift) ...
    + L_non_zero;
window_starts = window_stops - L_non_zero + 1;
timestamps = timestamps(window_stops);
% data_fft = zeros(num_windows, L/2);
data_fft = zeros(num_windows, L);
for s = 1:length(window_stops)
    % select the time-domain window and zero-pad remaining points
    td_window = zeros(1,L);
    td_window(1:L_non_zero) = ...
        data_td(window_starts(s):window_stops(s))';
    % take the FFT to get two-sided amplitude spectrum
    current_fft = fft(td_window.*hann_win, L);
    %     current_fft = abs(current_fft) / sqrt(2*L);
%     current_fft = 2*abs(current_fft)/L;
%     current_fft = 2*abs(current_fft)/sum(hann_win);
    current_fft = abs(current_fft);
%     current_fft = current_fft(1:L/2);
    %     current_fft = transformRCStoMV(current_fft, amp_gain); % this should be removed after testing. we can do it on the back end, but leaving it out will allow this function to be reused in a wrapper that does the full TD->FFT->PB
    data_fft(s,:) = current_fft;

end
end