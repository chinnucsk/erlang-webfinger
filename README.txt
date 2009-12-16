An Erlang webfinger client.

Quick start:

  $ make
  ...
  $ erl -pa ebin -s inets
  ...
  1> webfinger:lookup("acct:somebody@example.com").
  {ok, {xml, ...}}
