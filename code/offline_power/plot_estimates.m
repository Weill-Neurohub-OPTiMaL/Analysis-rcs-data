function plot_estimates(block, block_idx)
figure('Name', ['Block: ', num2str(block_idx)], ...
       'Position',[100,50,1200,900])

plot_range = min([100000, ...
                  length(block.time_pb_true{1}),...
                  length(block.time_pb_est{1})]);
time_pb_true = block.time_pb_true{1}(1:plot_range);
data_pb_true = block.data_pb_true{1}(1:plot_range,:);
time_pb_est = block.time_pb_est{1}(1:plot_range);
data_pb_est = block.data_pb_est{1}(1:plot_range,:);

zero_time = time_pb_true(1);
center_freqs = (0:(block.L/2-1)) * block.fs_td/block.L;
bin_edges_hz = center_freqs(block.pb_bins{1});
for k = 1:8
    ttl = {['Power band ', num2str(k),] ...
           ['bin indices [',num2str(block.pb_bins{1}(k,:)),']'], ...
           ['bin frequencies [',num2str(bin_edges_hz(k,:)),'] Hz']};
    subplot(4,2,k)
    plot((time_pb_true-zero_time)/1000, ...
         data_pb_true(:,k), 'LineWidth',1)
    hold on
    plot((time_pb_est-zero_time)/1000, ...
         data_pb_est(:,k), 'LineWidth',1)
    grid on
    ylabel({'Power', '[RCS units]'})
    xlabel('Time [sec]')
    title(ttl)
    xlim([1,120])
    ylim([0, quantile(block.data_pb_est{1}(:,k), 0.99)])
end
legend({'Measured', 'Computed from TD'})
end