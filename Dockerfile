FROM elixir:1.17-alpine AS build

RUN apk add --no-cache git build-base bash openssl-dev

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config config

RUN mix deps.get --only prod
RUN mix deps.compile

COPY lib lib
COPY priv priv

RUN mix compile 
RUN mix release


FROM alpine:3.19 AS app

RUN apk add --no-cache bash libstdc++ ncurses-libs 

WORKDIR /app

COPY --from=build /app/_build/prod/rel/langka_order_management ./
COPY --from=build /usr/lib/libcrypto.so.3 /usr/lib/
COPY --from=build /usr/lib/libssl.so.3 /usr/lib/
COPY docker-entrypoint.sh /app/docker-entrypoint.sh

RUN chmod +x /app/docker-entrypoint.sh

ENV HOME=/app
ENV MIX_ENV=prod

EXPOSE 4000

ENTRYPOINT ["/app/docker-entrypoint.sh"]