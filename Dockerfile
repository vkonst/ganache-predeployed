FROM trufflesuite/ganache-cli:latest

WORKDIR /app

COPY gcp-scripts ./gcp-scripts
COPY build ./build

EXPOSE 8080

ENTRYPOINT ["sh", "/app/gcp-scripts/start.sh"]
