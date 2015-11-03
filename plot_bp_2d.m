function plot_bp_2d(handles)
% Plot interpolated beampattern on azimuth-elevation plane

% Load data
data = getappdata(0,'data');
gui_op = getappdata(0,'gui_op');
mic_to_bat_angle = squeeze(data.proc.mic_to_bat_angle(gui_op.current_call_idx,:,:));
freq_wanted = str2num(get(handles.edit_bp_freq,'String'))*1e3;  % beampattern frequency [Hz]
[~,fidx] = min(abs(freq_wanted-data.proc.call_freq_vec{gui_op.current_call_idx}));
call_dB = squeeze(data.proc.call_psd_dB_comp_re20uPa_withbp{gui_op.current_call_idx}(fidx,:));

% Check for channels to be excluded
if isempty(data.proc.ch_ex{gui_op.current_call_idx})
    ch_ex_manual = [];
else
    ch_ex_manual = data.proc.ch_ex{gui_op.current_call_idx};
end
ch_ex_sig = find(isnan(call_dB));  % low quality channel from call extraction function

% Check for mics without location data
ch_good_loc = ~isnan(data.mic_loc(:,1))';

% Interpolation
mic_num = 1:data.mic_data.num_ch_in_file;
angle_notnanidx = ~ismember(1:data.mic_data.num_ch_in_file,union(ch_ex_manual,ch_ex_sig)) & ch_good_loc;
az = mic_to_bat_angle(angle_notnanidx,1);
el = mic_to_bat_angle(angle_notnanidx,2);
[azq,elq] = meshgrid(min(az):pi/180:max(az),min(el):pi/180:max(el));
vq = griddata(az,el,call_dB(angle_notnanidx),azq,elq,'natural');
vq_norm = vq-max(max(vq));

% Plot interpolated beampattern ==========================
axes(handles.axes_bp);
if get(handles.checkbox_norm,'Value')==0  % if "normalized" not checked
    himg = imagesc(azq(1,:)/pi*180,elq(:,1)/pi*180,vq);
    set(himg,'AlphaData',~isnan(vq));  % make NaN part transparent
    c_max = ceil(max(max(vq))/5)*5;
    c_min = floor(min(min(vq))/5)*5;
    hold on
else
    himg = imagesc(azq(1,:)/pi*180,elq(:,1)/pi*180,vq_norm);
    set(himg,'AlphaData',~isnan(vq));  % make NaN part transparent
    c_max = ceil(max(max(vq_norm))/5)*5;
    c_min = floor(min(min(vq_norm))/5)*5;
    hold on
end
contour(azq/pi*180,elq/pi*180,vq_norm,[0 -3],'w','linewidth',2);
plot([-90 90],[0 0],'k--');
plot([0 0],[-90 90],'k--');
% plot([-90 90 90 -90,-90],[90,90,-90,-90,90],'k-');
text(az/pi*180,el/pi*180,num2str(mic_num(angle_notnanidx)'),'horizontalalignment','center');
set(gca,'xtick',-90:30:90,'ytick',-90:30:90);
xlabel('Azimuth (deg)');
ylabel('Elevation (deg)');
grid
axis xy
axis equal
axis([-90 90 -90 90]);
% axis([-180 180 -180 180]);
caxis([c_min c_max]);
colormap(handles.axes_bp,parula);
colorbar
hold off

% Plot contour beampattern ==========================
% Set contour vector
contour_vec = 0:-3:-60;
vq_norm_min = min(min(vq_norm));
cvec_min_idx = find(contour_vec-vq_norm_min<0,1,'first');

% Plot contour beampattern
axes(handles.axes_bp_contour);
contourf(azq/pi*180,elq/pi*180,vq_norm,contour_vec(1:cvec_min_idx),'w');
hold on
plot(az/pi*180,el/pi*180,'wx');

xlabel('Azimuth (deg)');
ylabel('Elevation (deg)');
grid
axis xy
axis equal
axis([floor(min(az/pi*180)/5)*5 ceil(max(az/pi*180)/5)*5 floor(min(el/pi*180)/5)*5 ceil(max(el/pi*180)/5)*5]);
caxis(contour_vec([cvec_min_idx 1]))
colormap(handles.axes_bp_contour,parula(cvec_min_idx));
colorbar('southoutside')
hold off