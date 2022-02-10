%% Function Name: shifted_ints = bit_shift_rcs(original_ints, bit_shift)
%
% Description: Performs the bit-shifting operation that is done onboard the
% RC+S device. This takes in a 40-bit signed integer (FFT output) and 
% returns a signed integer represented by 32 of those bits, which have been 
% selected according to the `bit_shift` parameter. Note that the sign bit
% is irrelevant for FFT outputs.
%
% Inputs:
%     original_ints : (num_bins, num_samples) array, int40
%         Input values (from a previously performed FFT). If the input is
%         not given as values that can be readily interpreted as 40-bit 
%         signed integers, they will be converted prior to running the 
%         bit-shift operation and will only throw a warning.
%     bit_shift : int, 0:7
%         Parameter indicating the number of most-significant-bits to be
%         discarded. This value should be input as exactly the same value
%         programmed on the device.
%
% Author: Tanner Chas Dixon, tanner.dixon@ucsf.edu
% Date: February 3, 2022
%---------------------------------------------------------

 
function shifted_ints = bit_shift_rcs(original_ints, bit_shift)

% reshape the input array into a row-vector. return to original format at
% the end
[num_bins, num_samples] = size(original_ints);
original_ints = original_ints(:)';

% if any portion of the input is beyond the range of 40-bit values, throw
% an overflow warning with the number of values out of range
overflow = sum(abs(original_ints) > 2^39);
if overflow > 0
    warning(['Overflow warning: input contains ' num2str(overflow), ...
        ' samples that are out of range for a 40-bit signed integer.'])
end

% if the input values were not given as integers, round them off
if any(mod(original_ints, 1) > 0)
    warning(['`original_ints` was given as fractional values and has '...
            'been converted to 40-bit signed integers. Results may be '...
            'imprecise.'])
    original_ints = int64(original_ints);
end

% convert to bit-wise representation and perform the bit-shift
original_bits = int2bit(original_ints, 39);
shifted_bits = original_bits((1+bit_shift):(31+bit_shift),:);
shifted_ints = bit2int(shifted_bits, 31); % note the sign bit is discarded
shifted_ints = reshape(shifted_ints, num_bins, num_samples);





