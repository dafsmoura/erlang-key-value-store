-module(store_map).
-export([set/3, get/2, remove/2]).


set(Map, Key, Value) -> 
    Map#{Key => Value}.

get(Map, Key) ->
    Result = maps:find(Key, Map),
    case Result of
        {ok, Value} -> Value;
        error -> not_found
    end.

remove(Map, Key) ->
    maps:remove(Key, Map).