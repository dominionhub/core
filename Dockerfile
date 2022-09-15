FROM ignitehq/cli:latest

USER root

WORKDIR /app

COPY . .

RUN mv /app/test-config.yml /app/config.yml
RUN ignite chain init

EXPOSE 1317
EXPOSE 26657
EXPOSE 4500

ENTRYPOINT ["dominiond"]
