%% Function Name: data_fft = rcs_fft_to_pb(data_td, L, interval, fs_td, amp_gain)
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

function data_pb = rcs_fft_to_pb(data_fft, L, fs_td, hann_win, bit_shift)



% normalize by hann_win or L (not sure which is done on device yet)
% data_fft = data_fft/L;
% data_fft = data_fft/sum(hann_win);

% convert amplitude to power
data_fft = data_fft.^2;

% convert from single-sided to two-sided spectrum
data_fft = 64 * data_fft(:,1:L/2) / (L^2);
% data_fft(:,2:end) = 2*data_fft(:,2:end);
% data_fft = data_fft/(fs_td/L);

% perform the bit-shift
data_pb = floor(data_fft/(2^(8-bit_shift)));

end