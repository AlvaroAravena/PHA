function HPA

clear all; clc; close all;

% PROCEDURE TO VERIFY THE PRESENCE OF IMAGE PROCESSING TOOLBOX
hasIPT = license('test', 'image_toolbox');
if ~hasIPT
	uiwait(msgbox('Sorry, but you do not seem to have the Image Processing Toolbox.'));
	return;
end

% GLOBAL VARIABLES
global current_path
global image_reference
global fixed_mask
global vent_point
global calibration
global cluster_definition
global max_number_clusters
global mean_size_clusters
global step_lines_mask
global threshold_lines
global min_distance_cluster
global max_distance_cluster_vent
global min_distance_vent_lobes
global threshold_lobes_factor
global threshold_lobes_distance
global shift_max_lab_mask; 
global shift_number;

% DEFINE VARIABLES
current_path = pwd;
image_reference = NaN;
fixed_mask = NaN;
vent_point = NaN;
calibration = NaN;
cluster_definition = NaN;
max_number_clusters = 5;
mean_size_clusters = 7;
step_lines_mask = 20;
threshold_lines = 0.2;
min_distance_cluster = 3;
max_distance_cluster_vent = 3;
min_distance_vent_lobes = 100;
threshold_lobes_factor = 0.15;
threshold_lobes_distance = 50;
shift_max_lab_mask = 15; 
shift_number = 9;

% CREATE MAIN WINDOW
% Create window
scr = get(0,'ScreenSize'); w = 500; h = 400;
t.fig = figure('position', [scr(3)/2 - w/2 scr(4)/2-h/2 w h], 'Color', [.2 .2 .2], 'Resize', 'off', 'Toolbar', 'none','Menubar', 'none','Name', 'HeightPlumeAnalyzer','NumberTitle', 'off','DeleteFcn', @delete_figure);

% Menu
t.menu0 = uimenu(t.fig, 'Label', 'Fixed Mask');
t.m01 = uimenu(t.menu0, 'Label', 'Load', 'callback', @load_mask );
t.m02 = uimenu(t.menu0, 'Label', 'Create', 'callback', @create_mask );
t.m03 = uimenu(t.menu0, 'Label', 'Plot Current', 'callback', @plot_mask );
t.menu1 = uimenu(t.fig, 'Label', 'Vent Position');
t.m11 = uimenu(t.menu1, 'Label', 'Load', 'callback', @load_vent );
t.m12 = uimenu(t.menu1, 'Label', 'Create', 'callback', @create_vent );
t.m13 = uimenu(t.menu1, 'Label', 'Plot Current', 'callback', @plot_vent );
t.menu2 = uimenu(t.fig, 'Label', 'Calibration');
t.m21 = uimenu(t.menu2, 'Label', 'Lab Mask', 'Separator', 'on');
t.m210 = uimenu(t.m21, 'Label', 'Load', 'callback', @load_lab );
t.m211 = uimenu(t.m21, 'Label', 'Create', 'callback', @create_lab );
t.m212 = uimenu(t.m21, 'Label', 'Improve', 'callback', @improve_lab );
t.m213 = uimenu(t.m21, 'Label', 'Test', 'callback', @test_lab );
t.m214 = uimenu(t.m21, 'Label', 'Compare', 'callback', @compare_lab );
t.menu3 = uimenu(t.fig, 'Label', 'Pixel to height');
t.m31 = uimenu(t.menu3, 'Label', 'Load', 'callback', @load_height );
t.m32 = uimenu(t.menu3, 'Label', 'Create', 'callback', @create_height );
t.m33 = uimenu(t.menu3, 'Label', 'Improve', 'callback', @improve_height );
t.m34 = uimenu(t.menu3, 'Label', 'Plot', 'callback', @plot_height );
t.menu4 = uimenu(t.fig, 'Label', 'Analysis');
t.m41 = uimenu(t.menu4, 'Label', 'Single Video', 'callback', @analysis_video );

logo = imread('Logo/logo.png');
im = imagesc(logo);
axis off; ax = gca; outerpos = ax.OuterPosition;
ti = ax.TightInset; left = outerpos(1) ; bottom = outerpos(2) ;
ax_width = outerpos(3) ; ax_height = outerpos(4) ; ax.Position = [left bottom ax_width ax_height];

function load_mask(~,~)

global current_path
global fixed_mask
global calibration
global cluster_definition
global image_reference

[ filename , pathname ] = uigetfile('*.mat', 'Select mask', fullfile( current_path , 'MaskFiles' ) ) ;
if( filename == 0)
    uiwait(msgbox('Mask was not loaded.')); return;
end
old_fixed_mask = fixed_mask;
fixed_mask = load( fullfile( pathname , filename ) );
fixed_mask = fixed_mask.fixed_mask;
message = 'Fixed mask loaded successfully.';
if( isequaln( old_fixed_mask, fixed_mask ) == 0 & isequaln( calibration , NaN ) == 0 )
    calibration = NaN; cluster_definition = NaN;
    message = strcat( message , '\nBecause this fixed mask and the fixed mask associated with the current Lab calibration are different, the current Lab calibration was removed.' );
end
if( isequaln( size(fixed_mask), size(squeeze(image_reference(:,:,1))) ) == 0 & isequaln( image_reference , NaN ) == 0  )
    image_reference = NaN;
    message = strcat( message , '\nBecause the size of this fixed mask and the size of the reference image are different, the current reference image was removed.' );
end
uiwait(msgbox(sprintf(message)));
displace_vent;

function create_mask(~,~)

global current_path
global image_reference
global fixed_mask
global vent_point
global calibration
global cluster_definition

if( isequaln( image_reference , NaN ) )
    return_data = ask_image_reference;
    if( return_data == 0 )
        uiwait(msgbox('Reference image was not loaded.'));
        return
    end
else
	button = questdlg('Use current reference image:', 'Use current reference image:', 'Yes', 'Choice other image', 'Yes');
    if strcmpi(button, 'Choice other image')
        return_data = ask_image_reference;
        if( return_data == 0 )
            uiwait(msgbox('Reference image was not loaded.'));
            return
        end
    end
end

[rows, columns, numberOfColorChannels] = size( image_reference );
old_fixed_mask = fixed_mask;
old_calibration = calibration;
old_cluster_definition = cluster_definition;
try
    f_polygons = figure;
    imshow( image_reference );
    title('Reference Image'); hold on;
    if( isequaln( vent_point , NaN ) == 0 )
        plot( vent_point(1), vent_point(2), 'bo' , 'MarkerFaceColor', 'b' );
    end
    set(f_polygons, 'units','normalized','outerposition',[0 0 1 1]);
    set(f_polygons,'name','Creating masked zone','numbertitle','off');
    regionCount = 0; option_finish = 'Create Empty Mask';
    fixed_mask = ones(rows, columns);
    while true && regionCount < 20
        button = questdlg(sprintf('Draw region #%d in the image,\nor Finish?', regionCount + 1), 'Continue?', 'Draw', option_finish , 'Draw');
        if strcmpi(button, option_finish)
            close(f_polygons);
            break;
        end
        option_finish = 'Finish'; regionCount = regionCount + 1;
        message = sprintf('Left click vertices in the image.\nRight click the last vertex to finish.\nThen double click in the middle to accept it.');
        uiwait(msgbox(message));
        [this_fixed_mask, xi, yi] = roipoly();
        fixed_mask = fixed_mask .* (1 - this_fixed_mask);
    end
    factor_borders = floor( 0.02 .* sqrt( rows .* columns) );
    while true
        current_fixed_mask = fixed_mask;
        for i = 1:rows
            fixed_mask(i,1:factor_borders) =  min(fixed_mask(i,1:factor_borders));
            fixed_mask(i,end - factor_borders + 1 : end) =  min(fixed_mask(i,end - factor_borders + 1 : end));
        end
        for i = 1:columns
            fixed_mask(1:factor_borders,i) =  min(fixed_mask(1:factor_borders,i));
            fixed_mask(end - factor_borders + 1 : end, i) =  min(fixed_mask(end - factor_borders + 1 : end , i));
        end
        if( current_fixed_mask == fixed_mask )
            definput = {'Default','hsv'};
            mask_name = inputdlg('Enter mask name:','Mask name',[1 100],definput);
            if( length(mask_name) == 0 )
                uiwait(msgbox('Fixed mask was not saved.')); fixed_mask = NaN; return;
            end
            save( fullfile( current_path , 'MaskFiles', mask_name{1} ) , 'fixed_mask');
            break
        end
    end
    message = 'Fixed mask saved successfully.';
    if( isequaln( old_fixed_mask, fixed_mask ) == 0 & isequaln( old_fixed_mask , NaN ) == 0 & isequaln( calibration , NaN ) == 0 )
        calibration = NaN; cluster_definition = NaN;
        message = strcat( message , '\nBecause this fixed mask and the fixed mask associated with the current Lab calibration are different, the current Lab calibration was removed.' );
    end
    if( isequaln( size(fixed_mask), size(squeeze(image_reference(:,:,1))) ) == 0 & isequaln( image_reference , NaN ) == 0  )
        image_reference = NaN;
        message = strcat( message , '\nBecause the size of this fixed mask and the size of the reference image are different, the current reference image was removed.' );
    end
    uiwait(msgbox(sprintf(message)));
    displace_vent;
catch
    uiwait(msgbox(sprintf('Mask was not created.'))); 
    fixed_mask = old_fixed_mask;
    calibration = old_calibration;
    cluster_definition = old_cluster_definition;
    return;
end

function plot_mask( ~ , ~ )

global image_reference
global fixed_mask

if( isequaln( image_reference , NaN ) )
	button = questdlg('Reference image is not loaded', 'Reference image is not loaded', 'Choice an image', 'Continue without reference image', 'Choice an image');
    if strcmpi(button, 'Choice an image')
        return_data = ask_image_reference;
        if( return_data == 0 )
            uiwait(msgbox('Warning: reference image was not loaded.'));
        end
    end    
end
if( isequaln( fixed_mask , NaN ) & isequaln( image_reference , NaN) )
    uiwait(msgbox('Fixed mask and reference image are not present.'));
    return
elseif( isequaln( fixed_mask , NaN ) )
	uiwait(msgbox('Warning: fixed mask is not present.'));
	f_fixed_mask = figure;    
	imshow( image_reference );
elseif( isequaln( image_reference , NaN ) )
	f_fixed_mask = figure;    
    imshow( fixed_mask );
else
    f_fixed_mask = figure;    
    imshow( image_reference ); hold on;
	h = imshow( fixed_mask );
	set(h, 'AlphaData', 0.2);
end

function load_vent(~,~)

global vent_point
global current_path

[ filename , pathname ] = uigetfile('*.mat', 'Select vent', fullfile( current_path , 'VentFiles' ) ) ;
if( filename == 0)
    uiwait(msgbox('Vent position was not loaded.'));
    return
end
vent_point = load( fullfile( pathname , filename ) );
vent_point = vent_point.vent_point;
uiwait(msgbox('Vent position loaded successfully.'));
displace_vent;

function create_vent(~,~)

global current_path
global image_reference
global fixed_mask
global vent_point

if( isequaln( image_reference , NaN ) )
    return_data = ask_image_reference;
    if( return_data == 0 )
        uiwait(msgbox('Reference image was not loaded.'));
        return
    end
else
	button = questdlg('Use current reference image', 'Use current reference image', 'Yes', 'Choice other image', 'Yes');
    if strcmpi(button, 'Choice other image')
        return_data = ask_image_reference;
        if( return_data == 0 )
            uiwait(msgbox('Reference image was not loaded.'));
            return
        end
    end
end
old_vent_point = vent_point;
try
    f_vent = figure;
    imshow( image_reference ); hold on;
    if( isequaln( fixed_mask , NaN ) == 0 )
        h = imshow( fixed_mask );
        set(h, 'AlphaData', 0.2)
    end
    title('Reference Image');
    set(f_vent, 'units','normalized','outerposition',[0 0 1 1]);
    set(f_vent,'name','Creating vent position','numbertitle','off');
    uiwait(msgbox('Select vent position'));
    vent_point = drawpoint();
    vent_point = round(vent_point.Position);
    uiwait(msgbox('Vent selected. This vent may be displaced vertically if it is in the masked zone.'));
    close(f_vent);
    definput = {'Default','hsv'};
    vent_name = inputdlg('Enter vent name:','Vent name',[1 100],definput);
	if( length(vent_name) == 0 )
        uiwait(msgbox('Vent was not created.')); 
        vent_point = old_vent_point;
        return;
	end
    save( fullfile( current_path , 'VentFiles', vent_name{1} ) , 'vent_point');
    displace_vent;
catch
    uiwait(msgbox(sprintf('Vent was not created.')));
    vent_point = old_vent_point;
    return;
end

function plot_vent( ~ , ~ )

global image_reference
global fixed_mask
global vent_point

if( isequaln( vent_point , NaN ) )
	uiwait(msgbox('The vent point is not present.'));
    return
end
if( isequaln( image_reference , NaN ) )
	button = questdlg('Reference image is not loaded', 'Reference image is not loaded', 'Choice an image', 'Continue without reference image', 'Choice an image');
    if strcmpi(button, 'Choice an image')
        return_data = ask_image_reference;
        if( return_data == 0 )
            uiwait(msgbox('Warning: reference image was not loaded.'));
        end
    end    
end

if( isequaln( fixed_mask , NaN ) & isequaln( image_reference , NaN) )
    uiwait(msgbox('Fixed mask and reference image are not present.'));
    return
elseif( isequaln( fixed_mask , NaN ) )
	uiwait(msgbox('Warning: fixed mask is not present.'));
	f_vent_point = figure;    
	imshow( image_reference ); hold on;
elseif( isequaln( image_reference , NaN ) )
	f_vent_point = figure;    
    imshow( fixed_mask ); hold on;
else
    f_vent_point = figure;    
    imshow( image_reference ); hold on;
	h = imshow( fixed_mask ); hold on;
	set(h, 'AlphaData', 0.2);
end
plot( vent_point(1), vent_point(2), 'bo' , 'MarkerFaceColor', 'b' );

function load_lab(~,~)

global fixed_mask
global cluster_definition
global calibration
global current_path
global image_reference

[ filename , pathname ] = uigetfile('*.mat', 'Select Lab calibration file' , fullfile( current_path , fullfile('CalibrationFiles', 'LabMask') ) ) ;
if( filename == 0 )
    uiwait(msgbox('Calibration file was not loaded.'));
    return
end
calibration_data = load( fullfile( pathname , filename ) );
cluster_definition = calibration_data.cluster_definition;
calibration = calibration_data.calibration;
fixed_mask = calibration_data.fixed_mask;
displace_vent;
message = 'Calibration file and the associated fixed mask loaded successfully.';
if( isequaln( size(fixed_mask), size(squeeze(image_reference(:,:,1))) ) == 0 & isequaln( image_reference , NaN ) == 0 )
    image_reference = NaN;
    message = strcat( message , '\nBecause the size of this fixed mask and the size of the reference image are different, the current reference image was removed.' );
end
uiwait(msgbox(sprintf(message)));

function create_lab(~,~)

global image_reference
global fixed_mask
global calibration
global cluster_definition

if( isequaln( fixed_mask , NaN ) )
    button = questdlg('Warning: the fixed mask is not present', 'Warning: the fixed mask is not present', 'Cancel', 'Continue with empty mask', 'Cancel');
    if strcmpi(button, 'Cancel')
        return;
    end
end
selection_type = questdlg('Select data type', 'Select data type' , 'Single video', 'Folder of videos', 'Folder of images',  'Single video');
if( isequaln(selection_type, 'Single video' ))
	[ filename , pathname ] = uigetfile('*.avi','Select calibration video') ;
elseif( isequaln(selection_type, 'Folder of videos' ) | isequaln(selection_type, 'Folder of images' ) )
	[ pathname ] = uigetdir('Select folder of images/videos for calibration') ;
	filename = '';
else
	uiwait(msgbox('Data type was not selected.'));
	return;
end
if( pathname == 0 )
	uiwait(msgbox('Data for calibration was not selected.')); return;
else
    old_calibration = calibration;
    old_cluster_definition = cluster_definition;
    old_fixed_mask = fixed_mask;
	calibration = zeros(0,7);
	return_data = calibration_procedure( selection_type , pathname , filename );
    if( return_data == 1 )
    	lab_calibration_name = inputdlg( 'PromptString' , 'Lab calibration name' , [1 100] , {'Default'} );
        if( length( lab_calibration_name ) > 0 )
            compute_calibration( lab_calibration_name{1} );
        else
            calibration = old_calibration;
            cluster_definition = old_cluster_definition;
            fixed_mask = old_fixed_mask;
            uiwait(msgbox('Calibration was not saved.'));
            return;
        end
    else
        calibration = old_calibration;
        cluster_definition = old_cluster_definition;
        fixed_mask = old_fixed_mask;
        if( return_data == - 1)
            uiwait(msgbox('Fixed mask dimensions and dimensions of images/videos used in calibration do not coincide. Calibration was not saved.'));
        else
            uiwait(msgbox('Calibration was not saved because the window was closed incorrectly.'));
        end
        return;
    end
end

function improve_lab(~,~)

global image_reference
global fixed_mask
global calibration
global cluster_definition
global current_path

[ filename , pathname ] = uigetfile('*.mat', 'Select calibration to be improved' , fullfile( current_path , fullfile('CalibrationFiles', 'LabMask') ) ) ;
if( filename == 0)
    uiwait(msgbox('Data of the calibration file to be improved was not selected.'));
    return;
else
    imp_calibration = load( fullfile( pathname , filename ) );
	imp_fixed_mask = imp_calibration.fixed_mask;
    imp_calibration = imp_calibration.calibration;
    old_calibration = calibration;
	old_fixed_mask = fixed_mask;
    old_cluster_definition = cluster_definition;
    lab_calibration_name = {filename(1 : end - 4)};
end
if( isequaln( imp_fixed_mask , old_fixed_mask ) == 0 )
	uiwait(msgbox('The mask associated with the calibration to improve was loaded.'));
	fixed_mask = imp_fixed_mask;
end
selection_type = questdlg('Select data type', 'Select data type' , 'Single video', 'Folder of videos', 'Folder of images',  'Single video');
if( isequaln(selection_type, 'Single video' ))
	[ filename , pathname ] = uigetfile('*.avi','Select calibration video') ;
elseif( isequaln(selection_type, 'Folder of videos' ) | isequaln(selection_type, 'Folder of images' ) )
	[ pathname ] = uigetdir('Select folder of images/videos for calibration') ;
	filename = '';
else
	uiwait(msgbox('Data type was not selected.'));
    fixed_mask = old_fixed_mask;
	return;
end
if( pathname == 0 )
	uiwait(msgbox('Data for calibration was not selected.')); 
    fixed_mask = old_fixed_mask;
    return;
else
	calibration = zeros(0,7);
	return_data = calibration_procedure( selection_type , pathname , filename );
    if( return_data == 1 )
        button = questdlg('Do you confirm to improve calibration?', 'Do you confirm to improve calibration?', 'Yes' , 'No' , 'Yes' );
        if strcmpi(button, 'Yes')
            calibration = [imp_calibration; calibration];
            compute_calibration( lab_calibration_name{1} );
        else
            calibration = old_calibration;
            cluster_definition = old_cluster_definition;
            fixed_mask = old_fixed_mask;
            uiwait(msgbox('Calibration was not saved.'));
            return;
        end
    else
        calibration = old_calibration;
        cluster_definition = old_cluster_definition;
        fixed_mask = old_fixed_mask;
        if( return_data == - 1)
            uiwait(msgbox('Fixed mask dimensions and dimensions of images/videos used in calibration do not coincide. Calibration was not saved.'));
        else
            uiwait(msgbox('Calibration was not saved because the window was closed incorrectly.'));
        end
        return;
    end
end

function test_lab(~,~)

global fixed_mask
global calibration
global cluster_definition

if( isequaln(calibration, NaN) | isequaln(cluster_definition, NaN) | isequaln( fixed_mask , NaN ) )
   	uiwait(msgbox('Lab calibration is not loaded.'));
    return
end
selection_type = questdlg('Select data type', 'Select data type' , 'Single video', 'Folder of videos', 'Folder of images',  'Single video');
if( isequaln(selection_type, 'Single video' ))
	[ filename , pathname ] = uigetfile('*.avi','Select calibration video') ;
elseif( isequaln(selection_type, 'Folder of videos' ) | isequaln(selection_type, 'Folder of images' ) )
	[ pathname ] = uigetdir('Select folder of images/videos for calibration') ;
	filename = '';
else
	uiwait(msgbox('Data type was not selected.'));
	return;
end
if( pathname == 0 )
	uiwait(msgbox('Data for calibration was not selected.')); 
    return;
else
    test_procedure( selection_type , pathname , filename );
end

function compare_lab(~,~)

global fixed_mask
global calibration
global cluster_definition
global current_path

calibration_set = struct; counter_cal = 0;
if( isequaln(calibration, NaN) == 0 & isequaln(cluster_definition, NaN) == 0 & isequaln( fixed_mask , NaN ) == 0 )
	button = questdlg('Consider loaded calibration?', 'Consider loaded calibration?', 'Yes', 'No', 'Yes');
    if strcmpi(button, 'Yes')
        calibration_set.(strcat('cal','1')).calibration = calibration;
        calibration_set.(strcat('cal','1')).fixed_mask = fixed_mask;
        calibration_set.(strcat('cal','1')).cluster_definition = cluster_definition;
        calibration_set.(strcat('cal','1')).name = 'Current calibration';
        counter_cal = counter_cal + 1;
    end
end
[ filename , pathname ] = uigetfile('*.mat', 'Select Lab calibration files' , fullfile( current_path , fullfile('CalibrationFiles', 'LabMask') ) , 'MultiSelect', 'on');
message = '';
if( iscell(filename) )
    for i = 1:length(filename)
        calibration_new = load( fullfile( pathname , filename{i} ) );
        cluster_new = calibration_new.cluster_definition;
        fixed_mask_new = calibration_new.fixed_mask;
        calibration_new = calibration_new.calibration;
        [calibration_set, counter_cal, message] = add_calibration( calibration_set , counter_cal, message, filename{i}, fixed_mask_new, calibration_new, cluster_new );
    end
elseif( ischar(filename) )
    calibration_new = load( fullfile( pathname , filename ) );
	cluster_new = calibration_new.cluster_definition;
	fixed_mask_new = calibration_new.fixed_mask;
	calibration_new = calibration_new.calibration;
	[calibration_set, counter_cal, message] = add_calibration( calibration_set , counter_cal, message, filename, fixed_mask_new, calibration_new, cluster_new );
end
if( isequaln( message, '') == 0 )
	uiwait(msgbox(sprintf(message)));
end
if( counter_cal == 0 )
    uiwait(msgbox('Calibrations for comparison were not selected.'));
	return;
end
selection_type = questdlg('Select data type for comparison', 'Select data type' , 'Single video', 'Folder of images',  'Single video');
if( isequaln(selection_type, 'Single video' ))
    [ filename , pathname ] = uigetfile('*.avi','Select video for comparison') ;
else
	[ pathname ] = uigetdir('Select folder of images for calibration') ;
	filename = '';
end
if( pathname == 0 )
    uiwait(msgbox('Video/images for comparison was/were not selected.'));
	return;
end
if( isequaln(selection_type, 'Folder of images' ) 
    names = dir(pathname);
    counter_names = 0; files_names = {};
    for i = 1:length(names)
        if( strcmp(names(i).name(max(1,end-3):end), '.jpg'))
            counter_names = counter_names + 1;
            files_names{counter_names} = names(i).name;
        end
    end
end
max_num_frame = inputdlg('Maximum number of frames');
max_num_frame = str2num(max_num_frame{1});
if( max_num_frame < 1 )
    uiwait(msgbox('Maximum number of frames must be equal or higher than 1.'));
    return;
else
    if( isequaln(selection_type, 'Single video' ))
        video = VideoReader( fullfile( pathname , filename ) );
        max_num_frame = min( max_num_frame , video.Duration * video.FrameRate - 1 );
        ind_frame = round( linspace( 1, video.Duration * video.FrameRate - 1 , max_num_frame ));
    else
        max_num_frame = min( max_num_frame, length(names));
        ind_frame = 1:1:max_num_frame;
    end
    threshold_p = nan( counter_cal , max_num_frame );
    threshold_n = nan( counter_cal , max_num_frame );
    for i  = 1 : length(ind_frame)
        if( isequaln(selection_type, 'Single video' ))
            frame = read( video, ind_frame(i) );
        else
            frame = imread( fullfile( pathname , files_names{i} ) );
        end
        frame_lab = rgb2lab( frame );
        frame_l = squeeze(frame_lab(:,:,1));
        frame_a = squeeze(frame_lab(:,:,2));
        frame_b = squeeze(frame_lab(:,:,3));
        frame_red = squeeze(frame(:,:,1));
        frame_blue = squeeze(frame(:,:,2));
        frame_green = squeeze(frame(:,:,3));
        for j = 1 : counter_cal
            c_calibration = calibration_set.(strcat('cal',num2str(j))).calibration;
            c_fixed_mask = calibration_set.(strcat('cal',num2str(j))).fixed_mask;
            c_cluster_definition = calibration_set.(strcat('cal',num2str(j))).cluster_definition;
            c_name = calibration_set.(strcat('cal',num2str(j))).name;
            mean_frame_l = mean(frame_l( find( c_fixed_mask == 1 )));
            mean_frame_a = mean(frame_a( find( c_fixed_mask == 1 )));
            mean_frame_b = mean(frame_b( find( c_fixed_mask == 1 )));
            mean_frame_red = mean(frame_red( find( c_fixed_mask == 1 )));
            mean_frame_blue = mean(frame_blue( find( c_fixed_mask == 1 )));
            mean_frame_green = mean(frame_green( find( c_fixed_mask == 1 )));
            parameters_image = [ mean_frame_l, mean_frame_a, mean_frame_b, mean_frame_red , mean_frame_blue , mean_frame_green ];
            [minvalue, minindex] = min(sum(((parameters_image - c_cluster_definition(:,1:6)).^2)'));
            [sortvalue, sortindex] = sort(sum(((parameters_image - c_calibration(:,1:6)).^2)'));
            minima_index = find( sortindex <= 3 );
            soglia_b1 = sum([parameters_image, parameters_image.^2, 1] .* c_cluster_definition(minindex,7:19));
            soglia_b1 = min( soglia_b1 , max( c_calibration(:,3) + c_calibration(:,7) ) );
            soglia_b1 = max( soglia_b1 , min( c_calibration(:,3) + c_calibration(:,7) ) );
            soglia_b2 = mean( c_calibration(minima_index,3) + c_calibration(minima_index,7));
            threshold_p( j, i ) = soglia_b1;
            threshold_n( j, i ) = soglia_b2;
        end
        disp(['- Frame ' num2str(i) '/' num2str(length(ind_frame)) '.']);
    end
end
all_names = {};
for j = 1 : counter_cal
	c_name = calibration_set.(strcat('cal',num2str(j))).name;
    all_names{j} = c_name;
end
max_val = -1e10;
min_val = 1e10;
f_comparison = figure;
subplot(1,2,1);
for j = 1 : counter_cal
    plot( ind_frame, threshold_p(j,:),'.-','MarkerSize', 10, 'LineWidth', 1 ); hold on;
    max_val = max( max_val , max(threshold_p(j,:)));
    min_val = min( min_val , min(threshold_p(j,:)));
end
legend(all_names, 'LineWidth', 1);
subplot(1,2,2);
for j = 1 : counter_cal
    plot( ind_frame, threshold_n(j,:),'.-','MarkerSize', 10, 'LineWidth', 1); hold on;
    max_val = max( max_val , max(threshold_p(j,:)));
    min_val = min( min_val , min(threshold_p(j,:)));
end    
legend(all_names, 'LineWidth',1);
subplot(1,2,1); ylim([round(min_val-5),round(max_val+5)]); xlabel('Frame'); ylabel('Lab threshold'); title('Clustering/Polynomial fit');
subplot(1,2,2); ylim([round(min_val-5),round(max_val+5)]); xlabel('Frame'); ylabel('Lab threshold'); title('Nearest value');

function analysis_video(~,~)

global image_reference
global fixed_mask
global calibration
global cluster_definition
global vent_point

if( isequaln(calibration, NaN) | isequaln(cluster_definition, NaN) | isequaln( fixed_mask , NaN ) )
   	uiwait(msgbox('Lab calibration is not loaded.'));
    return
end
if( isequaln(vent_point, NaN) )
   	uiwait(msgbox('Vent position is not loaded.'));
    return
end
[ filename , pathname ] = uigetfile('*.avi','Select video for developing analysis.') ;
if( pathname == 0 )
    uiwait(msgbox('Video for analysis was not selected.'));
    return;
else
    video_analysis_procedure( pathname , filename );
end

function compute_calibration( name_file )

global current_path
global calibration
global cluster_definition
global max_number_clusters
global mean_size_clusters
global fixed_mask

Z = linkage( calibration( : , 1 : 6 ) ,'weighted');
c = cluster(Z, 'maxclust', floor(max(1, min(max_number_clusters, length(calibration(:,1))./ mean_size_clusters )) ));
cluster_definition = zeros( max(c), 19 );
for i = 1:max(c)
    current_c = find(c == i);
    if( length(current_c(:,1)) > 1)
        cluster_definition(i, 1:6) = mean( calibration(current_c , 1 : 6 ) ) ;
    else
        cluster_definition(i, 1:6) = ( calibration(current_c , 1 : 6 ) ) ;
    end
    if( sum( isnan(calibration( current_c , 7 ) ) ) > .2 * length(current_c(:,1)) );
        cluster_definition(i, 7 : 19) = NaN;
    elseif( length(current_c(:,1)) < 10 )
        cluster_definition(i, 19) = mean( calibration(current_c , 3) + calibration(current_c , 7) );
    elseif( length(current_c(:,1)) < 20 )
        F = [ calibration(current_c , 1:6) , ones(length( calibration(current_c , 1) ),1)];
        cluster_definition(i, [7:12, 19]) = regress( calibration(current_c , 3) + calibration(current_c , 7) , F);
    else
        F = [ calibration(current_c , 1:6), calibration(current_c , 1:6) .* calibration(current_c , 1:6) , ones(length(calibration(current_c , 1)),1)];
        cluster_definition(i, 7:19) = regress( calibration(current_c , 3) + calibration(current_c , 7) , F);
    end
end
save( fullfile( current_path , 'CalibrationFiles', 'LabMask', name_file ) , 'calibration' , 'cluster_definition', 'fixed_mask');

function return_data = ask_image_reference

global image_reference
global fixed_mask
global calibration
global cluster_definition

[ filename , pathname ] = uigetfile({'*.jpg';'*.avi'},'Select reference video') ;
if( filename == 0)
    return_data = 0;
    return;
elseif( isequaln(filename(end-2:end), 'jpg'))
    image_reference = imread( fullfile( pathname , filename) );
else
    video_reference = VideoReader( fullfile( pathname , filename ) );
    image_reference = readFrame( video_reference );
end
if( isequaln( size( fixed_mask ), size(squeeze(image_reference(:,:,1))) ) == 0 & isequaln( fixed_mask , NaN ) == 0  )
    fixed_mask = NaN;
    message = 'Because the size of the fixed mask and the size of the loaded reference image are different, the current fixed mask was removed.';
    if( isequaln( calibration , NaN ) == 0 )
        calibration = NaN; cluster_definition = NaN;
        message = strcat( message , '\nBecause the calibration files are associated with the removed fixed mask, the current calibration was removed.' );
    end
    uiwait(msgbox(sprintf(message)));
end
return_data = 1;

function displace_vent

global fixed_mask
global vent_point

if( isequaln( vent_point , NaN) | isequaln( fixed_mask , NaN))
    return
end  
message_boolean = 0;
for i = vent_point(2):-1:1
    if( fixed_mask( i, vent_point(1)) == 1)
        vent_point(2) = i; break
    elseif(message_boolean == 0)
        message_boolean = 1;
        uiwait(msgbox('Vent was displaced vertically because it is in the masked zone.'));
    end
end

function delete_figure(~,~)
if exist('tmp.mat', 'file')
    clear tmp
    delete('tmp.mat');
end

function return_data = calibration_procedure( selection_type , pathname , filename )

global calibration
global fixed_mask
global shift_max_lab_mask; 
global shift_number;

return_data = 1;
list_letters = {'A','B','C','D','E','F','G','H','I','Cloudy (Not recognizable plume)','Finish Calibration'};
list_letters_zoom = {'A','B','C','D','E','F','G','H','I'};
counter_calibration = length( calibration(:,1) ); finish_calibration = 0;
frame = NaN;
if( isequaln(selection_type, 'Single video' ) == 0 )
    names = dir(pathname);
    counter_names = 0; files_names = {};
    if( isequaln(selection_type, 'Folder of videos' ) )
        format_file = '.avi';
    else
        format_file = '.jpg';
    end
    for i = 1:length(names)
        if( strcmp(names(i).name(max(1,end-3):end), format_file))
            counter_names = counter_names + 1;
            files_names{counter_names} = names(i).name;
        end
    end
end
try
    while finish_calibration == 0
        if( isequaln(selection_type, 'Single video' ) & isnan(frame) )
            video = VideoReader( fullfile( pathname , filename ) );
            ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
            frame = read( video, ind_frame );
        elseif( isequaln(selection_type, 'Single video' ) )
            ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
            frame = read( video, ind_frame );
        elseif( isequaln(selection_type, 'Folder of videos' ) )
            i = 1 + round( rand()* ( length(files_names) - 1 ) );
            video = VideoReader( fullfile( pathname , files_names{i} ) );
            ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
            frame = read( video, ind_frame );
        elseif( isequaln(selection_type, 'Folder of images' ) )
            i = 1 + round( rand()* ( length(files_names) - 1 ) );
            frame = imread( fullfile( pathname , files_names{i} ) );
        end
        if( isequaln( fixed_mask , NaN ) )
            [rows, columns, numberOfColorChannels] = size( frame );
            fixed_mask = ones(rows, columns);
        end
        if( isequaln( squeeze(size(frame(:,:,1))), size(fixed_mask) ) == 0  )
            return_data = -1; return;
        end
        shift = linspace(  -shift_max_lab_mask ,  shift_max_lab_mask , shift_number );
        step_shift = 2 .* shift_max_lab_mask ./ ( shift_number - 1 );
        shift = shift + (rand( shift_number , 1 ) .* step_shift - step_shift ./ 2)';
        frame_lab = rgb2lab( frame );
        frame_l = squeeze(frame_lab(:,:,1));
        frame_a = squeeze(frame_lab(:,:,2));
        frame_b = squeeze(frame_lab(:,:,3));
        mean_frame_l = mean(frame_l( find( fixed_mask == 1 )));
        mean_frame_a = mean(frame_a( find( fixed_mask == 1 )));
        mean_frame_b = mean(frame_b( find( fixed_mask == 1 )));
        figure_calibration = figure('NumberTitle', 'off', 'Name', ['Iteration: ' num2str(counter_calibration + 1)]);
        for j = 1 : shift_number
            subplot(3 , 3 , j);
            soglia_b = mean_frame_b + shift(j);
            frame_c = frame_b;
            if( soglia_b < 1 )
                frame_c( find( frame_c >= soglia_b ) ) = 1;
                frame_c( find( frame_c < soglia_b ) ) = 0;
            else
                frame_c( find( frame_c < soglia_b ) ) = 0;
                frame_c( find( frame_c >= soglia_b ) ) = 1;
            end
            imshow(frame);
            hold on;
            h = imshow( frame_c .* fixed_mask );
            set(h, 'AlphaData', 0.2);
            title( list_letters{j} );
        end
        set(figure_calibration, 'units','normalized','outerposition',[0 0 1 1]);
        selection = listdlg('PromptString', 'Select best conservative mask (i.e., not masking the plume)', 'ListSize', [300 300],'ListString', list_letters, 'SelectionMode', 'single' );
        if( length(selection) > 0 & selection < 11 )
            frame_red = squeeze(frame(:,:,1));
            frame_blue = squeeze(frame(:,:,2));
            frame_green = squeeze(frame(:,:,3));
            mean_frame_red = mean(frame_red( find( fixed_mask == 1 )));
            mean_frame_blue = mean(frame_blue( find( fixed_mask == 1 )));
            mean_frame_green = mean(frame_green( find( fixed_mask == 1 )));
            if( selection == 10 )
                counter_calibration = counter_calibration + 1;
                calibration( counter_calibration, 1 : end-1 ) = [ mean_frame_l, mean_frame_a, mean_frame_b, mean_frame_red , mean_frame_blue , mean_frame_green ];
                calibration( counter_calibration , end ) = NaN;
                close( figure_calibration )
            elseif( selection == 9 )
                counter_calibration = counter_calibration + 1;
                calibration( counter_calibration, 1 : end-1 ) = [ mean_frame_l, mean_frame_a, mean_frame_b, mean_frame_red , mean_frame_blue , mean_frame_green ];
                calibration( counter_calibration , end) = [shift(selection)];
                close( figure_calibration )
            else
                close( figure_calibration )
                shift = linspace(  shift(selection) ,  shift(selection + 1) , shift_number );
                step_shift = (shift(selection + 1) - shift(selection )) ./ ( shift_number - 1 );
                shift(2:end) = shift(2:end) + (rand( shift_number - 1 , 1 ) .* step_shift - step_shift ./ 2)';
                figure_calibration = figure('NumberTitle', 'off', 'Name', ['Iteration: ' num2str(counter_calibration + 1) ' (Zoom)']);
                for j = 1 : shift_number
                    subplot(3 , 3 , j);
                    soglia_b = mean_frame_b + shift(j);
                    frame_c = frame_b;
                    if( soglia_b < 1 )
                        frame_c( find( frame_c >= soglia_b ) ) = 1;
                        frame_c( find( frame_c < soglia_b ) ) = 0;
                    else
                        frame_c( find( frame_c < soglia_b ) ) = 0;
                        frame_c(  frame_c >= soglia_b  ) = 1;
                    end
                    imshow(frame);
                    hold on;
                    h = imshow( frame_c .* fixed_mask );
                    set(h, 'AlphaData', 0.2);
                    title( list_letters{j} );
                end
                set( figure_calibration , 'units','normalized','outerposition',[0 0 1 1]);
                selection = listdlg('PromptString', 'Select best conservative mask (i.e., not masking the plume)','ListString', list_letters_zoom , 'SelectionMode', 'single' );
                if( length(selection) > 0)
                    counter_calibration = counter_calibration + 1;
                    calibration( counter_calibration, 1 : end - 1 ) = [ mean_frame_l, mean_frame_a, mean_frame_b, mean_frame_red , mean_frame_blue , mean_frame_green ];
                    calibration( counter_calibration , end ) = [shift(selection)];
                    close( figure_calibration )
                else
                    close( figure_calibration )
                    finish_calibration = 1;
                end
            end
        else
            close( figure_calibration )
            finish_calibration = 1;
        end
    end
catch
    return_data = 0;
    return
end

function test_procedure( selection_type , pathname , filename )

global calibration
global fixed_mask
global cluster_definition

finish_test = 0;
frame = NaN;
if( isequaln(selection_type, 'Single video' ) == 0 )
    names = dir(pathname);
    counter_names = 0; files_names = {};
    for i = 1:length(names)
        if( strcmp(names(i).name(max(1,end-3):end), '.avi'))
            counter_names = counter_names + 1;
            files_names{counter_names} = names(i).name;
        end
    end
end
while finish_test == 0
	if( isequaln(selection_type, 'Single video' ) & isnan(frame) )
        video = VideoReader( fullfile( pathname , filename ) );
        ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
        frame = read( video, ind_frame );
    elseif( isequaln(selection_type, 'Single video' ) )
        ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
        frame = read( video, ind_frame );
    elseif( isequaln(selection_type, 'Folder of videos' ) )
        i = 1 + round( rand()* ( length(files_names) - 1 ) );
        video = VideoReader( fullfile( pathname , files_names{i} ) );
        ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
        frame = read( video, ind_frame );
    end
    frame_lab = rgb2lab( frame );
    frame_l = squeeze(frame_lab(:,:,1));
    frame_a = squeeze(frame_lab(:,:,2));
    frame_b = squeeze(frame_lab(:,:,3)); frame_bs = frame_b;
    mean_frame_l = mean(frame_l( find( fixed_mask == 1 )));
    mean_frame_a = mean(frame_a( find( fixed_mask == 1 )));
    mean_frame_b = mean(frame_b( find( fixed_mask == 1 )));
    frame_red = squeeze(frame(:,:,1));
    frame_blue = squeeze(frame(:,:,2));
    frame_green = squeeze(frame(:,:,3));
    mean_frame_red = mean(frame_red( find( fixed_mask == 1 )));
    mean_frame_blue = mean(frame_blue( find( fixed_mask == 1 )));
    mean_frame_green = mean(frame_green( find( fixed_mask == 1 )));
    parameters_image = [ mean_frame_l, mean_frame_a, mean_frame_b, mean_frame_red , mean_frame_blue , mean_frame_green ];
    [minvalue, minindex] = min(sum(((parameters_image - cluster_definition(:,1:6)).^2)'));
	[sortvalue, sortindex] = sort(sum(((parameters_image - calibration(:,1:6)).^2)'));
	minima_index = find( sortindex <= 3 );
	soglia_b1 = sum([parameters_image, parameters_image.^2, 1] .* cluster_definition(minindex,7:19));
    soglia_b1 = min( soglia_b1 , max( calibration(:,3) + calibration(:,7) ) );
    soglia_b1 = max( soglia_b1 , min( calibration(:,3) + calibration(:,7) ) );
	soglia_b2 = mean(calibration(minima_index,3) + calibration(minima_index,7));
	figure_test = figure;
	if( soglia_b1 < 1 )
        frame_b( find( frame_b >= soglia_b1 ) ) = 1;
        frame_b( find( frame_b < soglia_b1 ) ) = 0;
    else
        frame_b( find( frame_b < soglia_b1 ) ) = 0;
        frame_b( find( frame_b >= soglia_b1 ) ) = 1;
    end
    subplot(1,2,1);
    imshow(frame);
    hold on;
    h = imshow( frame_b .* fixed_mask );
    set(h, 'AlphaData', 0.2);
    title('Polynomial fit');
    frame_b = frame_bs;
	if( soglia_b2 < 1 )
        frame_b( find( frame_b >= soglia_b2 ) ) = 1;
        frame_b( find( frame_b < soglia_b2 ) ) = 0;
    else
        frame_b( find( frame_b < soglia_b2 ) ) = 0;
        frame_b( find( frame_b >= soglia_b2 ) ) = 1;
    end
    subplot(1,2,2);
    imshow(frame);
    hold on;
    h = imshow( frame_b .* fixed_mask );
    set(h, 'AlphaData', 0.2);
    title('Nearest value');
    selection = questdlg('Continue?', 'Continue?', 'Yes', 'No', 'Yes');
	if( strcmp(selection, 'Yes') == 0 )
        finish_test = 1;
    end
	close(figure_test);
end

function [calibration_set_out, counter_cal_out , message_out ] = add_calibration( calibration_set_in , counter_cal_in , message_in , filename_in , fixed_mask_new, calibration_new, cluster_new )

for i = 1:counter_cal_in
    current_struct = calibration_set_in.(strcat('cal',num2str(i)));
    if( isequaln( current_struct.calibration , calibration_new ) & isequaln( current_struct.fixed_mask , fixed_mask_new ) & isequaln( current_struct.cluster_definition , cluster_new ) )
        if( isequaln( message_in , '') )
            message_in = 'The following calibrations are equivalent (only one is used):';
        end
        message_out = strcat( message_in , ['\n- ' current_struct.name ' and ' filename_in '.']);
        calibration_set_out = calibration_set_in;
        counter_cal_out = counter_cal_in;
        return
    end
end

counter_cal_out = counter_cal_in + 1;
message_out = message_in;
calibration_set_out = calibration_set_in;
calibration_set_out.(strcat('cal',num2str(counter_cal_out))).calibration = calibration_new;
calibration_set_out.(strcat('cal',num2str(counter_cal_out))).fixed_mask =  fixed_mask_new;
calibration_set_out.(strcat('cal',num2str(counter_cal_out))).cluster_definition = cluster_new;
calibration_set_out.(strcat('cal',num2str(counter_cal_out))).name = strrep(filename_in,'_',' ');

function video_analysis_procedure( pathname , filename )

global calibration
global fixed_mask
global cluster_definition
global vent_point

data_min_pix = zeros(0,1);  data_t = zeros(0,1);
counter_data = 0;
% names = dir(pathname);
% counter_names = 0; files_names = {};
% for i = 1:length(names)
%     if( strcmp(names(i).name(max(1,end-3):end), '.avi'))
%         counter_names = counter_names + 1;
%         files_names{counter_names} = names(i).name;
%     end
% end
video = VideoReader( fullfile( pathname , filename ) );
button = questdlg('Lab Calibration', 'Lab Calibration', 'Polynomial Fit', 'Nearest Value', 'Polynomial Fit');
button_plot = questdlg('Plot Frames?','Plot Frames?', 'No', 'Yes', 'No');
step_frame = max(1,floor(str2num(cell2mat(inputdlg({'Frame step:'},'Frame Step',[1 75],{'1'})))));
for ind_frame = 1:step_frame:video.Duration * video.FrameRate
	frame = read( video, ind_frame );
    frame_lab = rgb2lab( frame );
    frame_l = squeeze(frame_lab(:,:,1));
    frame_a = squeeze(frame_lab(:,:,2));
    frame_b = squeeze(frame_lab(:,:,3)); 
    mean_frame_l = mean(frame_l( find( fixed_mask == 1 )));
    mean_frame_a = mean(frame_a( find( fixed_mask == 1 )));
    mean_frame_b = mean(frame_b( find( fixed_mask == 1 )));
    frame_red = squeeze(frame(:,:,1));
    frame_blue = squeeze(frame(:,:,2));
    frame_green = squeeze(frame(:,:,3));
    mean_frame_red = mean(frame_red( find( fixed_mask == 1 )));
    mean_frame_blue = mean(frame_blue( find( fixed_mask == 1 )));
    mean_frame_green = mean(frame_green( find( fixed_mask == 1 )));
    parameters_image = [ mean_frame_l, mean_frame_a, mean_frame_b, mean_frame_red , mean_frame_blue , mean_frame_green ];
    if( strcmpi(button, 'Polynomial Fit'))
        [minvalue, minindex] = min(sum(((parameters_image - cluster_definition(:,1:6)).^2)'));
        soglia_b = sum([parameters_image, parameters_image.^2, 1] .* cluster_definition(minindex,7:19));
        soglia_b = max( soglia_b , min( calibration(:,3) + calibration(:,7) ) );
        soglia_b = min( soglia_b , max( calibration(:,3) + calibration(:,7) ) );
    else
        [sortvalue, sortindex] = sort(sum(((parameters_image - calibration(:,1:6)).^2)'));
        minima_index = find( sortindex <= 3 );
        soglia_b = mean(calibration(minima_index,3) + calibration(minima_index,7));
    end
	if( soglia_b < 1 )
        frame_b( find( frame_b >= soglia_b ) ) = 1;
        frame_b( find( frame_b < soglia_b ) ) = 0;
    else
        frame_b(  frame_b < soglia_b  ) = 0;
        frame_b( find( frame_b >= soglia_b ) ) = 1;
    end
    frame_b = frame_b .* fixed_mask;
	frame_b = procedure_lines( frame_b );
    frame_b = procedure_clusters( frame_b );
    %frame_b = procedure_lobes( frame_b );
    [ind_1, ind_2] = find( frame_b == 1 );
    counter_data = counter_data + 1;
    data_min_pix(counter_data) = vent_point(1) - min(ind_1); 
    data_t(counter_data) = ind_frame;
    if( strcmpi(button_plot, 'Yes') )
        figure_video_analysis = figure;
        imshow(frame);
        hold on;
        h = imshow( frame_b );
        set(h, 'AlphaData', 0.2);
        pause(1);
        close( figure_video_analysis );
    end
    disp(['- Frame: ', num2str(ind_frame), '/',num2str(video.Duration * video.FrameRate),'.']);
end
figure
plot( data_t, data_min_pix , 'ko:');

function mask_lines = procedure_lines( frame_input )

global step_lines_mask;
global vent_point;
global threshold_lines;

size_frame = size( frame_input );
height = size_frame(1); width = size_frame(2);
mask_lines = zeros( height , width );
len_ax1_lr = floor( height ./step_lines_mask );
len_ax2_lr = floor( width ./ step_lines_mask );
current_image_lr = imresize( frame_input , [ len_ax1_lr, len_ax2_lr ] );
[index_1_x, index_1_y] = find( current_image_lr > 0 );
lines_low_values = [0, 0, 0, 0];
counter = 0;
for j = min(index_1_x) : floor(vent_point(1)./step_lines_mask);
    for k =  min(index_1_x) : floor(vent_point(1)./step_lines_mask);
        if( max(improfile( current_image_lr ,[1 , len_ax2_lr],[j,k])) < threshold_lines )
            counter = counter + 1;
            m = (k - j) / (len_ax2_lr - 1);
            lines_low_values(counter, 1:4)= [j, k, m, ( j * step_lines_mask - step_lines_mask ./ 2 ) - m * ( step_lines_mask ./ 2 )];
        end
    end
end
for j = min(index_1_x) : floor(vent_point(1)./step_lines_mask);
    for k = 3 : len_ax2_lr - 2
        if( max(improfile( current_image_lr ,[1,k],[j,1])) < threshold_lines )
            counter = counter + 1;
            m = (1 - j) / (k - 1);
            lines_low_values(counter, 1:4)= [j, k, m, ( j * step_lines_mask - step_lines_mask ./ 2 ) - m * ( step_lines_mask ./ 2 )];
        end
    end
end
for j =  min(index_1_x) : floor(vent_point(1)./step_lines_mask);
    for k = 3 : len_ax2_lr - 2
        if( max(improfile( current_image_lr ,[k, len_ax2_lr],[1 , j])) < threshold_lines )
            counter = counter + 1;
            m = (j - 1) / (len_ax2_lr - k);
            lines_low_values(counter, 1:4)= [j, k, m, ( j * step_lines_mask - step_lines_mask ./2 ) - m * ( step_lines_mask * len_ax2_lr - step_lines_mask ./2  )];
        end
    end
end
for j1 = 1 : (len_ax2_lr .* step_lines_mask)
    j2 = max(1, floor(max(j1.*lines_low_values(:,3) + lines_low_values(:,4)) - step_lines_mask ./2));
    mask_lines( j2 : end , j1 ) = 1;
end
for j1 = (len_ax2_lr .* step_lines_mask + 1) : width
    mask_lines( : , j1 ) = mask_lines( : , len_ax2_lr .* step_lines_mask );
end
mask_lines = mask_lines .* frame_input;

function mask_cluster = procedure_clusters( frame_input )

global vent_point;
global min_distance_cluster;
global max_distance_cluster_vent;

SE = strel('sphere', min_distance_cluster);
mask_cluster = imerode( frame_input , SE );
[labeled_frame, numberOfRegions] = bwlabel( mask_cluster );
distance_regions = zeros(numberOfRegions, 1);
for i = 1:numberOfRegions
    [ind_1, ind_2] = find( labeled_frame == i);
    distance_regions(i) = sqrt(min(sum((([ind_1, ind_2] - vent_point).^2)')));
end
for i = 1:numberOfRegions
    if( distance_regions(i) > max( max_distance_cluster_vent, min(distance_regions)))
        mask_cluster(find( labeled_frame == i )) = 0;
    end
end
mask_cluster = mask_cluster .* frame_input;

function mask_lobes = procedure_lobes( frame_input )

global vent_point;
global min_distance_vent_lobes;
global threshold_lobes_factor;
global threshold_lobes_distance;

size_frame = size( frame_input );
height = size_frame(1); width = size_frame(2);
points = cell2mat(bwboundaries( frame_input ,'noholes'));
distance_points = zeros( length( points ) - 1, 1 );
for j = 1 : length( points ) - 1
    p1 = points( j , : ); p2 = points( j + 1 , : );
    distance_points( j ) = sqrt( sum( ( ( p2 - p1 ).^2 ) ) );
end
cumulative_sum = cumsum( distance_points );
distance_vent = sqrt( sum( ( ( points - vent_point ).^2 )' ) );
[min_distance_vent, index_vent] = min(distance_vent);
boolean_distance_vent = ( distance_vent( 1 : end-1 ) < min_distance_vent_lobes );
min_factor = 1e10; in1 = 1; in2 = 1; din = 0;
for j = 1 : length( points ) - 1
    point_1 = points(j,:);
    cum_sum = cumulative_sum - cumulative_sum(j);
    cum_sum( 1 : j - 1 ) = cum_sum( end ) + cumulative_sum(1:j-1);
    boolean_distance = find( cum_sum > cumulative_sum( end ) - cum_sum );
    c_boolean_distance = find( cum_sum <= cumulative_sum( end ) - cum_sum );
    distance_no_vent = zeros( length( points ) - 1 , 1);
    if( index_vent >= j )
        distance_no_vent( intersect(1 : j - 1, boolean_distance ) ) =  cumulative_sum(end) - cum_sum(intersect(1 : j - 1, boolean_distance ) );
        distance_no_vent( intersect( j : index_vent , c_boolean_distance ) ) =  cum_sum(intersect( j : index_vent , c_boolean_distance ) ) ;
        distance_no_vent( intersect( index_vent + 1 : end , boolean_distance ) ) =  cumulative_sum(end) - cum_sum(intersect(index_vent + 1 : end, boolean_distance ) ) ;
        distance_no_vent( find(boolean_distance_vent == 1 )) = NaN;
        distance_no_vent( find( distance_no_vent == 0 ) ) = NaN;
    else
        distance_no_vent( intersect(1 : index_vent , c_boolean_distance ) ) =  cum_sum(intersect(1 : index_vent, c_boolean_distance ) ) ;
        distance_no_vent( intersect( index_vent + 1 : j - 1 , boolean_distance ) ) =  cumulative_sum(end) - cum_sum(intersect( index_vent + 1 : j - 1 , boolean_distance ) ) ;
        distance_no_vent( intersect( j : end , c_boolean_distance ) ) = cum_sum(intersect( j : end , c_boolean_distance ) ) ;
        distance_no_vent( find(boolean_distance_vent == 1 )) = NaN;
        distance_no_vent( find( distance_no_vent == 0 ) ) = NaN;
    end
    distance_line = sqrt(sum((point_1' - points(1:end-1,:)').^2));
    distance_line( find( distance_line == 0 ) ) = NaN;
    if( min_factor > min(distance_line./distance_no_vent') & boolean_distance_vent(j) == 0)
        min_factor = min(distance_line./distance_no_vent');
        in1 = j;
        [~, in2] = min(distance_line./distance_no_vent');
        din = distance_line(in2);
    end
end
if( min_factor < threshold_lobes_factor && abs(in1 - in2) > 1 )
    if( din > threshold_lobes_distance )
        m1 = (( points(in1,1) - points(index_vent,1))./( points(in1,2) - points(index_vent,2)));
        m2 = (( points(in2,1) - points(index_vent,1))./( points(in2,2) - points(index_vent,2)));
        if( abs(m1) > abs(m2) )
            m = m1;
        else
            m = m2;
        end
        n1 = points(in1,1) - m.*points(in1,2);
        n2 = points(in2,1) - m.*points(in2,2);
    end
    if( min( in1, in2 ) > index_vent | max( in1, in2 ) < index_vent )
        if( din > threshold_lobes_distance )
            index_sup = min(in1,in2) + 1 : max(in1,in2) - 1;
            g = [];
            g1 = index_sup(find(points(index_sup,2).* m + n1 < points(index_sup,1)));
            g2 = index_sup(find(points(index_sup,2).* m + n2 < points(index_sup,1)));
            if( length(g1) > length(g2) &&  max(length(g1),length(g2)) < length(index_sup) )
                g = g1;
            elseif( length(g1) > length(g2) &&  max(length(g1),length(g2)) < length(index_sup) )
                g = g2;
            end
            index_pres = [ max( in1 , in2 ) : length( points ), g ,  1 : min( in1 , in2 ) ];
        else
            index_pres = [ max( in1 , in2 ) : length( points ), 1 : min( in1 , in2 ) ];
        end
    else
        if( din > threshold_lobes_distance )
            index_sup = [ max( in1 , in2 ) + 1 : length( points ), 1 : min( in1 , in2 ) - 1 ];
            g = [];
            g1 = index_sup(find(points(index_sup,2).* m + n1 < points(index_sup,1)));
            g2 = index_sup(find(points(index_sup,2).* m + n2 < points(index_sup,1)));
            if( length(g1) > length(g2) &&  max(length(g1),length(g2)) < length(index_sup) )
                g = g1;
            elseif( length(g1) > length(g2) &&  max(length(g1),length(g2)) < length(index_sup) )
                g = g2;
            end
            index_pres = [g( g < min( in1 , in2) ),  min( in1 , in2 ) : max( in1 , in2 ), g( g > max( in1 , in2) )];
        else
            index_pres = min( in1 , in2 ) : max( in1 , in2 );
        end
    end
    points = points( index_pres , :);
    mask_lobes = poly2mask(points(:,2), points(:,1), height, width);
    mask_lobes = procedure_lobes( mask_lobes );
else
    mask_lobes = frame_input;
end
