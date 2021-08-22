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

    io:format("~p~n",[{"Start pod_0()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=pod_0(),
    io:format("~p~n",[{"Stop pod_0()",?MODULE,?FUNCTION_NAME,?LINE}]),

 
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
