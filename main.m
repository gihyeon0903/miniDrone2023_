clear all;
close;
droneobj = ryze()
cameraObj = camera(droneobj);

stage=0;
stage_pre=0;
targetcenter_notfull=[480 240];%[480 300];
targetcenter_full=[480 260];%[480 240];
targetcenter_circle=[480 220];%낮을수록 원의 아래로 통과
count=0;
stop_count=0;
reverse_th=650000;
figure();hold on;
takeoff(droneobj);
print_on=0;

%% pause(0.5);

% 원하는 높이만큼 띄우는 코드
% dist=readHeight(droneobj); %0.2가 가장 극단적 %1.7
% disp(dist);
% uptarget=1.1-dist;
% 
% if uptarget>=0.2
%     moveup(droneobj,'Distance',uptarget,'WaitUntilDone',true);
% elseif uptarget <= -0.2
%     movedown(droneobj,'Distance',abs(uptarget),'WaitUntilDone',true); 
% end
moveup(droneobj,'Distance',0.9,'WaitUntilDone',true);

%%

% 비행을 위해 바뀌는 변수
margin_notfull=[350,50]; % 가로, 세로
margin_full=[40,40];
margin_circle=[60,60];%[45,45];
hovering=100;
move_ref=[0,0];
convert_pixel2ply=[40,40];
rf=480;
cf=360;
reverseOn=0;
center_in=0;
stage_in=0;
stage_up_count=0;
large_circle_pre=100;
add_go=0;

while(stage<=3)
    if stage_in==0
        disp("previous up count="+stage_up_count);
        [targetcenter_full,targetcenter_notfull,targetcenter_circle]=stage_init(stage,droneobj,targetcenter_full,targetcenter_notfull,targetcenter_circle,stage_up_count);
        stage_up_count=0;
        stage_in=1;
        disp(targetcenter_full);
        disp(targetcenter_notfull);
        center_in=0;
        disp("stage init");
        stage_pre=stage;
        stop_count=0;
        if stage==2
            margin_circle(1)=50;
            margin_circle(2)=45;
        elseif stage==1
            margin_circle(1)=50;
            margin_circle(2)=50;
            margin_notfull(1)=50;
            margin_notfull(2)=50;

        end
    end
    blue_mean_on=0;
    target_on=0;
    count=count+1;

    image=snapshot(cameraObj);
    if(isempty(image))
        disp("next step");
        continue;
    end
    nRows = size(image, 1);
    nCols = size(image, 2);

    image1R = image(:,:,1);
    image1G = image(:,:,2);
    image1B = image(:,:,3);

    image_only_B=image1B-image1R/2-image1G/2;
    bw = image_only_B >58;
    bw = bwareaopen(bw,8000);
    se = strel('disk',8);
    bw_mopology= imerode(bw,se); 
    bw_mopology = imdilate(bw_mopology,se);
    
    bw_fill=logical(zeros(720,960));%bw;
    bw_fill(:,:)=0;
    bw_show=bw;
    circle_sensitivity=0.98;

    if (~isempty(bw))
        if stage==0
            circle_sensitivity=0.97;
        end
        [centers,radii]=imfindcircles(bw,[100,400],"ObjectPolarity","dark","Sensitivity",circle_sensitivity);
        
    end
    centerIdx=1;
    find_circle=0;
    if (~isempty(radii))
        [centerIdx, cf,rf,find_circle,large_circle_pre]=detect_circle(centers,radii,large_circle_pre);
    end    

    
    % if (length(row_fill) > reverse_th && length(col_fill) > reverse_th)
    %     blue_full=1;
    % else
    %     blue_full=0;
    %     % bw_show=bw_fill;
    % end

    if find_circle==1
        % [move_ref,rf,cf,center_in]=goWhere(row_fill,col_fill,targetcenter_notfull,convert_pixel2ply,margin_notfull);
        [move_ref,center_in]=goWhere_circle(rf,cf,targetcenter_circle,convert_pixel2ply,margin_circle);
        if mean(abs(move_ref))
            move(droneobj, [0 move_ref(2)*0.2 -move_ref(1)*0.2],"WaitUntilDone",true,"Speed",0.1);
            move_ref(1)=0;
            move_ref(2)=0;
            stop_count=0;
        else
            stop_count=stop_count+1;
        end
    else
        blue_mean_on=1;
        stats = regionprops(bw_mopology);   
        centerIdx=1;
        if(~isempty(stats)) 
            target_on=1;
            bw_fill=bw_fill_rectangle(bw_fill,stats,centerIdx);
            [row_fill, col_fill] = find(bw_fill);
            [move_ref,rf,cf,center_in]=goWhere(row_fill,col_fill,targetcenter_notfull,convert_pixel2ply,margin_notfull);
            
            if stage==0
                move_ref(2)=0.0;
            end
            if mean(abs(move_ref))
                move(droneobj,[0 move_ref(2)*0.2 -move_ref(1)*0.2],"WaitUntilDone",true,"Speed",0.1);
                move_ref(1)=0;
                move_ref(2)=0;
                stop_count=0;
            else
                stop_count=stop_count+1;
            end
        end
    end

    if stop_count>2
        move(droneobj,[0 0 -0.2],"WaitUntilDone",true,"Speed",0.1);
    end
%         
    if center_in
        stage=goThroughCircle(droneobj,stage);
        stage_in=0;
    end
    
    if print_on==1
        imshow(bw_show);
        viscircles([cf,rf],3,'Color','red');
        
        
        if (~isempty(centers)) && find_circle==1
            rectangle("Position",[targetcenter_circle(1)-margin_circle(1), ...
                targetcenter_circle(2)-margin_circle(2), ...
                margin_circle(1)*2 ,margin_circle(2)*2 ],'EdgeColor','b',"LineWidth",4);
            if numel(radii)==1
                viscircles(centers,radii);
            else
                viscircles(centers(centerIdx,:),radii(centerIdx,:));
            end
        end   
        
        if blue_mean_on==1 && (~isempty(stats)) 
            rectangle('Position', stats(centerIdx).BoundingBox, ...
                'Linewidth', 3, 'EdgeColor', 'g', 'LineStyle', '--');
            rectangle("Position",[targetcenter_notfull(1)-margin_notfull(1), ...
                targetcenter_notfull(2)-margin_notfull(2), ...
                margin_notfull(1)*2 ,margin_notfull(2)*2 ],'EdgeColor','b',"LineWidth",4);
        end
            
            % rectangle("Position",[targetcenter_full(1)-margin_full(1), ...
            %     targetcenter_full(2)-margin_full(2), ...
            %     margin_full(1)*2 ,margin_full(2)*2 ],'EdgeColor','g',"LineWidth",4);
        
        image_n="./ply_image/step"+count+".png";
        saveas(gcf,image_n);
    end
end

while(stage==4)
    if stage_in==0
        [targetcenter_full,targetcenter_notfull,targetcenter_circle]=stage_init(stage,droneobj,targetcenter_full,targetcenter_notfull,targetcenter_circle,stage_up_count);
        stage_in=1;
        disp(targetcenter_full);
        disp(targetcenter_notfull);
        center_in=0;
        stop_count=0;
    end
    count=count+1;
    image=snapshot(cameraObj);
    if(isempty(image))
        disp("next step");
        continue;
    end
    nRows = size(image, 1);
    nCols = size(image, 2);

    image1R = image(:,:,1);
    image1G = image(:,:,2);
    image1B = image(:,:,3);

    image_only_B=image1B-image1R/2-image1G/2;
    bw = image_only_B >63;
    bw_fill=logical(zeros(720,960));%bw;
    % bw_fill(:,:)=0;
    bw_show=bw;

    
    
    if (~isempty(bw))
        [centers,radii]=imfindcircles(bw,[100,400],"ObjectPolarity","dark","Sensitivity",0.98);
    end
    centerIdx=1;
    find_circle=0;
    if (~isempty(radii))
        [centerIdx, cf,rf,find_circle,large_circle_pre]=detect_circle(centers,radii,large_circle_pre);
    end
    go=0;
    if find_circle==1
        [move_ref,center_in]=goWhere_circle(rf,cf,targetcenter_notfull,convert_pixel2ply,margin_notfull);
        if mean(abs(move_ref))
            move(droneobj, [0 move_ref(2)*0.2 -move_ref(1)*0.2],"WaitUntilDone",true,"Speed",0.1);
          
        end
        
        
        if radii(centerIdx)> 200 && radii(centerIdx) < 227
            stage=stage+1;
            stage_in=0;
        elseif radii(centerIdx) >= 227
            go=-1;
        else
            go=1;
        end
        stop_count=0;
    else
        stop_count=stop_count+1;
    end

    if stop_count>2
        move(droneobj,[0.2 0 0.2],"WaitUntilDone",true,"Speed",0.1);
        stop_count=0;
    end

    if center_in
        if go==1
            moveforward(droneobj,'WaitUntilDone',true,'distance',0.25);
        else
            moveback(droneobj,'WaitUntilDone',true,'distance',0.21);
        end
        % move(droneobj, [go*0.2 0 0],"WaitUntilDone",true,"Speed",1);
    end


    % 
    % if (length(row_fill) > reverse_th && length(col_fill) > reverse_th)
    %     blue_full=1;
    % else
    %     blue_full=0;
    %     % bw_show=bw_fill;
    % end
    % 
    % if blue_full==0 && target_on==1
    %     [move_ref,rf,cf,center_in]=goWhere(row_fill,col_fill,targetcenter_notfull,convert_pixel2ply,margin_notfull);
    % elseif blue_full==1
    % 
    %     reverseOn=1;
    %     bw=~bw;
    % 
    %     bw = imerode(bw,se); %밖으로 미는것
    %     % bw = imdilate(bw,se); %안으로 미는것
    % 
    %     [row, col] = find(bw);
    %     [move_ref,rf,cf,center_in]=goWhere(row,col,targetcenter_full,convert_pixel2ply,margin_full);
    % 
    % 
    %     bw_show=bw;
    % end
    
%         
    
    
    if print_on==1
        imshow(bw_show);
        if (~isempty(centers)) && find_circle==1
            if numel(radii)==1
                viscircles(centers,radii);
            else
                viscircles(centers(centerIdx,:),radii(centerIdx,:));
            end
        end     
        viscircles([cf,rf],3,'Color','red');
        
        rectangle("Position",[targetcenter_notfull(1)-margin_notfull(1), ...
            targetcenter_notfull(2)-margin_notfull(2), ...
            margin_notfull(1)*2 ,margin_notfull(2)*2 ],'EdgeColor','b',"LineWidth",4);
      
        image_n="./ply_image/step"+count+".png";
        saveas(gcf,image_n);
    end

end

while(stage==5)

    disp("stage=5");
    land(droneobj);
    % abort(droneobj);
end

function [centerIdx, cf,rf,find_circle,large_circle_pre]=detect_circle(centers,radii,large_circle_pre)
    centerIdx=1;
    find_circle=1;
    for i = 1:numel(radii)
        if radii(i)>radii(centerIdx)
            centerIdx=i;
        end 
    end
    if numel(radii)==1
        cf=centers(1);
        rf=centers(2);
    else
        cf=centers(centerIdx,1);
        rf=centers(centerIdx,2);
    end
    if abs(large_circle_pre-radii(centerIdx))>50
        find_circle=0;
    end
    large_circle_pre=radii(centerIdx);
    disp("large_circle_pre ="+large_circle_pre);
    disp("large radii="+radii(centerIdx));
end

function bw_fill=bw_fill_rectangle(bw_fill,stats,centerIdx)
    for i = 1:numel(stats)
        if stats(i).Area>stats(centerIdx).Area
            centerIdx=i;
        end
    end
    

    stat_int=uint16(stats(centerIdx).BoundingBox);
    bw_fill(stat_int(2):stat_int(2)+stat_int(4),stat_int(1):stat_int(1)+stat_int(3))=1;
end


function [move_ref,center_in]=goWhere_circle(rf,cf,targetcenter,convert_pixel2ply,margin)
    
    error_r=rf-targetcenter(2);
    error_c=cf-targetcenter(1);
    move_ref(1)=0;
    move_ref(2)=0;
    center_r=0;
    center_c=0;
    center_in=0;
    if abs(error_r)>margin(2) %위아래 판단, 에러가 특정 margin 밖에 있을 때
        if error_r>0
            disp('down');
            move_ref(1)=-1;
            center_r=0;
        else
            disp('up');
            move_ref(1)=1;
            center_r=0;
        end
    else
        disp('stop up down');
        center_r=1;
        % UDIn_notfull=UDIn_notfull+1;
    end
    
    if abs(error_c)>margin(1) %양옆 판단, 에러가 특정 margin 밖에 있을 때
        if error_c>0
            disp('right');
            move_ref(2)=1;
            center_c=0;
        else
            disp('left');
            move_ref(2)=-1;
            center_c=0;
        end
    else
        disp('stop right left');
        center_c=1;
        % RLIn_notfull=RLIn_notfull+1;
    end

    if center_c && center_r
        center_in=1;
    end
end

function [move_ref,rf,cf,center_in]=goWhere(row,col,targetcenter,convert_pixel2ply,margin)
    rf=mean(row);
    cf=mean(col);
    %viscircles([cf rf],3);

    error_r=rf-targetcenter(2);
    error_c=cf-targetcenter(1);
    move_ref(1)=0;
    move_ref(2)=0;
    center_r=0;
    center_c=0;
    center_in=0;
    if abs(error_r)>margin(2) %위아래 판단, 에러가 특정 margin 밖에 있을 때
        if error_r>0
            disp('down');
            move_ref(1)=-1;
            center_r=0;
        else
            disp('up');
            move_ref(1)=1;
            center_r=0;
        end
    else
        disp('stop up down');
        center_r=1;
        % UDIn_notfull=UDIn_notfull+1;
    end
    
    if abs(error_c)>margin(1) %양옆 판단, 에러가 특정 margin 밖에 있을 때
        if error_c>0
            disp('right');
            move_ref(2)=1;
            center_c=0;
        else
            disp('left');
            move_ref(2)=-1;
            center_c=0;
        end
    else
        disp('stop right left');
        center_c=1;
        % RLIn_notfull=RLIn_notfull+1;
    end

    if center_c && center_r
        center_in=1;
    end
end

function stage=goThroughCircle(droneobj,stage)
    switch stage
        case 0
            moveforward(droneobj,'WaitUntilDone',true,'distance',2.6,'Speed',1);
        case 1
            moveforward(droneobj,'WaitUntilDone',true,'distance',2.6,'Speed',1);
        case 2
            moveforward(droneobj,'WaitUntilDone',true,'distance',2.1,'Speed',1);
        case 3
            moveforward(droneobj,'WaitUntilDone',true,'distance',0.7,'Speed',1);
        otherwise
            disp("other");
    end
    disp("moveforward");
    stage=stage+1;
    
end

function [targetcenter_full,targetcenter_notfull,targetcenter_circle]=stage_init(stage,droneobj,targetcenter_full,targetcenter_notfull,targetcenter_circle,stage_up_count)
    switch stage
        case 0
            moveback(droneobj,'WaitUntilDone',true,'distance',0.7);
        case 1
            turn(droneobj,deg2rad(90));
            moveback(droneobj,'WaitUntilDone',true,'distance',0.6);
            if(stage_up_count>2)
                move(droneobj, [0 0 0.4],"WaitUntilDone",true,"Speed",0.1);
            end
            targetcenter_notfull(1)=480;
            targetcenter_notfull(2)=260;
        case 2
            turn(droneobj,deg2rad(90));
            moveback(droneobj,'WaitUntilDone',true,'distance',0.6);
        case 3
            turn(droneobj,deg2rad(45));
            moveforward(droneobj,'WaitUntilDone',true,'distance',1);
        case 4
            targetcenter_notfull(1)=480;
            targetcenter_notfull(2)=240;
        otherwise
            disp("other");
    end
        
end
