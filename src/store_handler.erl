-module(store_handler).
-export([init/2]).

init(Req, [StorePid]) ->
    Method = cowboy_req:method(Req),
    case Method of
        <<"GET">> ->
            handle_get(Req, StorePid);
        <<"PUT">> ->
            handle_put(Req, StorePid);
        <<"DELETE">> ->
            handle_delete(Req, StorePid);
        _ ->
            Req2 = cowboy_req:reply(
                405, 
                #{<<"content-type">> => <<"text/plain">>, <<"allow">> => <<"GET, PUT, DELETE">>},
                <<"Method Not Allowed">>,
                Req
            ),
            {ok, Req2, StorePid}
    end.


handle_get(Req, StorePid) ->
    Key = binary_to_list(cowboy_req:binding(key, Req)), %% :binding return a binary key, such as <<"name">>
    Value = memory_store:get(StorePid, Key),
    case Value of
        {error, timeout} ->
            Req2 = cowboy_req:reply(
                503, 
                #{<<"content-type">> => <<"text/plain">>},
                <<"Service Unavailable">>,
                Req
            ),
            {ok, Req2, StorePid};
        not_found ->
            Req2 = cowboy_req:reply(
                404, 
                #{<<"content-type">> => <<"text/plain">>},
                <<"Not Found">>,
                Req
            ),
            {ok, Req2, StorePid};
        Value ->
            Body = list_to_binary("key=" ++ Key ++ "\nvalue=" ++ Value),
            Req2 = cowboy_req:reply(
                200, 
                #{<<"content-type">> => <<"text/plain">>},
                Body,
                Req
            ),
            {ok, Req2, StorePid}
    end.

handle_put(Req, StorePid) ->
    Key = binary_to_list(cowboy_req:binding(key, Req)),
    {ok, Body, Req2} = cowboy_req:read_body(Req),
    ValueToStore = binary_to_list(Body),
    Value = memory_store:set(StorePid, Key, ValueToStore),
    case Value of
        ok ->
            Req3 = cowboy_req:reply(
                204, 
                #{},
                <<>>,
                Req2
            ),
            {ok, Req3, StorePid};
        {error, timeout} ->
            Req3 = cowboy_req:reply(
                503, 
                #{<<"content-type">> => <<"text/plain">>},
                <<"Service Unavailable">>,
                Req2
            ),
            {ok, Req3, StorePid}
    end.

handle_delete(Req, StorePid) ->
    Key = binary_to_list(cowboy_req:binding(key, Req)), %% :binding return a binary key, such as <<"name">>
    Value = memory_store:clear(StorePid, Key),
    case Value of
        ok ->
            Req2 = cowboy_req:reply(
                204, 
                #{},
                <<>>,
                Req
            ),
            {ok, Req2, StorePid};
        {error, timeout} ->
            Req2 = cowboy_req:reply(
                503, 
                #{<<"content-type">> => <<"text/plain">>},
                <<"Service Unavailable">>,
                Req
            ),
            {ok, Req2, StorePid};
        not_found ->
            Req2 = cowboy_req:reply(
                404, 
                #{<<"content-type">> => <<"text/plain">>},
                <<"Not Found">>,
                Req
            ),
            {ok, Req2, StorePid}
    end.