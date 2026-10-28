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

concurrency_test() ->
    StorePid = memory_store:start(),
    TestPid = self(),
    [
        spawn(fun() -> 
            memory_store:set(StorePid, Number, Number), 
            TestPid ! {done, Number} 
        end) 
        || Number <- lists:seq(1, 20)
    ],
    ?assertEqual(done, wait_for_workers(20)),
    [
        ?assertEqual(Number, memory_store:get(StorePid, Number))
        || Number <- lists:seq(1, 20)
    ].

wait_for_workers(0) ->
    done;
wait_for_workers(N) ->
    receive
        {done, _Number} ->
            wait_for_workers(N-1)
    after 5000 ->
        timeout
    end.
