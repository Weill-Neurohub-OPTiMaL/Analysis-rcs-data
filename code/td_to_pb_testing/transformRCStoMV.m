%% Function Name: data_mv = transformRCStoMV(data_rcs, amp_gain)
%
% Description: Converts data in units of mV to the internal unit 
% representation used on the RC+S device.
%
% Inputs:
%     data_mV : (num_samples, num_channels) array, or transpose
%         Data, either time-domain or FFT amplitude, given in units of mV.
%         If a two dimensional array is given, the result will be returned
%         in the same shape.
%     amp_gain : int, 
%         Parameter indicating the channel gain represented by the
%         cfg_config_data.dev.HT_sns_ampX_gain250_trim value in the
%         DeviceSettings.json file, or the metaData.ampGains OpenMind
%         output.
%
% Author: Tanner Chas Dixon, tanner.dixon@ucsf.edu
% Date: February 3, 2022
%---------------------------------------------------------

function data_mv = transformRCStoMV(data_rcs, amp_gain)
rcs_constant = 48644.8683623726;    % unique RC+S constant
amp_gain = 250*(amp_gain/255);  % convert actual channel amp gain
data_mv = data_rcs * (1000*1.2) / (amp_gain*rcs_constant);
end