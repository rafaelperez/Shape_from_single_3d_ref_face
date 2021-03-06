clear variables
% close all
import plot3D_helper.label_axis


%% set initial variables
fusion_path = '.\data\fusion.jpg';
folder_path = '.\data\l_test\';
n = 8;
talk = 0;
cols = 4;

f=figure;hold on
f3d = figure;hold on;

count = 1;
for i=1:n
    impath = [folder_path num2str(i) '.pgm'];
%% make image
im = read_image(impath);
fused = fuse_image_YaleB(fusion_path, im);

%% Run face tracker
landmarks = stasm_tracker_YaleB(fused,talk);
if isempty(landmarks)
    continue;
end

%% Compute pose
Rpose = makehgtform('zrotate',deg2rad(-10))*makehgtform('xrotate',deg2rad(20))*makehgtform('yrotate',deg2rad(10));

[Rpose2, Scale] = compute_pose_YaleB(landmarks, talk, im);
% Rpose  = Rpose2 * Rpose;
% Rpose = makehgtform('scale',[Scale ;1])*Rpose;
% Rpose(1:3,4) = Rpose2(1:3,4);
Rpose = Rpose2*   Rpose;
% Rpose  = Rpose2;
%% generate ref depth map 
ply_path = '.\data\ref_model.ply';
[dmap_ref, n_ref, N_ref] = generate_ref_depthmap(ply_path,Scale, talk, size(im,1), size(im,2), Rpose,im);


%% generate ref albedo
face_database_path = '../datasets/CroppedYale';
talk = 0;
alb_ref = get_ref_albedo_YaleB(face_database_path,landmarks,size(im) , fusion_path, talk);
% alb_ref = ((get_ref_albedo(face_database_path,landmarks, size(im),fusion_path, talk)+0.5).^0.3-0.5);
% alb_ref = alb_ref*0+1;
%% estimate lighting
talk = 0;
l = estimate_lighting(n_ref, alb_ref, im,4);
s = 150;
Rpose = makehgtform('scale',1/s);
% c4 = render_model('./data/sphere.ply',l,talk,Rpose, 1000,1000);
c4 = render_model('./data/sphere.ply',l,talk,Rpose, 1000,1000);
c4_face = render_model_noGL( n_ref, l, alb_ref,talk );
% l = estimate_lighting(n_ref, alb_ref, im,9);
% c9 = render_model('./data/sphere.ply',l,talk,1000,1000);


figure(f)
subplot(3,min(n,cols),count)
imshow(im)
subplot(3,min(n,cols),count+min(n,cols))
imshow(c4)
subplot(3,min(n,cols),count+min(n,cols)*2)
imshow(c4_face)

% subplot(3,n,count+2*n)
% imshow(c9)
drawnow
depth = estimate_depth(N_ref,alb_ref,im,dmap_ref,l,30);
% depth = depth(:,end:-1:1);
% [ n,N_ref, depth_map ] = normal_from_depth( depth );
% c4 = render_model_noGL( n, l, alb_ref,1 );

figure(f3d);
subplot(1,min(n,cols),count)
surf(depth);axis equal
if mod(count,cols)==0 && i<n
    f=figure;
    f3d = figure; hold on;
    count = 0;
end
count = count+1;
end
