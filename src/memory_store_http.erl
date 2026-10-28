-module(memory_store_http).
-export([start/1]).

start(Pid) ->
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/health", health_handler, []},
            {"/store/:key", store_handler, [Pid]}
        ]}
    ]),

    cowboy:start_clear(memory_store_listener, [{port, 8080}], #{
        env => #{dispatch => Dispatch}
    }).