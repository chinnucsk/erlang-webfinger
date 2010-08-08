-module(webfinger).

-export([lookup/1]).

-include_lib("xmerl/include/xmerl.hrl").


lookup(URI) ->
  {acct, _Userinfo, Host} = uri_parse(URI),
  case http_get(lists:concat(["http://", Host, "/.well-known/host-meta"])) of
    {ok, {xml, XRD}} ->
      lookup(URI, XRD);
    _ ->
      {error, bad_http}
  end.

lookup(URI, XRD) ->
  case template_search(xmerl_xpath:string("//XRD/Link", XRD)) of
    {template, Template} ->
      http_get(re:replace(Template, "\\{uri\\}", percent_encode(URI), [{return, list}]));
    none ->
      {error, no_link_template}
  end.

template_search([]) ->
  none;
template_search([#xmlElement{attributes=Attrs}|Links]) ->
  Props = [{K, V} || #xmlAttribute{name=K, value=V} <- Attrs],
  case proplists:get_value(rel, Props) =:= "lrdd" of
    true ->
      proplists:lookup(template, Props);
    false ->
      template_search(Links)
  end.

http_get(URL) ->
  case httpc:request(get, {URL, []}, [{relaxed, true}], []) of
    Response={ok, {{_, 200, _}, Headers, Body}} ->
      Type = media_type(Headers),
      case lists:suffix("/xml", Type) orelse lists:suffix("+xml", Type) orelse lists:prefix("<?xml ", Body) of
        true ->
          {XML, []} = xmerl_scan:string(Body),
          {ok, {xml, XML}};
        false ->
          Response
      end;
    Other ->
      Other
  end.

media_type(Headers) ->
  case proplists:get_value("content-type", Headers) of
    undefined ->
      "";
    ContentType ->
      hd(string:tokens(ContentType, ";"))
  end.

uri_parse("acct:" ++ ID) ->
  uri_parse({acct, ID});
uri_parse({acct, ID}) ->
  {Userinfo, [$@|Host]} = lists:split(string:rstr(ID, "@") - 1, ID),
  {acct, Userinfo, Host}.

-define(is_alphanum(C), C >= $A, C =< $Z; C >= $a, C =< $z; C >= $0, C =< $9).

percent_encode(Term) when is_list(Term) ->
  percent_encode(lists:reverse(Term, []), []).

percent_encode([X | T], Acc) when ?is_alphanum(X); X =:= $-; X =:= $_; X =:= $.; X =:= $~ ->
  percent_encode(T, [X | Acc]);
percent_encode([X | T], Acc) ->
  percent_encode(T, [$%, dec2hex(X bsr 4), dec2hex(X band 16#0f) | Acc]);
percent_encode([], Acc) ->
  Acc.

-compile({inline, [{dec2hex, 1}]}).

dec2hex(N) when N >= 10 andalso N =< 15 ->
  N + $A - 10;
dec2hex(N) when N >= 0 andalso N =< 9 ->
  N + $0.
