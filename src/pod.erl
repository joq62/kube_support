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
       	 create/1
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
%% AppPa=AppdIR/ebin
%% Returns: non
%% --------------------------------------------------------------------
create(HostNode)->
    ok.
