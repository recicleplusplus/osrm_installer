#!/bin/bash

# Clonar projeto OSRM backend
git clone https://github.com/Project-OSRM/osrm-backend.git

# Navegar para o diretorio do projeto OSRM backend
cd osrm-backend

# Baixar o arquivo de dados OSM de Berlin
wget http://download.geofabrik.de/europe/germany/berlin-latest.osm.pbf

# Remover pacotes Docker antigos (se existirem)
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done

# Atualizar pacotes e instalar dependências para Docker
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg

# Criar o diretório para as chaves do Docker (se não existir)
sudo install -m 0755 -d /etc/apt/keyrings

# Baixar e instalar a chave GPG oficial do Docker, sobrescrevendo se necessário
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Adicionar o repositório do Docker às fontes do APT
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Atualizar o APT novamente e instalar o Docker
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verificar se o grupo 'docker' já existe e criar caso não exista
if ! getent group docker > /dev/null; then
  sudo groupadd docker
fi

# Adicionar o usuário ao grupo docker
sudo usermod -aG docker $USER

sudo systemctl restart docker

# Informar o usuário que precisa reiniciar a sessão para aplicar as mudanças de grupo
echo "Instalação concluída! Para usar o Docker sem sudo, você precisará reiniciar a sessão do terminal ou fazer logoff e logon novamente."

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
