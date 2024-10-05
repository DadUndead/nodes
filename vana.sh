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

  sleep 1

  sudo apt update && sudo apt upgrade -y
  sudo apt-get install git -y
  sudo apt install unzip
  sudo apt install nano
  sudo apt install software-properties-common -y
  sudo add-apt-repository ppa:deadsnakes/ppa
  sudo apt update
  sudo apt install python3.12 -y
  sudo apt install python3-pip python3-venv curl -y
  curl -sSL https://install.python-poetry.org | python3 -
  export PATH="$HOME/.local/bin:$PATH"
  source ~/.bashrc
  curl -fsSL https://fnm.vercel.app/install | bash
  source ~/.bashrc
  fnm use --install-if-missing 22
  apt-get install nodejs -y
  npm install -g yarn

  git clone https://github.com/vana-com/vana-dlp-chatgpt.git
  cd vana-dlp-chatgpt
  cp .env.example .env
  poetry install
  pip install vana

  echo 'Придумайте пароль для двух кошельков который у вас сейчас будут на экране'
  echo 'Сохраните пароль в надежном месте, как и сид фразы, отмеченные желтым текстом'
  echo '!!! ЭТО ВАЖНО !!!'

  read -p "Как прочтете, введите что-нибудь: " inputsmth

  vanacli wallet create --wallet.name default --wallet.hotkey default

  sleep 1

  vanacli wallet export_private_key

  sleep 1

  vanacli wallet export_private_key

  sleep 1

  echo 'Следуйте дальше инструкции по гайду'
}

deploy_dlp() {
  cd $HOME
  rm -rf vana-dlp-smart-contracts
  git clone https://github.com/Josephtran102/vana-dlp-smart-contracts
  cd vana-dlp-smart-contracts
  npm install -g yarn
  yarn install
  cp .env.example .env
  nano .env

  sleep 1

  npx hardhat deploy --network moksha --tags DLPDeploy
}

download_validator() {
  echo 'Сохраните данный публичный ключ в надежном месте'
  cat /root/vana-dlp-chatgpt/public_key_base64.asc
  
  read -p "Как сохраните, введите что-нибудь: " inputsmthhh
  
  cd
  cd vana-dlp-chatgpt
  nano .env

  sleep 1

  read -p "Введите ваш хоткей адрес из MetaMask (0x...): " validator_address

  ./vanacli dlp register_validator --stake_amount 10
  ./vanacli dlp approve_validator --validator_address=$validator_address

  poetry run python -m chatgpt.nodes.validator
}

service_start() {
  poetry_path=$(which poetry)

  sudo tee /etc/systemd/system/vana.service << EOF
[Unit]
Description=Vana Validator Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/vana-dlp-chatgpt
ExecStart=$poetry_path run python -m chatgpt.nodes.validator
Restart=on-failure
RestartSec=10
Environment=PATH=/root/.local/bin:/usr/local/bin:/usr/bin:/bin:/root/vana-dlp-chatgpt/myenv/bin
Environment=PYTHONPATH=/root/vana-dlp-chatgpt

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload && \
  sudo systemctl enable vana.service && \
  sudo systemctl start vana.service && \
  sudo systemctl status vana.service
}

check_logs() {
  sudo journalctl -u vana.service -f
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. Начать установку ноды"
    echo '2. Деплой DLP'
    echo '3. Установка валидатора'
    echo '4. Установить фоновый сервис'
    echo '5. Проверить логи'
    echo -e "6. Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        deploy_dlp
        ;;
      3)
        download_validator
        ;;
      4)
        service_start
        ;;
      5)
        check_logs
        ;;
      6)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
