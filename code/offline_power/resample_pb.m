function [pb_true_resampled, pb_est_resampled] ...
                  = resample_pb(time_pb_true, pb_true, time_pb_est, pb_est)
% Resample estimates at the same timestamps as the true signals
pb_est_resampled = interp1(time_pb_est, pb_est, time_pb_true);
% Throw away the first ten seconds, since these are often aberrant
keep_mask = (time_pb_true-time_pb_true(1)) > (10*1000);
pb_true_resampled = pb_true(keep_mask);
pb_est_resampled = pb_est_resampled(keep_mask);
end