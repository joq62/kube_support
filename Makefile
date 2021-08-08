all:
#	service
	rm -f ebin/*;
	erlc -I ../interfaces -o ebin src/*.erl;
	rm -rf src/*.beam *.beam  test_src/*.beam test_ebin;
	rm -rf  *~ */*~  erl_cra*;
	rm -rf *_specs *_config *.log;
	rm -rf support etcd catalog cluster_config host_config;
	echo Done
doc_gen:
	echo glurk not implemented
test_10_unit_test:
	rm -rf test_10_ebin;
	rm -rf src/*.beam *.beam test_src/*.beam test_ebin;
	rm -rf  *~ */*~  erl_cra*;
	mkdir test_10_ebin;
#	interface
	erlc -I ../interfaces -o test_10_ebin ../interfaces/*.erl;
#	support
	rm -rf support;
	erlc -I ../interfaces -o test_10_ebin ../support/src/*.erl;
#	etcd
	cp ../applications/etcd/src/*.app test_10_ebin;
	erlc -I ../interfaces -o test_10_ebin ../kube_dbase/src/*.erl;
	erlc -I ../interfaces -o test_10_ebin ../applications/etcd/src/*.erl;
#	iaas
	erlc -I ../interfaces -o test_10_ebin src/*.erl;
#	test application
	mkdir test_ebin;
	cp test_src/*.app test_ebin;
	erlc -I ../interfaces -o test_ebin test_src/*.erl;
	erl -pa test_10_ebin -pa test_ebin\
	    -setcookie test_10_cookie\
	    -sname iaas_test_10\
	    -unit_test monitor_node iaas_test_10\
	    -unit_test cluster_id test_10\
	    -unit_test start_host_id c1_varmdo\
	    -run unit_test start_test test_src/test.config
