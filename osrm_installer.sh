#!/bin/bash

# Clonar projeto OSRM backend
git clone https://github.com/Project-OSRM/osrm-backend.git

# Navegar para o diretorio do projeto OSRM backend
cd osrm-backend

# Baixar o arquivo de dados OSM de Berlin
wget http://download.geofabrik.de/europe/germany/berlin-latest.osm.pbf

# Extrair os dados do OSM com o perfil de carro (após reiniciar a sessão)
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend osrm-extract -p /opt/car.lua /data/berlin-latest.osm.pbf
if [ $? -ne 0 ]; then
    echo "osrm-extract failed"
    exit 1
fi

# Particionar os dados
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend osrm-partition /data/berlin-latest.osrm
if [ $? -ne 0 ]; then
    echo "osrm-partition failed"
    exit 1
fi

# Customizar os dados
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend osrm-customize /data/berlin-latest.osrm
if [ $? -ne 0 ]; then
    echo "osrm-customize failed"
    exit 1
fi

# Adicionar regra de firewall para permitir conexao com a porta 9099
sudo ufw allow 9099/tcp
sudo ufw reload

# Iniciar o servidor OSRM na porta 5000
docker run -t -i -p 9099:5000 -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend osrm-routed --algorithm mld /data/berlin-latest.osrm

# Fazer uma requisição de rota exemplo
sleep 5
curl "http://127.0.0.1:9099/route/v1/driving/13.388860,52.517037;13.385983,52.496891?steps=true"
