function numInter = calc_collisionNum(Floe)

numInter=cat(1,Floe.interactions);
if ~isempty(numInter)
    % SG: for interactions between floes divide by 2 since they will be double
    % counted and add all for interactions between boundaries
    numInter=size(numInter(numInter(:,1)<Inf,1),1)/2+size(numInter(numInter(:,1)==Inf,1),1);
    
else
    numInter=0;
end

end

