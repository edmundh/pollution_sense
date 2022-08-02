%simple simulation of random walking 'floating' robots sensing pollution
clear

T_sim=500;
N_agents=10;
width_arena=100;
step_size=2; %how big a step is in the random walk

agent_thresholds=zeros(N_agents,1);
agent_thresholds(:,1)=0.5; %start off with identical threshold of 0.5

agent_active=ones(N_agents,1); %indicator 1,0 for whether agent is still active
active_history=ones(T_sim+1,N_agents); %history of whether agents active

agent_positions=zeros(N_agents,2); 
agent_position_history=zeros(T_sim+1,2,N_agents);

%create pollution regions with an associated pollution level - uses
%function file 'circle_coords.m'

N_regions=3; %set this equal to the number of regions named below
region_info=zeros(N_regions,4); %x,y of centre, radius, pollution concentration

%set regions manually but number them sequentially
%region 1
region_info(1,:)=[30,30,10,0.5]; % x,y of centre and radius, pollution concentration
[region1_x,region1_y]=circle_coords(region_info(1,1),region_info(1,2),region_info(1,3));

%region 2
region_info(2,:)=[60,30,10,0.5]; 
[region2_x,region2_y]=circle_coords(region_info(2,1),region_info(2,2),region_info(2,3));


%region 3
region_info(3,:)=[80,80,15,0.8]; 
[region3_x,region3_y]=circle_coords(region_info(3,1),region_info(3,2),region_info(3,3));

%set agent positions. Assume agents are small enough to have 2 in same location

% for a=1:N_agents
% %     agent_positions(a,1)=round(rand()*width_arena);   %for random start
% %     agent_positions(a,2)=round(rand()*width_arena);
% %     agent_position_history(1,1,a)=agent_positions(a,1);
% %     agent_position_history(1,2,a)=agent_positions(a,2);
% end

grid_spacing=1; %set spacing in grid
x=width_arena/2; %bottom left placement of first agent in grid
y=width_arena/2; 
grid_width=floor(sqrt(N_agents)); %the width of the grid

a=1;
for dy=0:grid_width
    for dx=0:grid_width-1

     if a <= N_agents
         
        agent_positions(a,1)=x+dx;
        agent_positions(a,2)=y+dy;

        agent_position_history(1,1,a)=agent_positions(a,1);
        agent_position_history(1,2,a)=agent_positions(a,2);
     
        a=a+1;
        
     end
    
    end
end

% simulation starts

for t=1:T_sim

    for a=1:N_agents

        if agent_active(a)==1
    
                within_arena_check=0;
        
                while within_arena_check == 0 
        
                    agent_step_x=agent_positions(a,1)+round((rand-0.5)*step_size*2); %produces -1,0,+1, 50% chance staying still in x dim
                    agent_step_y=agent_positions(a,2)+round((rand-0.5)*step_size*2);
        
                    if (agent_step_x > width_arena) || (agent_step_y > width_arena) || (agent_step_x < 0) || (agent_step_y <0)
                        within_arena_check=0;
                    else 
                        agent_positions(a,1)=agent_step_x;
                        agent_positions(a,2)=agent_step_y;
                        within_arena_check=1; %new position within arena, break while loop
                    end
                end
        
            agent_position_history(t+1,1,a)=agent_positions(a,1);
            agent_position_history(t+1,2,a)=agent_positions(a,2);
        
            in_pollution=0;
        
            for region=1:N_regions

                region_name_x=strcat('region',num2str(region),'_x'); %pass in the coords of the numbered region
                region_name_y=strcat('region',num2str(region),'_y');

                in_pollution=inpolygon(agent_positions(a,1),agent_positions(a,2),eval(region_name_x),eval(region_name_y));
            
                if in_pollution==1
                    if region_info(region,4) >= agent_thresholds(a)
                        agent_active(a)=0;  % if agent is found to be in any region with a concentration above threshold it is set to inactive
                    end
                end
        
            end
    
        else
            agent_position_history(t+1,1,a)=agent_position_history(t,1,a); % if agent not active copy forward its stationary position
            agent_position_history(t+1,2,a)=agent_position_history(t,2,a);
        end

    active_history(t+1,a)=agent_active(a);

    end
end

clf

%-----Figure to create target & estimate
figure(1)
for region=1:N_regions
    
    hold on
    rectangle('Position',[region_info(region,1)-region_info(region,3),region_info(region,2)-region_info(region,3),region_info(region,3)*2,region_info(region,3)*2],'Curvature',[1 1],...
        'FaceColor',[region_info(region,4),0,0],'LineStyle','none') %redder for higher concentration pollution
end
xlim([0 width_arena]), ylim([0 width_arena])
set(gcf,'color','w')
axis off
F = getframe(gca);
[X, ~] = frame2im(F);
X=imresize(X,[width_arena,width_arena]);
bw_target = imbinarize(rgb2gray(X));

clf

figure(1)
agent_patch_radius=10;

for a=1:N_agents
    if agent_active(a)==0
        hold on
        rectangle('Position',[agent_position_history(end,1,a)-agent_patch_radius,agent_position_history(end,2,a)-agent_patch_radius,agent_patch_radius*2,agent_patch_radius*2],'Curvature',[1 1],...
         'FaceColor','k','LineStyle','none') %redder for higher concentration pollution     
    end
end
xlim([0 width_arena]), ylim([0 width_arena])
set(gcf,'color','w')
axis off
F = getframe(gca);
[X, ~] = frame2im(F);
X=imresize(X,[width_arena,width_arena]);
bw_estimate = imbinarize(rgb2gray(X));

clf

subplot(1,2,1),imshow(bw_target),title('Target')
subplot(1,2,2),imshow(bw_estimate),title('Estimate')

%---- Figure to show agent movement over time
figure(2)
subplot(1,2,1)

%plot pollution patches
for region=1:N_regions
    
    hold on
    rectangle('Position',[region_info(region,1)-region_info(region,3),region_info(region,2)-region_info(region,3),region_info(region,3)*2,region_info(region,3)*2],'Curvature',[1 1],...
        'FaceColor',[region_info(region,4),0,0],'LineStyle','none') %redder for higher concentration pollution
end

%plot agent trajectories & active status
for a=1:N_agents
hold on
plot(agent_position_history(:,1,a),agent_position_history(:,2,a))

    if agent_active(a)==1
        hold on
        plot(agent_position_history(end,1,a),agent_position_history(end,2,a),'ok','MarkerFaceColor','g'); %plot green if no pollution detected and still active
    else
        hold on
        plot(agent_position_history(end,1,a),agent_position_history(end,2,a),'ok','MarkerFaceColor','r'); %plot red if pollution detected and stopped
    end

end

xlim([0 width_arena]), ylim([0 width_arena])
box on 
set(gcf,'color','w')
title('Agent trajectories over time','FontSize',14)

subplot(1,2,2)

plot(1:T_sim+1,sum(active_history,2))
set(gcf,'color','w')
xlabel('Time steps')
ylabel('Number of agents active')
ylim([0 N_agents])
xlim([0 T_sim+1])
title('Number of active agents over time','FontSize',14)

%------- Figure to assess system performance
figure(3)
subplot(2,2,1)
for region=1:N_regions
    
    hold on
    rectangle('Position',[region_info(region,1)-region_info(region,3),region_info(region,2)-region_info(region,3),region_info(region,3)*2,region_info(region,3)*2],'Curvature',[1 1],...
        'FaceColor',[region_info(region,4),0,0],'LineStyle','none') %redder for higher concentration pollution
end

xlim([0 width_arena]), ylim([0 width_arena])
box on 
set(gcf,'color','w')
title('Unknown target environment','FontSize',14)

subplot(2,2,2)
for a=1:N_agents
hold on

    if agent_active(a)==1
        hold on
        plot(agent_position_history(end,1,a),agent_position_history(end,2,a),'ok','MarkerFaceColor','g'); %plot green if no pollution detected and still active
    else
        hold on
        plot(agent_position_history(end,1,a),agent_position_history(end,2,a),'ok','MarkerFaceColor','r'); %plot red if pollution detected and stopped
    end

end
xlim([0 width_arena]), ylim([0 width_arena])
box on 
set(gcf,'color','w')
title('Estimated environment (points)','FontSize',14)

subplot(2,2,3)

agent_patch_radius=10;

for a=1:N_agents
    if agent_active(a)==0
        hold on
        rectangle('Position',[agent_position_history(end,1,a)-agent_patch_radius,agent_position_history(end,2,a)-agent_patch_radius,agent_patch_radius*2,agent_patch_radius*2],'Curvature',[1 1],...
         'FaceColor','k','LineStyle','none') %redder for higher concentration pollution     
    end
end
xlim([0 width_arena]), ylim([0 width_arena])
box on

similarity=jaccard(bw_estimate,bw_target);
title({'Estimated environment (patches)',strcat('Jaccard similarity =',num2str(similarity))},'FontSize',14)

subplot(2,2,4)
histogram(agent_thresholds,20) %20 bins
title('Agent threshold distribution','FontSize',14)
ylabel('Count')
xlabel('Threshold')