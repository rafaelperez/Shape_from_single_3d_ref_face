function [ l ] = estimate_lighting( n, alb, im,nComp,talk,is_ambient,non_lin,eye_mask )
%ESTIMATE_LIGHTING etimate lighting spherical harmonic coefficients given
%the normal map and input image
%
% Syntax:
%       estimate_lighting( n, alb, im,nComp,talk,is_ambient,non_lin )
%
%   im must be grayscale n must be of dimensions same as image with 3rd
%   dimension having 3 slices containing nx,ny,nz

if nargin<4
    nComp = 4;
end
if nargin<5
    talk = 0;
end
if nargin<6
    is_ambient = 1;
end
if nargin<7
    non_lin = 1;
end
if nargin<8
    eye_mask = ones(size(im));
end
if talk
    rad = im./alb;
    
    figure;imagesc(rad);
    title('Radiosity (image / albedo)')
end
im = im2double(im);


a0 = pi;
a1 = 2*pi/sqrt(3);
a2= 2*pi/sqrt(8);

c0 =    sqrt(1  /(4*pi));
c1 =    sqrt(3  /(4*pi));
c2 = 3* sqrt(5  /(12*pi));

nx = n(:,:,1);
nx = nx(:)';        %change to row vector
ny = n(:,:,2);
ny = ny(:)';
nz = n(:,:,3);
nz = nz(:)';

Y = [   a0*c0*     ones(size(nx));
        a1*c1*     nx;
        a1*c1*     ny;
        a1*c1*     nz;
        a2*c2*     nx.*ny;
        a2*c2*     nx.*nz;
        a2*c2*     ny.*nz;
       a2*c2/2*    (nx.^2 - ny.^2);
  a2*c2/(12)^.5*   (3*nz.^2-1) ];

% pick 1st 4 coefficients and remove nan values
im2 = im;
eye_mask_v = (eye_mask(:)'==1);
Y = Y(1:nComp,~isnan(nx) & eye_mask_v & ~isnan(alb(:)'));
%vectorize image as row vector and remove nan values
im = im(:);
alb = alb(:);
im = im(~isnan(nx) & eye_mask_v & ~isnan(alb'))';
alb = alb(~isnan(nx) & eye_mask_v & ~isnan(alb'))';

bad = im<0.01 | im>0.9 | alb< 0.01;
% bad = [];
im(bad) = [];
alb(bad) = [];
Y(:,bad) = [];
%account for brdf
rho = ones(size(im));
radiosity = im./rho./alb;

if ~is_ambient
    l = radiosity * pinv(Y(2:end,:));
    l(2:end+1) = l(1:end);
    l(1) = 0;
else
    if non_lin==1
        A = [-1;zeros(size(Y,1)-1,1)]';
        b = 0;
        fval = [];l = [];
        for i=1:3
            init =[0; rand(size(Y,1)-1,1)];
            [l(:,end+1),fval(end+1)]=fmincon(@(x)cost_est_l(x,radiosity,Y),init,A,b);
        
        end
        [~,ind] = min(fval);
        l = l(:,ind);
        l = l';
    elseif non_lin==2
        init =rand(size(Y,1),1);
        options = optimset('Display','Iter-Detailed','Algorithm','trust-region-reflective');
        l = lsqnonlin(@(x)cost_est_l_max(x,radiosity,Y),init,[],[],options);
        l = l';
%         cost = cost_est_l_max(l',radiosity,Y);
%         im3 = zeros(size(n,1),size(n,2));
%         c = zeros(size(n,1),size(n,2));
%         c(~isnan(n(:,:,1))) = cost.^2;
%         im3(~isnan(n(:,:,1))) = l*Y;
    else
        l = radiosity * pinv(Y);
    end
end
l(10) = 0;
l(10) = [];
l = l'.* [a0*c0; a1*c1; a1*c1; a1*c1;  a2*c2; a2*c2; a2*c2; a2*c2/2; a2*c2/(12)^.5 ];

l = double(l);
end

