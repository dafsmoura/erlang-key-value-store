-module(memory_store_app).
-export([start/0]).

start() ->
    {ok, _} = application:ensure_all_started(cowboy),
    StorePid = memory_store:start(),
    memory_store_http:start(StorePid).