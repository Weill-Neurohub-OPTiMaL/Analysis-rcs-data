function [frechet] = z_score_frechet(pb_true, pb_est)
% Compute the mean and standard deviation of the measured signal
mu = mean(pb_true);
sigma = std(pb_true);
% Standardize both the measured and estimated signals
pb_true = (pb_true - mu) / sigma;
pb_est = (pb_est - mu) / sigma;
% Compute the Frechet distance
[frechet, ~] = DiscreteFrechetDist(pb_true, pb_est);
end