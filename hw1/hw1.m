% 2023 miniDrone

x=[input('x[a b c] 중 a 입력'),input('x[a b c] 중 b 입력'),input('x[a b c] 중 c 입력')]
y=[input('y[a b c] 중 a 입력'),input('y[a b c] 중 b 입력'),input('y[a b c] 중 c 입력')]
z=[input('z[a b c] 중 a 입력'),input('z[a b c] 중 b 입력'),input('z[a b c] 중 c 입력')]

% x=[1,2,3];
% y=[5,6,1];
% z=[1,6,7];

global param
param = ["x,y","y,z","z,x"];

fprintf('유클리디안 거리로 보았을 때 가장 가까운 벡터 = %s\n',find_min_eu_dist_vector(x, y, z))
fprintf('코사인유사도로 보았을 때 가장 유사한 벡터 = %s\n',find_max_cos_sim_vector(x, y, z))


function min_vector=find_min_eu_dist_vector(x,y,z)
    global param
    [min_Euclidean,idx_Euclidean]=min([norm(x-y), norm(y-z), norm(z-x)]);
    min_vector = param(idx_Euclidean);
end

function max_vector=find_max_cos_sim_vector(x, y, z)
    global param
    cos_sim_x_y = cosineSim(x, y);
    cos_sim_y_z = cosineSim(y, z);
    cos_sim_z_x = cosineSim(z, x);
    [max_cos_sim,idx_cos]=max([cos_sim_x_y, cos_sim_y_z, cos_sim_z_x]);
    max_vector = param(idx_cos);
end

function similarity=cosineSim(x,y)
    dot_product = dot(x, y);
    norm_x = norm(x);
    norm_y = norm(y);
    similarity = dot_product / (norm_x * norm_y);
end
