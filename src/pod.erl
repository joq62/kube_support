%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : 
%%% ToDo 
%%% 1. New cluster
%%% 2. Check existing cluster -> restart missing node vms
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(pod).    
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("kube_logger.hrl").
%%---------------------------------------------------------------------
%% Records & defintions
%%---------------------------------------------------------------------
%missing clusters
%running clusters

%% --------------------------------------------------------------------

-export([new_node/4,
	 create_node/3,
	 create_node/7,  
	 delete_node/1
	]).

%% ====================================================================
%% External functions
%% ====================================================================  
new_node(Alias,NodeName,PodDir,Cookie)->
    Result=case db_host_info:read(Alias) of
	       []->
		     {error,[eexist,Alias,?FUNCTION_NAME,?MODULE,?LINE]};
	       [{Alias,HostId,_Ip,_SshPort,_UId,_Pwd}]->
		   case create_node(Alias,NodeName,Cookie) of
		       {error,Reason}->
			   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]};
		       {ok,Pod,HostId,Ip,SshPort}->
			   case rpc:call(Pod,file,make_dir,[PodDir],5*1000) of
			       {error,Reason}->
				   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]};
			       ok->
				   case db_pod:create(Pod,PodDir,[],HostId,{date(),time()}) of
				       {atomic,ok}->
					   case container:load_start("support",Pod) of
					       {ok,_}->
						   {ok,Pod};
					        {Error,Reason}->
						   {Error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]}
					   end;
				       Error ->
					   {error,[Error,?FUNCTION_NAME,?MODULE,?LINE]}
				   end
			   end
		   end
	   end,
    Result.
				       
   


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Creates a slave node via HostNode 
%% NodeName=pod_microseconds_clusterId_HostId
%% PodDir=clusterId/pod_microseconds
%% AppDir=PodDir/AppId
%% AppPa=AppDir/ebin
%% Returns: non
%% --------------------------------------------------------------------
delete_node(Node)->
    rpc:call(Node,init,stop,[],5*1000).

create_node(Alias,NodeName,Cookie)->
    [{Alias,HostId,Ip,SshPort,UId,Pwd}]=db_host_info:read(Alias),
    ErlCallArgs="-c "++Cookie++" "++"-sname "++NodeName,
    Node=list_to_atom(NodeName++"@"++HostId),    
    true=erlang:set_cookie(Node,list_to_atom(Cookie)),
    true=erlang:set_cookie(node(),list_to_atom(Cookie)),
    Result=create_node(Ip,SshPort,UId,Pwd,HostId,NodeName,ErlCallArgs),
    Result.

create_node(Ip,SshPort,UId,Pwd,HostId,NodeName,ErlCallArgs)->    
    ErlCmd="erl_call -s "++ErlCallArgs, 
    SshCmd="nohup "++ErlCmd++" &",
    ErlCallResult=rpc:call(node(),my_ssh,ssh_send,[Ip,SshPort,UId,Pwd,SshCmd,3*5000],4*5000),
    Result=case ErlCallResult of
	       {badrpc,timeout}->
		   ?PrintLog(ticket,"Failed to start node",[Ip,SshPort,UId,Pwd,NodeName,ErlCallArgs,badrpc,timeout,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,[{badrpc,timeout},Ip,SshPort,UId,Pwd,NodeName,ErlCallArgs,?FUNCTION_NAME,?MODULE,?LINE]};
	       {error,Reason}->
		   ?PrintLog(ticket,"Failed to start node",[Ip,SshPort,UId,Pwd,NodeName,ErlCallArgs,error,Reason,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,[Reason,?FUNCTION_NAME,?MODULE,?LINE]};
	       StartResult->
		   Node=list_to_atom(NodeName++"@"++HostId),
		   case node_started(Node) of
		       true->
			  % ?PrintLog(debug,"  {atomic,ok}",[ClusterAddResult,Node,HostId,?FUNCTION_NAME,?MODULE,?LINE]),
			   {ok,Node,HostId,Ip,SshPort};
		       false->
			   ?PrintLog(ticket,"Failed to connect to node",[Ip,SshPort,UId,Pwd,HostId,NodeName,ErlCallArgs,?FUNCTION_NAME,?MODULE,?LINE]),
			   {error,["Failed to connect to node",Ip,SshPort,UId,Pwd,HostId,NodeName,ErlCallArgs,?MODULE,?FUNCTION_NAME,?LINE]}
		   end
	   end,
    Result.
		   
	      
node_started(Node)->
    check_started(50,Node,10,false).
    
check_started(_N,_Vm,_SleepTime,true)->
   true;
check_started(0,_Vm,_SleepTime,Result)->
    Result;
check_started(N,Vm,SleepTime,_Result)->
 %   io:format("net_Adm ~p~n",[net_adm:ping(Vm)]),
    NewResult= case net_adm:ping(Vm) of
	%case rpc:call(node(),net_adm,ping,[Vm],1000) of
		  pong->
		     true;
		  pang->
		       timer:sleep(SleepTime),
		       false;
		   {badrpc,_}->
		       timer:sleep(SleepTime),
		       false
	      end,
    check_started(N-1,Vm,SleepTime,NewResult).

