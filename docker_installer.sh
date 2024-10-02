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

# Atualizar grupos e reiniciar o Docker
newgrp docker
sudo systemctl restart docker

