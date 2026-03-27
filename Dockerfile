FROM alpine:3.20 AS builder

RUN apk add --no-cache lua5.4 lua5.4-dev luarocks5.4 gcc musl-dev

WORKDIR /app

RUN luarocks-5.4 install pegasus && \
    luarocks-5.4 install dkjson

COPY src/ src/
COPY main.lua .

FROM alpine:3.20

RUN apk add --no-cache lua5.4 lua5.4-libs

RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /usr/local/lib/lua /usr/local/lib/lua
COPY --from=builder /usr/local/share/lua /usr/local/share/lua
COPY --from=builder /app /app

RUN chown -R appuser:appgroup /app

USER appuser

ENV PORT=8080
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["lua5.4", "main.lua"]
