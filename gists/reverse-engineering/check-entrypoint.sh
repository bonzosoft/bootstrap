docker inspect docker.io/<image>:<latest> --format='{{json .Config.Entrypoint}} {{json .Config.Cmd}}'
  # Si devuelve null ["/app/wealthfolio"]: Significa que usa CMD.
  # Si devuelve ["/app/wealthfolio"] null: Significa que usa ENTRYPOINT.