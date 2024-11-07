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

  sudo apt-get update -y && sudo apt upgrade -y
  sudo apt-get install make tar screen nano build-essential unzip lz4 gcc git jq -y

  sudo rm -rf /usr/local/go
  curl -Ls https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
  eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
  eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

  wget https://github.com/hemilabs/heminetwork/releases/download/v0.5.0/heminetwork_v0.5.0_linux_amd64.tar.gz
  mkdir -p hemi
  tar --strip-components=1 -xzvf heminetwork_v0.5.0_linux_amd64.tar.gz -C hemi
  sudo rm -rf heminetwork_v0.5.0_linux_amd64.tar.gz

  cd hemi/

  ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json

  eth_address=$(jq -r '.ethereum_address' ~/popm-address.json)
  private_key=$(jq -r '.private_key' ~/popm-address.json)
  public_key=$(jq -r '.public_key' ~/popm-address.json)
  pubkey_hash=$(jq -r '.pubkey_hash' ~/popm-address.json)

  echo "Дискорд канал, нужно зайти: https://discord.gg/hemixyz"
  echo "Запросите средства на этот адрес в канале faucet (в дискорде): $pubkey_hash"
  echo "Команда: /tbtc-faucet и вводите ваш адрес, который вывелся"
  read -p "Как выполните, введите любую кнопку сюда: " checkjust
  
  echo "export POPM_PRIVATE_KEY=$private_key" >> ~/.bashrc
  echo 'export POPM_STATIC_FEE=1040' >> ~/.bashrc
  echo 'export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public' >> ~/.bashrc
  source ~/.bashrc

  sudo tee /etc/systemd/system/hemid.service > /dev/null <<EOF
[Unit]
Description=Hemi
After=network.target

[Service]
User=$USER
Environment="POPM_BFG_REQUEST_TIMEOUT=60s"
Environment="POPM_BTC_PRIVKEY=$private_key"
Environment="POPM_STATIC_FEE=1040"
Environment="POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public"
WorkingDirectory=$HOME/hemi
ExecStart=$HOME/hemi/popmd
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl enable hemid
  sudo systemctl daemon-reload
  sudo systemctl start hemid
}

check_logs() {
  sudo journalctl -u hemid -f --no-hostname -o cat
}

output_all_data() {
  cd $HOME

  eth_address=$(jq -r '.ethereum_address' ~/popm-address.json)
  private_key=$(jq -r '.private_key' ~/popm-address.json)
  public_key=$(jq -r '.public_key' ~/popm-address.json)
  pubkey_hash=$(jq -r '.pubkey_hash' ~/popm-address.json)
  
  echo "Ethereum Address: $eth_address"
  echo "Private Key: $private_key"
  echo "Public Key: $public_key"
  echo "Pubkey Hash: $pubkey_hash"
}

change_fee() {
  service_file="/etc/systemd/system/hemid.service"
  
  read -p "Введите новое значение POPM_STATIC_FEE: " new_fee
  
  sudo sed -i "s/^Environment=\"POPM_STATIC_FEE=[0-9]*\"/Environment=\"POPM_STATIC_FEE=$new_fee\"/" "$service_file"
  
  sudo systemctl daemon-reload
  sudo systemctl restart hemid

  echo 'Значение FEE поменялось...'
}

restart_node() {
  cd $HOME/hemi/

  sudo systemctl daemon-reload
  sudo systemctl restart hemid.service

  echo 'Перезагрузка была выполнена...'
}

delete_node() {
  read -p 'Если вы уверены удалить ноду, напишите любой символ (CTRL+C чтобы выйти): ' checkjust

  sudo systemctl stop hemid.service
  sudo systemctl disable hemid.service
  sudo rm /etc/systemd/system/hemid.service
  sudo systemctl daemon-reload

  cd $HOME
  sudo rm -r hemi/
  sudo rm popm-address.json
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🔧 Установить ноду"
    echo "2. 📜 Посмотреть логи"
    echo "3. 📊 Вывести данные"
    echo "4. 👨‍💻 Поменять значение POPM_STATIC_FEE"
    echo "5. ♻️ Перезапустить ноду"
    echo "6. 🗑️ Удалить ноду"
    echo -e "7. 🚪 Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        check_logs
        ;;
      3)
        output_all_data
        ;;
      4)
        change_fee
        ;;
      5)
        restart_node
        ;;
      6)
        delete_node
        ;;
      7)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
