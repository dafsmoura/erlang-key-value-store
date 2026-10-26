-module(memory_store).
-export([start/0, store/1, set/3, get/2, clear/2]).

start() ->
    spawn(memory_store, store, [#{}]).

store(State) ->
    receive
        {set, Key, Value, CallerPid, RequestRef} ->
            NewState = store_map:set(State, Key, Value),
            CallerPid ! {RequestRef, ok},
            store(NewState);
        {get, Key, CallerPid, RequestRef} ->
            CallerPid ! {RequestRef, store_map:get(State, Key)},
            store(State);
        {remove, Key, CallerPid, RequestRef} ->
            case maps:find(Key, State) of
                {ok, _Value} ->
                    NewState = store_map:remove(State, Key),
                    CallerPid ! {RequestRef, ok},
                    store(NewState);
                error ->
                    CallerPid ! {RequestRef, not_found},
                    store(State)
            end
    end.

set(Pid, Key, Value) ->
    RequestRef = make_ref(),
    Pid ! {set, Key, Value, self(), RequestRef},
    receive 
        {RequestRef, ok} ->
            ok
    end.

get(Pid, Key) ->
    RequestRef = make_ref(),
    Pid ! {get, Key, self(), RequestRef},
    receive
        {RequestRef, Result} ->
            Result
    end.

clear(Pid, Key) ->
    RequestRef = make_ref(),
    Pid ! {remove, Key, self(), RequestRef},
    receive
        {RequestRef, Result} ->
            Result
    end.
