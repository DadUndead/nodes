channel_logo() {
  echo -e '\033[0;31m'
  echo -e '┌┐ ┌─┐┌─┐┌─┐┌┬┐┬┬ ┬  ┌─┐┬ ┬┌┐ ┬┬  '
  echo -e '├┴┐│ ││ ┬├─┤ │ │└┬┘  └─┐└┬┘├┴┐││  '
  echo -e '└─┘└─┘└─┘┴ ┴ ┴ ┴ ┴   └─┘ ┴ └─┘┴┴─┘'
  echo -e '\e[0m'
  echo -e "\n\nПодпишись на самый 4ekHyTbIu* канал в крипте @bogatiy_sybil [💸]"
}

download_node() {
  echo 'Начинаю установку ноды...'

  sudo apt install lsof

  ports=(7310 8545 8546 8551 9545 9222 6060 30303)

  for port in "${ports[@]}"; do
    if [[ $(lsof -i :"$port" | wc -l) -gt 0 ]]; then
      echo "Ошибка: Порт $port занят. Программа не сможет выполниться."
      exit 1
    fi
  done

  echo -e "Все порты свободны! Сейчас начнется установка...\n"

  sudo apt update -y && sudo apt upgrade -y
  sudo apt install screen curl git jq nano gnupg build-essential wget lz4 gcc make ca-certificates lsb-release -y

  if ! command -v docker &> /dev/null; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker.io
  else
    echo "Docker уже установлен, пропускаем установку..."
  fi
  sudo usermod -aG docker $USER
  newgrp docker

  if ! command -v docker-compose &> /dev/null; then
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  else
    echo "Docker-compose уже установлен, пропускаем установку..."
  fi


  git clone https://github.com/Soneium/soneium-node.git
  cd soneium-node/minato

  openssl rand -hex 32 > jwt.txt
  mv sample.env .env

  SERVER_IP=$(curl -s ifconfig.me)

  echo "Ваш IP-адрес сервера: $SERVER_IP. Это правильный IP? (y/n)"
  read -r CONFIRM
  
  if [[ $CONFIRM == "y" ]]; then
      echo "IP подтвержден: $SERVER_IP"
  else
      echo "Введите ваш IP-адрес:"
      read -r SERVER_IP
      echo "Вы ввели IP: $SERVER_IP"
  fi

  sed -i 's|^L1_URL=.*|L1_URL=https://ethereum-sepolia-rpc.publicnode.com|' .env
  sed -i 's|^L1_BEACON=.*|L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|' .env
  sed -i "s|^P2P_ADVERTISE_IP=.*|P2P_ADVERTISE_IP=${SERVER_IP}|" .env

  sed -i "s/<your_node_public_ip>/$SERVER_IP/g" docker-compose.yml

  docker-compose up -d

  echo -e '\n\nНода была запущена, проверяйте ваши логи, сохраняйте в надежном месте приватный ключ.'
}

check_private_key() {
  jwt_value=$(cat $HOME/soneium-node/minato/jwt.txt)
  echo $jwt_value
}

check_logs_op_node() {
  cd $HOME/soneium-node/minato
  docker-compose logs -f op-node-minato --tail 300
}

check_logs_op_minato() {
  cd $HOME/soneium-node/minato
  docker-compose logs -f op-geth-minato --tail 300
}

restart_node() {
  echo 'Начинаю перезагрузку...'

  cd $HOME/soneium-node/minato
  sudo docker-compose down
  sudo docker-compose up -d

  echo 'Ноды были перезагружены.'
}

stop_node() {
  echo 'Начинаю остановку...'

  cd $HOME/soneium-node/minato
  sudo docker-compose down
  
  echo 'Ноды были остановлены.'
}

clear_data_containers() {
  echo 'Начинаю удаления кэша...'

  cd $HOME/soneium-node/minato
  sudo docker-compose down --volumes --remove-orphans

  echo 'Кэш был удален и нода остановлена. Если захотите снова запустить, нажимайте в скрипте: перезагрузить ноду'
}

delete_node() {
  read -p 'Если вы уверены удалить ноду, напишите любой символ (CTRL+C чтобы выйти): ' checkjust

  cd $HOME/soneium-node/minato
  sudo docker-compose down --volumes --remove-orphans
  sudo docker rmi $(docker images | grep "us-docker.pkg.dev/oplabs-tools-artifacts/images/op-node" | awk '{print $1 ":" $2}')
  sudo docker rmi $(docker images | grep "us-docker.pkg.dev/oplabs-tools-artifacts/images/op-geth" | awk '{print $1 ":" $2}')
  cd $HOME
  sudo rm -r soneium-node/

  echo 'Нода была удалена.'
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🚀 Установить ноду"
    echo "2. 🔑 Посмотреть приватный ключ"
    echo "3. 📜 Посмотреть логи op-node-minato (выйти CTRL+C)"
    echo "4. 📜 Посмотреть логи op-geth-minato (выйти CTRL+C)"
    echo "5. 🔄 Перезагрузить ноду"
    echo "6. 🛑 Остановить ноду"
    echo "7. 🔰 Удалить кэш ноды"
    echo "8. 🤬 Удалить ноду полностью"
    echo -e "9. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_private_key
        ;;
      3)
        check_logs_op_node
        ;;
      4)
        check_logs_op_minato
        ;;
      5)
        restart_node
        ;;
      6)
        stop_node
        ;;
      7)
        clear_data_containers
        ;;
      8)
        delete_node
        ;;
      9)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
