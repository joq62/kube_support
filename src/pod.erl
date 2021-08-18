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
       	 create/4,
	 delete/4,
       	 create/5,
	 delete/5,

	 load/4,
	 start/2,
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
%% PodDir=clusterId/pod_microseconds
%% AppDir=PodDir/AppId
%% AppPa=AppDir/ebin
%% Returns: non
%% --------------------------------------------------------------------
load(WantedPodSpec,HostNode,PodNode,PodDir)->
    AppId=db_pod_spec:app_id(WantedPodSpec),
    LoadedApps=rpc:call(PodNode,application,loaded_applications,[],3*1000),
   % ?PrintLog(debug,"LoadedApps ",[LoadedApps,PodNode,?FUNCTION_NAME,?MODULE,?LINE]),
    Result=case lists:keymember(list_to_atom(AppId),1,LoadedApps) of
	       true->
		   ?PrintLog(log,'Already loaded',[WantedPodSpec,AppId,PodNode,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,['Already loaded',AppId,PodNode]};
	       false ->
		   GitPath=db_pod_spec:git_path(WantedPodSpec),
		   AppDir=filename:join(PodDir,AppId),
		   AppEbin=filename:join(AppDir,"ebin"),
		   App=list_to_atom(AppId),
		   rpc:call(HostNode,os,cmd,["rm -rf "++AppId],5*1000),
		   GitResult=rpc:call(HostNode,os,cmd,["git clone "++GitPath],5*1000),
		   ?PrintLog(log,"GitResult",[PodNode,GitPath,GitResult,?FUNCTION_NAME,?MODULE,?LINE]),
		   MVResult=rpc:call(HostNode,os,cmd,["mv "++AppId++" "++AppDir],5*1000),
		   ?PrintLog(log,"MVResult",[AppId,AppDir,MVResult,?FUNCTION_NAME,?MODULE,?LINE]),
		   true=rpc:call(PodNode,code,add_patha,[AppEbin],2*1000),
		   AppEnv=db_pod_spec:app_env(WantedPodSpec),
		   ok=rpc:call(PodNode,application,set_env,[[{App,AppEnv}]]),		       
		   {ok,[]}
	   end,
    Result.

start(PodNode,WantedPodSpec)->
    App=list_to_atom(db_pod_spec:app_id(WantedPodSpec)),
    Result=case rpc:call(PodNode,application,start,[App],5*1000) of
	       ok->
		   {ok,[App]};
	       {error,{already_started,App}}->
		   {ok,[already_started,App]};
	       {Error,Reason}->
		   {Error,Reason}
	   end,
    Result.

load_start(WantedPodSpec,Reference)->
    ?PrintLog(log,"load_start",[WantedPodSpec,Reference,?FUNCTION_NAME,?MODULE,?LINE]),
    load_start(WantedPodSpec,Reference,worker_nodes).
load_start(WantedPodSpec,Reference,Type)->
    Result=case db_pod:read(Reference) of
	       []->
		%   ?PrintLog(ticket," Reference eexists",[Reference,Type,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,["Reference eexists",Reference,Type,?FUNCTION_NAME,?MODULE,?LINE]};
	       [{Reference,PodNode,PodDir,PodSpecs,HostNode,Created}]->
		   PodLoadResult=rpc:call(node(),pod,load,[WantedPodSpec,HostNode,PodNode,PodDir],5*1000),
		   case PodLoadResult  of
		       {ok,_}->
			   PodstartResult=rpc:call(node(),pod,start,[PodNode,WantedPodSpec],5*1000),
		%	   ?PrintLog(debug,"PodstartResult",[PodstartResult,?FUNCTION_NAME,?MODULE,?LINE]),
			   case PodstartResult of
			       {ok,Reason2}->
				   {atomic,ok}=db_pod:add_spec(Reference,WantedPodSpec),
				   {ok,Reason2};
			       {Error,Reason2}->
				   {Error,Reason2}
			   end;
		       {Error,Reason}->
			   {Error,Reason}
		   end;
	       UnMatched ->
		   ?PrintLog(ticket,"UnMatched",[UnMatched,WantedPodSpec,Reference,?FUNCTION_NAME,?MODULE,?LINE]),
		   {error,[ticket,"unmatched signal",[UnMatched,?FUNCTION_NAME,?MODULE,?LINE]]}
	   end,
    ?PrintLog(log,"load_start, Result=",[Result,WantedPodSpec,Reference,?FUNCTION_NAME,?MODULE,?LINE]),
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
create(WantedHostId,HostNode,ClusterId,Cookie)->
    create(WantedHostId,worker_nodes,HostNode,ClusterId,Cookie).
create(WantedHostId,Type,HostNode,ClusterId,Cookie)->
%    ?PrintLog(debug,"Start Create pod",[WantedHostId,Type,?FUNCTION_NAME,?MODULE,?LINE]),
 %   Result=case [HostNode||{HostNode,HostId}<-db_cluster:read(host_nodes),
%			   HostId==WantedHostId] of
%	       []->
%		   ?PrintLog(ticket,"WantedHost eexists",[WantedHostId,?FUNCTION_NAME,?MODULE,?LINE]),
%		   erlang:exit({"WantedHost eexists",[WantedHostId,?FUNCTION_NAME,?MODULE,?LINE]}),
%		   {error,["WantedHost eexists",WantedHostId,?FUNCTION_NAME,?MODULE,?LINE]};
%	       [HostNode]->
		%   Cookie=db_cluster:read(cookie),
		%   ClusterId=db_cluster:read(cluster_id),
    SystemTime=integer_to_list(erlang:system_time(microsecond)),
    NodeName="pod_"++SystemTime++"_"++ClusterId++"_"++WantedHostId,
    PodDirName="pod_"++SystemTime++"_"++ClusterId,
    PodDir=filename:join(ClusterId,PodDirName),
    Reference=PodDirName,
    Args="-setcookie "++Cookie,
    rpc:call(HostNode,os,cmd,["rm -rf "++PodDir],5*1000),
    ok=rpc:call(HostNode,file,make_dir,[PodDir],5*1000),
    {ok,PodNode}=rpc:call(HostNode,slave,start,[WantedHostId,NodeName,Args],5*1000),
    pong=net_adm:ping(PodNode),
    {atomic,ok}=db_pod:create(Reference,PodNode,PodDir,[],HostNode,{date(),time()}),
						%		   ?PrintLog(debug,"PodNode info",[{Reference,PodNode,PodDir,HostNode,WantedHostId},?FUNCTION_NAME,?MODULE,?LINE]),
    Result={ok,Reference},
	 %  end,
 %   ?PrintLog(debug,"Create pod Result",[Result,WantedHostId,?FUNCTION_NAME,?MODULE,?LINE]),
    Result.

delete(DeleteReference,HostNode,PodNode,PodDir)->
    delete(DeleteReference,worker_nodes,HostNode,PodNode,PodDir).
delete(DeleteReference,Type,HostNode,PodNode,PodDir)->
    rpc:call(HostNode,os,cmd,["rm -rf "++PodDir],2*1000),
    rpc:call(HostNode,slave,stop,[PodNode],2*1000),
    {atomic,ok}=db_pod:delete(DeleteReference),
    Result=ok,
    %Result=case [{Reference,PodNode,PodDir,HostNode,WantedHostId}||{Reference,PodNode,PodDir,HostNode,WantedHostId}<-db_cluster:read(Type),
%			 Reference==DeleteReference]of
%	       []->
%		   ?PrintLog(ticket,"PodNode eexists",[DeleteReference,Type,?FUNCTION_NAME,?MODULE,?LINE]),
%		   {error,["WantedHost eexists",DeleteReference,Type,?FUNCTION_NAME,?MODULE,?LINE]};
%	       [{Reference,PodNode,PodDir,HostNode,WantedHostId}]->
		   
%		   rpc:call(HostNode,os,cmd,["rm -rf "++PodDir],2*1000),
%		   rpc:call(HostNode,slave,stop,[PodNode],2*1000),
%		   {atomic,ok}=db_pod:delete(DeleteReference),
%		   ok
%	   end,
    Result.
		   

