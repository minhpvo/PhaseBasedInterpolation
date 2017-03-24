%% Phase Based View Interpolation
% This is a personal reimplementation by Oliver Wang: oliver.wang2@gmail.com
% It is written for clarity and is highly unoptimized.
% Note: see README before using!!!

%%
im1 = (imread('data/frame07.png'));
im2 = (imread('data/frame10.png'));

addpath('matlabPyrTools');
addpath('matlabPyrTools/Mex');

%% parameters
[h,w,l] = size(im1);

% Number of frames to interpolate
params.nFrames = 7;

% Number of orientations in the steerable pyramid (more = more accurate but slower)
params.nOrientations = 8;

% Width of transition region
params.tWidth = 1;

% Steepness of the pyramid (smaller = slower)
params.scale = 0.5^(1/4);

% Maximum allowed shift in radians (larger = more motion, but more artifacts)
params.limit = 0.4;

% Number of levels of the pyramid
params.min_size = 15;
params.max_levels = 23;
params.nScales = min(ceil(log2(min([h w]))/log2(1/params.scale) - ...
    (log2(params.min_size)/log2(1/params.scale))),params.max_levels);

%% Allocate output video
output_video = zeros([h,w,l,params.nFrames],'uint8');

%% Decompose images using steerable pyramid
L = decompose(im1,params);
R = decompose(im2,params);

%% Compute shift corrected phase difference
phase_diff = computePhaseDifference(L.phase, R.phase, L.pind, params);

%% Generate inbetween images
step = 1/(params.nFrames+1);
for f=1:params.nFrames
    alpha = step*f;
    
    % interpolate the pyramid
    inter_pyr = interpolatePyramid(L, R, phase_diff, alpha);
    
    % reconstruct the image from steerable pyramid
    recon_image = reconstructImage(inter_pyr,params,L.pind);
    
    output_video(:,:,:,f) = recon_image;
end

%% Visualize
implay(output_video);

%% Compare to flow (requires computer vision toolbox)
output_flow = zeros([h,w,l,params.nFrames],'uint8');

% compute optical flow
opticalFlow = opticalFlowLK;
estimateFlow(opticalFlow,rgb2gray(im1));
flowObj = estimateFlow(opticalFlow,rgb2gray(im2));
flow = double(cat(3,flowObj.Vx,flowObj.Vy));

% for each timestep, generate the inbetween image
step = 1/(params.nFrames+1);
for f=1:params.nFrames
    alpha = step*f;
    output_flow(:,:,:,f) = im2uint8(frameInterpFlow(im1,im2,flow,alpha));
end

% visualize flow output
implay(output_flow);
