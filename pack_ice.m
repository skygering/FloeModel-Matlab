function [floe2,Vd] = pack_ice(Floe,c2_boundary,dhdt,Vd,SUBFLOES, PACKING)
%UNTITLED2 Summary of this function goes here
%% 
id = 'MATLAB:polyshape:tinyBoundaryDropped';
warning('off',id);
floe2 = [];
rho_ice = 920;
[Ny,Nx,~] = size(Vd);
x = min(c2_boundary(1,:)):(max(c2_boundary(1,:))-min(c2_boundary(1,:)))/Nx:max(c2_boundary(1,:));
y = min(c2_boundary(2,:)):(max(c2_boundary(2,:))-min(c2_boundary(2,:)))/Ny:max(c2_boundary(2,:));
y = fliplr(y);
dx = abs(x(2)-x(1));
dy = abs(y(2)-y(1));
[xx,yy] = meshgrid(0.5*(x(1:end-1)+x(2:end)),0.5*(y(1:end-1)+y(2:end)));
xf = cat(1,Floe.Xi);
yf = cat(1,Floe.Yi);
r_max = sqrt((dx/2)^2+(dy/2)^2);
rmax = cat(1,Floe.rmax);
potentialInteractions = zeros(Ny,Nx,length(Floe));
for ii = 1:length(Floe)
    pint = sqrt((xx-xf(ii)).^2+(yy-yf(ii)).^2)-(rmax(ii)+r_max);
    pint(pint>0) = 0;
    pint(pint<0) = 1;
    potentialInteractions(:,:,ii) = pint;
end

%make actual function where i can input dhdt to get value
ramp = @(dhdt) heaviside(dhdt)*dhdt;

%% 

p = rand(1);
if p <ramp(dhdt)
    ii = randi([1, Nx]);
    jj = randi([1, Ny]);
    bound = [x(ii) x(ii) x(ii+1) x(ii+1) x(ii);y(jj) y(jj+1) y(jj+1) y(jj) y(jj)];
    box = polyshape(bound(1,:), bound(2,:));
    poly = intersect(box,[Floe(logical(potentialInteractions(jj,ii,:))).poly]);
    floe.poly = union([poly]);
    floe.poly = subtract(box,floe.poly);
    floe.rmax = r_max;
    if area(floe.poly) > 3500
        [Xi,Yi] = centroid(box);
        floe.Xi = Xi; floe.Yi = Yi;
        N = 50;
        [subfloes,~] = create_subfloes(floe,N,false);
        if ~SUBFLOES
            subfloes = floe.poly;
        end
        for kk = 1:length(subfloes)
            areas(kk) = area(subfloes(kk));
        end
        [~,I] = max(areas);
        floe2 = initialize_floe_values(subfloes(I),SUBFLOES,PACKING);
        Vd(jj,ii,1) = Vd(jj,ii,1)-floe2.h*floe2.area*rho_ice;
        
        if floe2.poly.NumHoles > 0
            xx = 1;
            xx(1) = [1 2];
        end
    end
end

warning('on',id)
end