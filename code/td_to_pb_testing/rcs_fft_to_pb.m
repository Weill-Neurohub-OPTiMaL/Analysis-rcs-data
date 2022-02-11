%% Function Name: rcs_fft_to_pb()
%
% Description: Converts short-time FFT outputs to scaled Power Band signals 
% (or full spectrogram) with the same scaling operations performed onboard 
% the RC+S device.
%
% Inputs:
%     data_fft : (num_windows, L) array, or transpose
%         FFT amplitude data given in internal RC+S units. This may also be
%         given in units of mV (matching the format in FFT data logs) if 
%         specified by the `input_is_mv` parameter. The result will be 
%         returned in the same shape.
%     fs_td : int
%         The Time-Domain sampling rate, in Hz.
%     L : int, {64, 256, 1024}
%         FFT size, in number of samples.
%     bit_shift : int, 0:7
%         Parameter indicating the number of most-significant-bits to be
%         discarded. This value should be input as exactly the same value
%         programmed on the device.
%     band_edges : optional (num_bands, 2) array, or transpose, default=[]
%         Edges of each power band requested. If empty, the function will
%         return the full L/2-dimensional single-sided spectrogram.
%     input_is_mv : optional boolean, default=False
%         Boolean flag indicating whether the FFT input was given in units
%         of scaled mV, matching the format in the raw data logs.
%
% Outputs:
%     data_pb : (num_windows, num_bands) array
%         Power Band data given in internal RC+S units, or the full
%         L/2-dimensional spectrogram.
%
% Author: Tanner Chas Dixon, tanner.dixon@ucsf.edu. Credit to Juan Anso for
%             earlier version of the code.
% Date last updated: February 10, 2022
%---------------------------------------------------------

function data_pb = rcs_fft_to_pb(data_fft, fs_td, L, bit_shift, ...
                                 band_edges, input_is_mv)

% Validate function arguments and set defaults
arguments
    data_fft {mustBeNumeric}
    fs_td {mustBeInteger}
    L {mustBeMember(L,[64,256,1024])} 
    bit_shift {mustBeMember(bit_shift,0:7)} 
    band_edges {mustBeNumeric} = []
    input_is_mv {mustBeNumericOrLogical} = false
end

% Create a vector containing the center frequencies of all FFT bins
center_freqs = (0:(L/2-1)) * fs_td/L;

% convert amplitude to power
data_fft = data_fft.^2;

% convert from single-sided to two-sided spectrum
data_fft = 64 * data_fft(:,1:L/2) / (L^2);
% data_fft(:,2:end) = 2*data_fft(:,2:end);
% data_fft = data_fft/(fs_td/L);

% perform the bit-shift
data_pb = floor(data_fft/(2^(8-bit_shift)));

end