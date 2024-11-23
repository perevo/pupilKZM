%% 清除
clear ;
clc;
%% load data
pupl_init('noUI', 'noGlobals', 'noWeb'); %%不打开交互 不全局配置 不联网使用
loadPath = 'E:\Projects\hrr\data\raw data\'; loadFex = '.edf';%%加载数据路径 可修改相应的数据位置"\"必须要
savePath = 'E:\Projects\hrr\data\clear data\'; saveFex = '.mat';%%保存数据
subjList = GetSubjectList(loadPath, loadFex, savePath, saveFex);%%防止重复处理 
% idx = strcmp(subjList, 'fxy_r');%%被试名称要对应 从一组被试找一个有需要可以取消备注
% subj = subjList{idx};
subj = subjList{1}; filePath = [loadPath, subj, loadFex];%% {x}x表示被试数据是第几个
eye_rawdata = pupl_import('eyedata', struct([]), 'loadfunc', @readeyelinkEDF_edf2mat,...
    'filefilt', '*.edf', 'type', 'eye', 'bids', false, 'filepath', {filePath}, ...
    'args', {}, 'native', false);
%原来用的是readeyelinkEDF_edf2mat 可用的有oct base


%% trim data
plotforeach(eye_rawdata, 'Pupil size', @pupl_plot_sizehist);
eye_trim_outlier = pupl_trim_pupil(eye_rawdata, 'lims', {'400' '1200'});%%定义区间
eye_trim_tailing = pupl_feval(@pupl_trim_dilationspeed, eye_trim_outlier);%%删除尾巴

plotforeach(eye_trim_tailing, 'Gap duration', @pupl_plot_gap_durs);%%由于存在被试休息时的记录 间隔不太好
eye_trim_islands = pupl_trim_short(eye_trim_tailing, 'lenthresh', '30ms', 'septhresh', '25ms');%%孤岛 和 空隙

plotforeach(eye_trim_islands, 'Pupil size', @pupl_plot_scroll, 'type', 'pupil');%%修改后呈现的图

%% detect and remove blink 
eye_blink_noise = pupl_blink_id(eye_trim_islands, 'method', 'noise', 'overwrite', true, 'cfg', []);%%一般用噪音法 10%左右或以下太高有问题噪音法效果不好用下面
plotforeach(eye_blink_noise, 'Pupil size', @pupl_plot_scroll, 'type', 'pupil');
plotforeach(eye_blink_noise, 'Blink duration', @pupl_plot_blink_durs);

% eye_blink_velocity = pupl_feval(@pupl_blink_id, eye_trim_islands, 'method', 'velocity', 'overwrite', false, 'cfg', []);
% plotforeach(eye_blink_velocity, 'Pupil size', @pupl_plot_scroll, 'type', 'pupil');
% plotforeach(eye_blink_velocity, 'Blink duration', @pupl_plot_blink_durs); %%自己设置值 一般22ms 建议不使用

eye_blink_removed = pupl_blink_rm(eye_blink_noise, 'trim', {'25ms';'100ms'});%%眨眼在数据上的表现。检测时间往前推25ms，往后推100ms。因为眨眼闭眼睛是快的，张开是慢的，
plotforeach(eye_blink_removed, 'Pupil size', @pupl_plot_scroll, 'type', 'pupil');

%% intepolate, filter and downdample
plotforeach(eye_blink_removed, 'Gap duration', @pupl_plot_gap_durs);
eye_intepolate = pupl_interp(eye_blink_removed, 'data', 'pupil', ...
    'interptype', 'linear', 'maxlen', '500ms', 'maxdist', '1`sd');%%插值 线性插值500ms以内 方差一
plotforeach(eye_intepolate, 'Pupil size', @pupl_plot_scroll, 'type', 'pupil');
% while eye_intepolate.ppnmissing > 0
%    eye_intepolate = pupl_feval(@pupl_interp, eye_blink_removed, 'data', 'pupil', 'interptype', 'linear', 'maxlen', '450ms');
% end

eye_filter = pupl_filt(eye_intepolate, 'data', 'pupil', 'avfunc', 'mean', 'win', 'hann', 'width', '101ms', 'cfg', []);%%平均值 汉宁窗 100ms
plotforeach(eye_filter, 'Pupil size', @pupl_plot_scroll, 'type', 'pupil');

newSrate = 100; oldSrate = eye_filter.srate; factor = oldSrate/newSrate;
eye_downsample = pupl_downsample(eye_filter, 'fac', factor);

%% epoch and baseline corrected
marker = {'tri'}; name = eye_downsample.name; lims = {'-0.5s';'3s'};%%lims前面几秒到，marker永远是0，时间窗口就是marker之前的0.5到之后的3s
eye_epoch_define = pupl_epoch(eye_downsample, 'len', 'fixed', 'timelocking', ...
    struct('sel', marker, 'by', {'regexp'}),'lims', lims ,'other',...
    struct('when', {'after'}, 'event', {0}), 'overwrite', false, 'name', name);%%regexp 正字法？
eye_epoch_define = pupl_check(eye_epoch_define);
plotforeach(eye_epoch_define, 'Epochs', @pupl_plot_epochs);% , 'type', 'pupil'
%%矫正
eye_epoch_baseline = pupl_baseline(eye_epoch_define, 'epoch', struct('type', name),...
    'correction', 'subtract baseline mean', 'mapping', 'one:one',...%%one one 一个值减去一个基线值。mean是基线平均值
    'len', 'fixed', 'when', 0, 'timelocking', 0, 'lims', {'-0.5s';'0s'},...%%lims基线值取的时间
    'other', struct('event', {0}, 'when', {'after'}));
plotforeach(eye_epoch_baseline, 'Pupil size', @pupl_plot_scroll, 'type', 'pupil');

eye_epoch_reject = pupl_feval(@pupl_epoch_reject, eye_epoch_baseline, 'method', 'ppnmissing');%% 拒掉0.01的epoch

eye = GetClearEpochs(eye_epoch_reject, savePath, saveFex,eye_intepolate);%%储存数据
close all;




