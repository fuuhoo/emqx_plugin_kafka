-module(emqx_plugin_kafka_hook).

-include_lib("emqx/include/emqx.hrl").
-include_lib("emqx/include/emqx_hooks.hrl").
-include_lib("emqx/include/logger.hrl").
-include("emqx_plugin_kafka.hrl").



-export([
    hooks/3
    , unhook/0
]).

-export([
    endpoint_func/2

]).

-export([
    on_client_connect/3
    , on_client_connack/4
    , on_client_connected/3
    , on_client_disconnected/4
    , on_client_authenticate/3
    , on_client_authorize/5
    , on_client_check_authz_complete/6
]).

-export([
    on_session_created/3
    , on_session_subscribed/4
    , on_session_unsubscribed/4
    , on_session_resumed/3
    , on_session_discarded/3
    , on_session_takenover/3
    , on_session_terminated/4
]).

-export([
    on_message_publish_0/2,
    on_message_publish_1/2,
    on_message_publish_2/2,
    on_message_publish_3/2,
    on_message_publish_4/2,
    on_message_publish_5/2,
    on_message_publish_6/2,
    on_message_publish_7/2,
    on_message_publish_8/2,
    on_message_publish_9/2,
    on_message_publish_10/2
    , on_message_delivered/3
    , on_message_acked/3
    , on_message_dropped/4
]).

-define(evt_mod, emqx_plugin_kafka_evt).

hooks([Hook | T], Producer, Acc) ->
    Ret = hook(emqx_plugin_kafka_util:resource_id(), Hook#{producer => Producer}),
    hooks(T, Producer, [Ret | Acc]);
hooks([], _, Acc) ->
    persistent_term:put({?EMQX_PLUGIN_KAFKA_APP, ?EMQX_PLUGIN_KAFKA_CHANNELS}, Acc).

hook(ResId, Hook = #{endpoint := Endpoint0,index:=Index, filter := Filter}) ->

    % % 根据 Endpoint0 和 Index 生成 Endpoint
    EndpointStr = lists:flatten(io_lib:format("~s.~s", [Endpoint0, Index])),
    % {ok, EndpointS} = emqx_utils:safe_to_existing_atom(EndpointStr),

    {ok, Endpoint} = emqx_utils:safe_to_existing_atom(Endpoint0),

    {ok, Endpoint1} = emqx_utils:safe_to_existing_atom(list_to_atom(EndpointStr)),

    % this add channel,see emqx_plugins_kafka_producer.erl on_add_channel

    ChannelId = emqx_plugin_kafka_util:channel_id(Endpoint1),
    
    emqx_resource_manager:add_channel(ResId, ChannelId, Hook),

    Opts = #{
        channel_id => ChannelId,
        filter => Filter,
        index =>Index

    },

    Indexx=list_to_atom(binary_to_list(Index)),

    % ?SLOG(info, #{
    %     endpointStr000=>Endpoint1,
    %     channel_id111 => ChannelId,
    %     filter => Filter,
    %     endpoint=> Endpoint,
    %     optsssssssssssssssssssssss=>Opts,
    %     funccccccccccccccccccccccc=>endpoint_func(Endpoint,Index),
    %     indexxxxxxxxxxxxxxxxxxxxxxxxxxxxx=>Index,
    %     indexxxxxxxxxxxxxxxxxxxxxxxxxxxxx2=>Indexx

    % }),

    % ?SLOG(info, endpoint_func(Endpoint,Index)),

    trigger_hook(Endpoint, endpoint_func(Endpoint,Indexx), Opts),


    {ChannelId, Hook}.

trigger_hook(_, undefined, _) ->
    ok;
trigger_hook(Endpoint, Func, Opts = #{index:=Index,filter := Filter}) ->
    % IndexInt = binary_to_integer(Index),
    % Result = ?HP_HIGHEST - IndexInt,


    NewOpts = maps:remove(index, Opts),

    Index2 = binary_to_integer(Index),  % 转换为整数
    NewPriority = ?HP_HIGHEST - Index2,  % 执行减法运算


    % ?SLOG(info, "new hookkkkkkkkkkkkkkkkkkkkkkkkk"),
    % ?SLOG(info, #{
    %         newOptssssssssssssssssssssssssssssssssssssss=>NewOpts,
    %         filttttttttttttttttttttttttttttttttttttttter=>Filter,
    %         newPriorityyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy=>NewPriority,
    %         index2222222222222222222222222222222222222222=>Index2
    %     }   
    % ),

    % ?GEN_FUNC(Index);

    Result1=emqx_hooks:add(Endpoint, {?MODULE, Func, [NewOpts]}, _Property = NewPriority),

    ?SLOG(info, #{
        emqx_hooks_add_result=>Result1
    }).


endpoint_func('client.connect',_) -> on_client_connect;
endpoint_func('client.connack',_) -> on_client_connack;
endpoint_func('client.connected',_) -> on_client_connected;
endpoint_func('client.disconnected',_) -> on_client_disconnected;
endpoint_func('client.authenticate',_) -> on_client_authenticate;
endpoint_func('client.authorize',_) -> on_client_authorize;
endpoint_func('client.authenticate',_) -> on_client_authenticate;
endpoint_func('client.check_authz_complete',_) -> on_client_check_authz_complete;
endpoint_func('session.created',_) -> on_session_created;
endpoint_func('session.subscribed',_) -> on_session_subscribed;
endpoint_func('session.unsubscribed',_) -> on_session_unsubscribed;
endpoint_func('session.resumed',_) -> on_session_resumed;
endpoint_func('session.discarded',_) -> on_session_discarded;
endpoint_func('session.takenover',_) -> on_session_takenover;
endpoint_func('session.terminated',_) -> on_session_terminated;

endpoint_func('message.publish','0') -> on_message_publish_0;
endpoint_func('message.publish','1') -> on_message_publish_1;
endpoint_func('message.publish','2') -> on_message_publish_2;
endpoint_func('message.publish','3') -> on_message_publish_3;
endpoint_func('message.publish','4') -> on_message_publish_4;
endpoint_func('message.publish','5') -> on_message_publish_5;
endpoint_func('message.publish','6') -> on_message_publish_6;
endpoint_func('message.publish','7') -> on_message_publish_7;
endpoint_func('message.publish','8') -> on_message_publish_8;
endpoint_func('message.publish','9') -> on_message_publish_9;
endpoint_func('message.publish','10') -> on_message_publish_10;



endpoint_func('message.delivered',_) -> on_message_delivered;
endpoint_func('message.acked',_) -> on_message_acked;
endpoint_func('message.dropped',_) -> on_message_dropped;
endpoint_func(_,_) -> undefined.

unhook() ->
    unhook('client.connect', {?MODULE, on_client_connect}),
    unhook('client.connack', {?MODULE, on_client_connack}),
    unhook('client.connected', {?MODULE, on_client_connected}),
    unhook('client.disconnected', {?MODULE, on_client_disconnected}),
    unhook('client.authenticate', {?MODULE, on_client_authenticate}),
    unhook('client.authorize', {?MODULE, on_client_authorize}),
    unhook('client.check_authz_complete', {?MODULE, on_client_check_authz_complete}),
    unhook('session.created', {?MODULE, on_session_created}),
    unhook('session.subscribed', {?MODULE, on_session_subscribed}),
    unhook('session.unsubscribed', {?MODULE, on_session_unsubscribed}),
    unhook('session.resumed', {?MODULE, on_session_resumed}),
    unhook('session.discarded', {?MODULE, on_session_discarded}),
    unhook('session.takenover', {?MODULE, on_session_takenover}),
    unhook('session.terminated', {?MODULE, on_session_terminated}),
    % unhook('message.publish', {?MODULE, on_message_publish}),

    unhook('message.publish', {?MODULE, on_message_publish_0}),
    unhook('message.publish', {?MODULE, on_message_publish_1}),
    unhook('message.publish', {?MODULE, on_message_publish_2}),
    unhook('message.publish', {?MODULE, on_message_publish_3}),
    unhook('message.publish', {?MODULE, on_message_publish_4}),
    unhook('message.publish', {?MODULE, on_message_publish_5}),
    unhook('message.publish', {?MODULE, on_message_publish_6}),
    unhook('message.publish', {?MODULE, on_message_publish_7}),
    unhook('message.publish', {?MODULE, on_message_publish_8}),
    unhook('message.publish', {?MODULE, on_message_publish_9}),
    unhook('message.publish', {?MODULE, on_message_publish_10}),


    unhook('message.delivered', {?MODULE, on_message_delivered}),
    unhook('message.acked', {?MODULE, on_message_acked}),
    unhook('message.dropped', {?MODULE, on_message_dropped}).

unhook(Endpoint, MFA) ->
    emqx_hooks:del(Endpoint, MFA).


%%--------------------------------------------------------------------
%% Client Lifecycle Hooks
%%--------------------------------------------------------------------

on_client_connect(ConnInfo, Props, Opts) ->
    query(?evt_mod:eventmsg_connect(ConnInfo), Opts),
    {ok, Props}.

on_client_connack(ConnInfo, Rc, Props, Opts) ->
    query(?evt_mod:eventmsg_connack(ConnInfo, Rc), Opts),
    {ok, Props}.

on_client_connected(ClientInfo, ConnInfo, Opts) ->
    query(?evt_mod:eventmsg_connected(ClientInfo, ConnInfo), Opts),
    ok.

on_client_disconnected(ClientInfo, ReasonCode, ConnInfo, Opts) ->
    query(?evt_mod:eventmsg_disconnected(ClientInfo, ConnInfo, ReasonCode), Opts),
    ok.

on_client_authenticate(ClientInfo, Result, Opts) ->
    query(?evt_mod:eventmsg_authenticate(ClientInfo, Result), Opts),
    {ok, Result}.

on_client_authorize(ClientInfo, PubSub, Topic, Result, Opts) ->
    query(?evt_mod:eventmsg_authorize(ClientInfo, PubSub, Topic, Result), Opts),
    {ok, Result}.

on_client_check_authz_complete(ClientInfo, PubSub, Topic, Result, AuthzSource, Opts) ->
    query(?evt_mod:eventmsg_check_authz_complete(ClientInfo, PubSub, Topic, Result, AuthzSource), Opts),
    {ok, Result}.

%%--------------------------------------------------------------------
%% Session Lifecycle Hooks
%%--------------------------------------------------------------------

on_session_created(ClientInfo, #{id := SessionId, created_at := CreatedAt}, Opts) ->
    query(?evt_mod:eventmsg_session_created(ClientInfo, SessionId, CreatedAt), Opts),
    ok.

on_session_subscribed(ClientInfo, Topic, SubOpts, Opts) ->
    query(?evt_mod:eventmsg_sub_or_unsub('session.subscribed', ClientInfo, Topic, SubOpts), Opts),
    ok.

on_session_unsubscribed(ClientInfo, Topic, SubOpts, Opts) ->
    query(?evt_mod:eventmsg_sub_or_unsub('session.unsubscribed', ClientInfo, Topic, SubOpts), Opts),
    ok.

on_session_resumed(ClientInfo, _SessInfo, Opts) ->
    query(?evt_mod:eventmsg_session('session.resumed', ClientInfo), Opts),
    ok.

on_session_discarded(ClientInfo, _SessInfo, Opts) ->
    query(?evt_mod:eventmsg_session('session.discarded', ClientInfo), Opts),
    ok.

on_session_takenover(ClientInfo, _SessInfo, Opts) ->
    query(?evt_mod:eventmsg_session('session.takenover', ClientInfo), Opts),
    ok.

on_session_terminated(ClientInfo, Reason, _SessInfo, Opts) ->
    query(?evt_mod:eventmsg_session_terminated(ClientInfo, Reason), Opts),
    ok.

%%--------------------------------------------------------------------
%% Message PubSub Hooks
%%--------------------------------------------------------------------

% on_message_publish(Message, Opts = #{filter := Filter}) ->

%     ?SLOG(info, #{
%         msg => Message,
%         fffffffffffffffffffffffffff => Filter
%     }),
        
%     case match_topic(Message, Filter) of
%         true ->
%             query(?evt_mod:eventmsg_publish(Message), Opts);
%         false ->
%             ok
%     end,
%     {ok, Message}.
on_message_publish_0(Message, Opts = #{filter := Filter}) ->


    % ?SLOG(info, #{
    %     msg0000 => Message,
    %     fffffffffffffffffffffffffff => Filter
    % }),
   
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_publish(Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.

on_message_publish_1(Message, Opts = #{filter := Filter}) ->


    % ?SLOG(info, #{
    %     msg1111 => Message,
    %     fffffffffffffffffffffffffff => Filter
    % }),

    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_publish(Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.

on_message_publish_2(Message, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_publish(Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.
on_message_publish_3(Message, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_publish(Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.
on_message_publish_4(Message, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_publish(Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.
on_message_publish_5(Message, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_publish(Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.
on_message_publish_6(Message, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_publish(Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.
on_message_publish_7(Message, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_publish(Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.
on_message_publish_8(Message, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_publish(Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.
on_message_publish_9(Message, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_publish(Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.
on_message_publish_10(Message, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_publish(Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.


on_message_dropped(Message, #{node := ByNode}, Reason, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_dropped(Message, ByNode, Reason), Opts);
        false ->
            ok
    end,
    ok.

on_message_delivered(ClientInfo, Message, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_delivered(ClientInfo, Message), Opts);
        false ->
            ok
    end,
    {ok, Message}.

on_message_acked(ClientInfo, Message, Opts = #{filter := Filter}) ->
    case match_topic(Message, Filter) of
        true ->
            query(?evt_mod:eventmsg_acked(ClientInfo, Message), Opts);
        false ->
            ok
    end,
    ok.

%%%===================================================================
%%% External functions
%%%===================================================================

match_topic(_, <<$#, _/binary>>) ->
    false;
match_topic(_, <<$+, _/binary>>) ->
    false;
match_topic(#message{topic = <<"$SYS/", _/binary>>}, _) ->
    false;
match_topic(#message{topic = Topic}, Filter) ->
    emqx_topic:match(Topic, Filter);
match_topic(_, _) ->
    false.

query(
    EvtMsg,
    #{channel_id := ChannelId}
) ->
    query_ret(
        emqx_resource:query(emqx_plugin_kafka_util:resource_id(), {ChannelId, EvtMsg}),
        EvtMsg
    ).

query_ret({_, {ok, _}}, _) ->
    ok;
query_ret(Ret, EvtMsg) ->
    ?SLOG(error,
        #{
            msg => "failed_to_query_kafka_resource",
            ret => Ret,
            evt_msg => EvtMsg
        }).