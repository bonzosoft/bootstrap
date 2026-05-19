# Github New Importer

Se puede importar un repositorio desde otra fuente con:

````
https://github.com/new/import
````

Luego se puede mantener actualizado con alguna versión de esto:

````yaml
name: Sync from 0xacab
on:
  schedule:
    - cron: '0 0 * * *' # cada día a medianoche
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v3
      - name: Sync
        run: |
          git remote add upstream https://0xacab.org/usuario/proyecto.git
          git fetch upstream
          git reset --hard upstream/main
          git push origin main --force
````