channel_logo() {
  echo -e '\033[0;31m'
  echo -e '┌┐ ┌─┐┌─┐┌─┐┌┬┐┬┬ ┬  ┌─┐┬ ┬┌┐ ┬┬  '
  echo -e '├┴┐│ ││ ┬├─┤ │ │└┬┘  └─┐└┬┘├┴┐││  '
  echo -e '└─┘└─┘└─┘┴ ┴ ┴ ┴ ┴   └─┘ ┴ └─┘┴┴─┘'
  echo -e '\e[0m'
  echo -e "\n\nПодпишись на самый 4ekHyTbIu* канал в крипте @bogatiy_sybil [💸]"
}

download_node() {
  echo 'Начинаю установку...'

  cd $HOME

  sudo apt install lsof

  ports=(1433 8080)

  for port in "${ports[@]}"; do
    if [[ $(lsof -i :"$port" | wc -l) -gt 0 ]]; then
      echo "Ошибка: Порт $port занят. Программа не сможет выполниться."
      exit 1
    fi
  done

  sudo apt update -y && sudo apt upgrade -y

  sudo dpkg --configure -a

  sudo apt install screen net-tools iptables jq curl -y

  wget https://network3.io/ubuntu-node-v2.1.1.tar.gz
  tar -xvf ubuntu-node-v2.1.1.tar.gz
  sudo rm -rf ubuntu-node-v2.1.1.tar.gz

  cd ubuntu-node

  screen -S network3
}

launch_node() {
  cd $HOME/ubuntu-node
  sudo bash manager.sh up
}

stop_node() {
  cd $HOME/ubuntu-node
  sudo bash manager.sh down
}

check_points() {
  my_ip=$(hostname -I | awk '{print $1}')
  total_points=$(curl -s http://$my_ip:8080/detail | jq '.earnings.total')
  echo -e "У вас столько поинтов: $total_points"
}

check_private_key() {
  cd $HOME/ubuntu-node
  sudo bash manager.sh key
}

update_node() {
  cd $HOME/ubuntu-node
  sudo bash manager.sh key

  read -p '(!) СОХРАНИЕ ВАШ ПРИВАТНЫЙ КЛЮЧ В НАДЕЖНОМ МЕСТЕ, КАК ЭТО СДЕЛАЕТЕ, ВВЕДИТЕ ЛЮБОЙ СИМВОЛ: ' checkjust

  cd $HOME
  sudo rm -r ubuntu-node

  wget https://network3.io/ubuntu-node-v2.1.1.tar.gz
  tar -xvf ubuntu-node-v2.1.1.tar.gz
  sudo rm -rf ubuntu-node-v2.1.1.tar.gz


  screen -S network3 -X stuff "cd ubuntu-node$(printf \\r)sudo bash manager.sh up$(printf \\r)"
}

exit_from_script() {
  exit 0
}

while true; do
    channel_logo
    sleep 2
    echo -e "\n\nМеню:"
    echo "1. 🔧 Установить ноду"
    echo "2. 🚀 Запустить ноду"
    echo "3. ⛔ Остановить ноду"
    echo "4. 🎯 Проверить количество поинтов"
    echo "5. 🔑 Посмотреть приватный ключ"
    echo "6. 💻 Обновить ноду"
    echo -e "7. ❌ Выйти из скрипта\n"
    read -p "Выберите пункт меню: " choice

    case $choice in
      1)
        download_node
        ;;
      2)
        launch_node
        ;;
      3)
        stop_node
        ;;
      4)
        check_points
        ;;
      5)
        check_private_key
        ;;
      6)
        update_node
        ;;
      7)
        exit_from_script
        ;;
      *)
        echo "Неверный пункт. Пожалуйста, выберите правильную цифру в меню."
        ;;
    esac
  done
