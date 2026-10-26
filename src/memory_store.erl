-module(memory_store).
-export([start/0, store/1, set/3, get/2, clear/2]).

start() ->
    spawn(memory_store, store, [#{}]).

store(State) ->
    receive
        {set, Key, Value} ->
            NewState = store_map:set(State, Key, Value),
            store(NewState);
        {get, Key, CallerPid} ->
            CallerPid ! store_map:get(State, Key),
            store(State);
        {remove, Key, CallerPid} ->
            case maps:find(Key, State) of
                {ok, _Value} ->
                    NewState = store_map:remove(State, Key),
                    CallerPid ! ok,
                    store(NewState);
                error ->
                    CallerPid ! not_found,
                    store(State)
            end
    end.

set(Pid, Key, Value) ->
    Pid ! {set, Key, Value}.

get(Pid, Key) ->
    Pid ! {get, Key, self()},
    receive
        Result ->
            Result
    end.

clear(Pid, Key) ->
    Pid ! {remove, Key, self()},
    receive
        Result ->
            Result
    end.
