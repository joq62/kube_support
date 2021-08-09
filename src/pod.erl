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
-export([
       	 create/1,
	 delete/1,
       	 create/2,
	 delete/2,
	 load_start/2,
	 load_start/3
	 
	]).


%% ====================================================================
%% External functions
%% ====================================================================  
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Creates a slave node via HostNode 
%% NodeName=pod_microseconds_clusterId_HostId
%% PodDir=pod_microseconds_clusterId
%% AppDir=PodDir/AppId
%% AppPa=AppDir/ebin
%% Returns: non
%% --------------------------------------------------------------------
load_start(AppId,Reference)->
    load_start(AppId,Reference,worker_nodes).
load_start(AppId,Reference,Type)->
    Result=case [{XReference,PodNode,PodDir,HostNode,WantedHostId}||{XReference,PodNode,PodDir,HostNode,WantedHostId}<-db_cluster:read(Type),
								   Reference==XReference]of
	       []->
		   ?PrintLog(ticket," Reference eexists",[Reference,Type,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,["Reference eexists",Reference,Type,?FUNCTION_NAME,?MODULE,?LINE]};
	       [{Reference,PodNode,_PodDir,_HostNode,_WantedHostId}]->
		   RunningApps=rpc:call(PodNode,application,which_applications,[],3*1000),
		   case lists:keymember(list_to_atom(AppId),1,RunningApps) of
		       true->
			   ?PrintLog(log,"already started",[AppId,PodNode,Reference,Type,?FUNCTION_NAME,?MODULE,?LINE]),
			   {error,['already started',AppId,PodNode]};
		       false ->
			   glurk
		   end
	   end,
    Result.
		   %check if app already loaded 
		   %clone the app
		   %start app
		   %check if started 
		   %


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Creates a slave node via HostNode 
%% NodeName=pod_microseconds_clusterId_HostId
%% PodDir=pod_microseconds_clusterId
%% AppDir=PodDir/AppId
%% AppPa=AppDir/ebin
%% Returns: non
%% --------------------------------------------------------------------
create(WantedHostId)->
    create(WantedHostId,worker_nodes).
create(WantedHostId,Type)->
    Result=case [HostNode||{HostNode,HostId}<-db_cluster:read(host_nodes),
			   HostId==WantedHostId] of
	       []->
		   ?PrintLog(ticket,"WantedHost eexists",[WantedHostId,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,["WantedHost eexists",WantedHostId,?FUNCTION_NAME,?MODULE,?LINE]};
	       [HostNode]->
		   CookieAtom=db_cluster:read(cookie),
		   ClusterId=db_cluster:read(cluster_id),
		   SystemTime=integer_to_list(erlang:system_time(microsecond)),
		   NodeName="pod_"++SystemTime++"_"++ClusterId++"_"++WantedHostId,
		   PodDir="pod_"++SystemTime++"_"++ClusterId,
		   Reference=PodDir,
		   Args="-setcookie "++atom_to_list(CookieAtom),
		   rpc:call(HostNode,os,cmd,["rm -rf "++PodDir],5*1000),
		   ok=rpc:call(HostNode,file,make_dir,[PodDir],5*1000),
		   {ok,PodNode}=rpc:call(HostNode,slave,start,[WantedHostId,NodeName,Args],5*1000),
		   {atomic,ok}=db_cluster:add(Type,{Reference,PodNode,PodDir,HostNode,WantedHostId}),
		   {ok,Reference}
	   end,
    Result.

delete(DeleteReference)->
    delete(DeleteReference,worker_nodes).
delete(DeleteReference,Type)->
    Result=case [{Reference,PodNode,PodDir,HostNode,WantedHostId}||{Reference,PodNode,PodDir,HostNode,WantedHostId}<-db_cluster:read(Type),
			 Reference==DeleteReference]of
	       []->
		   ?PrintLog(ticket,"PodNode eexists",[DeleteReference,Type,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,["WantedHost eexists",DeleteReference,Type,?FUNCTION_NAME,?MODULE,?LINE]};
	       [{Reference,PodNode,PodDir,HostNode,WantedHostId}]->
		   rpc:call(HostNode,os,cmd,["rm -rf "++PodDir],2*1000),
		   rpc:call(HostNode,slave,stop,[PodNode],2*1000),
		   {atomic,ok}=db_cluster:remove(Type,{Reference,PodNode,PodDir,HostNode,WantedHostId}),
		   ok
	   end,
    Result.
		   

