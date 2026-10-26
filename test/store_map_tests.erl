-module(store_map_tests).
-include_lib("eunit/include/eunit.hrl").

set_test() ->
    Map = #{},
    ResultMap = store_map:set(Map, "Key1", "Value1"),
    ?assertEqual(#{"Key1" => "Value1"}, ResultMap).

get_existing_key_test() ->
    Map = #{},
    ResultMap = store_map:set(Map, "Key1", "Value1"),
    ?assertEqual("Value1", store_map:get(ResultMap, "Key1")).

get_missing_key_test() ->
    Map = #{},
    ResultMap = store_map:set(Map, "Key1", "Value1"),
    ?assertEqual(not_found, store_map:get(ResultMap, "Key2")).

remove_existing_key_test() ->
    Map = #{},
    ResultMap = store_map:set(Map, "Key1", "Value1"),
    EmptyMap = store_map:remove(ResultMap, "Key1"),
    ?assertEqual(#{}, EmptyMap).