An Erlang webfinger client.

Quick start:

  $ make
  ...
  $ erl -pa ebin -s inets -s ssl
  ...
  1> webfinger:lookup("acct:somebody@example.com").
  {ok, {xml, ...}}
