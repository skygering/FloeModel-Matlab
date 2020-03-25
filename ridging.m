function [Floe1,Floe2,dissolvedNEW]= ridging(dissolvedNEW,Floe1,Floe2,Nx,Ny,c2_boundary_poly,PERIODIC)
%% 
floe1 = Floe1;
floe2 = Floe2;
Lx= max(c2_boundary_poly.Vertices(:,1));
Ly= max(c2_boundary_poly.Vertices(:,2));%c2 must be symmetric around x=0 for channel boundary conditions.
x=[-1 -1 1 1 -1]*Lx*2; 
y=[-1 1 1 -1 -1]*Ly*2;
polybound = polyshape(x,y);
c2_poly = subtract(polybound,c2_boundary_poly);
if isempty(Floe1.SubFloes)
    SUBFLOES = true;
    potentialInteractions = Floe1.potentialInteractions;
    Floe1 = initialize_floe_values(Floe1.poly, SUBFLOES);
    Floe1.potentialInteractions = potentialInteractions;
elseif isempty(Floe2.SubFloes)
    SUBFLOES = true;
    potentialInteractions = Floe2.potentialInteractions;
    Floe2 = initialize_floe_values(Floe2.poly, SUBFLOES);
    Floe2.potentialInteractions = potentialInteractions;
end
poly1 = union([Floe1.SubFloes.poly]);
poly2 = union([Floe2.SubFloes.poly]);
if area(subtract(Floe1.poly,poly1))/area(Floe1.poly) > 0.15
    polynew = subtract(Floe1.poly,poly1);
    polyout = sortregions(polynew,'area','descend');
    R = regions(polyout);
    polynew = R(1);
    Floe1.SubFloes(length(Floe1.SubFloes)+1).poly = rmholes(polynew);
    Floe1.SubFloes(length(Floe1.SubFloes)).h = mean(cat(1,Floe1.SubFloes.h));
    poly1 = union([Floe1.SubFloes.poly]);
elseif area(subtract(Floe2.poly,poly2))/area(Floe2.poly) > 0.15
    polynew = subtract(Floe2.poly,poly2);
    polyout = sortregions(polynew,'area','descend');
    R = regions(polyout);
    polynew = R(1);
    Floe2.SubFloes(length(Floe2.SubFloes)+1).poly = rmholes(polynew);
    Floe2.SubFloes(length(Floe2.SubFloes)).h = mean(cat(1,Floe2.SubFloes.h));
    poly2 = union([Floe2.SubFloes.poly]);
end

Hmin1 = min(cat(1,Floe1.SubFloes.h));
Hmin2 = min(cat(1,Floe2.SubFloes.h));

polyout = intersect(poly1,poly2);
areaPoly = area(polyout);
aPoly = area(intersect(Floe1.poly,Floe2.poly));
rho_ice=920;
rho_l = 997;
E = max([Floe1.E, Floe2.E]);
sigma_m = max([Floe1.sigma_m, Floe2.sigma_m]);
nu = 0.29;
g = 9.81;
hc = 2;%14.2*(1-nu^2)/(rho_l*g)*sigma_m^2/E;
disolved = 0;

%check to make sure one floe is not inside the other
if aPoly/area(Floe1.poly)>0.9
    dissolvedNEW = dissolvedNEW+calc_vol_dissolved(Floe1,Nx,Ny,c2_boundary_poly);
    disolved = 1;
    Floe1.alive = 0;
elseif aPoly/area(Floe2.poly)>0.9
    dissolvedNEW = dissolvedNEW+calc_vol_dissolved(Floe2,Nx,Ny,c2_boundary_poly);
    disolved = 1;
    Floe2.alive = 0;
end
%% 

if disolved == 0 && areaPoly > 500
    kk=1;
    V1 = 0; V2 = 0;
    A1 = 0; A2 = 0;
    for ii = 1:length(Floe1.SubFloes)
        if area(intersect(polyout,Floe1.SubFloes(ii).poly))>0
            V1 = V1 + area(intersect(polyout,Floe1.SubFloes(ii).poly)); 
            A1 = A1 + area(Floe1.SubFloes(ii).poly); 
            overlap1(kk) = ii;kk = kk+1; 
        end
    end
    kk = 1;
    for ii = 1:length(Floe2.SubFloes)
        if area(intersect(polyout,Floe2.SubFloes(ii).poly))>0
            V2 = V2 + area(intersect(polyout,Floe2.SubFloes(ii).poly))*Floe2.SubFloes(ii).h; 
            A2 = A2 + area(Floe2.SubFloes(ii).poly); 
            overlap2(kk) = ii; kk = kk+1; 
        end
    end
    Floe1.h = mean(cat(1,Floe1.SubFloes(overlap1).h));
    Floe2.h = mean(cat(1,Floe2.SubFloes(overlap2).h));
    if Floe1.h>= hc && Floe2.h >= hc
        p=1/(1+Floe1.h/Floe2.h);
        if rand(1)>= p
            [Floe1, Floe2] = ridge_values_update(Floe1,Floe2, overlap1, overlap2, V2, A1);
        else
            [Floe2, Floe1] = ridge_values_update(Floe2,Floe1, overlap2, overlap1, V1, A2);
        end
    elseif Floe1.h>= hc && Floe2.h< hc
        [Floe1, Floe2] = ridge_values_update(Floe1,Floe2, overlap1, overlap2, V2, A1);
    elseif Floe1.h < hc && Floe2.h >= hc
        [Floe2, Floe1] = ridge_values_update(Floe2,Floe1, overlap2, overlap1, V1, A2);
    end
end

if ~PERIODIC
    poly1 = union([Floe1.SubFloes.poly]);
    Abound = area(intersect(poly1,c2_poly));
    Ainbound = area(subtract(poly1,c2_poly));
    kk = 1;
    V1 = 0; 
    for ii = 1:length(Floe1.SubFloes)
        if area(intersect(c2_poly,Floe1.SubFloes(ii).poly))>0
            V1 = V1 + area(intersect(c2_poly,Floe1.SubFloes(ii).poly))*Floe1.SubFloes(ii).h;
            overlap(kk) = ii;kk = kk+1; 
        end
    end
    if Ainbound < 1000
        Floe1.alive = 0;
    elseif Abound>0 && Ainbound >= 1000
        [poly1new] = subtract(Floe1.poly,c2_poly);
        polyout = sortregions(poly1new,'area','descend');
        R = regions(polyout);
        poly1new = R(1);
        Floe1.area = area(poly1new);
        Floe1.h = Floe1.h+V1/Floe1.area;
        Floe1.poly = poly1new;
        [Xi,Yi] = centroid(poly1new);
        Floe1.Xi = Xi;
        Floe1.Yi = Yi;
        alive = ones(1,length(Floe1.SubFloes));
        for ii = 1:length(overlap)
            [poly1] = subtract(Floe1.SubFloes(overlap(ii)).poly,c2_poly);
            if area(poly1) < 10
                alive(overlap(ii)) = 0;
            else
                polyout = sortregions(poly1,'area','descend');
                R = regions(polyout);
                poly1 = R(1);
                poly1 = rmholes(poly1);
                Floe1.SubFloes(overlap(ii)).poly = poly1;
                Floe1.SubFloes(overlap(ii)).h = Floe1.SubFloes(overlap(ii)).h + V1/Floe1.area;
            end
        end
        Floe1.SubFloes(alive == 0) = [];
        Nw = length(Floe1.SubFloes);
        areaS = zeros(Nw,1);
        inertia = zeros(Nw,1);
        centers = zeros(Nw,2);
        for ii = 1:Nw
            areaS(ii) = area(Floe1.SubFloes(ii).poly);
            inertia(ii) = PolygonMoments(Floe1.SubFloes(ii).poly.Vertices,Floe1.SubFloes(ii).h);
            [Xi,Yi] = centroid(Floe1.SubFloes(ii).poly);
            centers(ii,:) = [Xi,Yi];
        end
        Floe1.Xm = sum(rho_ice*areaS.*cat(1,Floe1.SubFloes.h).*centers(:,1))./Floe1.mass;
        Floe1.Ym = sum(rho_ice*areaS.*cat(1,Floe1.SubFloes.h).*centers(:,2))./Floe1.mass;
        Floe1.rmax = sqrt(max(sum((poly1new.Vertices' - [Floe1.Xi; Floe1.Yi]).^2,1)));
        Floe1.inertia_moment = sum(inertia+cat(1,Floe1.SubFloes.h).*sqrt((centers(:,1)-Floe1.Xm).^2+(centers(:,2)-Floe1.Ym).^2));
    end
end

if length(Floe1.poly.Vertices) > 500
    Floe1 = FloeSimplify(Floe1, 250);
elseif length(Floe2.poly.Vertices) > 500
    Floe2 = FloeSimplify(Floe2, 250);
end


end