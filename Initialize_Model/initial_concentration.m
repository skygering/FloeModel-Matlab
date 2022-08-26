function [Floe, Nb] = initial_concentration(c2_boundary,target_concentration,height, NumFloes, min_floe_size)
%% This function is used to generate the initial floe field

%Identify the grids to align with the concentrations specified by the input
[Ny, Nx] = size(target_concentration); %Input is 2D matrix of target concentrations
c = flipud(target_concentration);
x = min(c2_boundary(1,:)):(max(c2_boundary(1,:))-min(c2_boundary(1,:)))/Nx:max(c2_boundary(1,:));
y = min(c2_boundary(2,:)):(max(c2_boundary(2,:))-min(c2_boundary(2,:)))/Ny:max(c2_boundary(2,:));
c2_boundary_poly = polyshape(c2_boundary');
dx = x(2)-x(1);
dy = y(2)-y(1);

Nb = 0;
Floe = [];

%Loop through all the regions of the domain to create new floes
for jj = 1:Ny
    for ii = 1:Nx
        if c(jj,ii)>0
            % boundary of each grid box determined by number of
            % target_concentrations provided
            boundary = polyshape([x(ii) x(ii) x(ii+1) x(ii+1)], [y(jj) y(jj+1) y(jj+1) y(jj)]);
            boundary = intersect(boundary,c2_boundary_poly);
            % number of floes to fill grid if target concentration is 1
            N = ceil(NumFloes*area(boundary)/area(c2_boundary_poly)/c(jj,ii));
            % generate N coordinates within grid box
            X = 0.975*dx/2*(2*rand(N,1)-1)+(x(ii)+x(ii+1))/2;
            Y = 0.975*dy/2*(2*rand(N,1)-1)+(y(jj)+y(jj+1))/2;
            in = inpolygon(X,Y,boundary.Vertices(:,1),boundary.Vertices(:,2));
            X = X(in); Y = Y(in);
            % generate voronoi cells based on seed points
            [~, b,~,~,~] = polybnd_voronoi([X Y],boundary.Vertices);
            Nf = 1:length(b);
            Atot = 0;
            count = 1;
            % add cells to floe list while concentration is less that
            % desired
            while Atot/area(boundary)<=c(jj,ii)
                disp(Nf(count))
                if ~isnan(b{Nf(count)})
                    poly = polyshape(b{Nf(count)});
                    floenew = initialize_floe_values(poly,height);
                    Floe = [Floe floenew];
                    Atot = Atot+area(poly);
                end
                count = count+1;
                % if we run out of floes, stop! 
                if count > length(Nf)
                    Atot = area(boundary)+1;
                end
            end
        end
    end
end

areas = cat(1,Floe.area);
Floe(areas<min_floe_size)=[];
end

