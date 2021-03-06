

function passivewalker(flag)  

clc
clear all
close all
format long
global check;


    
    %% c = COM on the leg from hip, w = COM fore-aft offset, r = radius of feet
    %% M = hip mass, m = leg mass, I = leg inertia, l = leg length
  
    walker.M = 10000; walker.m = 1.0; walker.I = 0.00; walker.l = 1.0; walker.w = 0.0; 
    walker.c = 1.0;  walker.r = 0.0; walker.g = 1.0; walker.gam = 0.016; 
    

    %%%% Initial State %%%%%
    q1 = 0.2; % theta
    u1 = -0.2; % theta_dot
    q2 = 0.4; % phi
    u2 = -0.3; % phi_dot

    z0 = [q1 u1 q2 u2];
   
    %zstar = [0.200161072169750  -0.199906060087682   0.400322144339512  -0.015805473227965];


%%%%%%%%%%%%%%%%%%%%%%%%%
steps = 100; %number of steps to animate
fps = 10; 



options = optimset('TolFun',1e-10,'TolX',1e-10,'Display','off');
[zstar,fval,exitflag] = fsolve(@fixedpt,z0,options,walker);
if exitflag == 1
    disp('Fixed point:');
    disp(zstar);
else
    error('Root finder not converged, change guess or change system parameters')
end



 %zstar=[0.243326370662233  -0.238229075514881 0.486652741324536  -0.027657628719873];
 

  

tic
[z,t] = onestep(zstar,walker,steps);
toc


disp('Some plots...')
plot(z(:,1),z(:,2))
xlabel('Angle'); ylabel('Vel');
legend('Stance Angle','stance velocity');
title('State  vs time ');


%===================================================================
function zdiff=fixedpt(z0,walker)
%===================================================================
zdiff=onestep(z0,walker)-z0; 


%===================================================================
function [z,t]=onestep(z0,walker,steps)
%===================================================================
global check;
M = walker.M;  m = walker.m; I = walker.I;   
l = walker.l;  c = walker.c; w = walker.w;   
r = walker.r;  g = walker.g; gam = walker.gam;

flag = 1;
if nargin<2
    error('need more inputs to onestep');
elseif nargin<3
    flag = 0; 
    steps = 1;
end

q1 = z0(1);
u1 = z0(2);
q2 = z0(3);
u2 = z0(4);

    
    
z0 = [q1 u1 q2 u2 ];

t0 = 0; 
dt = 5; 
time_stamps = 100;
t_ode = t0;
z_ode = z0;

for i=1:steps
    check=i;
    options=odeset('abstol',1e-12,'reltol',1e-12,'events',@collision);
    tspan = linspace(t0,t0+dt,time_stamps);
    [t_temp, z_temp, TE, YE, IE] = ode45(@single_stance,tspan,z0,options,walker);
    
    zplus=heelstrike(t_temp(end),z_temp(end,:),walker); 
    
    z0 = zplus;
    if i==steps
    z0(1:4);
    end
    t0 = t_temp(end);
    
    
    t_ode = [t_ode; t_temp(2:end)];
    z_ode = [z_ode; z_temp(2:end,:)];
    
end

z = zplus(1:4);

if flag==1
   z=z_ode;
   t=t_ode;
end

%===================================================================
function zdot=single_stance(t,z,walker)  
%===================================================================
global check;
q1 = z(1);   u1 = z(2);                         
q2 = z(3);   u2 = z(4);                         
                   

M = walker.M;  m = walker.m; I = walker.I;   
l = walker.l;  c = walker.c; w = walker.w;   
r = walker.r;  g = walker.g; gam = walker.gam;

if check >= 91
Th=0.0250*q2;    %torque              
elseif check >=90
    Th=0.0025*q2;
else
    Th=0;

end 

M11 = -2*m*c^2-2*m*l^2-M*l^2+2*m*l*c-2*m*r^2-M*r^2+2*m*r*c*cos(q1-q2)-2*M*r*l*cos(q1)-4*m*r*l*cos(q1)+2*m*r*c*cos(q1); 
M12 = -m*l*c*cos(q2)+m*c^2-m*r*c*cos(q1-q2); 

M21 = +m*l*c*cos(q2)+m*r*c*cos(q1-q2)-m*c^2; 
M22 = +m*c^2; 

RHS1 = -2*m*r*u1*u2*c*sin(q1-q2)+m*r*u1^2*w*cos(q1)+m*r*u1^2*c*sin(q1)-2*m*r*l*sin(q1)*u1^2+M*g*sin(gam)*r+m*r*u2^2*c*sin(q1-q2)+m*r*u1^2*c*sin(q1-q2)-M*r*l*sin(q1)*u1^2+M*g*l*sin(gam-q1)+2*m*g*l*sin(gam-q1)-m*g*c*sin(gam-q1)-m*g*c*sin(gam-q1+q2)-m*l*u2^2*c*sin(q2)+2*m*l*u1*u2*c*sin(q2); 
RHS2 = -m*g*c*sin(gam-q1+q2)-Th+m*l*u1^2*c*sin(q2); 

MM = [M11 M12;                               
     M21 M22];                               

RHS = [RHS1; RHS2];                       

X = MM \ RHS;                                    

ud1 = X(1);                                       
ud2 = X(2);                                       



zdot = [u1 ud1 u2 ud2 ...           
       ]';  

%===================================================================
function [gstop, isterminal,direction]=collision(t,z,walker)
%===================================================================

M = walker.M;  m = walker.m; I = walker.I;   
l = walker.l;  c = walker.c; w = walker.w;   
r = walker.r;  g = walker.g; gam = walker.gam; 

q1 = z(1); q2 = z(3); 

gstop = -q2 + 2*q1;
if (q2>-0.05) %allow legs to pass 
    isterminal = 0;
else
    isterminal=1; %ode should terminate 
end
direction=-1; 

%===================================================================
function zplus=heelstrike(t,z,walker)      
%===================================================================

r1 = z(1);   v1 = z(2);                         
r2 = z(3);   v2 = z(4);                         
                       

q1 = r1 - r2;                         
q2 = -r2;                                       

M = walker.M;  m = walker.m; I = walker.I;   
l = walker.l;  c = walker.c; w = walker.w;   
r = walker.r;  g = walker.g; gam = walker.gam; 

M11 = 2*m*l^2-2*m*l*c+2*m*c^2+2*m*w^2+2*m*r^2+4*m*r*l*cos(q1)-2*m*r*c*cos(q1)*r-2*m*l*c*cos(q2)-2*m*r*c*cos(q1-q2)+M*l^2+2*M*r*l*cos(q1); 
M12 = m*l*c*cos(q2)-m*c^2+m*r*c*cos(q1-q2); 

M21 = -m*l*c*cos(q2)+m*c^2-m*r*c*cos(q1-q2); 
M22 = -m*c^2; 

RHS1 = m*l*v2*c-m*c^2*v2+M*v1*r^2-2*m*c*l*v1+M*v1*l^2*cos(r2)+2*m*l^2*v1*cos(r2)+2*I*v1-I*v2+2*m*v1*r^2-2*m*l*v1*c*cos(r2)+2*m*c^2*v1+M*r*v1*l*cos(r1)+M*l*cos(-r1+r2)*v1*r-2*m*r*v1*c*cos(r1)+2*m*l*cos(-r1+r2)*v1*r+2*m*r*v1*l*cos(r1)-2*m*r*v1*c*cos(-r1+r2)+m*r*v2*c*cos(-r1+r2); 
RHS2 = -m*r*v1*c*cos(r1)+I*v1-I*v2-m*c*l*v1+m*c^2*v1; 

MM = [M11 M12;                               
     M21 M22];    

RHS = [RHS1; RHS2];                      

X = MM \ RHS;                                    

u1 = X(1);                                       
u2 = X(2);                                      

 
q1
zplus = [q1 u1 q2 u2 ];                     



