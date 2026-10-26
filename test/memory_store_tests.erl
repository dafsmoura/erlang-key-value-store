-module(memory_store_tests).
-include_lib("eunit/include/eunit.hrl").

set_get_test() ->
    Pid = memory_store:start(),
    memory_store:set(Pid, "name", "David"),
    Name = memory_store:get(Pid, "name"),
    ?assertEqual("David", Name).

get_missing_key_test() ->
    Pid = memory_store:start(),
    Name = memory_store:get(Pid, "name"),
    ?assertEqual(not_found, Name).

clear_test() ->
    Pid = memory_store:start(),
    memory_store:set(Pid, "name", "David"),
    Response = memory_store:clear(Pid, "name"),
    ?assertEqual(ok, Response),
    Name = memory_store:get(Pid, "name"),
    ?assertEqual(not_found, Name).

independent_stores_test() ->
    Pid1 = memory_store:start(),
    Pid2 = memory_store:start(),
    memory_store:set(Pid1, "name", "David"),
    Name1 = memory_store:get(Pid1, "name"),
    ?assertEqual("David", Name1),
    Name2 = memory_store:get(Pid2, "name"),
    ?assertEqual(not_found, Name2).

get_timeout_test() ->
    Pid = list_to_pid("<0.999.0>"),
    Response = memory_store:get(Pid, "name", 50),
    ?assertEqual({error, timeout}, Response).

monitor_store_down_test() ->
    Pid = memory_store:start(),
    Ref = monitor(process, Pid),
    exit(Pid, kill),
    Result = receive
        {'DOWN', Ref, process, Pid, killed} ->
            ok
    after 1000 ->
        timeout
    end,
    ?assertEqual(ok, Result).