function PHA
 
clc; close all;

% PROCEDURE TO VERIFY THE PRESENCE OF IMAGE PROCESSING TOOLBOX
hasIPT = license( 'test' , 'image_toolbox' );
if ~hasIPT
	uiwait( msgbox( 'Sorry, but you do not seem to have the Image Processing Toolbox.' ) );
	return;
end

% GLOBAL VARIABLES
global current_path
global image_reference
global fixed_mask
global vent_point
global calibration
global cluster_fit
global max_number_clusters
global mean_size_clusters
global step_lines_mask
global threshold_lines
global min_distance_cluster
global max_distance_cluster_vent
global min_distance_vent_lobes
global threshold_lobes_factor
global threshold_lobes_distance
global shift_max_lab_mask
global shift_number
global shift_raw
global threshold_dark
global threshold_blue_dark
global prctile_dark
global factor_cloud
global pixel_height
global gradient_threshold
global gradient_threshold_min
global gradient_frac_threshold
global gradient_threshold_min_2
global gradient_frac_threshold_2
global gradient_max
global factor_threshold_top
global min_height
global factor_mat_eval
global factor_val_max
global gradient_val_max 
global factor_dark_val_max
global dark_val_max
global save_video

% DEFINE VARIABLES
current_path = pwd;
image_reference = NaN;
fixed_mask = NaN;
vent_point = NaN;
calibration = NaN;
cluster_fit = NaN;
max_number_clusters = 5;
mean_size_clusters = 7;
step_lines_mask = 20;
threshold_lines = 0.20;
min_distance_cluster = 1;
max_distance_cluster_vent = 50;
min_distance_vent_lobes = 100;
threshold_lobes_factor = 0.15;
threshold_lobes_distance = 10;
shift_max_lab_mask = 15; 
shift_number = 9;
shift_raw = 3;
threshold_dark = 0.85;
threshold_blue_dark = 160;
prctile_dark = 99;
factor_cloud = 0.95;
pixel_height = NaN;
gradient_threshold = 15;
factor_threshold_top = 0.3;
gradient_threshold_min = 5;
gradient_frac_threshold = 0.8;
gradient_threshold_min_2 = 30;
gradient_frac_threshold_2 = 0.6;
gradient_max = 30;
min_height = 500;
factor_mat_eval = [ 0.8 0.7 0.6];
factor_val_max = [ 0.6 0.5 0.4];
gradient_val_max = 4.0;
factor_dark_val_max = [ 0.2 0.15 0.1 ];
dark_val_max = [4.0 3.5 3.0];
save_video = 0;

% CREATE MAIN WINDOW
% Create window
scr = get( 0 , 'ScreenSize' ); w = 500; h = 400;
fig = figure( 'position' , [ scr( 3 ) / 2 - w/2 scr( 4 ) / 2 - h / 2 w h ], 'Color' , [ .2 .2 .2 ], 'Resize' , 'off' , 'Toolbar' , 'none' , 'Menubar' , 'none' , 'Name' , 'PHA: PlumeHeightAnalyzer' , 'NumberTitle' , 'off' , 'DeleteFcn' , @delete_figure );

% Menu
menu0 = uimenu( fig , 'Label' , 'Fixed Mask' );
uimenu( menu0 , 'Label' , 'Load' , 'callback' , @load_mask );
uimenu( menu0 , 'Label' , 'Create' , 'callback' , @create_mask );
uimenu( menu0 , 'Label' , 'Plot' , 'callback' , @plot_mask );
menu1 = uimenu( fig , 'Label' , 'Vent Position' );
uimenu( menu1 , 'Label' , 'Load' , 'callback' , @load_vent );
uimenu( menu1 , 'Label' , 'Create' , 'callback' , @create_vent );
uimenu( menu1 , 'Label' , 'Plot' , 'callback' , @plot_vent );
menu2 = uimenu( fig , 'Label' , 'Pixel to height' );
uimenu( menu2 , 'Label' , 'Load' , 'callback' , @load_height );
uimenu( menu2 , 'Label' , 'Create' , 'callback' , @create_height );
uimenu( menu2 , 'Label' , 'Plot' , 'callback' , @plot_height );
menu3 = uimenu( fig , 'Label' , 'Calibration' );
m31 = uimenu( menu3 , 'Label' , 'Lab Mask' , 'Separator' , 'off' );
m32 = uimenu( menu3 , 'Label' , 'Default Parameters' , 'Separator' , 'off' );
uimenu( m32 , 'Label' , 'Load' , 'callback' , @load_default_param );
uimenu( m32 , 'Label' , 'Create' , 'callback' , @default_param );
uimenu( m31 , 'Label' , 'Load' , 'callback' , @load_lab );
uimenu( m31 , 'Label' , 'Create' , 'callback' , @create_lab );
uimenu( m31 , 'Label' , 'Improve' , 'callback' , @improve_lab );
uimenu( m31 , 'Label' , 'Merge' , 'callback' , @merge_lab );
uimenu( m31 , 'Label' , 'Test' , 'callback' , @test_lab );
m315 = uimenu( m31 , 'Label' , 'Compare' );
uimenu( m315 , 'Label' , 'Plot Threshold' , 'callback' , @compare_1_lab );
uimenu( m315 , 'Label' , 'Show Images' , 'callback' , @compare_2_lab );
menu4 = uimenu( fig , 'Label' , 'Analysis' );
uimenu( menu4 , 'Label' , 'Single Video' , 'callback' , @analysis_video );
uimenu( menu4 , 'Label' , 'Folder of Images' , 'callback' , @analysis_images );
uimenu( menu4 , 'Label' , 'Analyze manually' , 'callback' , @analysis_manually );
menu5 = uimenu( fig , 'Label' , 'Results' );
uimenu( menu5 , 'Label' , 'Single Plot' , 'callback' , @plot_results );
uimenu( menu5 , 'Label' , 'Compare Plots' , 'callback' , @plot_compare );

logo = imread( 'Logo/logo.png' );
imagesc( logo );
axis off; ax = gca; outerpos = ax.OuterPosition;
left = outerpos( 1 ) ; bottom = outerpos( 2 ) ;
ax_width = outerpos( 3 ) ; ax_height = outerpos( 4 ) ; ax.Position = [ left bottom ax_width ax_height ];

function load_mask( ~ , ~ )

global current_path
global fixed_mask

[ filename , pathname ] = uigetfile( '*.mat' , 'Select mask' , fullfile( current_path , 'MaskFiles' ) ) ;
if( filename == 0 )
    uiwait( msgbox( 'Mask was not loaded.' ) ); return;
end
old_fixed_mask = fixed_mask;
fixed_mask = load( fullfile( pathname , filename ) ); fixed_mask = fixed_mask.fixed_mask;
message = 'Fixed mask loaded successfully.';
message = verify_consistency( message , "fixed_mask" , old_fixed_mask );
uiwait( msgbox( sprintf( message ) ) );
displace_vent;

function create_mask( ~ , ~ )

global current_path
global image_reference
global fixed_mask
global vent_point
global calibration
global cluster_fit

if( isequaln( image_reference , NaN ) )
    return_data = ask_image_reference;
    if( return_data == 0 )
        uiwait( msgbox( 'Reference image was not loaded.' ) ); return;
    end
else
	button = questdlg( 'Use current reference image:' , 'Use current reference image:' , 'Yes' , 'Choice other image' , 'Yes' );
    if strcmpi( button , 'Choice other image' )
        return_data = ask_image_reference;
        if( return_data == 0 )
            uiwait( msgbox( 'Reference image was not loaded.' ) ); return;
        end
    elseif ~strcmpi( button , 'Yes' )
        uiwait( msgbox( sprintf( 'Mask was not created.' ) ) ); return;
    end
end
[ rows , columns , ~ ] = size( image_reference );
old_fixed_mask = fixed_mask;
old_calibration = calibration;
old_cluster_fit = cluster_fit;
old_vent_point = vent_point;
try
    f_polygons = figure; ax = axes( f_polygons );
    imshow( image_reference , 'Parent' , ax );
    title( ax , 'Creating masked zone' ); hold on;
    if( ~isequaln( vent_point , NaN ) )
        plot( ax , vent_point( 1 ), vent_point( 2 ), 'bo' , 'MarkerFaceColor' , 'b' );
    end
    set( f_polygons, 'units' , 'normalized' , 'outerposition' ,[ 0 0 1 1 ] );
    set( f_polygons, 'name' , 'Creating masked zone' , 'numbertitle' , 'off' );
    regionCount = 0; option_finish = 'Create Empty Mask';
    fixed_mask = ones( rows , columns );
    while true && regionCount < 20
        button = questdlg( sprintf( 'Draw region #%d in the image,\nor finish?' , regionCount + 1), 'Continue?' , 'Draw' , option_finish , 'Draw' );
        if strcmpi( button, option_finish )
            close( f_polygons ); break;
        elseif ~strcmpi( button, 'Draw' )
            fixed_mask = old_fixed_mask; close( f_polygons ); 
            uiwait( msgbox( sprintf( 'Mask was not created.' ) ) ); return;
        end
        option_finish = 'Finish'; regionCount = regionCount + 1;
        message = sprintf( 'Left click vertices in the image.\nRight click the last vertex to finish.\nThen double click in the middle to accept it.' );
        uiwait( msgbox( message ) );
        [ this_fixed_mask ,  ~ , ~] = roipoly();
        fixed_mask = fixed_mask .* ( 1 - this_fixed_mask );
    end
    factor_borders = floor( 0.02 .* sqrt( rows .* columns ) );
    while true
        current_fixed_mask = fixed_mask;
        for i = 1:rows
            fixed_mask( i , 1 : factor_borders ) =  min( fixed_mask( i , 1 : factor_borders ) );
            fixed_mask( i , end - factor_borders + 1 : end ) =  min( fixed_mask( i , end - factor_borders + 1 : end ) );
        end
        for i = 1:columns
            fixed_mask( 1 : factor_borders , i ) =  min( fixed_mask( 1 : factor_borders , i ) );
            fixed_mask( end - factor_borders + 1 : end , i ) =  min( fixed_mask( end - factor_borders + 1 : end , i ) );
        end
        if( current_fixed_mask == fixed_mask )
            definput = { 'Default_Mask' , 'hsv' };
            mask_name = inputdlg( 'Enter mask name:' , 'Mask name' , [ 1 100] , definput );
            if( isempty( mask_name ) )
                uiwait( msgbox( 'Fixed mask was not saved.' ) ); fixed_mask = old_fixed_mask; return;
            end
            save( fullfile( current_path , 'MaskFiles' , mask_name{ 1 } ) , 'fixed_mask' );
            break
        end
    end
    message = 'Fixed mask saved successfully.';
    message = verify_consistency( message , "fixed_mask" , old_fixed_mask );
    uiwait( msgbox( sprintf( message ) ) );
	displace_vent;
catch
    fixed_mask = old_fixed_mask;
    calibration = old_calibration;
    cluster_fit = old_cluster_fit;
    vent_point = old_vent_point;
    uiwait( msgbox( sprintf( 'Mask was not created.' ) ) ); 
    return;
end

function plot_mask( ~ , ~ )

global image_reference
global fixed_mask

if( isequaln( image_reference , NaN ) )
	button = questdlg( 'Reference image is not loaded' , 'Reference image is not loaded' , 'Choice an image' , 'Continue without reference image' , 'Choice an image' );
    if strcmpi( button, 'Choice an image' )
        return_data = ask_image_reference;
        if( return_data == 0 )
            uiwait( msgbox( 'Reference image was not loaded.' ) ); return;
        end
    elseif ~strcmpi( button, 'Continue without reference image' )
        return;
    end
end
if( isequaln( fixed_mask , NaN ) && isequaln( image_reference , NaN ) )
    uiwait( msgbox( 'Fixed mask and reference image are not present.' ) ); return;
elseif( isequaln( fixed_mask , NaN ) )
	uiwait( msgbox( 'Warning: fixed mask is not present.' ) );
	f_plot_mask = figure; axes_pm = axes( 'Parent' , f_plot_mask );
	imshow( image_reference , 'Parent' , axes_pm ); hold on;
elseif( isequaln( image_reference , NaN ) )
	f_plot_mask = figure; axes_pm = axes( 'Parent' , f_plot_mask );
    imshow( fixed_mask , 'Parent' , axes_pm ); hold on;
else
    fixed_mask_plot = fixed_mask;
    fixed_mask_plot( fixed_mask_plot == 0 ) = 0.5;
	f_plot_mask = figure; axes_pm = axes( 'Parent' , f_plot_mask );
    imagesc( im2double( image_reference ) .* cat( 3 , fixed_mask_plot , fixed_mask_plot , fixed_mask_plot ) , 'Parent' , axes_pm );
end

function load_vent( ~ , ~ )

global vent_point
global current_path

[ filename , pathname ] = uigetfile( '*.mat' , 'Select vent' , fullfile( current_path , 'VentFiles' ) ) ;
if( filename == 0 )
    uiwait( msgbox( 'Vent position was not loaded.' ) ); return
end
old_vent_point = vent_point;
vent_point = load( fullfile( pathname , filename ) );
vent_point = vent_point.vent_point;
message = 'Vent position loaded successfully.';
message = verify_consistency( message , "vent_point" , old_vent_point );
uiwait( msgbox( sprintf( message ) ) );
displace_vent;

function create_vent( ~ , ~ )

global current_path
global image_reference
global fixed_mask
global vent_point

if( isequaln( image_reference , NaN ) )
    return_data = ask_image_reference;
    if( return_data == 0 )
        uiwait( msgbox( 'Reference image was not loaded.' ) ); return;
    end
else
	button = questdlg( 'Use current reference image' , 'Use current reference image' , 'Yes' , 'Choice other image' , 'Yes' );
    if strcmpi( button, 'Choice other image' )
        return_data = ask_image_reference;
        if( return_data == 0 )
            uiwait( msgbox( 'Reference image was not loaded.' ) ); return;
        end
    elseif ~strcmpi( button , 'Yes' )
        uiwait( msgbox( sprintf( 'Vent was not created.' ) ) ); return;
    end
end
old_vent_point = vent_point;
try
    f_vent = figure; ax = axes( f_vent );
    imshow( image_reference , 'Parent' , ax ); hold on;
    if( ~isequaln( fixed_mask , NaN ) )
        h = imshow( fixed_mask ); set( h , 'AlphaData' , 0.2 ); hold on;
    end
    title( ax , 'Creating vent position' );
    set( f_vent, 'units' , 'normalized' , 'outerposition' , [ 0 0 1 1 ] );
    set( f_vent, 'name' , 'Creating vent position' , 'numbertitle' , 'off' );
    uiwait( msgbox( 'Select vent position' ) );
    vent_point = drawpoint();
    vent_point = round( vent_point.Position );
    close( f_vent );
    vent_name = inputdlg( 'Enter vent name:' , 'Vent name' , [ 1 100 ] , { 'Default_Vent' , 'hsv' } );
	if( isempty( vent_name ) )
        vent_point = old_vent_point; 
        uiwait( msgbox( 'Vent was not created.' ) ); 
        return;
	end
    save( fullfile( current_path , 'VentFiles' , vent_name{ 1 } ) , 'vent_point' );
    message = 'Vent position saved successfully.';
    message = verify_consistency( message , "vent_point" , old_vent_point );
    uiwait( msgbox( sprintf( message ) ) );
    displace_vent;
catch
    vent_point = old_vent_point; 
    uiwait( msgbox( sprintf( 'Vent was not created.' ) ) ); return;
end

function plot_vent( ~ , ~ )

global image_reference
global fixed_mask
global vent_point

if( isequaln( vent_point , NaN ) )
	uiwait( msgbox( 'The vent point is not present.' ) ); return;
end
if( isequaln( image_reference , NaN ) )
	button = questdlg( 'Reference image is not loaded' , 'Reference image is not loaded' , 'Choice an image' , 'Continue without reference image' , 'Choice an image' );
    if strcmpi( button, 'Choice an image' )
        return_data = ask_image_reference;
        if( return_data == 0 )
            uiwait( msgbox( 'Reference image was not loaded.' ) ); return;
        end
    elseif ~strcmpi( button, 'Continue without reference image' )
        uiwait( msgbox( 'Reference image was not loaded.' ) ); return;
    end    
end
if( isequaln( vent_point , NaN ) )
	uiwait( msgbox( 'The vent point is not present.' ) ); return;
end
if( isequaln( fixed_mask , NaN ) && isequaln( image_reference , NaN ) )
    uiwait( msgbox( 'Fixed mask and reference image are not present.' ) ); return
elseif( isequaln( fixed_mask , NaN ) )
	uiwait( msgbox( 'Warning: fixed mask is not present.' ) );
	f_plot_vent = figure; axes_pv = axes( 'Parent' , f_plot_vent ); pause( 0.001 );
	imshow( image_reference , 'Parent' , axes_pv ); hold on; pause( 0.001 );
elseif( isequaln( image_reference , NaN ) )
	f_plot_vent = figure; axes_pv = axes( 'Parent' , f_plot_vent ); pause( 0.001 );
    imshow( fixed_mask , 'Parent' , axes_pv ); hold on; pause( 0.001 );
else
	f_plot_vent = figure; axes_pv = axes( 'Parent' , f_plot_vent ); pause( 0.001 );
    imshow( image_reference , 'Parent' , axes_pv ); hold on; pause( 0.001 );
	h = imshow( fixed_mask , 'Parent' , axes_pv ); hold on; pause( 0.001 );
	set( h, 'AlphaData' , 0.2 ); pause( 0.001 );
end
plot( vent_point( 1 ), vent_point( 2 ), 'bo' , 'MarkerFaceColor' , 'b' , 'Parent' , axes_pv ); pause( 0.001 );

function load_height( ~ , ~ )

global pixel_height
global current_path

[ filename , pathname ] = uigetfile( '*.mat' , 'Select pixel-height conversion file' , fullfile( current_path , 'PixelHeightFiles' ) );
if( filename == 0 )
    uiwait( msgbox( 'Pixel-height conversion file was not loaded.' ) ); return;
end
pixel_height = load( fullfile( pathname , filename ) );
pixel_height = pixel_height.pixel_height;
message = 'Pixel-height conversion file loaded successfully.';
message = verify_consistency( message , "pixel_height" , 0 );
uiwait( msgbox( sprintf( message ) ) );

function create_height( ~ , ~ )

global vent_point
global image_reference
global fixed_mask
global pixel_height;
global current_path 

if( isequaln( vent_point , NaN ) )
    uiwait( msgbox( 'Vent position is not loaded.' ) ); return
end
old_pixel_height = pixel_height;
button = questdlg( 'Select type of pixel-height conversion' , 'Select type of pixel-height conversion' , 'Constant, vertical gradient' , 'Input file' , 'Interpolation' , 'Contant, vertical gradient' );
if ( strcmpi( button, 'Interpolation' ) )
    button_2 = questdlg( 'Select type of interpolation' , 'Select type of interpolation' , 'Bilinear interpolation' , 'Second-order interpolation' , 'Bilinear interpolation' );
    if ( strcmpi( button_2 , 'Bilinear interpolation' ) )
        minpoints = 3;
    elseif( strcmpi( button_2 , 'Second-order interpolation' ) )
        minpoints = 5;
    else
        return
    end
elseif( ~strcmpi( button, 'Constant, vertical gradient' ) && ~strcmpi( button, 'Input file' ) )
    return;
end
if( isequaln( image_reference , NaN ) )
    return_data = ask_image_reference;
    if( return_data == 0 )
        uiwait( msgbox( 'Reference image was not loaded.' ) ); return;
    end
else
	button_ir = questdlg( 'Use current reference image:' , 'Use current reference image:' , 'Yes' , 'Choice other image' , 'Yes' );
    if strcmpi( button_ir , 'Choice other image' )
        return_data = ask_image_reference;
        if( return_data == 0 )
            uiwait( msgbox( 'Reference image was not loaded.' ) ); return;
        end
    elseif ~strcmpi( button_ir, 'Yes' )
        return;
    end
end
if( isequaln( vent_point , NaN ) )
    uiwait( msgbox( 'Vent position is not loaded.' ) ); return
end
f_pixelheight = figure; ax = axes( f_pixelheight ); pause( 0.001 );
size_image = size( image_reference ); pause( 0.001 );
imshow( image_reference ,  'Parent' , ax ); hold on; pause( 0.001 );
if( ~isequaln( fixed_mask , NaN ) )
    h = imshow( fixed_mask ,  'Parent' , ax ); hold on; pause( 0.001 );
    set( h , 'AlphaData' , 0.2 ); pause( 0.001 );
end
plot( vent_point( 1 ), vent_point( 2 ), 'bo' , 'MarkerFaceColor' , 'b' , 'Parent' , ax ); pause( 0.001 );
try
    if strcmpi( button , 'Constant, vertical gradient' )
        vent_height = max( 0 , str2double( cell2mat( inputdlg ( { 'Vent height (m a.s.l.):' } , 'Vent height'  , [ 1 75] , {'1000'} ) ) ) );
        top_height = max( 0 , str2double( cell2mat( inputdlg( { 'Height of image top (m a.s.l.):' } , 'Height of image top' , [ 1 75] , {'10000'} ) ) ) );
        pixel_to_1_km = ( vent_point( 2 ) - 1 ) .* 1000 / ( top_height - vent_height );
        pixel_height = nan( size_image( 1 ) , size_image( 2 ) );
        for i = 1 : vent_point( 2 )
            pixel_height( i , : ) = vent_height + ( vent_point( 2 ) - i ) * 1000 / pixel_to_1_km;
        end
        pixel_name = inputdlg( 'Enter pixel-height conversion name:' , 'Pixel-height conversion name' , [ 1 100] , {'Default_PixelHeight' , 'hsv'});
        if( isempty( pixel_name ) )
            pixel_height = old_pixel_height; 
            uiwait( msgbox( 'Pixel-height conversion was not created.' ) ); return;
        end
        save( fullfile( current_path , 'PixelHeightFiles' , pixel_name{ 1 } ) , 'pixel_height' );
        message = 'Pixel-height conversion saved successfully.';
        message = verify_consistency( message , "pixel_height" , 0 );
        uiwait( msgbox( sprintf( message ) ) );
    elseif( strcmpi( button, 'Interpolation' ) )
        set( f_pixelheight , 'units' , 'normalized' , 'outerposition' , [ 0 0 1 1 ] );
        set( f_pixelheight , 'name' , 'Add points for pixel-height conversion' , 'numbertitle' , 'off' );
        height_save = zeros( 0 ,1); point_save = zeros( 0 ,2);
        counter_points = 0; continue_boolean = 1;
        while continue_boolean
            point = drawpoint();
            point_height = str2double( cell2mat( inputdlg( { 'Point height (m a.s.l.):' } , 'Point height' , [ 1 75 ] , { '1000' } ) ) );
            if( isnan( point_height ) )
                pixel_height = old_pixel_height;
                try
                    close( f_pixelheight ); clear f_pixelheight; clear ax;
                catch
                    continue;
                end
                uiwait( msgbox( 'Pixel-height conversion was not created.' ) );
                return;
            end
            counter_points = counter_points + 1;
            point_save( counter_points, : ) = point.Position;
            height_save( counter_points, : ) = point_height;
            if( counter_points >= minpoints )
                button_continue = questdlg( 'Do you want to add more points?' , 'Add more points?' , 'Yes' , 'No' , 'Yes' );
                if( strcmpi( button_continue , 'No' ) )
                    continue_boolean = 0;
                elseif( ~strcmpi( button_continue , 'Yes' ) )
                    pixel_height = old_pixel_height; return;
                end
            end
        end
        if( strcmpi( button_2 , 'Bilinear interpolation' ) )
            fit = regress( height_save , [ point_save ones( length( height_save ) , 1 ) ] );
        elseif( strcmpi( button_2 , 'Second-order interpolation' ) )
            fit = regress( height_save , [ ( point_save.^2 ) point_save ones( length( height_save ) , 1 ) ] );
        end
        pixel_height_aux1 = zeros( size_image( 1 ), size_image( 2 ) );
        for i = 1 : size_image( 1 )
            pixel_height_aux1( i , : ) = i;
        end
        pixel_height_aux2 = zeros( size_image( 1 ), size_image( 2 ) );
        for j = 1 : size_image( 2 )
            pixel_height_aux2(:, j ) = j;
        end
        if( strcmpi( button_2 , 'Bilinear interpolation' ) )
            pixel_height = pixel_height_aux2 .* fit( 1 ) + pixel_height_aux1 .* fit( 2 ) + fit( 3 );
            vent_height = vent_point( 1 ) .* fit( 1 ) + vent_point( 2 ) .* fit( 2 ) + fit( 3 );
        elseif( strcmpi( button_2 , 'Second-order interpolation' ) )
            pixel_height = pixel_height_aux2.^2 .* fit( 1 ) + pixel_height_aux1 .^ 2 .* fit( 2 ) + pixel_height_aux2 .* fit( 3 ) + pixel_height_aux1 .* fit( 4 ) + fit( 5 );
            vent_height = vent_point( 1 ) .^ 2 .* fit( 1 ) + vent_point( 2 ) .^ 2 .* fit( 2 ) + vent_point( 1 ) .* fit( 3 ) + vent_point( 2 ) .* fit( 4 ) + fit( 5 );
        end
        pixel_height( pixel_height < vent_height ) = NaN;
        pixel_name = inputdlg( 'Enter pixel-height conversion name:' , 'Pixel-height conversion name' , [ 1 100] , { 'Default_PixelHeight' , 'hsv' } );
        if( isempty( pixel_name ) )
            pixel_height = old_pixel_height; 
            uiwait( msgbox( 'Pixel-height conversion was not created.' ) ); return;
        end
        save( fullfile( current_path , 'PixelHeightFiles' , pixel_name{ 1 } ) , 'pixel_height' );
        message = 'Pixel-height conversion saved successfully.';
        message = verify_consistency( message , "pixel_height" , 0 );
        uiwait( msgbox( sprintf( message ) ) );
    elseif( strcmpi( button , 'Input file' ) )
        [ filename , pathname ] = uigetfile( '*.txt' , 'Select pixel-height conversion file' , current_path ) ;
        pixel_height = load( fullfile( pathname , filename ) );
        pixel_name = inputdlg( 'Enter pixel-height conversion name:' , 'Pixel-height conversion name' , [ 1 100 ] , {'Default_PixelHeight' , 'hsv' } );
        if( isempty( pixel_name ) )
            pixel_height = old_pixel_height; 
            uiwait( msgbox( 'Pixel-height conversion was not created.' ) ); return;
        end
        save( fullfile( current_path , 'PixelHeightFiles' , pixel_name{ 1 } ) , 'pixel_height' );
        message = 'Pixel-height conversion saved successfully.';
        message = verify_consistency( message , "pixel_height" , 0 );
        uiwait( msgbox( sprintf( message ) ) );     
    end
catch
    pixel_height = old_pixel_height; uiwait( msgbox( 'Error in input parameters.' ) );
end
try
    close( f_pixelheight ); return;
catch
    return;
end

function plot_height( ~ , ~ )

global image_reference
global fixed_mask
global pixel_height

if( isequaln( pixel_height , NaN ) )
	uiwait( msgbox( 'Pixel-height conversion is not present.' ) ); return;
end
if( isequaln( image_reference , NaN ) )
	button = questdlg( 'Reference image is not loaded' , 'Reference image is not loaded' , 'Choice an image' , 'Continue without reference image' , 'Choice an image' );
    if strcmpi( button, 'Choice an image' )
        return_data = ask_image_reference;
        if( return_data == 0 )
            uiwait( msgbox( 'Reference image was not loaded.' ) ); return;
        end
    elseif ~strcmpi( button , 'Continue without reference image' )
        uiwait( msgbox( 'Reference image was not loaded.' ) ); return;
    end    
end
if( isequaln( pixel_height , NaN ) )
	uiwait( msgbox( 'Pixel-height conversion is not present.' ) ); return;
end
if( ~isequaln( image_reference , NaN ) )
    f_plot_pixel = figure; ax = axes( f_plot_pixel ); pause( 0.001 );
    imshow( image_reference , 'Parent' , ax ); hold on; pause( 0.001 );
elseif( ~isequaln( fixed_mask , NaN ) )
    f_plot_pixel = figure; ax = axes( f_plot_pixel ); pause( 0.001 );   
	imshow( fixed_mask , 'Parent' , ax ); hold on; pause( 0.001 );
else
    uiwait( msgbox( 'Fixed mask and reference image are not present.' ) ); return;
end
x_contour = 1 : length( pixel_height( : , 1 ) ); y_contour = 1 : length( pixel_height( 1 , : ) );
[ x_plot , y_plot ] = meshgrid( y_contour, x_contour );
[ cc , hc ] = contour( x_plot, y_plot, pixel_height, sort( 0 : 1000 : 20000 ), 'k' , 'Parent' , ax ); pause( 0.001 );
clabel( cc , hc );pause( 0.001 );

function load_lab( ~ , ~ )

global current_path
global fixed_mask
global cluster_fit
global calibration
global vent_point

[ filename , pathname ] = uigetfile( '*.mat' , 'Select Lab calibration file' , fullfile( current_path , fullfile( 'CalibrationFiles' , 'LabMask' ) ) ) ;
if( filename == 0 )
    uiwait( msgbox( 'Calibration file was not loaded.' ) ); return;
end
calibration_data = load( fullfile( pathname , filename ) );
cluster_fit = calibration_data.cluster_fit;
calibration = calibration_data.calibration;
fixed_mask = calibration_data.fixed_mask;
vent_point = calibration_data.vent_point;
message = 'Calibration file and the associated fixed mask and vent position were loaded successfully.';
message = verify_consistency( message , "calibration" , 0 );
uiwait( msgbox( sprintf( message ) ) );

function create_lab( ~ , ~ )

global fixed_mask
global vent_point
global calibration
global cluster_fit

if( isequaln( vent_point , NaN ) )
	uiwait( msgbox( 'Vent point is not present.' ) ); return;
end
if( isequaln( fixed_mask , NaN ) )
	uiwait( msgbox( 'Fixed mask is not present.' ) ); return;
end
selection_type = questdlg( 'Select data type' , 'Select data type' , 'Single video' , 'Folder of videos' , 'Folder of images' , 'Single video' );
if( isequaln( selection_type , 'Single video' ) )
	[ filename , pathname ] = uigetfile( '*.avi' , 'Select calibration video' ) ;
elseif( isequaln( selection_type , 'Folder of videos' ) || isequaln( selection_type , 'Folder of images' ) )
	[ pathname ] = uigetdir( 'Select folder of images/videos for calibration' ) ;
	filename = '';
else
	uiwait( msgbox( 'Data type was not selected.' ) ); return;
end
if( pathname == 0 )
	uiwait( msgbox( 'Data for calibration was not selected.' ) ); return;
else
    old_calibration = calibration;
    old_cluster_fit = cluster_fit;
	calibration = zeros( 0 , 8 );
	return_data = calibration_procedure( selection_type , pathname , filename , 0 );
    if( return_data == 1 && ~isempty( calibration ) )
    	lab_calibration_name = inputdlg( '' , 'Lab calibration name' , [ 1 100] , {'Default_LabCalibration'} );
        if( ~isempty( lab_calibration_name ) )
            compute_calibration( lab_calibration_name{ 1 } );
        else
            calibration = old_calibration; cluster_fit = old_cluster_fit; uiwait( msgbox( 'Calibration was not saved.' ) ); return;
        end
    else
        calibration = old_calibration; cluster_fit = old_cluster_fit;
        if( return_data == - 1 )
            uiwait( msgbox( 'Fixed mask dimensions and dimensions of images/videos used in calibration do not coincide. Calibration was not saved.' ) );
        elseif( return_data == 1 )
            uiwait( msgbox( 'Calibration was not saved because it does not contain any data.' ) );
        else
            uiwait( msgbox( 'Calibration was not saved because the window was closed incorrectly.' ) );
        end
        return;
    end
end

function improve_lab( ~ , ~ )

global current_path
global fixed_mask
global calibration
global cluster_fit
global vent_point

[ filename , pathname ] = uigetfile( '*.mat' , 'Select calibration to be improved' , fullfile( current_path , fullfile( 'CalibrationFiles' , 'LabMask' ) ) ) ;
if( filename == 0 )
    uiwait( msgbox( 'Data of the calibration file to be improved was not selected.' ) ); return;
end
calibration_file = load( fullfile( pathname , filename ) );
fixed_mask = calibration_file.fixed_mask;
vent_point = calibration_file.vent_point;
calibration = calibration_file.calibration;
cluster_fit =  calibration_file.cluster_fit;
size_imp_calibration = length( calibration( : , 1 ) );
lab_calibration_name = { filename( 1 : end - 4 ) };
imp_calibration = calibration; imp_cluster_fit = cluster_fit;
uiwait( msgbox( sprintf( 'Calibration file and the associated fixed mask and vent position were loaded successfully.' ) ) );
selection_type = questdlg( 'Select data type' , 'Select data type' , 'Single video' , 'Folder of videos' , 'Folder of images' , 'Single video' );
if( isequaln( selection_type , 'Single video' ) )
	[ filename , pathname ] = uigetfile( '*.avi' , 'Select calibration video' ) ;
elseif( isequaln( selection_type , 'Folder of videos' ) || isequaln( selection_type , 'Folder of images' ) )
	[ pathname ] = uigetdir( 'Select folder of images/videos for calibration' ) ; filename = '';
else
	uiwait( msgbox( 'Data type was not selected.' ) ); return;
end
if( pathname == 0 )
	uiwait( msgbox( 'Data for calibration was not selected.' ) ); return;
else
	return_data = calibration_procedure( selection_type , pathname , filename , size_imp_calibration );
    if( return_data == 1 && ~isequaln( imp_calibration , calibration ) )
        button = questdlg( 'Do you confirm to improve calibration?' , 'Do you confirm to improve calibration?' , 'Yes, save with other name' , 'Yes, overwrite previous file' , 'No' , 'Yes, save with other name' );
        if( strcmpi( button , 'Yes, save with other name' ) )
            lab_calibration_name = inputdlg( '' , 'Lab calibration name' , [ 1 100] , {'Default_LabCalibration'} );
            if( ~isempty( lab_calibration_name ) )
                compute_calibration( lab_calibration_name{ 1 } ); uiwait( msgbox( 'Calibration saved successfully.' ) ); return;
            else
                calibration = imp_calibration; cluster_fit = imp_cluster_fit; uiwait( msgbox( 'Calibration was not saved.' ) ); return;
            end
        elseif( strcmpi( button , 'Yes, overwrite previous file' ) )
            compute_calibration( lab_calibration_name{ 1 } ); uiwait( msgbox( 'Calibration saved successfully.' ) ); return;
        else
            calibration = imp_calibration; cluster_fit = imp_cluster_fit; uiwait( msgbox( 'Calibration was not saved.' ) ); return;
        end
    else
        calibration = imp_calibration; cluster_fit = imp_cluster_fit;
        if( return_data == - 1 )
            uiwait( msgbox( 'Fixed mask dimensions and dimensions of images/videos used in calibration do not coincide. Calibration was not saved.' ) );
        elseif( return_data == 1 )
            uiwait( msgbox( 'New calibration was not saved because it does not contain additional data.' ) );
        else
            uiwait( msgbox( 'Calibration was not saved because the window was closed incorrectly.' ) );
        end
        return;
    end
end

function merge_lab( ~ , ~ )

global current_path
global vent_point
global fixed_mask
global calibration

[ filename , pathname ] = uigetfile( '*.mat' , 'Select Lab calibration files to merge' , fullfile( current_path , fullfile( 'CalibrationFiles' , 'LabMask' ) ) , 'MultiSelect' , 'on' );
if( iscell( filename ) )
    for i = 1:length( filename )
        calibration_file_new = load( fullfile( pathname , filename{i} ) );
        calibration_new = calibration_file_new.calibration;
        calibration_new( : , 8 ) = 0;
        fixed_mask_new = calibration_file_new.fixed_mask;
        vent_point_new = calibration_file_new.vent_point;
        if( i == 1 )
            calibration_cur = calibration_new;
            fixed_mask_cur = fixed_mask_new;
            vent_point_cur = vent_point_new;
        else
            if( ~isequaln( fixed_mask_new , fixed_mask_cur ) )
                uiwait( msgbox( 'Calibration files were defined using different fixed masks. Merging was not performed.' ) ); return;
            elseif( ~isequaln( vent_point_new, vent_point_cur ) )
                uiwait( msgbox( 'Calibration files were defined using different vent points. Merging was not performed.' ) ); return;
            else
                calibration_cur( end + 1 : end + length( calibration_new( : , 1 ) )  , : ) = calibration_new;
                calibration_cur = unique( calibration_cur , 'rows' );
            end
        end
    end
	lab_calibration_name = inputdlg( '' , 'Lab calibration name' , [ 1 100] , {'Default_LabCalibration'} );
	if( ~isempty( lab_calibration_name ) )
        calibration = calibration_cur;
        fixed_mask = fixed_mask_cur;
        vent_point = vent_point_cur;
        compute_calibration( lab_calibration_name{ 1 } );
        uiwait( msgbox( 'Calibration saved successfully.' ) ); return;
    else
        uiwait( msgbox( 'Calibration was not saved.' ) ); return;
	end
else
	uiwait( msgbox( 'Please select at least two files to merge.' ) ); return;
end

function test_lab( ~ , ~ )

global vent_point
global fixed_mask
global calibration
global cluster_fit

if( isequaln( calibration , NaN ) || isequaln( cluster_fit , NaN ) || isequaln( fixed_mask , NaN ) || isequaln( vent_point , NaN ) )
   	uiwait( msgbox( 'Lab calibration is not loaded.' ) ); return;
end
selection_type = questdlg( 'Select data type' , 'Select data type' , 'Single video' , 'Folder of videos' , 'Folder of images' ,  'Single video' );
if( isequaln( selection_type , 'Single video' ) )
	[ filename , pathname ] = uigetfile( '*.avi' , 'Select test video' ) ;
elseif( isequaln( selection_type , 'Folder of videos' ) || isequaln( selection_type , 'Folder of images' ) )
	[ pathname ] = uigetdir( 'Select folder of images/videos for test' ) ; filename = '';
else
	uiwait( msgbox( 'Data type was not selected.' ) ); return;
end
if( pathname == 0 )
	uiwait( msgbox( 'Data for calibration was not selected.' ) ); return;
else
    selection_test = questdlg( 'Select test type' , 'Select test type' , 'Only Lab mask' , 'Lab mask and Post-Processing' , 'Only Lab mask' );
    if( isequaln(selection_test, 'Only Lab mask' ) || isequaln(selection_test, 'Lab mask and Post-Processing' ) )
        test_procedure( selection_type , selection_test , pathname , filename );
    else
        uiwait( msgbox( 'Test type was not selected.' ) ); return;
    end
end

function compare_1_lab( ~ , ~ )

global fixed_mask
global calibration
global cluster_fit
global current_path
global vent_point

calibration_set = struct; counter_cal = 0;
if( ~isequaln( calibration , NaN ) && ~isequaln( cluster_fit , NaN ) && ~isequaln( fixed_mask , NaN ) && ~isequaln( vent_point , NaN ) )
	button = questdlg( 'Consider loaded calibration?' , 'Consider loaded calibration?' , 'Yes' , 'No' , 'Yes' );
    if strcmpi( button , 'Yes' )
        calibration_set.( strcat( 'cal' , '1' ) ).calibration = calibration;
        calibration_set.( strcat( 'cal' , '1' ) ).fixed_mask = fixed_mask;
        calibration_set.( strcat( 'cal' , '1' ) ).cluster_fit = cluster_fit;
        calibration_set.( strcat( 'cal' , '1' ) ).vent_point = vent_point;
        calibration_set.( strcat( 'cal' , '1' ) ).name = 'Current calibration';
        counter_cal = counter_cal + 1;
    elseif ~strcmpi( button , 'No' )
        return;
    end
end
[ filename , pathname ] = uigetfile( '*.mat' , 'Select Lab calibration files' , fullfile( current_path , fullfile( 'CalibrationFiles' , 'LabMask' ) ) , 'MultiSelect' , 'on' );
message = '';
if( iscell( filename ) )
    for i = 1:length( filename )
        calibration_file = load( fullfile( pathname , filename{i} ) );
        cluster_new = calibration_file.cluster_fit;
        fixed_mask_new = calibration_file.fixed_mask;
        vent_point_new = calibration_file.vent_point;
        calibration_new = calibration_file.calibration;
        [ calibration_set , counter_cal , message ] = add_calibration( calibration_set , counter_cal , message , filename{i} , fixed_mask_new , calibration_new , cluster_new , vent_point_new );
    end
elseif( ischar( filename ) )
    calibration_file = load( fullfile( pathname , filename ) );
	cluster_new = calibration_file.cluster_fit;
	fixed_mask_new = calibration_file.fixed_mask;
	vent_point_new = calibration_file.vent_point;
	calibration_new = calibration_file.calibration;
	[ calibration_set , counter_cal , message ] = add_calibration( calibration_set , counter_cal , message , filename , fixed_mask_new , calibration_new , cluster_new , vent_point_new );
end
if( ~isequaln( message , '' ) )
	uiwait( msgbox( sprintf( message ) ) );
end
if( counter_cal == 0 )
    uiwait( msgbox( 'Calibrations for comparison were not selected.' ) ); return;
end
selection_type = questdlg( 'Select data type for comparison' , 'Select data type' , 'Single video' , 'Folder of images' ,  'Single video' );
if( isequaln( selection_type , 'Single video' ) )
    [ filename , pathname ] = uigetfile( '*.avi' , 'Select video for comparison' ) ;
elseif( isequaln( selection_type , 'Folder of images' ) )
	[ pathname ] = uigetdir( 'Select folder of images for comparison' ) ; filename = '';
else
    return;
end
if( pathname == 0 )
    uiwait( msgbox( 'Video/images for comparison was/were not selected.' ) ); return;
elseif( isequaln( selection_type , 'Folder of images' ) ) 
    names = dir( pathname );
    for i = 1 : length( names )
        if( strcmp( names( i ).name( max( 1 , end - 3 ) : end ) , '.jpg' ) )
            files_names{ end + 1 } = names( i ).name;
        end
    end
end
step_frame = max( 1 , floor( str2double( cell2mat( inputdlg( {'Frame step:'} , 'Frame Step' , [ 1 75 ] , { '1' } ) ) ) ) );
if( step_frame  < 1 )
    uiwait( msgbox( 'Frame step must be equal or higher than 1.' ) ); return;
else
    if( isequaln( selection_type , 'Single video' ) )
        video = VideoReader( fullfile( pathname , filename ) );
        ind_frame = 1 : step_frame : video.Duration * video.FrameRate;
    else
        ind_frame = 1 : step_frame : length( files_names );
    end
    threshold_p = nan( counter_cal , length( ind_frame ) );
    threshold_n = nan( counter_cal , length( ind_frame ) );
    for i  = 1 : length( ind_frame )
        if( isequaln( selection_type , 'Single video' ) )
            frame = read( video , ind_frame( i ) );
        else
            frame = imread( fullfile( pathname , files_names{i} ) );
        end
        frame_lab = rgb2lab( frame );
        frame_l = squeeze( frame_lab( : , : , 1 ) );
        frame_a = squeeze( frame_lab( : , : , 2 ) );
        frame_b = squeeze( frame_lab( : , : , 3 ) );
        frame_red = squeeze( frame( : , : , 1 ) );
        frame_green = squeeze( frame( : , : , 2 ) );
        frame_blue = squeeze( frame( : , : , 3 ) );
        for j = 1 : counter_cal
            c_calibration = calibration_set.( strcat( 'cal' , num2str( j ) ) ).calibration;
            c_fixed_mask = calibration_set.( strcat( 'cal' , num2str( j ) ) ).fixed_mask;
            c_cluster_fit = calibration_set.( strcat( 'cal' , num2str( j ) ) ).cluster_fit;
            mean_frame_l = mean( frame_l( c_fixed_mask == 1 ) );
            mean_frame_a = mean( frame_a( c_fixed_mask == 1 ) );
            mean_frame_b = mean( frame_b( c_fixed_mask == 1 ) );
            mean_frame_red = mean( frame_red( c_fixed_mask == 1 ) );
            mean_frame_green = mean( frame_green( c_fixed_mask == 1 ) );
            mean_frame_blue = mean( frame_blue( c_fixed_mask == 1 ) );
            parameters_image = [ mean_frame_l , mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue ];
            [ threshold_p( j, i ), threshold_n( j, i ) ] = get_threshold( parameters_image , c_calibration , c_cluster_fit );
        end
        disp( ['- Frame ' num2str( i ) '/' num2str( length( ind_frame ) ) '.' ] );
    end
end
all_names = cell( counter_cal , 1 );
for j = 1 : counter_cal
	c_name = calibration_set.( strcat( 'cal' , num2str( j ) ) ).name;
    all_names{ j } = c_name;
end
max_val = -1e10;  min_val = 1e10;
figure; subplot( 1 , 3 , 1 );
for j = 1 : counter_cal
    plot( ind_frame , threshold_p( j , : ) , '-' , 'MarkerSize' , 10 , 'LineWidth' , 1 ); hold on;
    max_val = max( max_val , max( threshold_p( j , : ) ) ); min_val = min( min_val , min( threshold_p( j , : ) ) );
end
legend( all_names , 'LineWidth' , 1 );
subplot( 1 , 3 , 2 );
for j = 1 : counter_cal
    plot( ind_frame , threshold_n( j , : ) , '-' , 'MarkerSize' , 10 , 'LineWidth' , 1 ); hold on;
    max_val = max( max_val , max( threshold_n( j , : ) ) ); min_val = min( min_val , min( threshold_n( j , : ) ) );
end    
legend( all_names , 'LineWidth' , 1 );
subplot( 1 , 3 , 3 );
for j = 1 : counter_cal
    plot( ind_frame , min( threshold_p( j , : ) , threshold_n( j , : ) ), '-' , 'MarkerSize' , 10 , 'LineWidth' , 1 ); hold on;
end    
legend( all_names , 'LineWidth' , 1 );
subplot( 1 , 3 , 1 ); ylim( [ round( min_val - 5 ) , round( max_val + 5 ) ] ); xlabel( 'Frame' ); ylabel( 'Lab threshold' ); title( 'Clustering/Polynomial fit' );
subplot( 1 , 3 , 2 ); ylim( [ round( min_val - 5 ) , round( max_val + 5 ) ] ); xlabel( 'Frame' ); ylabel( 'Lab threshold' ); title( 'Nearest value' );
subplot( 1 , 3 , 3 ); ylim( [ round( min_val - 5 ) , round( max_val + 5 ) ] ); xlabel( 'Frame' ); ylabel( 'Lab threshold' ); title( 'More conservative value' );
if( any( all( isnan( threshold_p' ) ) ) ||  any( all( isnan( threshold_n' ) ) ) )
    uiwait( msgbox( sprintf( [ 'The images are not processable (Calibration: ' c_name ' ).' ] ) ) );
end

function compare_2_lab( ~ , ~ )

global fixed_mask
global calibration
global cluster_fit
global current_path
global vent_point

calibration_set = struct; counter_cal = 0;
if( ~isequaln( calibration , NaN ) && ~isequaln( cluster_fit , NaN ) && ~isequaln( fixed_mask , NaN ) && ~isequaln( vent_point , NaN ) )
	button = questdlg( 'Consider loaded calibration?' , 'Consider loaded calibration?' , 'Yes' , 'No' , 'Yes' );
    if strcmpi( button, 'Yes' )
        calibration_set.( strcat( 'cal' , '1' ) ).calibration = calibration;
        calibration_set.( strcat( 'cal' , '1' ) ).fixed_mask = fixed_mask;
        calibration_set.( strcat( 'cal' , '1' ) ).cluster_fit = cluster_fit;
        calibration_set.( strcat( 'cal' , '1' ) ).vent_point = vent_point;
        calibration_set.( strcat( 'cal' , '1' ) ).name = 'Current calibration';
        counter_cal = counter_cal + 1;
    end
end
[ filename , pathname ] = uigetfile( '*.mat' , 'Select Lab calibration files' , fullfile( current_path , fullfile( 'CalibrationFiles' , 'LabMask' ) ) , 'MultiSelect' , 'on' );
message = '';
if( iscell( filename ) )
    for i = 1:length( filename )
        calibration_file = load( fullfile( pathname , filename{ i } ) );
        cluster_new = calibration_file.cluster_fit;
        fixed_mask_new = calibration_file.fixed_mask;
        vent_point_new = calibration_file.vent_point;
        calibration_new = calibration_file.calibration;
        [ calibration_set , counter_cal , message ] = add_calibration( calibration_set , counter_cal , message , filename{i} , fixed_mask_new , calibration_new , cluster_new , vent_point_new );
    end
elseif( ischar( filename ) )
    calibration_file = load( fullfile( pathname , filename ) );
	cluster_new = calibration_file.cluster_fit;
	fixed_mask_new = calibration_file.fixed_mask;
	calibration_new = calibration_file.calibration;
	vent_point_new = calibration_file.vent_point;
	[ calibration_set , counter_cal , message ] = add_calibration( calibration_set , counter_cal , message , filename , fixed_mask_new , calibration_new , cluster_new , vent_point_new );
end
if( ~isequaln( message , '' ) )
	uiwait( msgbox( sprintf( message ) ) );
end
if( counter_cal == 0 )
    uiwait( msgbox( 'Calibrations for comparison were not selected.' ) ); return;
end
selection_type = questdlg( 'Select data type for comparison' , 'Select data type for comparison' , 'Single video' , 'Folder of videos' , 'Folder of images' ,  'Single video' );
if( isequaln( selection_type , 'Single video' ) )
	[ filename , pathname ] = uigetfile( '*.avi' , 'Select video for comparison' ) ;
elseif( isequaln( selection_type , 'Folder of videos' ) || isequaln( selection_type , 'Folder of images' ) )
	[ pathname ] = uigetdir( 'Select folder of images/videos for comparison' ) ; filename = '';
else
	uiwait( msgbox( 'Data type was not selected.' ) ); return;
end
if( pathname == 0 )
	uiwait( msgbox( 'Data for comparison was not selected.' ) ); return;
else
    selection_test = questdlg( 'Select comparison type' , 'Select comparison type' , 'Only Lab mask' , 'Lab mask and Post-Processing' , 'Only Lab mask' );
    if( isequaln(selection_test, 'Only Lab mask' ) || isequaln(selection_test, 'Lab mask and Post-Processing' ) )
        comparison_procedure_2( selection_type , selection_test , calibration_set , counter_cal , pathname , filename );
    else
        uiwait( msgbox( 'Comparison type was not selected.' ) ); return;
    end
end

function load_default_param( ~ , ~ )

global current_path
global max_number_clusters
global mean_size_clusters
global gradient_threshold
global threshold_lobes_factor

[ filename , pathname ] = uigetfile( '*.mat' , 'Select mask' , fullfile( current_path , 'CalibrationFiles' , 'DefaultParameters' ) ) ;
if( filename == 0 )
    uiwait( msgbox( 'Invariant parameters were not loaded.' ) ); return;
end
default_param = load( fullfile( pathname , filename ) );
max_number_clusters = default_param.max_number_clusters;
mean_size_clusters = default_param.mean_size_clusters;
gradient_threshold = default_param.gradient_threshold;
threshold_lobes_factor = default_param.threshold_lobes_factor;
uiwait( msgbox( sprintf( 'Invariant parameters were loaded successfully.' ) ) );

function default_param( ~ , ~ )

global current_path
global max_number_clusters
global mean_size_clusters
global gradient_threshold
global threshold_lobes_factor

prompt = { 'Maximum number of clusters (Lab Calibration):' , 'Minimum number of frames in each cluster (Lab Calibration):' , 'Gradient threshold for plume detection (gray scale):' , 'Threshold for lobes detection:' };
dlgtitle = 'Invariant model parameters';
dims = [ 1 80 ];
definput = { num2str( max_number_clusters ) , num2str( mean_size_clusters ), num2str( gradient_threshold ), num2str( threshold_lobes_factor ) };
answer = inputdlg( prompt , dlgtitle , dims , definput );
if( isempty( answer ) )
    return;
end
for i = 1 : length( answer )
    if( isempty( answer{ i } ) )
        uiwait( msgbox( 'Error in input values. Data was not saved.' ) ); return;
    end
end
max_number_clusters = str2double( answer{ 1 } );
mean_size_clusters = str2double( answer{ 2 } );
gradient_threshold = str2double( answer{ 3 } );
threshold_lobes_factor = str2double( answer{ 4 } );
selection_type = questdlg( 'Parameters modified succesfully. Do you want to save this data?' , 'Save?' , 'Yes' , 'No' , 'Yes' );
if( isequaln( selection_type , 'Yes' ) )
    param_name = inputdlg( 'Enter invariant parameters file name:' , 'File name' , [ 1 100] , {'Default_InvariantParameters' , 'hsv'} );
    if( isempty( param_name ) )
        uiwait( msgbox( 'File with invariant parameters was not created.' ) ); return;
    end
    save( fullfile( current_path , 'CalibrationFiles' , 'DefaultParameters' , param_name{ 1 } ) , 'max_number_clusters' , 'mean_size_clusters' , 'gradient_threshold' , 'threshold_lobes_factor' );
    uiwait( msgbox ( 'File saved succesfully.' ) );
end

function analysis_video( ~ , ~ )

global fixed_mask
global calibration
global cluster_fit
global vent_point
global pixel_height

if( isequaln( calibration , NaN ) || isequaln( cluster_fit , NaN ) || isequaln( fixed_mask , NaN ) || isequaln( vent_point , NaN ) )
   	uiwait( msgbox( 'Lab calibration is not loaded.' ) );
    return
end
if( isequaln( pixel_height , NaN ) )
   	uiwait( msgbox( 'Pixel-height conversion matrix is absent.' ) );
    return
end
[ filename , pathname ] = uigetfile( '*.avi' , 'Select video for developing analysis.' ) ;
if( pathname == 0 )
    uiwait( msgbox( 'Video for analysis was not selected.' ) ); return;
else
    video_analysis_procedure( pathname , filename );
end

function analysis_images( ~ , ~ )

global fixed_mask
global calibration
global cluster_fit
global vent_point
global pixel_height

if( isequaln( calibration , NaN ) || isequaln( cluster_fit , NaN ) || isequaln( fixed_mask , NaN ) || isequaln( vent_point , NaN ) )
   	uiwait( msgbox( 'Lab calibration is not loaded.' ) ); return;
end
if( isequaln( pixel_height , NaN ) )
   	uiwait( msgbox( 'Pixel-height conversion matrix is absent.' ) );
    return
end
[ pathname ] = uigetdir( 'Select folder of images for developing analysis.' ) ;
if( pathname == 0 )
    uiwait( msgbox( 'Folder for analysis was not selected.' ) ); return;
else
    images_analysis_procedure( pathname );
end

function analysis_manually( ~ , ~ )

global pixel_height
global vent_point

if( isequaln( vent_point , NaN ) )
   	uiwait( msgbox( 'Vent point is not loaded.' ) ); return;
end
if( isequaln( pixel_height , NaN ) )
   	uiwait( msgbox( 'Pixel-height conversion matrix is absent.' ) );
    return
end
button = questdlg( 'Type of analysis' , 'Type of analysis' , 'Single video' , 'Folder of images' , 'Single video' );
if( ~strcmpi( button , 'Folder of images' ) && ~strcmpi( button , 'Single video' ) )
    return;
end

if( strcmpi( button , 'Folder of images' ) )
    [ pathname ] = uigetdir( 'Select folder of images for developing analysis.' ) ;
    if( pathname == 0 )
        uiwait( msgbox( 'Folder for analysis was not selected.' ) ); return;
    else
       images_analysis_manually( pathname );
    end
else
    [ filename , pathname ] = uigetfile( '*.avi' , 'Select video for developing analysis.' ) ;
    if( pathname == 0 )
        uiwait( msgbox( 'Video for analysis was not selected.' ) ); return;
    else
        video_analysis_manually( pathname , filename );
    end
end

function plot_results( ~ , ~ )

global current_path

[ filename , pathname ] = uigetfile( '*.mat' , 'Select results file' , fullfile( current_path , fullfile( 'Results' ) ) , 'MultiSelect' , 'off' );
if( pathname == 0 )
    uiwait( msgbox( 'Results file was not selected.' ) );
else
    data_file = load( fullfile( pathname , filename ) );
    procedure_plot( data_file.data_t , data_file.data_min_pix , data_file.max_height , data_file.vent_height , data_file.frame_step , data_file.total_frames , data_file.type_plume , 0 , 0 );
end

function plot_compare( ~ , ~ )

global current_path

[ filename , pathname ] = uigetfile( '*.mat' , 'Select results file' , fullfile( current_path , fullfile( 'Results' ) ) , 'MultiSelect' , 'on' );
if( ~iscell( filename ) )
    uiwait( msgbox( 'Please select at least two results files.' ) ); return;
else
    vent_heights = zeros( length( filename ) , 1 ); 
    for i = 1 : length( filename )
        data_file = load( fullfile( pathname , filename{i} ) );
        vent_heights( i , 1 ) = data_file.vent_height; 
    end
    if( min( sum( isnan( vent_heights ) ), sum( ~isnan( vent_heights ) ) ) > 0 )
        uiwait( msgbox( 'Dataset includes results with and without information in height.' ) ); return;
    end
	figure_comparison = figure; 
	set( figure_comparison , 'units' , 'normalized' , 'outerposition' ,[ 0 0 1 1 ] );
	lim1 = NaN; lim2 = NaN; lim3 = NaN; lim4 = NaN;
    for i = 1 : length( filename )
        data_file = load( fullfile( pathname , filename{i} ) );
        [lim1 , lim2 , lim3 , lim4] = procedure_plot_comparison( data_file , i , length( filename ) , lim1 , lim2 , lim3 , lim4 , filename );
    end 
end

function delete_figure( ~ , ~ )
if exist( 'tmp.mat' , 'file' )
    clear tmp
    delete( 'tmp.mat' );
end

function return_message = verify_consistency( message , str_type , old_data )

global fixed_mask
global calibration
global cluster_fit
global image_reference
global pixel_height
global vent_point

if( isequaln( str_type , "calibration" ) )
    if( ~isequaln( size( fixed_mask ), size(squeeze( image_reference( :,:,1) ) ) ) && ~isequaln( image_reference , NaN ) )
        image_reference = NaN; message = strcat( message , '\nBecause the size of the fixed mask and the size of the reference image are different, the current reference image was removed.' );
    end
    if( ~isequaln( size( fixed_mask ), size( pixel_height ) ) && ~isequaln( pixel_height , NaN )  )
        pixel_height = NaN; message = strcat( message , '\nBecause the size of the fixed mask and the size of the pixel-height conversion matrix are different, the current pixel-height conversion matrix was removed.' );
    end
elseif( isequaln( str_type , "fixed_mask" ) )
    if( ~isequaln( old_data , fixed_mask ) && ~isequaln( calibration , NaN ) )
        calibration = NaN; cluster_fit = NaN; vent_point = NaN; message = strcat( message , '\nBecause this fixed mask and the fixed mask associated with the current Lab calibration are different, the current Lab calibration was removed.' );
    end
    if( ~isequaln( size( fixed_mask ), size( squeeze( image_reference( :,:,1) ) ) ) && ~isequaln( image_reference , NaN ) )
        image_reference = NaN; message = strcat( message , '\nBecause the size of this fixed mask and the size of the reference image are different, the current reference image was removed.' );
    end
    if( ~isequaln( size( fixed_mask ), size( pixel_height ) ) && ~isequaln( pixel_height , NaN )  )
        pixel_height = NaN; message = strcat( message , '\nBecause the size of this fixed mask and the size of the pixel-height conversion matrix are different, the current pixel-height conversion matrix was removed.' );
    end
    if( ~isequaln( vent_point , NaN ) )
        if( vent_point( 2 ) > length( fixed_mask( : , 1 ) ) || vent_point( 1 ) > length( fixed_mask( 1 , : ) ) )
            vent_point = NaN; message = strcat( message , '\nBecause vent position is not contained in the fixed mask, vent position was removed.' );
        end
    end
elseif( isequaln( str_type , "vent_point" ) )
    if( ~isequaln( old_data , vent_point ) && ~isequaln( calibration , NaN ) )
        calibration = NaN; cluster_fit = NaN; fixed_mask = NaN; message = strcat( message , '\nBecause this vent point and the vent point associated with the current Lab calibration are different, the current Lab calibration was removed.' );
    end
	if( ( vent_point( 2 ) > length( fixed_mask( : , 1 ) ) || vent_point( 1 ) > length( fixed_mask( 1 , : ) ) ) && ~isequaln( fixed_mask , NaN ) )
        fixed_mask = NaN; message = strcat( message , '\nBecause vent position is not contained in the fixed mask, the current fixed mask was removed.' );
	end
	if( ( vent_point( 2 ) > length( squeeze( image_reference( :,1 ,1) ) ) || vent_point( 1 ) > length( squeeze( image_reference( 1 ,:,1) ) ) ) && ~isequaln( image_reference , NaN ) )
        image_reference = NaN; message = strcat( message , '\nBecause vent position is not contained in the reference image, the current reference image was removed.' );
	end
	if( ( vent_point( 2 ) > length( pixel_height( : , 1 ) ) || vent_point( 1 ) > length( pixel_height( 1 , : ) ) ) && ~isequaln( pixel_height , NaN ) )
        pixel_height = NaN; message = strcat( message , '\nBecause vent position is not contained in the pixel-height conversion matrix, the current pixel-height conversion matrix was removed.' );
	end
elseif( isequaln( str_type , "pixel_height" ) )
	if( ~isequaln( size( fixed_mask ), size( pixel_height ) ) && ~isequaln( fixed_mask , NaN ) )
        fixed_mask = NaN; message = strcat( message , '\nBecause the size of the fixed mask and the size of the pixel-height conversion matrix are different, the current fixed mask was removed.' );
        if( ~isequaln( calibration , NaN ) )
            calibration = NaN; cluster_fit = NaN; vent_point = NaN; message = strcat( message , '\nBecause the calibration files are associated with the removed fixed mask, the current calibration was removed.' );
        end
	end
    if( ~isequaln( size( pixel_height ), size( squeeze( image_reference( :,:,1) ) ) ) && ~isequaln( image_reference , NaN ) )
        image_reference = NaN; message = strcat( message , '\nBecause the size of the pixel-height conversion matrix and the size of the reference image are different, the current reference image was removed.' );
    end
    if( ~isequaln( vent_point , NaN ) )
        if( vent_point( 2 ) > length( pixel_height( : , 1 ) ) || vent_point( 1 ) > length( pixel_height( 1 , : ) ) )
            vent_point = NaN; message = strcat( message , '\nBecause vent position is not contained in the pixel-height conversion matrix, the current vent position was removed.' );
        end
    end
elseif( isequaln( str_type , "image_reference" ) )
    if( ~isequaln( size( fixed_mask ), size( squeeze( image_reference( :,:,1) ) ) ) && ~isequaln( fixed_mask , NaN ) )
        fixed_mask = NaN; message = strcat( message , '\nBecause the size of the fixed mask and the size of the loaded reference image are different, the current fixed mask was removed.' );
        if( ~isequaln( calibration , NaN ) )
            calibration = NaN; cluster_fit = NaN; vent_point = NaN; message = strcat( message , '\nBecause the calibration files are associated with the removed fixed mask, the current calibration was removed.' );
        end
    end
    if( ~isequaln( vent_point , NaN ) )
        if( vent_point( 2 ) > length( squeeze( image_reference( : , 1 , 1 ) ) ) || vent_point( 1 ) > length( squeeze( image_reference( 1 , : , 1 ) ) ) )
            vent_point = NaN; message = strcat( message , '\nBecause vent position is not contained in the reference image, the current vent position was removed.' );
        end
    end
    if( ~isequaln( size( pixel_height ), size( squeeze( image_reference( :,:,1) ) ) ) && ~isequaln( pixel_height , NaN ) )
        pixel_height = NaN; message = strcat( message , '\nBecause the size of the pixel-height conversion matrix and the size of the reference image are different, the current pixel-height conversion was removed.' );
    end
end
return_message = message;

function displace_vent

global fixed_mask
global vent_point

if( isequaln( vent_point , NaN ) || isequaln( fixed_mask , NaN ) )
    return
end  
message_boolean = 0;
for i = vent_point( 2 ) : -1 : 1
    if( fixed_mask( i , vent_point( 1 ) ) == 1)
        vent_point( 2 ) = i; break
    elseif( message_boolean == 0 )
        message_boolean = 1;
        uiwait( msgbox( 'Vent was displaced vertically because it is in the masked zone.' ) );
    end
end

function return_data = ask_image_reference

global image_reference

[ filename , pathname ] = uigetfile( { '*.avi' ; '*.jpg' }, 'Select reference video/image' );
if( filename == 0 )
    return_data = 0; return;
elseif( isequaln( filename( end - 2 : end ), 'jpg' ) )
    image_reference = imread( fullfile( pathname , filename ) );
else
    video_reference = VideoReader( fullfile( pathname , filename ) );
    image_reference = readFrame( video_reference );
end
message = '';
message = verify_consistency( message , "image_reference" , 0 );
if( ~isequaln( message , '' ) )
    uiwait( msgbox( sprintf( message ) ) );
end
return_data = 1;

function return_data = calibration_procedure( selection_type , pathname , filename , size_previous )

global calibration
global fixed_mask
global shift_max_lab_mask
global shift_number
global shift_raw

return_data = 1;
list_letters = { 'A' , 'B' , 'C' , 'D' , 'E' , 'F' , 'G' , 'H' , 'I' , 'Cloudy/Night (Not recognizable plume)' , 'Indifferent' , 'Finish Calibration' };
list_letters_zoom = { 'A' , 'B' , 'C' , 'D' , 'E' , 'F' , 'G' , 'H' ,  'I' };
frame = NaN;
if( ~isequaln( selection_type , 'Single video' ) )
    names = dir( pathname );
    files_names = {};
    if( isequaln( selection_type , 'Folder of videos' ) )
        format_file = '.avi';
    else
        format_file = '.jpg';
    end
    for i = 1:length( names )
        if( strcmp( names( i ).name( max( 1 , end - 3 ) : end ) , format_file ) )
            files_names{ end + 1 } = names( i ).name;
        end
    end
end
try
    calibration_sample = questdlg( 'Calibration type' , 'Calibration type' , 'Optimized sampling' , 'Random sampling' , 'Optimized sampling' );
    while true
        if( isequaln( selection_type , 'Single video' ) )
            if( isnan( frame ) )
                video = VideoReader( fullfile( pathname , filename ) );
            end
            if( isequaln( calibration_sample , 'Optimized sampling' ) )
                if( isnan( frame ) )
                    ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
                    distances = abs( ( 1 : video.Duration * video.FrameRate ) - ind_frame );
                else
                    ind_frame = randsample( ( 1 : video.Duration * video.FrameRate ) , 1 , 'true' , distances );
                    distances = min( distances, abs( ( 1 : video.Duration * video.FrameRate ) - ind_frame ) );
                end
                if( max( distances ) == 0 )
                    distances = distances + video.Duration * video.FrameRate;
                end
            elseif( isequaln( calibration_sample , 'Random sampling' ) )
                ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
            else
                return_data = 0; return;            
            end
            frame = read( video, ind_frame );
        elseif( isequaln( selection_type , 'Folder of videos' ) )
            if( isequaln( calibration_sample , 'Optimized sampling' ) )
                if( isnan( frame ) )
                    ind_video = 1 + round( rand()* ( length( files_names ) - 1 ) );
                    distances = abs( ( 1 : length( files_names ) ) - ind_video );
                    distances_L2 = struct;
                    for ind_aux = 1 : length( files_names )
                        distances_L2.( strcat( 'V' , num2str( ind_aux ) ) ) = NaN;
                    end
                else
                    ind_video = randsample( ( 1 : length( files_names ) ) , 1 , 'true' , distances );
                    distances = min( distances , abs( ( 1 : length( files_names ) ) - ind_video ) );
                end
                if( max( distances ) == 0 )
                    distances = distances + length( files_names );
                end
                video = VideoReader( fullfile , files_names{ ind_video } );
                if( isnan( distances_L2.( strcat( 'V' , num2str( ind_video ) ) ) ) )
                    ind_frame = 1 + round( pathname ( rand()* ( video.Duration * video.FrameRate - 1 ) ) );
                    distances_L2.( strcat( 'V' , num2str( ind_video ) ) ) = abs( ( 1 : video.Duration * video.FrameRate ) - ind_frame );
                else
                    ind_frame = randsample( ( 1 : video.Duration * video.FrameRate ) , 1 , 'true' , distances_L2.( strcat( 'V' , num2str( ind_video ) ) ) );
                    distances_L2.( strcat( 'V' , num2str( ind_video ) ) ) = min( distances_L2.( strcat( 'V' , num2str( ind_video ) ) ), abs( ( 1 : video.Duration * video.FrameRate ) - ind_frame ) );
                end
                if( max( distances_L2.( strcat( 'V' , num2str( ind_video ) ) ) ) == 0 )
                    distances_L2.( strcat( 'V' , num2str( ind_video ) ) ) = distances_L2.( strcat( 'V' , num2str( ind_video ) ) ) + video.Duration * video.FrameRate;
                end
            elseif( isequaln( calibration_sample , 'Random sampling' ) )
                ind_video = 1 + round( rand() * ( length( files_names ) - 1 ) );
                video = VideoReader( fullfile( pathname , files_names{ ind_video } ) );
                ind_frame = 1 + round( rand() * ( video.Duration * video.FrameRate - 1 ) );
            else
                return_data = 0; return;
            end
            frame = read( video, ind_frame );
        elseif( isequaln( selection_type , 'Folder of images' ) )
            if( isequaln( calibration_sample , 'Optimized sampling' ) )
                if( isnan( frame ) )
                    ind_frame = 1 + round( rand() * ( length( files_names ) - 1 ) );
                    distances = abs( ( 1 : length( files_names ) ) - ind_frame );
                else
                    ind_frame = randsample( ( 1 : length( files_names ) ) , 1 , 'true' , distances );
                    distances = min( distances , abs( ( 1 : length( files_names ) ) - ind_frame ) );
                end
                if( max( distances ) == 0 )
                    distances = distances + length( files_names );
                end
            elseif( isequaln( calibration_sample , 'Random sampling' ) )
                ind_frame = 1 + round( rand()* ( length( files_names ) - 1 ) );
            else
                return_data = 0; return;
            end 
            frame = imread( fullfile( pathname , files_names{ ind_frame } ) );
        end
        if( ~isequaln( squeeze( size( frame( : , : , 1 ) ) ) , size( fixed_mask ) ) )
            return_data = -1; return;
        end
        [ frame_gray , ~ , frame_b , mean_frame_l , mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue , dark_mask ] = process_frame( frame );
        shift = linspace(  - shift_max_lab_mask , shift_max_lab_mask , shift_number );
        step_shift = 2 .* shift_max_lab_mask ./ ( shift_number - 1 );
        shift = shift + ( rand( shift_number , 1 ) .* step_shift - step_shift ./ 2 )';
        figure_calibration = figure( 'NumberTitle' , 'off' , 'Name' , ['Iteration: ' num2str( size_previous + 1 ) ] );
        for j = 1 : shift_number
            subplot( shift_raw , ceil( shift_number / shift_raw ) , j );
            soglia_b = mean_frame_b + shift( j );
            frame_c = frame_b;
            if( soglia_b < 1 )
                frame_c( frame_c >= soglia_b ) = 1;
                frame_c( frame_c < soglia_b ) = 0;
            else
                frame_c( frame_c < soglia_b ) = 0;
                frame_c( frame_c >= soglia_b ) = 1;
            end
            imshow( frame ); hold on;
            h = imshow( max( frame_c .* fixed_mask , dark_mask ) );
            set( h , 'AlphaData' , 0.2 ); colormap gray; title( list_letters{j} );
        end
        set( figure_calibration , 'units' , 'normalized' , 'outerposition' , [ 0 0 1 1 ] );
        if( max( max( mean_frame_red , mean_frame_blue ) , mean_frame_green ) > 50.0 )
            selection = listdlg( 'PromptString' , [ { 'Select best conservative mask (i.e., not masking the plume).' } { '' } { '' }] , 'ListSize' , [ 300 300 ] , 'ListString' , list_letters , 'SelectionMode' , 'single' );
        else
            selection = 10;
        end
        if( ~isempty( selection ) && selection < 12 )
            if( selection == 11 )
                close( figure_calibration )
            elseif( selection == 10 )
                size_previous = size_previous + 1;
                calibration( size_previous , 1 : end - 2 ) = [ mean_frame_l , mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue ];
                calibration( size_previous , end - 1 ) = NaN;
                close( figure_calibration )
            elseif( selection == 9 )
                size_previous = size_previous + 1;
                calibration( size_previous , 1 : end - 2 ) = [ mean_frame_l , mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue ];
                calibration( size_previous , end - 1 ) = shift( selection );
                close( figure_calibration )
            else
                close( figure_calibration )
                shift = linspace( shift( selection ) , shift( selection + 1 ) , shift_number );
                step_shift = ( shift( selection + 1 ) - shift( selection ) ) ./ ( shift_number - 1 );
                shift( 2 : end ) = shift( 2 : end ) + ( rand( shift_number - 1 , 1 ) .* step_shift - step_shift ./ 2 )';
                figure_calibration = figure( 'NumberTitle' , 'off' , 'Name' , ['Iteration: ' num2str( size_previous + 1 ) ' (Zoom)'] );
                for j = 1 : shift_number
                    subplot( shift_raw , ceil( shift_number / shift_raw ) , j );
                    soglia_b = mean_frame_b + shift( j );
                    frame_c = frame_b;
                    if( soglia_b < 1 )
                        frame_c( frame_c >= soglia_b ) = 1;
                        frame_c( frame_c < soglia_b ) = 0;
                    else
                        frame_c( frame_c < soglia_b ) = 0;
                        frame_c(  frame_c >= soglia_b  ) = 1;
                    end
                    imshow( frame ); hold on;
                    h = imshow( max( frame_c .* fixed_mask, dark_mask ) );
                    set( h , 'AlphaData' , 0.2 ); colormap gray; title( list_letters{j} );
                end
                set( figure_calibration , 'units' , 'normalized' , 'outerposition' , [ 0 0 1 1 ] );
                selection = listdlg( 'PromptString' , [ {'Select best conservative mask (i.e., not masking the plume)'} {''} {''} ] , 'ListSize' , [300 300] , 'ListString' , list_letters_zoom , 'SelectionMode' , 'single' );
                if( ~isempty( selection ) )
                    size_previous = size_previous + 1;
                    calibration( size_previous , 1 : end - 2 ) = [ mean_frame_l , mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue ];
                    calibration( size_previous , end - 1 ) = shift( selection );
                    close( figure_calibration )
                else
                    close( figure_calibration )
                end
            end
        else
            close( figure_calibration )
            return;
        end
    end
catch
    return_data = 0; return;
end

function compute_calibration( name_file )

global current_path
global calibration
global cluster_fit
global max_number_clusters
global mean_size_clusters
global fixed_mask
global vent_point

Z = linkage( calibration( : , 1 : 6 ) , 'weighted' );
c = cluster( Z , 'maxclust' , floor( max( 1 , min( max_number_clusters, length( calibration( : , 1 ) ) ./ mean_size_clusters ) ) ) );
calibration( : , 8 ) = c;
cluster_fit = zeros( max( c ) , 13 );
for i = 1 : max( c )
    current_c = find( c == i );
    if( sum( isnan( calibration( current_c , 7 ) ) ) > .2 * length( current_c( : , 1 ) ) )
        cluster_fit( i , : ) = NaN;
    elseif( length( current_c( : , 1 ) ) < 5 )
        cluster_fit( i , 13 ) = mean( calibration( current_c , 3 ) + calibration( current_c , 7 ) );
    elseif( length( current_c( : , 1 ) ) < 10 )
        F = [ calibration( current_c , 4 : 6 ) , ones( length( calibration( current_c , 1 ) ) , 1 ) ];
        cluster_fit( i , 10 : 13 ) = regress( calibration( current_c , 3 ) + calibration( current_c , 7 ) , F );
    elseif( length( current_c( : , 1 ) ) < 20 )
        F = [ calibration( current_c , 1 : 6 ) , ones( length( calibration( current_c , 1 ) ), 1 ) ];
        cluster_fit( i , 7 : 13 ) = regress( calibration( current_c , 3 ) + calibration( current_c , 7 ) , F );
    else
        F = [ calibration( current_c , 1 : 6 ) .* calibration( current_c , 1 : 6 ) , calibration( current_c , 1 : 6 ) , ones( length( calibration( current_c , 1 ) ) ,1 ) ];
        cluster_fit( i , 1 : 13 ) = regress( calibration( current_c , 3 ) + calibration( current_c , 7 ) , F );
    end
end
save( fullfile( current_path , 'CalibrationFiles' , 'LabMask' , name_file ) , 'calibration' , 'cluster_fit' , 'fixed_mask' , 'vent_point' );

function test_procedure( selection_type , selection_test , pathname , filename )

global calibration
global cluster_fit
global fixed_mask
global vent_point 

frame = NaN;
if( ~isequaln( selection_type , 'Single video' ) )
    names = dir( pathname ); files_names = {};
    if( isequaln( selection_type , 'Folder of videos' ) )
        format_file = '.avi';
    else
        format_file = '.jpg';
    end
    for i = 1 : length( names )
        if( strcmp( names( i ).name( max( 1 , end - 3 ): end ) , format_file ) )
            files_names{ end + 1 } = names( i ).name;
        end
    end
end
while true
	if( isequaln( selection_type , 'Single video' ) & isnan( frame ) )
        video = VideoReader( fullfile( pathname , filename ) );
        ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
        frame = read( video, ind_frame );
    elseif( isequaln( selection_type , 'Single video' ) )
        ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
        frame = read( video, ind_frame );
    elseif( isequaln( selection_type , 'Folder of videos' ) )
        i = 1 + round( rand()* ( length( files_names ) - 1 ) );
        video = VideoReader( fullfile( pathname , files_names{ i } ) );
        ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
        frame = read( video, ind_frame );
    elseif( isequaln( selection_type , 'Folder of images' ) )
        i = 1 + round( rand()* ( length( files_names ) - 1 ) );
        frame = imread( fullfile( pathname , files_names{ i } ) );
    end
    [ frame_gray , ~ , frame_b , mean_frame_l , mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue , dark_mask ] = process_frame( frame );
    frame_b_sup = frame_b;
    parameters_image = [ mean_frame_l , mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue ];
	[ soglia_b1 , soglia_b2 ] = get_threshold( parameters_image , calibration , cluster_fit );
    figure_test = figure;
	set( figure_test , 'units' , 'normalized' , 'outerposition' , [ 0 0 1 1 ] );
    if( isnan( soglia_b2 ) )
        imshow( frame );
        uiwait( msgbox( sprintf( 'This image is not processable.' ) ) );
    else
        if( soglia_b1 < 1 )
            frame_b( frame_b >= soglia_b1 ) = 1;
            frame_b( frame_b < soglia_b1 ) = 0;
    	else
            frame_b( frame_b < soglia_b1 ) = 0;
            frame_b( frame_b >= soglia_b1 ) = 1;
        end
        frame_b = max( frame_b .* fixed_mask , dark_mask );
        if( isequaln( selection_test , 'Lab mask and Post-Processing' ) )
            [ frame_b , ~ ] = postprocessing( frame_b , vent_point , fixed_mask );
        end
        subplot( 1 , 3 , 1 );
        imshow( frame ); hold on; h = imshow( frame_b );
        set( h , 'AlphaData' , 0.2 ); title( 'Clustering/Polynomial fit' );
        if( soglia_b1 < soglia_b2 )
            subplot( 1 , 3 , 3 );
            imshow( frame ); hold on; h = imshow( frame_b );
            set( h , 'AlphaData' , 0.2); title( 'Conservative fit' );
        end
    	frame_b = frame_b_sup;
    	if( soglia_b2 < 1 )
            frame_b( frame_b >= soglia_b2 ) = 1;
            frame_b( frame_b < soglia_b2 ) = 0;
        else
            frame_b( frame_b < soglia_b2 ) = 0;
            frame_b( frame_b >= soglia_b2 ) = 1;
        end
        frame_b = max( frame_b .* fixed_mask , dark_mask );
        if( isequaln( selection_test, 'Lab mask and Post-Processing' ) )
            [ frame_b , ~] = postprocessing( frame_b , vent_point , fixed_mask );
        end
        subplot( 1 , 3 , 2 );
        imshow( frame ); hold on; h = imshow( frame_b );
        set( h , 'AlphaData' , 0.2 ); title( 'Nearest value' );
        if( soglia_b1 >= soglia_b2 )
            subplot( 1 , 3 , 3 );
            imshow( frame ); hold on; h = imshow( frame_b );
            set( h , 'AlphaData' , 0.2 ); title( 'Conservative fit' );
        end
    end
    selection = questdlg( 'Continue?' , 'Continue?' , 'Yes' , 'No' , 'Yes' );
	close( figure_test );
	if( ~strcmpi( selection , 'Yes' ) )
        return
	end
end

function comparison_procedure_2( selection_type , selection_test , calibration_set, counter_cal, pathname , filename )

frame = NaN;
if( ~isequaln( selection_type , 'Single video' ) )
    names = dir( pathname ); files_names = {};
    if( isequaln( selection_type , 'Folder of videos' ) )
        format_file = '.avi';
    else
        format_file = '.jpg';
    end
    for i = 1:length( names )
        if( strcmp( names( i ).name( max( 1 , end - 3 ): end ), format_file ) )
            files_names{ end + 1 } = names( i ).name;
        end
    end
end
while true
	if( isequaln( selection_type , 'Single video' ) && any( isnan( frame( : ) ) ) )
        video = VideoReader( fullfile( pathname , filename ) );
        ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
        frame = read( video, ind_frame );
    elseif( isequaln( selection_type , 'Single video' ) )
        ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
        frame = read( video, ind_frame );
    elseif( isequaln( selection_type , 'Folder of videos' ) )
        i = 1 + round( rand()* ( length( files_names ) - 1 ) );
        video = VideoReader( fullfile( pathname , files_names{ i } ) );
        ind_frame = 1 + round( rand()* ( video.Duration * video.FrameRate - 1 ) );
        frame = read( video, ind_frame );
    elseif( isequaln( selection_type , 'Folder of images' ) )
        i = 1 + round( rand()* ( length( files_names ) - 1 ) );
        frame = imread( fullfile( pathname , files_names{ i } ) );
	end
    figure_comparison = figure; 
	set( figure_comparison , 'units' , 'normalized' , 'outerposition' , [ 0 0 1 1 ] );
    for j = 1:counter_cal
        c_calibration = calibration_set.( strcat( 'cal' , num2str( j ) ) ).calibration;
        c_fixed_mask = calibration_set.( strcat( 'cal' , num2str( j ) ) ).fixed_mask;
        c_cluster_fit = calibration_set.( strcat( 'cal' , num2str( j ) ) ).cluster_fit;
        c_vent_point = calibration_set.( strcat( 'cal' , num2str( j ) ) ).vent_point;
        c_name = calibration_set.( strcat( 'cal' , num2str( j ) ) ).name;
        [ frame_gray , ~ , frame_b , mean_frame_l , mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue , dark_mask ] = process_frame( frame );
        frame_b_sup = frame_b;
        parameters_image = [ mean_frame_l, mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue ];
        [ soglia_b1 , soglia_b2 ] = get_threshold( parameters_image , c_calibration , c_cluster_fit );
        if( isnan( soglia_b2 ) )
            subplot( counter_cal , 3 , 3 * j - 1 );
            imshow( frame );
            uiwait( msgbox( sprintf( [ 'This image is not processable (Calibration: ' c_name ' ).' ] ) ) );
        else
            if( soglia_b1 < 1 )
                frame_b( frame_b >= soglia_b1 ) = 1;
                frame_b( frame_b < soglia_b1 ) = 0;
            else
                frame_b( frame_b < soglia_b1 ) = 0;
                frame_b( frame_b >= soglia_b1 ) = 1;
            end
            frame_b = max( frame_b .* c_fixed_mask , dark_mask );
            if( isequaln(selection_test, 'Lab mask and Post-Processing' ) )
                [ frame_b , ~ ] = postprocessing( frame_b , c_vent_point , c_fixed_mask );
            end
            subplot( counter_cal , 3 , 3 * j - 2 );
            imshow( frame ); hold on; h = imshow( frame_b );
            set( h , 'AlphaData' , 0.2 );
            title( 'Clustering / Polynomial fit' );
            ylabel( c_name );
            if( soglia_b1 < soglia_b2 )
                subplot( counter_cal , 3 , 3 * j );
                imshow( frame ); hold on; h = imshow( frame_b );
                set( h , 'AlphaData' , 0.2 );
                title( 'Conservative fit' );
            end
            frame_b = frame_b_sup;
            if( soglia_b2 < 1 )
                frame_b( frame_b >= soglia_b2 ) = 1;
                frame_b( frame_b < soglia_b2 ) = 0;
            else
                frame_b( frame_b < soglia_b2 ) = 0;
                frame_b( frame_b >= soglia_b2 ) = 1;
            end
            frame_b = max( frame_b .* c_fixed_mask , dark_mask );
            if( isequaln( selection_test , 'Lab mask and Post-Processing' ) )
                [ frame_b , ~] = postprocessing( frame_b , c_vent_point , c_fixed_mask );
            end
            subplot( counter_cal , 3 , 3 * j - 1 );
            imshow( frame ); hold on; h = imshow( frame_b );
            set( h , 'AlphaData' , 0.2 );
            title( 'Nearest value' );
            if( soglia_b1 >= soglia_b2 )
                subplot( counter_cal , 3 , 3 * j );
                imshow( frame ); hold on; h = imshow( frame_b );
                set( h , 'AlphaData' , 0.2 );
                title( 'Conservative fit' );
            end
        end
    end
    selection = questdlg( 'Continue?' , 'Continue?' , 'Yes' , 'No' , 'Yes' );
	if( ~strcmp( selection , 'Yes' ) )
        close( figure_comparison ); return;
	end
	close( figure_comparison );
end

function [ calibration_set_out , counter_cal_out , message_out ] = add_calibration( calibration_set_in , counter_cal_in , message_in , filename_in , fixed_mask_new , calibration_new , cluster_new , vent_point_new )

for i = 1 : counter_cal_in
    current_struct = calibration_set_in.( strcat( 'cal' , num2str( i ) ) );
    if( isequaln( current_struct.calibration , calibration_new ) && isequaln( current_struct.fixed_mask , fixed_mask_new ) && isequaln( current_struct.cluster_fit , cluster_new ) && isequaln( current_struct.vent_point , vent_point_new ) )
        if( isequaln( message_in , '' ) )
            message_in = 'The following calibrations are equivalent (only one is used):';
        end
        message_out = strcat( message_in , ['\n- ' current_struct.name ' and ' filename_in '.'] );
        calibration_set_out = calibration_set_in;
        counter_cal_out = counter_cal_in;
        return;
    end
end
counter_cal_out = counter_cal_in + 1;
message_out = message_in;
calibration_set_out = calibration_set_in;
calibration_set_out.( strcat( 'cal' , num2str( counter_cal_out ) ) ).calibration = calibration_new;
calibration_set_out.( strcat( 'cal' , num2str( counter_cal_out ) ) ).fixed_mask =  fixed_mask_new;
calibration_set_out.( strcat( 'cal' , num2str( counter_cal_out ) ) ).cluster_fit = cluster_new;
calibration_set_out.( strcat( 'cal' , num2str( counter_cal_out ) ) ).vent_point = vent_point_new;
calibration_set_out.( strcat( 'cal' , num2str( counter_cal_out ) ) ).name = strrep( filename_in , '_' , ' ' );

function [ soglia_b1 , soglia_b2 ] = get_threshold( param_image , c_calibration , c_cluster_fit )

if( max( param_image( 4 : 6 ) ) > 50.00 )
    [ ~ , minindex ] = min( sum( ( param_image - c_calibration( : , 1 : 6 ) ) .^ 2 , 2 ) );
    soglia_b1 = sum( [ param_image .^2 , param_image , 1 ] .* c_cluster_fit( c_calibration( minindex , 8 ) , : ) );
    soglia_b1 = min( soglia_b1 , max( c_calibration( : , 3 ) + c_calibration( : , 7 ) ) );
    soglia_b1 = max( soglia_b1 , min( c_calibration( : , 3 ) + c_calibration( : , 7 ) ) );
    soglia_b2 = c_calibration( minindex , 3 ) + c_calibration( minindex , 7 );
else
    soglia_b1 = NaN; soglia_b2 = NaN;
end

function [ mask , message ] = postprocessing( mask_input , c_vent_point , c_fixed_mask )

global factor_cloud
global pixel_height

if( ~isequaln( pixel_height , NaN ) )
    mask_below = zeros( size( pixel_height ) );
    mask_below( pixel_height >= pixel_height( c_vent_point( 2 ), c_vent_point( 1 ) ) ) = 1;
    mask_input = mask_input .* mask_below;
    mask_below = zeros( size( pixel_height ) );
    mask_below( 1 : c_vent_point( 2 ) , : ) = 1;
    mask_input = mask_input .* mask_below;
end
mask = procedure_lines( mask_input , c_vent_point );
mask = procedure_clusters( mask , c_vent_point );
if( max( sum( mask( floor( c_vent_point( 2 ) / 2 ) : c_vent_point( 2 ) , : ) , 2 ) ./ sum( c_fixed_mask( floor( c_vent_point( 2 ) / 2 ) : c_vent_point( 2 ), : ) , 2 ) ) > factor_cloud )
    type_lobes = 1;
    message = 'A probable cloud level was identified (lobes-elimination was not performed).';
    mask = procedure_lobes( mask , c_vent_point , 0 , type_lobes );
    mask = procedure_cones( mask , c_vent_point );
else
    type_lobes = 0;
    mask = procedure_lobes( mask , c_vent_point , 0 , type_lobes );
    message = '';
end
mask = mask .* mask_input;

function mask_lines = procedure_lines( frame_input , c_vent_point )

global step_lines_mask;
global threshold_lines;

size_frame = size( frame_input );
height = size_frame( 1 ); width = size_frame( 2 );
mask_lines = zeros( height , width );
len_ax1_lr = floor( height ./ step_lines_mask );
len_ax2_lr = floor( width ./ step_lines_mask );
current_image_lr = imresize( frame_input , [ len_ax1_lr , len_ax2_lr ] );
[index_1_x, ~] = find( current_image_lr > 0 );
lines_low_values = [ 0 , 0 , 0 , 0];
counter = 0;
for j = min( index_1_x ) : floor( c_vent_point( 2 ) ./ step_lines_mask )
    for k =  min( index_1_x ) : floor( c_vent_point( 2 ) ./ step_lines_mask )
        if( max( improfile( current_image_lr ,[ 1 , len_ax2_lr ] , [ j , k ] ) ) < threshold_lines )
            counter = counter + 1;
            m = ( k - j ) / ( len_ax2_lr - 1 );
            lines_low_values( counter , 1 : 4 )= [j, k, m, ( j * step_lines_mask - step_lines_mask ./ 2 ) - m * ( step_lines_mask ./ 2 ) ];
        end
    end
end
for j = min( index_1_x ) : floor( c_vent_point( 2 ) ./ step_lines_mask )
    for k = 3 : len_ax2_lr - 2
        if( max( improfile( current_image_lr , [ 1 , k] , [j , 1 ] ) ) < threshold_lines )
            counter = counter + 1;
            m = ( 1 - j ) / ( k - 1 );
            lines_low_values( counter, 1 : 4 )= [ j , k , m , ( j * step_lines_mask - step_lines_mask ./ 2 ) - m * ( step_lines_mask ./ 2 ) ];
        end
    end
end
for j =  min( index_1_x ) : floor( c_vent_point( 2 ) ./ step_lines_mask )
    for k = 3 : len_ax2_lr - 2
        if( max( improfile( current_image_lr , [ k , len_ax2_lr ] , [ 1 , j ] ) ) < threshold_lines )
            counter = counter + 1;
            m = ( j - 1 ) / ( len_ax2_lr - k );
            lines_low_values( counter , 1 : 4 )= [ j , k , m , ( j * step_lines_mask - step_lines_mask ./ 2 ) - m * ( step_lines_mask * len_ax2_lr - step_lines_mask ./ 2  ) ];
        end
    end
end
for j1 = 1 : ( len_ax2_lr * step_lines_mask )
    j2 = max( 1 , floor( max( j1 .* lines_low_values( : , 3 ) + lines_low_values( : , 4 ) ) - step_lines_mask ./ 2 ) );
    mask_lines( j2 : end , j1 ) = 1;
end
for j1 = ( len_ax2_lr * step_lines_mask + 1 ) : width
    mask_lines( : , j1 ) = mask_lines( : , len_ax2_lr .* step_lines_mask );
end
mask_lines = mask_lines .* frame_input;

function mask_cluster = procedure_clusters( frame_input , c_vent_point )

global min_distance_cluster;
global max_distance_cluster_vent;

SE = strel( 'sphere' , min_distance_cluster );
mask_cluster = imerode( frame_input , SE );
[ labeled_frame , numberOfRegions ] = bwlabel( mask_cluster );
distance_regions = zeros( numberOfRegions , 1 );
for i = 1 : numberOfRegions
    [ ind_1 , ind_2 ] = find( labeled_frame == i );
    distance_regions( i ) = sqrt( min( sum( ( ( [ ind_2 , ind_1 ] - c_vent_point ).^2 ) , 2 ) ) );
end
for i = 1 : numberOfRegions
    if( distance_regions( i ) > max( max_distance_cluster_vent , min( distance_regions ) ) )
        mask_cluster( labeled_frame == i ) = 0;
    end
end
mask_cluster = mask_cluster .* frame_input ;
connection = bwconncomp( mask_cluster );
if( connection.NumObjects > 1 )
    [ labeled_frame , numberOfRegions ] = bwlabel( mask_cluster );
    num_regions = zeros( numberOfRegions , 1 );
    for i = 1 : numberOfRegions
        [ ind1 , ~ ] = ( find( labeled_frame == i ) );
        num_regions( i ) = min( ind1 );
    end
    [ ~ , index ] = min( num_regions );
    mask_cluster( labeled_frame ~= index ) = 0;
end

function mask_lobes = procedure_lobes( frame_input , c_vent_point , distance_exclude , type_lobes )

global min_distance_vent_lobes;
global threshold_lobes_factor;
global threshold_lobes_distance;

if( max( frame_input ) == 0 )
    mask_lobes = frame_input;
    return
end
connection = bwconncomp( frame_input );
while( connection.NumObjects > 1 )
    frame_input = procedure_clusters( frame_input , c_vent_point );
    connection = bwconncomp( frame_input );
end
size_frame = size( frame_input );
height = size_frame( 1 ); width = size_frame( 2 );
points = cell2mat( bwboundaries( frame_input , 'noholes' ) );
step_points = max( min( 5 , floor( length( points ) / 100 ) ) , 1);
points = points( 1 : step_points : end , : );
distance_points = zeros( length( points ) - 1 , 1 );
for j = 1 : length( points ) - 1
    p1 = points( j , : ); p2 = points( j + 1 , : );
    distance_points( j ) = sqrt( sum( ( ( p2 - p1 ).^2 ) ) );
end
cumulative_sum = cumsum( distance_points );
distance_vent = sqrt( sum( ( ( points - [ c_vent_point( 2 ) , c_vent_point( 1 ) ] ).^2 ), 2 ) );
[ ~ , index_vent ] = min( distance_vent );
boolean_distance_vent = max( distance_vent( 1 : end - 1 ) < min_distance_vent_lobes , points( 1 : end - 1 , 1 ) > c_vent_point( 2 ) - distance_exclude ) ;
min_factors = zeros( 0 , 4 ); counter = 0; 
in1 = 1; in2 = 1; din = 0;
for j = 1 : length( points ) - 1
    point_1 = points( j , : );
    cum_sum = cumulative_sum - cumulative_sum( j );
    cum_sum( 1 : j - 1 ) = cum_sum( end ) + cumulative_sum( 1 : j - 1 );
    boolean_distance = find( cum_sum > cumulative_sum( end ) - cum_sum );
    c_boolean_distance = find( cum_sum <= cumulative_sum( end ) - cum_sum );
    distance_no_vent = zeros( length( points ) - 1 , 1 );
    if( index_vent >= j )
        distance_no_vent( intersect( 1 : j - 1 , boolean_distance ) ) =  cumulative_sum( end ) - cum_sum( intersect( 1 : j - 1 , boolean_distance ) );
        distance_no_vent( intersect( j : index_vent , c_boolean_distance ) ) =  cum_sum( intersect( j : index_vent , c_boolean_distance ) ) ;
        distance_no_vent( intersect( index_vent + 1 : end , boolean_distance ) ) =  cumulative_sum( end ) - cum_sum( intersect( index_vent + 1 : end , boolean_distance ) ) ;
        distance_no_vent( boolean_distance_vent == 1 ) = NaN;
        distance_no_vent( distance_no_vent == 0 ) = NaN;
    else
        distance_no_vent( intersect( 1 : index_vent , c_boolean_distance ) ) =  cum_sum( intersect( 1 : index_vent, c_boolean_distance ) ) ;
        distance_no_vent( intersect( index_vent + 1 : j - 1 , boolean_distance ) ) =  cumulative_sum( end ) - cum_sum( intersect( index_vent + 1 : j - 1 , boolean_distance ) ) ;
        distance_no_vent( intersect( j : end , c_boolean_distance ) ) = cum_sum( intersect( j : end , c_boolean_distance ) ) ;
        distance_no_vent( boolean_distance_vent == 1 ) = NaN;
        distance_no_vent( distance_no_vent == 0 ) = NaN;
    end
    distance_line = sqrt( sum( ( point_1' - points( 1 : end - 1 , : )' ) .^ 2 ) );
    distance_line( distance_line == 0 ) = NaN;
    [ ~ , in2 ] = min( distance_line ./ distance_no_vent' ); 
    if( 1.2 * threshold_lobes_factor > min( distance_line ./ distance_no_vent' ) && boolean_distance_vent( j ) == 0 && distance_no_vent( in2 ) ./ max( cumulative_sum ) < 0.9 )
        if( type_lobes == 0 || distance_line( in2 ) < threshold_lobes_distance )
            counter = counter + 1;
            in1 = j;
            din = distance_line( in2 );
            min_factors( counter , : ) = [ min( distance_line ./ distance_no_vent' ) , in1 , in2 , din ];
        end
    end
end
preserve = [];
for i = 1 : max( [ min_factors( : , 2 ) ; min_factors( : , 3 ) ] )
    current_i = [ find( i == min_factors( : , 2 ) ) ; find( i == min_factors( : , 3 ) ) ];
    [ ~ , current_max ] = min( min_factors( current_i , 1 ) );
    if( length( current_i > 0 ) )
        preserve( end + 1 ) = current_i( current_max );
    end
end
min_factors = min_factors( preserve , : );
vec_points = [ min_factors( : , 2 ) ; min_factors( : , 3 ) ];
open_set = 0; counter_set = 0; save_sets = zeros( 0 , 2 );
for i = 1 : max( vec_points ) + 1 
    current_i = find( vec_points == i );
    if( length( current_i ) == 0 )
        if( open_set == 1 )
            open_set = 0;
            save_sets( counter_set , 2 ) = i - 1;
        end
    else
        if( open_set == 0 )
            open_set = 1;
            counter_set = counter_set + 1;
            save_sets( counter_set , 1 ) = i;
        end
    end
end
groups = zeros( length( min_factors( : , 1 ) ) , 2 );
for i = 1 : length( min_factors( : , 1 ) )
    for j = 1 : length( save_sets( : , 1 ) )
        if( min_factors( i , 2 ) >= save_sets( j , 1 ) && min_factors( i , 2 ) <= save_sets( j , 2 ) )
            groups_1 = j;
        end
        if( min_factors( i , 3 ) >= save_sets( j , 1 ) && min_factors( i , 3 ) <= save_sets( j , 2 ) )
            groups_2 = j;
        end
    end
    groups( i , : ) = [ min( groups_1 , groups_2 ) , max( groups_1 , groups_2 ) ];
end
preserve = ones( length( min_factors( : , 1 ) ) , 1 );
for i = 1 : length( preserve )
    if( preserve( i ) == 1 )
        current_point = groups( i , : );
        id_group = find( ( 1 - preserve ) + abs( current_point( 1 ) - groups( : , 1 ) ) + abs( current_point( 2 ) - groups( : , 2 ) ) == 0 );
        [ ~  , ind_min ] = min( min_factors( id_group , 1 ) );
        preserve( id_group ) = 0; preserve( id_group( ind_min ) ) = 1 ;
    end
end
min_factors = min_factors( find( preserve == 1 ) , : );
min_factors = sortrows( min_factors , 1 );
points_initial = points;
mask_lobes = frame_input;
for i = 1 : length( min_factors( : , 1 ) )
    min_factor = min_factors( i , 1 );
    in1 = min_factors( i , 2 );
    in2 = min_factors( i , 3 );
    din = min_factors( i , 4 );
    points = points_initial;
    if( min_factor < threshold_lobes_factor && abs( in1 - in2 ) > 1 )
        if( din > threshold_lobes_distance )
            m1 = ( ( points( in1 , 1 ) - points( index_vent,1 ) ) ./ ( points( in1 , 2 ) - points( index_vent , 2 ) ) );
            m2 = ( ( points( in2 , 1 ) - points( index_vent,1 ) ) ./ ( points( in2 , 2 ) - points( index_vent , 2 ) ) );
            n1 = points( in1 , 1 ) - m1 .* points( in1 , 2 );
            n2 = points( in2 , 1 ) - m2 .* points( in2 , 2 );
        end
        if( min( in1 , in2 ) > index_vent  || max( in1 , in2 ) < index_vent )
            if( din > threshold_lobes_distance )
                index_sup = min( in1 , in2 ) + 1 : max( in1 , in2 ) - 1;
                g1 = index_sup( points( index_sup ,2 ).* m1 + n1 < points( index_sup , 1 ) );
                g2 = index_sup( points( index_sup ,2 ).* m2 + n2 < points( index_sup , 1 ) );
                if( length( g1 ) > length( g2 )  )
                    g = g1;
                else
                    g = g2;
                end
                g = setdiff( index_sup , g );
                index_pres = [ max( in1 , in2 ) : length( points ),  1 : min( in1 , in2 ) , setdiff( min( in1 , in2 ) + 1 : max( in1 , in2 ) - 1 , g ) ];
            else
                index_pres = [ max( in1 , in2 ) : length( points ), 1 : min( in1 , in2 ) ];
            end
        else
            if( din > threshold_lobes_distance )
                index_sup = [ max( in1 , in2 ) + 1 : length( points ), 1 : min( in1 , in2 ) - 1 ];
                g1 = index_sup( points( index_sup , 2 ) .* m1 + n1 < points( index_sup , 1 ) );
                g2 = index_sup( points( index_sup , 2 ) .* m2 + n2 < points( index_sup , 1 ) );
                if( length( g1 ) > length( g2 )  )
                    g = g1;
                else
                    g = g2;
                end
                g = setdiff( index_sup , g );
                index_pres = [ setdiff( 1 : min( in1 , in2 ) - 1 , g ) ,  min( in1 , in2 ) : max( in1 , in2 ) , setdiff( max( in1 , in2 ) + 1 : length( points ) , g ) ];
            else
                index_pres = min( in1 , in2 ) : max( in1 , in2 );
            end
        end
        points_ex = points( setdiff( 1 : length( points ) , index_pres ) , : );
        if( ~isempty( points_ex ) )
            val = sqrt( sum( ( points_ex( end , : ) - points_ex( 1 , : ) ) .^ 2 ) );
            points = points( index_pres , : );
            mask_lobes = poly2mask( points( : , 2 ) - 0.5 , points( : , 1 ) - 0.5 , height , width );
            mask_lobes( : , end ) = max( mask_lobes( : , end ) , mask_lobes( : , end - 1 ) );    
            
            difference_masks = frame_input - mask_lobes;
            SE = strel( 'sphere' , 2 );
            difference_erode = imerode( difference_masks , SE );
            if( sum( difference_erode( : ) ) > 0 )
                difference_masks = difference_erode;
            end
            aspect_ratio = regionprops( difference_masks ,  'BoundingBox' );
            aspect_ratio = aspect_ratio.BoundingBox( 4 ) ./ ( 1e-10 + aspect_ratio.BoundingBox( 3 ) );
            mask_lobes = procedure_lobes( mask_lobes , c_vent_point , distance_exclude , type_lobes ); return;

        end
    elseif( min_factor < 1.2 .* threshold_lobes_factor && abs( in1 - in2 ) > 1 )
        if( din > threshold_lobes_distance )
            m1 = ( ( points( in1 , 1 ) - points( index_vent,1 ) ) ./ ( points( in1 , 2 ) - points( index_vent , 2 ) ) );
            m2 = ( ( points( in2 , 1 ) - points( index_vent,1 ) ) ./ ( points( in2 , 2 ) - points( index_vent , 2 ) ) );
            n1 = points( in1 , 1 ) - m1 .* points( in1 , 2 );
            n2 = points( in2 , 1 ) - m2 .* points( in2 , 2 );
        end
        if( min( in1 , in2 ) > index_vent  || max( in1 , in2 ) < index_vent )
            if( din > threshold_lobes_distance )
                index_sup = min( in1 , in2 ) + 1 : max( in1 , in2 ) - 1;
                g1 = index_sup( points( index_sup ,2 ).* m1 + n1 < points( index_sup , 1 ) );
                g2 = index_sup( points( index_sup ,2 ).* m2 + n2 < points( index_sup , 1 ) );
                if( length( g1 ) > length( g2 )  )
                    g = g1;
                else
                    g = g2;
                end
                g = setdiff( index_sup , g );
                index_pres = [ max( in1 , in2 ) : length( points ) , 1 : min( in1 , in2 ) , setdiff( min( in1 , in2 ) + 1 : max( in1 , in2 ) - 1 , g ) ];
            else
                index_pres = [ max( in1 , in2 ) : length( points ) , 1 : min( in1 , in2 ) ];
            end
        else
            if( din > threshold_lobes_distance )
                index_sup = [ max( in1 , in2 ) + 1 : length( points ), 1 : min( in1 , in2 ) - 1 ];
                g1 = index_sup( points( index_sup , 2 ) .* m1 + n1 < points( index_sup , 1 ) );
                g2 = index_sup( points( index_sup , 2 ) .* m2 + n2 < points( index_sup , 1 ) );
                if( length( g1 ) > length( g2 )  )
                    g = g1;
                else
                    g = g2;
                end
                g = setdiff( index_sup , g );
                index_pres = [ setdiff( 1 : min( in1 , in2 ) - 1 , g ) ,  min( in1 , in2 ) : max( in1 , in2 ) , setdiff( max( in1 , in2 ) + 1 : length( points ) , g ) ];
            else
                index_pres = min( in1 , in2 ) : max( in1 , in2 );
            end
        end
        points_ex = points( setdiff( 1 : length( points ) , index_pres ) , : );
        if( ~isempty( points_ex ) )
            val = sqrt( sum( ( points_ex( end , : ) - points_ex( 1 , : ) ) .^ 2 ) );
            points = points( index_pres , : );
            mask_lobes = poly2mask( points( : , 2 ) - 0.5 , points( : , 1 ) - 0.5 , height , width );
            mask_lobes( : , end ) = max( mask_lobes( : , end ) , mask_lobes( : , end - 1 ) );
            difference_masks = frame_input - mask_lobes;
            SE = strel( 'sphere' , 2 );
            difference_erode = imerode( difference_masks , SE );
            if( sum( difference_erode( : ) ) > 0 )
                difference_masks = difference_erode;
            end
            aspect_ratio = regionprops( difference_masks ,  'BoundingBox' );
            aspect_ratio = aspect_ratio.BoundingBox( 4 ) ./ ( 1e-10 + aspect_ratio.BoundingBox( 3 ) );
            if( aspect_ratio < 0.8 )
                mask_lobes = procedure_lobes( mask_lobes , c_vent_point , distance_exclude , type_lobes ); return;
            else
                mask_lobes = frame_input;
            end
        end
    end
end
if( isequal( mask_lobes , frame_input ) )
    return
else
    mask_lobes = procedure_lobes( mask_lobes , c_vent_point , distance_exclude , type_lobes ); return;
end

function mask_cones = procedure_cones( frame_input , c_vent_point )

global threshold_lobes_distance;

if( max( frame_input ) == 0 )
    mask_cones = frame_input;
    return
end
connection = bwconncomp( frame_input );
while( connection.NumObjects > 1 )
    frame_input = procedure_clusters( frame_input , c_vent_point );
    connection = bwconncomp( frame_input );
end
mask_cones = frame_input;
size_frame = size( frame_input );
height = size_frame( 1 ); width = size_frame( 2 );
points = cell2mat( bwboundaries( frame_input , 'noholes' ) );
step_points = max( min( 5 , floor( length( points ) / 100 ) ) , 1);
points = points( 1 : step_points : end , : );
distance_vent = sqrt( sum( ( ( points - [ c_vent_point( 2 ) , c_vent_point( 1 ) ] ).^2 ), 2 ) );
[ ~ , index_vent ] = min( distance_vent );
j = index_vent;
points = points( [ j : end , 1 : j - 1 ] , : );
distance_points = zeros( length( points ) , 1 );
for j = 2 : length( points )
    p1 = points( j , : ); p2 = points( j - 1 , : );
    distance_points( j ) = sqrt( sum( ( ( p2 - p1 ).^2 ) ) );
end
p1 = points( 1 , : ); p2 = points( end , : );
distance_border =sqrt( sum( ( ( p2 - p1 ).^2 ) ) ); 
cumulative_sum = cumsum( distance_points ) ;
cum_sum1 = cumulative_sum;
cum_sum2 = distance_border + cumulative_sum( end ) - cumulative_sum;
cum_sum = min( cum_sum1 , cum_sum2 );
direction = ( cum_sum1 - cum_sum2 );
distance_line = sqrt( sum( ( points( 1 , : )' - points( 1 : end , : )' ) .^ 2 ) );
distance_line( distance_line == 0 ) = NaN;
ind_mins = find( ( ( islocalmin( distance_line' ./ cum_sum ) == 1 ) .* ( ( distance_line' ./ cum_sum ) < 0.35 ) .* ( points( 1 : end , 1 ) > c_vent_point( 2 ) / 2 ) ) == 1 );
mask_cones = frame_input;
points_base = points;
for i = 1:length( ind_mins )
    in1 = 1;
    in2 = ind_mins( i );
    din = distance_line( in1 );
    points = points_base;
    if( din > threshold_lobes_distance )
        m1 = ( ( points( in1 , 1 ) - points( index_vent,1 ) ) ./ ( points( in1 , 2 ) - points( index_vent , 2 ) ) );
        m2 = ( ( points( in2 , 1 ) - points( index_vent,1 ) ) ./ ( points( in2 , 2 ) - points( index_vent , 2 ) ) );
        n1 = points( in1 , 1 ) - m1 .* points( in1 , 2 );
        n2 = points( in2 , 1 ) - m2 .* points( in2 , 2 );
    end
    
    if( din > threshold_lobes_distance )
        index_sup = min( in1 , in2 ) + 1 : max( in1 , in2 ) - 1;
        g1 = index_sup( points( index_sup ,2 ).* m1 + n1 < points( index_sup , 1 ) );
        g2 = index_sup( points( index_sup ,2 ).* m2 + n2 < points( index_sup , 1 ) );
        if( length( g1 ) > length( g2 )  )
            g = g1;
        else
            g = g2;
        end
        g = setdiff( index_sup , g );
        index_pres = [ max( in1 , in2 ) : length( points ), 1 : min( in1 , in2 ) , setdiff( min( in1 , in2 ) + 1 : max( in1 , in2 ) - 1 , g ) ];
    else
        index_pres = [ max( in1 , in2 ) : length( points ), 1 : min( in1 , in2 ) ];
    end
    if( direction( in2 ) > 0.1 .* max( cumulative_sum ) )
        points_pres = points( setdiff( 1 : length( points ) , index_pres ) , : );
        if( ~isempty( index_pres ) && min( points_pres( : , 1 ) ) == min( points( : , 1 ) ) )
            points = points_pres;
            mask_cones_c = poly2mask( points( : , 2 ) - 0.5 , points( : , 1 ) - 0.5 , height , width );
            mask_cones_c( : , end ) = max( mask_cones_c( : , end ) , mask_cones_c( : , end - 1 ) );
            mask_cones = mask_cones .* mask_cones_c;
        end
    elseif( direction( in2 ) < - 0.1 .* cumulative_sum( end ) )
        points_ex = points( setdiff( 1 : length( points ) , index_pres ) , : );
        if( ~isempty( points_ex ) && min( points_ex( : , 1 ) ) > min( points( : , 1 ) ) )
            val = sqrt( sum( ( points_ex( end , : ) - points_ex( 1 , : ) ) .^ 2 ) );
            points = points( index_pres , : );
            mask_cones_c = poly2mask( points( : , 2 ) - 0.5 , points( : , 1 ) - 0.5 , height , width );
            mask_cones_c( : , end ) = max( mask_cones_c(: , end ) , mask_cones_c( : , end - 1 ) );
            mask_cones = mask_cones .* mask_cones_c;
        end
    end
end

function mask_isolated = procedure_isolated( frame_input , c_fixed_mask )

global min_distance_cluster;

SE = strel( 'sphere' , min_distance_cluster );
mask_isolated = imerode( frame_input .* c_fixed_mask , SE );
[ labeled_frame , numberOfRegions ] = bwlabel( mask_isolated );
for i = 1 : numberOfRegions
    if( length( find( labeled_frame( : ) == i ) ) <  100 )
        mask_isolated( labeled_frame == i ) = 0;
    end
end
mask_isolated = mask_isolated .* frame_input ;

function video_analysis_procedure( pathname , filename )

global calibration
global fixed_mask
global cluster_fit
global vent_point
global pixel_height
global gradient_threshold
global gradient_max
global min_height
global factor_mat_eval
global factor_val_max
global gradient_val_max 
global factor_dark_val_max
global dark_val_max
global save_video

max_height_measurable = max( pixel_height( : , vent_point( 1 ) ) );
data_t = zeros( 0 , 1 ); type_plume = zeros( 1 , 0 );
max_height = zeros( 0 , 3 ); data_min_pix = zeros( 1 , 0 );
counter_data = 0;
video = VideoReader( fullfile( pathname , filename ) );
button = questdlg( 'Lab Calibration' , 'Lab Calibration' , 'Polynomial Fit' , 'Nearest Value' , 'More conservative choice' , 'Polynomial Fit' );
if( ~isequal( button, 'Polynomial Fit' ) && ~isequal( button, 'Nearest Value' ) && ~isequal( button, 'More conservative choice' ) )
    return;
end
button_plot = questdlg( 'Plot Frames?' , 'Plot Frames?' , 'Yes' , 'No' , 'No' );
if( ~isequal( button_plot , 'Yes' ) && ~isequal( button_plot , 'No' ) )
    return;
end
step_frame = max( 1 , floor( str2double( cell2mat( inputdlg( {'Frame step:'} , 'Frame Step' , [ 1 75] , {'1'} ) ) ) ) );
if( strcmpi( button_plot , 'Yes' ) ||  save_video == 1 )
	x_contour = 1 : length( pixel_height( : , 1 ) ); y_contour = 1 : length( pixel_height( 1 , : ) );
	[ x_plot, y_plot ] = meshgrid( y_contour, x_contour );
end
frame_step = str2double( cell2mat( inputdlg( {'Timestep between two consecutive frames (s):'} , 'Timestep between two consecutive frames' , [ 1 75] , {'1'} ) ) );
SE = strel( 'square' , 3 );
if( save_video == 1 )
    new_video = VideoWriter( strcat( filename( 1 : end - 4 ), '_Processing.avi' ) );
    open( new_video );
end
for ind_frame = 1 : step_frame : video.Duration * video.FrameRate
    boolean_top = 0;
	frame = read( video , ind_frame );
    [ frame_gray , frame_l , frame_b , mean_frame_l , mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue , dark_mask ] = process_frame( frame );
    parameters_image = [ mean_frame_l, mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue ];
	[ soglia_b1 , soglia_b2 ] = get_threshold( parameters_image , calibration , cluster_fit );
	if( strcmpi( button , 'Polynomial Fit' ) )
        soglia_b = soglia_b1;
    elseif( strcmpi( button, 'Nearest Value' ) )
        soglia_b = soglia_b2;
    elseif( isnan( soglia_b2 ) )
        soglia_b = soglia_b2;
    else
        soglia_b = min( soglia_b1 , soglia_b2 );
	end
    if( ~isnan( soglia_b ) )
        if( soglia_b < 1 )
            frame_b( frame_b >= soglia_b  ) = 1;
            frame_b( frame_b < soglia_b ) = 0;
        else
            frame_b(  frame_b < soglia_b  ) = 0;
            frame_b( frame_b >= soglia_b ) = 1;
        end
        frame_b = max( frame_b .* fixed_mask , dark_mask );
        [ frame_b , message ] = postprocessing( frame_b , vent_point , fixed_mask );
        [ ind_1 , ~] = find( frame_b == 1 );
        if( isempty( ind_1 ) )
            ind_1 = vent_point( 2 );
        end
        counter_data = counter_data + 1;
        gradient = min( gradient_max , imgaussfilt( imgradient( frame_l ) , 5 ) );
        data_min_pix( 1 , counter_data ) = vent_point( 2 ) - min( ind_1 );
        if( ~isequaln( pixel_height , NaN ) )
            factor_top = sum( sum( frame_b( 1 : 3 , : ) ) ) ./ ( 1e-10 + sum( sum( fixed_mask( 1 : 3 , : ) ) ) );
            mat_eval = ( pixel_height - min( pixel_height( : ) ) ) .* gradient .* fixed_mask .* frame_b ;
            mat_eval( isnan( pixel_height ) ) = 0;
            mat_eval( ( pixel_height - min( pixel_height( : ) ) ) <= min_height ) = 0;
            frame_b_a = imdilate( frame_b , SE ) .* fixed_mask; frame_b_b = frame_b_a; frame_b_c = frame_b_a;
            val_max = gradient( mat_eval == max( mat_eval( : ) ) );
            if( factor_top < 0.1 )
                max_mat_eval = prctile( mat_eval( mat_eval > 0 ) , 80 );
                frame_b_a( ( gradient < gradient_threshold ) & ( ( mat_eval < factor_mat_eval( 1 ) .* max_mat_eval ) | ( gradient < min( gradient_val_max , factor_val_max( 1 ) * min( val_max ) ) ) ) ) = 0;
                frame_b_b( ( gradient < gradient_threshold ) & ( ( mat_eval < factor_mat_eval( 2 ) .* max_mat_eval ) | ( gradient < min( gradient_val_max , factor_val_max( 2 ) * min( val_max ) ) ) ) ) = 0;
                frame_b_c( ( gradient < gradient_threshold ) & ( ( mat_eval < factor_mat_eval( 3 ) .* max_mat_eval ) | ( gradient < min( gradient_val_max , factor_val_max( 3 ) * min( val_max ) ) ) ) ) = 0;
                frame_b_a( pixel_height .* fixed_mask .* frame_b == max( pixel_height( : ) ) & gradient > max( factor_dark_val_max( 1 ) * min( val_max ) , dark_val_max( 1 ) ) ) = 1;
                frame_b_b( pixel_height .* fixed_mask .* frame_b == max( pixel_height( : ) ) & gradient > max( factor_dark_val_max( 2 ) * min( val_max ) , dark_val_max( 2 ) ) ) = 1;
                frame_b_c( pixel_height .* fixed_mask .* frame_b == max( pixel_height( : ) ) & gradient > max( factor_dark_val_max( 3 ) * min( val_max ) , dark_val_max( 3 ) ) ) = 1;
                frame_b_a( dark_mask .* fixed_mask == 1 ) = 1;
                frame_b_b( dark_mask .* fixed_mask == 1 ) = 1;
                frame_b_c( dark_mask .* fixed_mask == 1 ) = 1;
                max_height( counter_data , 1 ) = min( max( frame_b_a( : ) .* pixel_height( : ) ) , max_height_measurable );
                max_height( counter_data , 2 ) = min( max( frame_b_b( : ) .* pixel_height( : ) ) , max_height_measurable );
                max_height( counter_data , 3 ) = min( max( frame_b_c( : ) .* pixel_height( : ) ) , max_height_measurable );
                type_plume( 1 , counter_data ) = max( val_max );
                if( max( max_height( counter_data , : ) ) == max_height_measurable )
                    boolean_top = 1;
                end
            elseif( factor_top < 0.8 )
                max_height( counter_data , 1 ) = min( max( frame_b_a( : ) .* pixel_height( : ) ) , max_height_measurable );
                max_height( counter_data , 2 ) = min( max( frame_b_b( : ) .* pixel_height( : ) ) , max_height_measurable );
                max_height( counter_data , 3 ) = min( max( frame_b_c( : ) .* pixel_height( : ) ) , max_height_measurable );
                type_plume( 1 , counter_data ) = max( val_max );
                if( max( max_height( counter_data , : ) ) == max_height_measurable )
                    boolean_top = 1;
                end
            else
                max_height( counter_data , 1 ) = max_height_measurable;
                max_height( counter_data , 2 ) = max_height_measurable;
                max_height( counter_data , 3 ) = max_height_measurable;
                type_plume( 1 , counter_data ) = max( val_max );
                boolean_top = 1;
            end
        end
        data_t( counter_data ) = ind_frame;
        if( save_video == 1 )
            frame_video = frame ; 
            for i = 1:3
                frame_video( : , : , i ) = double( frame_video( : , : , i ) );
            end
            figure_video = figure( 'visible' , 'off' );
            axes_vs = axes( 'Parent' , figure_video );
            hold( axes_vs , 'on' );
            if( boolean_top == 0 )
                imshow( frame , 'Parent' , axes_vs ); pause( 0.001 );
                cont_a = contour( x_plot, y_plot , pixel_height , [ max_height( counter_data , 1 ) , max_height( counter_data , 1 ) ] , 'r:' , 'LineWidth' , 2 , 'Parent' , axes_vs ); pause( 0.001 );
                cont_b = contour( x_plot, y_plot , pixel_height , [ max_height( counter_data , 2 ) , max_height( counter_data , 2 ) ] , 'g:' , 'LineWidth' , 2 , 'Parent' , axes_vs ); pause( 0.001 );
                cont_c = contour( x_plot, y_plot , pixel_height , [ max_height( counter_data , 3 ) , max_height( counter_data , 3 ) ] , 'b:' , 'LineWidth' , 2 , 'Parent' , axes_vs ); pause( 0.001 );
                for i = 2 : length( cont_a( 1 , : ) )
                    frame_video( round( cont_a( 2 , i ) ) , round( cont_a( 1 , i ) ) , : )  = [ 255 0 0 ];
                end
                for i = 2 : length( cont_b( 1 , : ) )
                    frame_video( round( cont_b( 2 , i ) ) , round( cont_b( 1 , i ) ) , : ) = [ 0 255 0];
                end
                for i = 2 : length( cont_c( 1 , : ) )
                    frame_video( round( cont_c( 2 , i ) ) , round( cont_c( 1 , i ) ) , : ) = [ 0 0 255];
                end
            else
                frame_video( : , : , 1 ) = min( 255 , frame_video( : , : , 1 ) .* 1.5 );
            end
            close( figure_video );
            for i = ind_frame : 1 : min( ind_frame + step_frame , video.Duration * video.FrameRate ) 
                open( new_video )
                writeVideo( new_video , frame_video );
            end 
        end
        if( strcmpi( button_plot , 'Yes' ) )
            figure_video_analysis = figure;
            axes_va = axes( 'Parent' , figure_video_analysis );
            hold( axes_va , 'on' )
            imshow( frame , 'Parent' , axes_va ); pause( 0.001 );
            h = imshow( frame_b , 'Parent' , axes_va ); pause( 0.001 );
            set( h , 'AlphaData' , 0.1 ); pause( 0.001 );
            if( ~isequaln( pixel_height , NaN ) )
            	contour( x_plot, y_plot, pixel_height, [ max_height( counter_data , 1 ) , max_height( counter_data , 1 ) ] , 'r:' , 'LineWidth' , 2 , 'Parent' , axes_va ); pause( 0.001 );
                hold on;
            	contour( x_plot, y_plot, pixel_height, [ max_height( counter_data , 2 ) , max_height( counter_data , 2 ) ] , 'g:' , 'LineWidth' , 2 , 'Parent' , axes_va ); pause( 0.001 );
            	contour( x_plot, y_plot, pixel_height, [ max_height( counter_data , 3 ) , max_height( counter_data , 3 ) ] , 'b:' , 'LineWidth' , 2 , 'Parent' , axes_va ); pause( 0.001 );
            end
            pause( 3 );
            try
                close( figure_video_analysis );
            catch
                continue
            end
        end
    else
        counter_data = counter_data + 1;
        data_t( counter_data ) = ind_frame;
        type_plume( 1 , counter_data ) = NaN;
        max_height( counter_data , 1 : 3 ) = NaN; 
        data_min_pix( 1 , counter_data ) = NaN;
        message = 'Image considered not procesable.';
        if( save_video == 1 )
            frame_video = frame ; 
            for i = 1:3
                frame_video( : , : , i ) = double( frame_video( : , : , i ) );
            end
            figure_video = figure( 'visible' , 'off' );
            axes_vs = axes( 'Parent' , figure_video );
            hold( axes_vs , 'on' );
            frame_video( : , : , 3 ) = min( 255 , frame_video( : , : , 3 ) .* 1.5 );
            close( figure_video );
            for i = ind_frame : 1 : min( min( ind_frame + step_frame , 10 ) , video.Duration * video.FrameRate ) 
                writeVideo( new_video , frame_video );
            end 
        end
        if( strcmpi( button_plot , 'Yes' ) )
            figure_video_analysis = figure;
            axes_va = axes( 'Parent' , figure_video_analysis );
            hold( axes_va , 'on' )
            imshow( frame , 'Parent' , axes_va );
            pause( 3 );
            try
                close( figure_video_analysis );
            catch
                continue
            end
        end
    end
	disp( ['- Frame: ' , num2str( ind_frame ) , '/' , num2str( video.Duration * video.FrameRate ) , '. ' , message ] );
end
if( ~isequaln( pixel_height , NaN ) )
    vent_height = min( pixel_height( : ) );
else
    vent_height = NaN;
end
if( save_video == 1 )
    close( new_video );
end
procedure_plot( data_t , data_min_pix , max_height , vent_height , frame_step , video.Duration * video.FrameRate , type_plume , 1 , save_video );

function video_analysis_manually( pathname , filename )

global vent_point
global pixel_height
global save_video

max_height_measurable = max( pixel_height( : , vent_point( 1 ) ) );
data_t = zeros( 0 , 1 ); type_plume = zeros( 0 , 1 );
max_height = zeros( 0 , 3 ); data_min_pix = zeros( 0 , 1 );
counter_data = 0;
video = VideoReader( fullfile( pathname , filename ) );
step_frame = max( 1 , floor( str2double( cell2mat( inputdlg( {'Frame step:'} , 'Frame Step' , [ 1 75] , {'1'} ) ) ) ) );
height_data = [];
if( save_video == 1 )
	x_contour = 1 : length( pixel_height( : , 1 ) ); y_contour = 1 : length( pixel_height( 1 , : ) );
	[ x_plot, y_plot ] = meshgrid( y_contour, x_contour );
end
frame_step = str2double( cell2mat( inputdlg( {'Timestep between two consecutive frames (s):'} , 'Timestep between two consecutive frames' , [ 1 75] , {'1'} ) ) );
SE = strel( 'square' , 3 );
SE0 = strel( 'sphere' , 1 );
if( save_video == 1 )
    new_video = VideoWriter( strcat( filename( 1 : end - 4 ), '_Processing.avi' ) );
    open( new_video );
end
for ind_frame = 1 : step_frame : video.Duration * video.FrameRate
    boolean_top = 0;
	frame = read( video , ind_frame );
    f_pixelheight = figure; ax = axes( f_pixelheight ); pause( 0.001 );
    size_image = size( frame ); pause( 0.001 );
    imshow( frame ,  'Parent' , ax ); hold on; pause( 0.001 );
    plot( vent_point( 1 ), vent_point( 2 ), 'bo' , 'MarkerFaceColor' , 'b' , 'Parent' , ax ); pause( 0.001 );
    if( ~isequaln( pixel_height , NaN ) )
        x_contour = 1 : length( pixel_height( : , 1 ) ); y_contour = 1 : length( pixel_height( 1 , : ) );
        [ x_plot , y_plot ] = meshgrid( y_contour, x_contour );
        [ cc , hc ] = contour( x_plot , y_plot , pixel_height , sort( 0 : 500 : 20000 ) , 'k' , 'Parent' , ax ); pause( 0.001 );
        clabel( cc , hc ); pause( 0.001 );
    end
	point = drawpoint();
    counter_data = counter_data + 1;
    boolean_point = point.Position( 2 ) < length( frame( : , 1 , 1 ) );
    if( boolean_point )
        max_height( counter_data , 1 : 3 ) = min( pixel_height( floor( point.Position( 2 ) ) , floor( point.Position( 1 ) ) ) , max_height_measurable );
    else
        max_height( counter_data , 1 : 3 ) = [ NaN NaN NaN ];
    end
    data_t( counter_data ) = ind_frame;
    data_min_pix( counter_data ) = 0;
    type_plume( 1 , counter_data ) = 20;
    close( f_pixelheight );
    if( save_video == 1 )
        frame_video = frame ;
        for i = 1:3
            frame_video( : , : , i ) = double( frame_video( : , : , i ) );
        end
        figure_video = figure( 'visible' , 'off' );
        axes_vs = axes( 'Parent' , figure_video );
        hold( axes_vs , 'on' );
        if( boolean_top == 0 && boolean_point )
            imshow( frame , 'Parent' , axes_vs ); pause( 0.001 );
            cont_a = contour( x_plot, y_plot , pixel_height , [ max_height( counter_data , 1 ) , max_height( counter_data , 1 ) ] , 'r:' , 'LineWidth' , 2 , 'Parent' , axes_vs ); pause( 0.001 );
            for i = 2 : length( cont_a( 1 , : ) )
                frame_video( round( cont_a( 2 , i ) ) , round( cont_a( 1 , i ) ) , : )  = [ 255 0 0 ];
            end
        else
            frame_video( : , : , 1 ) = min( 255 , frame_video( : , : , 1 ) .* 1.5 );
        end
        close( figure_video );
        for i = ind_frame : 1 : min( min( ind_frame + step_frame , 10 ) , video.Duration * video.FrameRate )
            open( new_video )
            writeVideo( new_video , frame_video );
        end
    end
end  
if( ~isequaln( pixel_height , NaN ) )
    vent_height = min( pixel_height( : ) );
else
    vent_height = NaN;
end
if( save_video == 1 )
    close( new_video );
end
procedure_plot( data_t , data_min_pix , max_height , vent_height , frame_step , video.Duration * video.FrameRate , type_plume , 1 , save_video );

function images_analysis_procedure( pathname )

global calibration
global fixed_mask
global cluster_fit
global vent_point
global pixel_height
global gradient_threshold
global gradient_max
global min_height
global factor_mat_eval
global factor_val_max
global gradient_val_max 
global factor_dark_val_max
global dark_val_max
global save_video

max_height_measurable = max( pixel_height( : , vent_point( 1 ) ) );
data_t = zeros( 0 , 1 ); type_plume = zeros( 0 , 1 );
max_height = zeros( 0 , 3 ); data_min_pix = zeros( 0 , 1 );
counter_data = 0;
names = dir( pathname ); files_names = {}; format_file = '.jpg';
for i = 1:length( names )
    if( strcmp( names( i ).name( max( 1  , end - 3 ): end ), format_file ) )
        files_names{ end + 1 } = names( i ).name;
    end
end
button = questdlg( 'Lab Calibration' , 'Lab Calibration' , 'Polynomial Fit' , 'Nearest Value' , 'More conservative choice' , 'Polynomial Fit' );
if( ~isequal( button, 'Polynomial Fit' ) && ~isequal( button, 'Nearest Value' ) && ~isequal( button, 'More conservative choice' ) )
    return;
end
button_plot = questdlg( 'Plot Frames?' , 'Plot Frames?' , 'Yes' , 'No' , 'No' );
if( ~isequal( button_plot , 'Yes' ) && ~isequal( button_plot , 'No' ) )
    return;
end
if( strcmpi( button_plot , 'Yes' ) ||  save_video == 1 )
	x_contour = 1 : length( pixel_height( : , 1 ) ); y_contour = 1 : length( pixel_height( 1 , : ) );
	[ x_plot, y_plot ] = meshgrid( y_contour, x_contour );
end
frame_step = str2double( cell2mat( inputdlg( {'Timestep between two consecutive frames (s):'} , 'Timestep between two consecutive frames' , [ 1 75] , {'1'} ) ) );
SE = strel( 'square' , 3 );
if( save_video == 1 )
    [~ , name_file , ~] = fileparts( pathname );
    new_video = VideoWriter( strcat( name_file , '_Processing.avi' ) );
    open( new_video );
end
for ind_frame = 1 : length( files_names )
    boolean_top = 0;
	frame = imread( fullfile( pathname , files_names{ ind_frame } ) );
	[ frame_gray , frame_l , frame_b , mean_frame_l , mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue , dark_mask ] = process_frame( frame );
    parameters_image = [ mean_frame_l, mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue ];
	[ soglia_b1 , soglia_b2 ] = get_threshold( parameters_image , calibration , cluster_fit );
	if( strcmpi( button , 'Polynomial Fit' ) )
        soglia_b = soglia_b1;
    elseif( strcmpi( button, 'Nearest Value' ) )
        soglia_b = soglia_b2;
    elseif( isnan( soglia_b2 ) )
        soglia_b = soglia_b2;
    else
        soglia_b = min( soglia_b1 , soglia_b2 );
	end
    if( ~isnan( soglia_b ) )
        if( soglia_b < 1 )
            frame_b( frame_b >= soglia_b  ) = 1;
            frame_b( frame_b < soglia_b ) = 0;
        else
            frame_b(  frame_b < soglia_b ) = 0;
            frame_b( frame_b >= soglia_b ) = 1;
        end
        frame_b = max( frame_b .* fixed_mask , dark_mask );
        [ frame_b , message ] = postprocessing( frame_b , vent_point , fixed_mask );
        [ ind_1 , ~] = find( frame_b == 1 );
        if( isempty( ind_1 ) )
            ind_1 = vent_point( 2 );
        end
        counter_data = counter_data + 1;
        gradient = min( gradient_max , imgaussfilt( imgradient( frame_l ) , 5 ) );
        data_min_pix( counter_data ) = vent_point( 2 ) - min( ind_1 );
        if( ~isequaln( pixel_height , NaN ) )
            factor_top = sum( sum( frame_b( 1 : 3 , : ) ) ) ./ ( 1e-10 + sum( sum( fixed_mask( 1 : 3 , : ) ) ) );
            mat_eval = ( pixel_height - min( pixel_height( : ) ) ) .* gradient .* fixed_mask .* frame_b ;
            mat_eval( isnan( pixel_height ) ) = 0;
            mat_eval( ( pixel_height - min( pixel_height( : ) ) ) <= min_height ) = 0;
            frame_b_a = imdilate( frame_b , SE ) .* fixed_mask; frame_b_b = frame_b_a; frame_b_c = frame_b_a;
            val_max = gradient( mat_eval == max( mat_eval( : ) ) );
            if( factor_top < 0.1 )
                max_mat_eval = prctile( mat_eval( mat_eval > 0 ) , 80 );
                frame_b_a( ( gradient < gradient_threshold ) & ( ( mat_eval < factor_mat_eval( 1 ) .* max_mat_eval ) | ( gradient < min( gradient_val_max , factor_val_max( 1 ) * min( val_max ) ) ) ) ) = 0;
                frame_b_b( ( gradient < gradient_threshold ) & ( ( mat_eval < factor_mat_eval( 2 ) .* max_mat_eval ) | ( gradient < min( gradient_val_max , factor_val_max( 2 ) * min( val_max ) ) ) ) ) = 0;
                frame_b_c( ( gradient < gradient_threshold ) & ( ( mat_eval < factor_mat_eval( 3 ) .* max_mat_eval ) | ( gradient < min( gradient_val_max , factor_val_max( 3 ) * min( val_max ) ) ) ) ) = 0;
                frame_b_a( pixel_height .* fixed_mask .* frame_b == max( pixel_height( : ) ) & gradient > max( factor_dark_val_max( 1 ) * min( val_max ) , dark_val_max( 1 ) ) ) = 1;
                frame_b_b( pixel_height .* fixed_mask .* frame_b == max( pixel_height( : ) ) & gradient > max( factor_dark_val_max( 2 ) * min( val_max ) , dark_val_max( 2 ) ) ) = 1;
                frame_b_c( pixel_height .* fixed_mask .* frame_b == max( pixel_height( : ) ) & gradient > max( factor_dark_val_max( 3 ) * min( val_max ) , dark_val_max( 3 ) ) ) = 1;
                frame_b_a( dark_mask .* fixed_mask == 1 ) = 1;
                frame_b_b( dark_mask .* fixed_mask == 1 ) = 1;
                frame_b_c( dark_mask .* fixed_mask == 1 ) = 1;
                max_height( counter_data , 1 ) = min( max( frame_b_a( : ) .* pixel_height( : ) ) , max_height_measurable );
                max_height( counter_data , 2 ) = min( max( frame_b_b( : ) .* pixel_height( : ) ) , max_height_measurable );
                max_height( counter_data , 3 ) = min( max( frame_b_c( : ) .* pixel_height( : ) ) , max_height_measurable );
                type_plume( 1 , counter_data ) = max( val_max );
                if( max( max_height( counter_data , : ) ) == max_height_measurable )
                    boolean_top = 1;
                end
            elseif( factor_top < 0.8 )
                max_height( counter_data , 1 ) = min( max( frame_b_a( : ) .* pixel_height( : ) ) , max_height_measurable );
                max_height( counter_data , 2 ) = min( max( frame_b_b( : ) .* pixel_height( : ) ) , max_height_measurable );
                max_height( counter_data , 3 ) = min( max( frame_b_c( : ) .* pixel_height( : ) ) , max_height_measurable );
                type_plume( 1 , counter_data ) = max( val_max );
                if( max( max_height( counter_data , : ) ) == max_height_measurable )
                    boolean_top = 1;
                end
            else
                max_height( counter_data , 1 ) = max_height_measurable;
                max_height( counter_data , 2 ) = max_height_measurable;
                max_height( counter_data , 3 ) = max_height_measurable;
                type_plume( 1 , counter_data ) = max( val_max );
                boolean_top = 1;
            end
        end
        data_t( counter_data ) = ind_frame;
        if( save_video == 1 )
            frame_video = frame ; 
            for i = 1:3
                frame_video( : , : , i ) = double( frame_video( : , : , i ) );
            end
            figure_video = figure( 'visible' , 'off' );
            axes_vs = axes( 'Parent' , figure_video );
            hold( axes_vs , 'on' );
            if( boolean_top == 0 )
                imshow( frame , 'Parent' , axes_vs ); pause( 0.001 );
                cont_a = contour( x_plot, y_plot , pixel_height, [ max_height( counter_data , 1 ) , max_height( counter_data , 1 ) ] , 'r:' , 'LineWidth' , 2 , 'Parent' , axes_vs ); pause( 0.001 );
                cont_b = contour( x_plot, y_plot , pixel_height, [ max_height( counter_data , 2 ) , max_height( counter_data , 2 ) ] , 'g:' , 'LineWidth' , 2 , 'Parent' , axes_vs ); pause( 0.001 );
                cont_c = contour( x_plot, y_plot , pixel_height, [ max_height( counter_data , 3 ) , max_height( counter_data , 3 ) ] , 'b:' , 'LineWidth' , 2 , 'Parent' , axes_vs ); pause( 0.001 );
                for i = 2 : length( cont_a( 1 , : ) )
                    frame_video( round( cont_a( 2 , i ) ) , round( cont_a( 1 , i ) ) , : ) = [ 255 0 0 ];
                end
                for i = 2 : length( cont_b( 1 , : ) )
                    frame_video( round( cont_b( 2 , i ) ) , round( cont_b( 1 , i ) ) , : ) = [ 0 255 0 ];
                end
                for i = 2 : length( cont_c( 1 , : ) )
                    frame_video( round( cont_c( 2 , i ) ) , round( cont_c( 1 , i ) ) , : ) = [ 0 0 255 ];
                end
            else
               frame_video( : , : , 1 ) = min( 255 , frame_video( : , : , 1 ) .* 1.5 );
            end
            close( figure_video );
            writeVideo( new_video , frame_video );
        end
        if( strcmpi( button_plot , 'Yes' ) )
            figure_images_analysis = figure;
            axes_va = axes( 'Parent' , figure_images_analysis );
            hold( axes_va , 'on' )
            imshow( frame , 'Parent' , axes_va ); pause( 0.001 );
            h = imshow( frame_b , 'Parent' , axes_va ); pause( 0.001 );
            set( h , 'AlphaData' , 0.1 ); pause( 0.001 );
            if( ~isequaln( pixel_height , NaN ) )
            	contour( x_plot, y_plot, pixel_height, [ max_height( counter_data , 1 ) , max_height( counter_data , 1 ) ] , 'r:' , 'LineWidth' , 2 , 'Parent' , axes_va ); pause( 0.001 );
            	contour( x_plot, y_plot, pixel_height, [ max_height( counter_data , 2 ) , max_height( counter_data , 2 ) ] , 'g:' , 'LineWidth' , 2 , 'Parent' , axes_va ); pause( 0.001 );
            	contour( x_plot, y_plot, pixel_height, [ max_height( counter_data , 3 ) , max_height( counter_data , 3 ) ] , 'b:' , 'LineWidth' , 2 , 'Parent' , axes_va ); pause( 0.001 );
            end
            pause( 3 );
            try
                close( figure_images_analysis );
            catch
                continue
            end
        end
    else
        counter_data = counter_data + 1;
        data_t( counter_data ) = ind_frame;
        type_plume( 1 , counter_data ) = NaN;
        max_height( counter_data , 1 : 3 ) = NaN; 
        data_min_pix( 1 , counter_data ) = NaN;
        message = 'Image considered not procesable.';
        if( save_video == 1 )
            frame_video = frame ; 
            for i = 1:3
                frame_video( : , : , i ) = double( frame_video( : , : , i ) );
            end
            figure_video = figure( 'visible' , 'off' );
            axes_vs = axes( 'Parent' , figure_video );
            hold( axes_vs , 'on' );
            frame_video( : , : , 3 ) = min( 255 , frame_video( : , : , 3 ) .* 1.5 );
            close( figure_video );
            for i = ind_frame : 1 : length( files_names )
                open( new_video )
                writeVideo( new_video , frame_video );
            end 
        end
        if( strcmpi( button_plot , 'Yes' ) )
            figure_images_analysis = figure;
            axes_va = axes( 'Parent' , figure_images_analysis );
            hold( axes_va , 'on' )
            imshow( frame , 'Parent' , axes_va );
            pause( 3 );
            try
                close( figure_images_analysis );
            catch
                continue
            end
        end
    end
    disp( ['- Frame: ' , num2str( ind_frame ), '/' , num2str( length( files_names ) ) , '. ' , message ] );
end
if( ~isequaln( pixel_height , NaN ) )
    vent_height = min( pixel_height( : ) );
else
    vent_height = NaN;
end
if( save_video == 1 )
    close( new_video );
end
procedure_plot( data_t , data_min_pix , max_height , vent_height , frame_step , length( files_names ) , type_plume , 1 , save_video );

function images_analysis_manually( pathname )

global vent_point
global pixel_height
global save_video

max_height_measurable = max( pixel_height( : , vent_point( 1 ) ) );
data_t = zeros( 0 , 1 ); type_plume = zeros( 0 , 1 );
max_height = zeros( 0 , 3 ); data_min_pix = zeros( 0 , 1 );
counter_data = 0;
names = dir( pathname ); files_names = {}; format_file = '.jpg';
for i = 1:length( names )
    if( strcmp( names( i ).name( max( 1 , end - 3 ): end ), format_file ) )
        files_names{ end + 1 } = names( i ).name;
    end
end
if( save_video == 1 )
	x_contour = 1 : length( pixel_height( : , 1 ) ); y_contour = 1 : length( pixel_height( 1 , : ) );
	[ x_plot, y_plot ] = meshgrid( y_contour, x_contour );
end
frame_step = str2double( cell2mat( inputdlg( {'Timestep between two consecutive frames (s):'} , 'Timestep between two consecutive frames' , [ 1 75] , {'1'} ) ) );
SE = strel( 'square' , 3 );
if( save_video == 1 )
    [~ , name_file , ~] = fileparts( pathname );
    new_video = VideoWriter( strcat( name_file , '_Processing.avi' ) );
    open( new_video );
end
for ind_frame = 1 : length( files_names )
    boolean_top = 0;
	frame = imread( fullfile( pathname , files_names{ ind_frame } ) );
    f_pixelheight = figure; ax = axes( f_pixelheight ); pause( 0.001 );
    size_image = size( frame ); pause( 0.001 );
    imshow( frame ,  'Parent' , ax ); hold on; pause( 0.001 );
    plot( vent_point( 1 ), vent_point( 2 ), 'bo' , 'MarkerFaceColor' , 'b' , 'Parent' , ax ); pause( 0.001 );
    if( ~isequaln( pixel_height , NaN ) )
        x_contour = 1 : length( pixel_height( : , 1 ) ); y_contour = 1 : length( pixel_height( 1 , : ) );
        [ x_plot , y_plot ] = meshgrid( y_contour, x_contour );
        [ cc , hc ] = contour( x_plot, y_plot, pixel_height, sort( 0 : 500 : 20000 ), 'k' , 'Parent' , ax ); pause( 0.001 );
        clabel( cc , hc ); pause( 0.001 );
    end
	point = drawpoint();
    counter_data = counter_data + 1;
    max_height( counter_data , 1 : 3 ) = min( pixel_height( floor( point.Position( 2 ) ) , floor( point.Position( 1 ) ) ) , max_height_measurable );
    data_t( counter_data ) = ind_frame;
    data_min_pix( counter_data ) = 0;
    type_plume( 1 , counter_data ) = 20;
    close( f_pixelheight );
    if( save_video == 1 )
        frame_video = frame ;
        for i = 1:3
            frame_video( : , : , i ) = double( frame_video( : , : , i ) );
        end
        figure_video = figure( 'visible' , 'off' );
        axes_vs = axes( 'Parent' , figure_video );
        hold( axes_vs , 'on' );
        if( boolean_top == 0 )
            imshow( frame , 'Parent' , axes_vs ); pause( 0.001 );
            cont_a = contour( x_plot, y_plot , pixel_height , [ max_height( counter_data , 1 ) , max_height( counter_data , 1 ) ] , 'r:' , 'LineWidth' , 2 , 'Parent' , axes_vs ); pause( 0.001 );
            for i = 2 : length( cont_a( 1 , : ) )
                frame_video( round( cont_a( 2 , i ) ) , round( cont_a( 1 , i ) ) , : )  = [ 255 0 0 ];
            end
        else
            frame_video( : , : , 1 ) = min( 255 , frame_video( : , : , 1 ) .* 1.5 );
        end
        close( figure_video );
        writeVideo( new_video , frame_video );
    end
end  
if( ~isequaln( pixel_height , NaN ) )
    vent_height = min( pixel_height( : ) );
else
    vent_height = NaN;
end
if( save_video == 1 )
    close( new_video );
end
procedure_plot( data_t , data_min_pix , max_height , vent_height , frame_step , length( files_names ) , type_plume , 1 , save_video );

function [ frame_gray , frame_l , frame_b , mean_frame_l , mean_frame_a , mean_frame_b , mean_frame_red , mean_frame_green , mean_frame_blue , dark_mask ] = process_frame( frame )

global prctile_dark
global threshold_blue_dark
global vent_point
global threshold_dark
global fixed_mask

frame_gray = rgb2gray( frame ); frame_gray = imadjust( frame_gray );
frame_lab = rgb2lab( frame );
frame_l = squeeze( frame_lab( : , : , 1 ) );
frame_a = squeeze( frame_lab( : , : , 2 ) );
frame_b = squeeze( frame_lab( : , : , 3 ) );
frame_red = squeeze( frame( : , : , 1 ) );
frame_green = squeeze( frame( : , : , 2 ) );
frame_blue = squeeze( frame( : , : , 3 ) );
mean_frame_l = mean( frame_l( fixed_mask == 1 ) );
mean_frame_a = mean( frame_a( fixed_mask == 1 ) );
mean_frame_b = mean( frame_b( fixed_mask == 1 ) );
mean_frame_red = mean( frame_red( fixed_mask == 1 ) );
mean_frame_green = mean( frame_green( fixed_mask == 1 ) );
mean_frame_blue = mean( frame_blue( fixed_mask == 1 ) );
if( mean_frame_b < -5 )
    frame_blue_rel = double( frame_blue ) ./ ( 1e-10 + double( frame_red + frame_green + frame_blue ) ) .* fixed_mask;
    for i = 1 : length( frame_blue_rel( 1 , : ) )
    	max_rel = prctile( frame_blue_rel( : , i ), prctile_dark );
    	if( max_rel > 0 )
    		frame_blue_rel( : , i ) = frame_blue_rel( : , i ) ./ max_rel;
    	end
    end
    dark_mask = zeros( size( frame_gray ) );
    dark_mask( frame_blue_rel < threshold_dark & frame_blue < threshold_blue_dark ) = 1;
    dark_mask = procedure_lines( dark_mask , vent_point );
    dark_mask = procedure_isolated( dark_mask , fixed_mask );
    dark_mask = procedure_lines( dark_mask , vent_point );
else
    dark_mask = zeros( size( frame_gray ) );
    dark_mask( frame_gray < 220 & frame_blue < 140 ) = 1;
    dark_mask = procedure_lines( dark_mask , vent_point );
end

function procedure_plot( data_t , data_min_pix , max_height , vent_height , frame_step , total_frames , type_plume , save_input , save_video )

global current_path

if( save_input == 1 )
    button = questdlg( 'Do you want to save results?' , 'Save results?' , 'Yes' , 'No' , 'Yes' );
    if( strcmpi( button , 'Yes' ) )
        results_name = inputdlg( '' , 'File name' , [ 1 100 ] , {'Default_Results'} );
        if( ~isempty( results_name ) )
            save( fullfile( current_path , 'Results' , results_name{ 1 } ) , 'data_t' , 'data_min_pix' , 'max_height' , 'vent_height' , 'frame_step' , 'total_frames' , 'type_plume' );
            uiwait( msgbox( 'Results saved successfully.' ) );
        else
            uiwait( msgbox( 'Results were not saved.' ) );
        end
    end
end
sure = min( type_plume > 5 , std( max_height , [] , 2 )' < 50 );
outliers = isoutlier( max_height  , 'movmedian' , 5 );
outliers = find( outliers == 1 );
no_outliers = setdiff( 1 : length( data_t ) , outliers );
compare_val = [];
while true
    changes = ( max_height( no_outliers( 2 : end ) ) - max_height( no_outliers( 1 : end - 1 ) ) ) ./ ( data_t( no_outliers( 2 : end ) ) - data_t( no_outliers( 1 : end - 1 ) ) );
    changes = min( [ 0 abs( changes ) ], [ abs( changes ) 0 ] );
    if( isempty( compare_val ) )
        compare_val = 10 * median( changes( changes ~= 0 ) );
    end
    [ max_changes, ind_changes ] = max( changes );
    if( max_changes > compare_val )
        no_outliers = setdiff( no_outliers , no_outliers( ind_changes ) );
    else
        break
    end
end
outliers = isoutlier( max_height( no_outliers ) , 'movmedian' , 5 );
outliers = find(outliers == 1 );
no_outliers = setdiff( no_outliers , no_outliers( outliers ) );
data_t = ( data_t( no_outliers ) - 1 ) .* frame_step ./ 60;
sure = sure( no_outliers );
if( min( isnan( data_min_pix( no_outliers ) ) ) == 1 )
	uiwait( msgbox( 'Only no procesable frames are present.' ) ); return;
end
figure_results = figure;
set( figure_results , 'units' , 'normalized' , 'outerposition' , [ 0 0 1 1 ] );
t_all_video = ( 0 : total_frames ) .* frame_step ./ 60;
if( ~isequaln( vent_height , NaN ) )        
    max_height = max_height( no_outliers );
    height_all_video = interp1( data_t , max_height , t_all_video, 'linear' , 'extrap' );
    plot( data_t , max_height , 'k.' , 'MarkerSize' , 10 ); xlabel( 'Time (min)' ); ylabel( 'Height (m)' ); ylim( 1000.*[ 0 floor( max( max_height ) ./ 1000 + 2 ) ] ); grid on; title( 'Plume Height' ); xlim( [ 0 max( t_all_video ) ] );
    hold on; 
    plot( data_t , max_height - vent_height , 'r.' , 'MarkerSize' , 10 );
    plot( data_t( sure ) , max_height( sure ) , 'kx' , 'MarkerSize' , 10 ); 
    plot( data_t( sure ) , max_height( sure ) - vent_height , 'rx' , 'MarkerSize' , 10 ); 
    plot( t_all_video , height_all_video , 'k--' );
    plot( t_all_video , height_all_video - vent_height  , 'r--' );
    legend( 'Above sea level' , 'Above vent' );
else
    data_min_pix = data_min_pix( no_outliers );
    data_min_pix_all_video = interp1( data_t , data_min_pix , t_all_video, 'linear' , 'extrap' );
    plot( data_t, data_min_pix , 'k.' , 'MarkerSize' , 30 ); xlabel( 'Time (min)' ); ylabel( 'Pixels above vent' ); ylim( 100 .* [max( 0 , floor( min( data_min_pix ) ./ 100 - 1 ) ) floor( max( data_min_pix ) ./ 100 + 1 ) ] ); grid on; xlim( [ 0 max( t_all_video ) ] );
    hold on;
    plot( t_all_video , data_min_pix_all_video , 'k--' ); 
end

function [ output_1 , output_2 , output_3 , output_4 ] = procedure_plot_comparison( data_input , index , N , input_1 , input_2 , input_3 , input_4 , data_legend )

outliers = isoutlier( data_input.max_height  , 'movmedian' , 5 );
outliers = find( outliers == 1 );
no_outliers = setdiff( 1 : length( data_input.data_t ) , outliers );
t_all_video = ( 0 : data_input.total_frames ) .* data_input.frame_step ./ 60;
compare_val = [];
while true
	changes = ( data_input.max_height( no_outliers( 2 : end ) ) - data_input.max_height( no_outliers( 1 : end - 1 ) ) ) ./ ( data_input.data_t( no_outliers( 2 : end ) ) - data_input.data_t( no_outliers( 1 : end - 1 ) ) );
    changes = min( [ 0 abs( changes ) ], [ abs( changes ) 0 ] );
    if( isempty( compare_val ) )
        compare_val = 10 * median( changes( changes ~= 0 ) );
    end
	[ max_changes, ind_changes ] = max( changes );
    if( max_changes > compare_val )
        no_outliers = setdiff( no_outliers , no_outliers( ind_changes ) );
    else
        break
    end
end
outliers = isoutlier( data_input.max_height( no_outliers ) , 'movmedian' , 5 );
outliers = find(outliers == 1 );
no_outliers = setdiff( no_outliers , no_outliers( outliers ) );
data_input.data_t = ( data_input.data_t( no_outliers ) - 1 ) .* data_input.frame_step ./ 60;
if( isempty( data_input.data_min_pix( no_outliers ) ) )
	disp( 'Only no procesable frames are present.' ); return;
end
if( ~isequaln( data_input.vent_height , NaN ) )
    max_height = data_input.max_height( no_outliers );
    height_all_video = interp1( data_input.data_t , max_height , t_all_video, 'linear' , 'extrap' );
    h1 = plot( data_input.data_t , max_height , '.' , 'MarkerSize' , 10 , 'HandleVisibility' , 'off' ); 
    nextcolor = get( h1 , 'color' );
    if( index == 1 )
        xlabel( 'Time (min)' ); ylabel( 'Height (m a.s.l.)' ); grid on; title( 'Plume Height' ); hold on; 
        output_1 = max( t_all_video );
        output_2 = 1000 .* floor( max( max_height ) ./1000 + 2 );
        output_3 = input_3; output_4 = input_4;
    else
        output_1 = max( max( t_all_video ) , input_1 );
        output_2 = max( 1000 .* floor( max( max_height ) ./1000 + 2) , input_2 );
        output_3 = input_3; output_4 = input_4;
    end
    plot( t_all_video , height_all_video , '--' , 'Color' , nextcolor , 'LineWidth' , 2 );
    if( index == N )
        for i = 1:length( data_legend )
            data_legend{ i } = strrep( data_legend{ i }, '_' , ' ' );
            data_legend{ i } = strrep( data_legend{ i }, '.mat' , '' );
        end
        xlim( [ 0 output_1 ] ); ylim( [ 0 output_2]  ); legend( data_legend );
    end
else
    data_min_pix = data_input.data_min_pix( no_outliers );
    data_min_pix_all_video = interp1( data_input.data_t , data_min_pix , t_all_video , 'linear' , 'extrap' );
    h1 = plot( data_input.data_t , data_min_pix , '.' , 'MarkerSize' , 30 , 'HandleVisibility' , 'off' ); 
    nextcolor = get( h1 , 'color' );
    if( index == 1 )
        hold on; xlabel( 'Time (min)' ); ylabel( 'Pixels above vent' );
        output_1 = max( t_all_video );
        output_2 = max( 0 , 100 .* ( floor( min( data_min_pix ) ./ 100 ) ) );
        output_3 = 100 .* floor( max( data_min_pix ) ./ 100 + 1 );
        output_4 = input_4;
    else
        output_1 = max( max( t_all_video ) , input_1 );
        output_2 = min( max( 0 , 100 .* floor( min( data_min_pix ) ./ 100 ) ) , input_2 );
        output_3 = max( 100 .* ( floor( max( data_min_pix ) ./ 100 + 1 ) ) , input_3 );
        output_4 = input_4;
    end
    plot( t_all_video , data_min_pix_all_video , '--' , 'Color' , nextcolor , 'LineWidth' , 2); 
    sure = intersect( find( type_plume > 5 ) , find( std( max_height , [] , 2 ) < 50 ) );
    plot( t_all_video( sure ) , data_min_pix_all_video( sure ) , '.' , 'Color' , nextcolor , 'MarkerSize' , 100 , 'HandleVisibility' , 'off' ); 
    if( index == N )
        for i = 1:length( data_legend )
            data_legend{i} = strrep( data_legend{ i }, '_' , ' ' );
            data_legend{i} = strrep( data_legend{ i }, '.mat' , '' );
        end
        xlim( [ 0 output_1 ] ); ylim( [ output_2 output_3 ] ); legend( data_legend );
    end
end
