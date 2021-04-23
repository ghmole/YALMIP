function Z = jacobiansparsityfromnonlinear(model,includeLinear)

if nargin == 1
    % IPOPT appends linear constraints, and that sparsity structure should
    % thus be included. KNITRO does not append linears to the structure
    includeLinear = 1;
end

m = length(model.lb);
allA=[model.Anonlinineq];
if any(model.K.q)
    top = 1 + model.K.f + model.K.l;
    allQ = [];
    for i = 1:length(model.K.q)
        allQ = [allQ;any(model.F_struc(top:top+model.K.q(i)-1,2:end))];
        top = top + model.K.q(i);
    end
    allA = [allA;allQ];
end
if any(model.K.s)
    top = 1 + model.K.f + model.K.l + sum(model.K.q);
    allQ = [];
    for i = 1:length(model.K.s)
        s = any(model.F_struc(top:top+model.K.s(i)^2-1,2:end));
        allQ = [allQ;repmat(s,model.K.s(i),1)];
        top = top + model.K.s(i)^2;
    end
    allA = [allA;allQ];
end

allA = [allA;model.Anonlineq];
depends = allA | allA;
if length(model.linearindicies) == size(allA,2)
    % It is linear + possibly linear cone
    jacobianstructure = double(depends);
else
    jacobianstructure = spalloc(size(allA,1),m,0);
    for i = 1:size(depends,1)
        vars = find(depends(i,:));
        [ii,vars] = find(model.deppattern(vars,:));
        vars = unique(vars);
        s = size(jacobianstructure,1);
        [~,loc] = ismember(vars,model.linearindicies);
        jacobianstructure(i,loc) = 1;
        %for j = 1:length(vars)
        %    jacobianstructure(i,find(vars(j) == model.linearindicies)) = 1;
        %end
    end
end
if includeLinear
    allA=[model.A; model.Aeq];
    depends = allA | allA;
    jacobianstructure = [jacobianstructure;depends];
end
Z = sparse(jacobianstructure);

