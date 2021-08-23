%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(iaas_test).   
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include_lib("eunit/include/eunit.hrl").
%% --------------------------------------------------------------------



%% External exports
-export([start/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
    io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
    io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start pod_0()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=pod_0(),
 %   io:format("~p~n",[{"Stop pod_0()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start host_nodes_0()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=host_nodes_0(),
    io:format("~p~n",[{"Stop host_nodes_0()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start cluster_0()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cluster_0(),
    io:format("~p~n",[{"Stop cluster_0()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start load_app_0()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=load_app_0(),
%    io:format("~p~n",[{"Stop load_app_0()",?MODULE,?FUNCTION_NAME,?LINE}]),

 
%   io:format("~p~n",[{"Start pass_0()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=pass_0(),
%   io:format("~p~n",[{"Stop pass_0()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start pass_1()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=pass_1(),
%    io:format("~p~n",[{"Stop pass_1()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start pass_2()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=pass_2(),
 %   io:format("~p~n",[{"Stop pass_2()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start pass_3()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=pass_3(),
%    io:format("~p~n",[{"Stop pass_3()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start pass_4()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=pass_4(),
  %  io:format("~p~n",[{"Stop pass_4()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start pass_5()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=pass_5(),
  %  io:format("~p~n",[{"Stop pass_5()",?MODULE,?FUNCTION_NAME,?LINE}]),
 
    
   
      %% End application tests
    io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
    io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.




%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
host_nodes_0()->
    {ok,Running,Missing}=host:status_all_hosts(),
    io:format("Running ~p~n",[{Running,?MODULE,?LINE}]),
 %   Cookie="host_nodes_cookie",
 %   WantedHostAlias=["c2_lgh","c0_lgh","asus_lgh"],
    
    [pod:delete_node(Node)||Node<-['s1@c0','s2@c0']],

    NodeName1="s1",
    Cookie1="c1",
    Alias="c0_lgh",
  
    R1=pod:create_node(Alias,NodeName1,Cookie1),
    io:format("create_node 1 ~p~n",[{R1,?MODULE,?LINE}]),
 
   %% Salve 2
    NodeName2="s2",
    Cookie2="c2",
    R2=pod:create_node(Alias,NodeName2,Cookie2),
    io:format("create_node 2 ~p~n",[{R2,?MODULE,?LINE}]),

    [pod:delete_node(Node)||Node<-['s1@c0','s2@c0']],
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
cluster_0()->
   
    % Node1
    UniqueId1=integer_to_list(erlang:system_time(microsecond)), 
    ClusterId="c1",
    NodeName1=UniqueId1++"_"++ClusterId,
    Cookie="c1_cookie",
    Alias0="c0_lgh",
    HostId0="c0",
    Dir1=NodeName1,
    {ok,Pod1}=new_node(Alias0,HostId0,NodeName1,Dir1,Cookie),

    L1=container:load("mymath",Pod1,Dir1),
    io:format("L1 ~p~n",[{L1,?MODULE,?LINE}]),
    S1=container:start(Pod1,"mymath"),
    io:format("S1 ~p~n",[{S1,?MODULE,?LINE}]),
    timer:sleep(200),
    [N1]=sd:get(mymath),
    42=rpc:call(N1,mymath,add,[20,22],5*1000),

    %Node2
    UniqueId2=integer_to_list(erlang:system_time(microsecond)), 
    ClusterId="c1",
    NodeName2=UniqueId2++"_"++ClusterId,
    R2=pod:create_node(Alias0,NodeName2,Cookie),
    io:format("create_node 2 ~p~n",[{R2,?MODULE,?LINE}]),
    {ok,Pod2,_,_,_}=R2,
    Dir2=NodeName2,
    ok=rpc:call(Pod2,file,make_dir,[Dir2],5*1000),
    io:format("list dir node2 ~p~n",[{rpc:call(Pod2,file,list_dir,["."],5*1000),?MODULE,?LINE}]),
   
    %Node3
    UniqueId3=integer_to_list(erlang:system_time(microsecond)), 
    ClusterId="c1",
    NodeName3=UniqueId3++"_"++ClusterId,
    Alias2="c2_lgh",
    HostId2="c2",
    Dir3=NodeName3,
    {ok,Pod3}=new_node(Alias2,HostId2,NodeName3,Dir3,Cookie),
    io:format("list dir node3 ~p~n",[{rpc:call(Pod3,file,list_dir,["."],5*1000),?MODULE,?LINE}]),
    LS2=container:load_start("mymath",Pod3),
    [N3,N2]=sd:get(mymath),
    222=rpc:call(N2,mymath,add,[200,22],5*1000),
    24=rpc:call(N3,mymath,add,[2,22],5*1000),


    NodeList=[{NodeName1,"c0",Dir1},{NodeName2,"c0",Dir2},{NodeName3,"c2",Dir3}],

    io:format("nods() ~p~n",[{nodes(),?MODULE,?LINE}]),
    io:format("sd:all() ~p~n",[{sd:all(),?MODULE,?LINE}]),
    
    [rpc:call(list_to_atom(NodeName++"@"++HostId),os,cmd,["rm -rf "++Dir])||{NodeName,HostId,Dir}<-NodeList],
    [pod:delete_node(list_to_atom(NodeName++"@"++HostId))||{NodeName,HostId,Dir}<-NodeList],
    
    ok.

new_node(Alias,HostId,NodeName,PodDir,Cookie)->
    R=pod:create_node(Alias,NodeName,Cookie),
    io:format("create_node ~p~n",[{R,?MODULE,?LINE}]),
    {ok,Pod,_,_,_}=R,
    ok=rpc:call(Pod,file,make_dir,[PodDir],5*1000),
    io:format("list dir node ~p~n",[{rpc:call(Pod,file,list_dir,["."],5*1000),?MODULE,?LINE}]),
    {atomic,ok}=db_pod:create(Pod,PodDir,[],HostId,{date(),time()}),
    {ok,Pod}.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pod_0()->
    {ok,Running,Missing}=host:status_all_hosts(),
    io:format("Running ~p~n",[{Running,?MODULE,?LINE}]),

    SshPort=22,
    UId="joq62",
    Pwd="festum01",
    % ssh_start
    Node1_IP="192.168.0.202",
    Node1_HostId="c2",
    Node1_NodeName="node1",
    Node1_ErlCallArgs="-c lgh_cookie -sname "++Node1_NodeName,
    pod:delete_node('node1@c2'),
    timer:sleep(1000),
    {ok,Node1, Node1_HostId,Node1_IP,SshPort}=pod:create_node(Node1_IP,SshPort,UId,Pwd,Node1_HostId,Node1_NodeName,Node1_ErlCallArgs),
    pong=net_adm:ping(Node1),

    pod:delete_slave(Node1,list_to_atom("node2"++"@"++Node1_HostId)),
    %% Create slave with out dir
    
    Node2_NodeName="node2",
    HostId="c2",
    ErlArgs="-setcookie lgh_cookie",
    {ok,Node2}=pod:create_slave(Node1,HostId,Node2_NodeName,ErlArgs),
    pong=net_adm:ping(Node2),

    %% Create slave with dir
    
    Node3_NodeName="node3",
    HostId="c2",
    ErlArgs="-setcookie lgh_cookie",
    PodDir3="node3_dir",
    {ok,Node3}=pod:create_slave(Node1,HostId,Node3_NodeName,ErlArgs,PodDir3),
    pong=net_adm:ping(Node3),
    true=rpc:call(Node3,filelib,is_dir,[PodDir3],3*1000),
   
    io:format("nodes() ~p~n",[{nodes(),?MODULE,?LINE}]),
    pod:delete_slave(Node1,list_to_atom("node2"++"@"++Node1_HostId),PodDir3),
    pod:delete_slave(Node1,list_to_atom("node3"++"@"++Node1_HostId),PodDir3),
    pod:delete_node(Node1),
    timer:sleep(1000),

    io:format("nodes() ~p~n",[{nodes(),?MODULE,?LINE}]),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_0()->
    os:cmd("rm -rf pod_*"),
    timer:sleep(3000),
    true=wait_for_cluster(60,1000,false),
    {ok,Ref}=pod:create("joq62-X550CA"),
    timer:sleep(1000),
    io:format("nodes() ~p~n",[{nodes(),?MODULE,?FUNCTION_NAME,?LINE}]),
    
    pod:delete(Ref),
    io:format("nodes() ~p~n",[{nodes(),?MODULE,?FUNCTION_NAME,?LINE}]),
    
    ok.
wait_for_cluster(_N,_Time,true)->
    true;
wait_for_cluster(0,_Time,R)->
    R;
wait_for_cluster(N,T,false) ->
    New=case iaas:status_all_clusters() of
	    {{running,[]},{missing,_}}->
		timer:sleep(T),
		false;
	    {{running,Running},{missing,_}}->
		true
	end,
    wait_for_cluster(N-1,T,New).

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_1()->
    {ok,Ref1}=pod:create("joq62-X550CA"),
    PodSpecId="mymath",
    {ok,_}=pod:load_start("mymath",Ref1),
    timer:sleep(100),
    App=mymath,
    [Node1]=sd:get(App),
    42=rpc:call(Node1,mymath,add,[20,22],2*1000),
    
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_2()->

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_3()->

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_4()->
  
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_5()->
  
    ok.




%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

setup()->

  
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
    cluster:delete("test_10"),
%    application:stop(oam),
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
