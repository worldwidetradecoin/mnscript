#/bin/bash
NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
BLUE='\033[01;34m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
MAX=10

COINGITHUB=https://github.com/kyzersosa/WorldWideTradeCoinMN.git
SENTINELGITHUB=NOSENTINEL
COINSRCDIR=WorldWideTradeCoinMN
# P2Pport and RPCport can be found in chainparams.cpp -> CMainParams()
COINPORT=32390
COINRPCPORT=32391
COINDAEMON=WorldWideTradeCoind
# COINCORE can be found in util.cpp -> GetDefaultDataDir()
COINCORE=.WorldWideTradeCoinMN
COINCONFIG=WorldWideTradeCoin.conf
key=""

checkForUbuntuVersion() {
   echo "[1/${MAX}] Checking Ubuntu version..."
    if [[ `cat /etc/issue.net`  == *16.04* ]]; then
        echo -e "${GREEN}* You are running `cat /etc/issue.net` . Setup will continue.${NONE}";
    else
        echo -e "${RED}* You are not running Ubuntu 16.04.X. You are running `cat /etc/issue.net` ${NONE}";
        echo && echo "Installation cancelled" && echo;
        exit;
    fi
read -e -p "VPS Server IP Address and Masternode Port like IP:32390 : " ip
echo && sleep 3
}

updateAndUpgrade() {
    echo
    echo "[2/${MAX}] Runing update and upgrade. Please wait..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq -y > /dev/null 2>&1
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq > /dev/null 2>&1
    echo -e "${GREEN}* Completed${NONE}";
}

setupSwap() {
    echo -e "${BOLD}"
    read -e -p "Add swap space? (If your vps  is a 1G RAM VPS then you may want to choose Y.) [Y/n] :" add_swap
    if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
        swap_size="4G"
    else
        echo -e "${NONE}[3/${MAX}] Swap space not created."
    fi

    if [[ ("$add_swap" == "y" || "$add_swap" == "Y" || "$add_swap" == "") ]]; then
        echo && echo -e "${NONE}[3/${MAX}] Adding swap space...${YELLOW}"
        sudo fallocate -l $swap_size /swapfile
        sleep 2
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo -e "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null 2>&1
        sudo sysctl vm.swappiness=10
        sudo sysctl vm.vfs_cache_pressure=50
        echo -e "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
        echo -e "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf > /dev/null 2>&1
        echo -e "${NONE}${GREEN}* Completed${NONE}";
    fi
}

installFail2Ban() {
    echo -e "${BOLD}"
    read -e -p "Install Fail2Ban? (This is just a safety program, optional.) [Y/n] :" install_F2B
    if [[ ("$install_F2B" == "y" || "$install_F2B" == "Y" || "$install_F2B" == "") ]]; then
        echo -e "[4/${MAX}] Installing fail2ban. Please wait..."
        sudo apt-get -y install fail2ban > /dev/null 2>&1
        sudo systemctl enable fail2ban > /dev/null 2>&1
        sudo systemctl start fail2ban > /dev/null 2>&1
        echo -e "${NONE}${GREEN}* Completed${NONE}";
    else
        echo -e "${NONE}[4/${MAX}] Fail2Ban not installed."
    fi
}

installFirewall() {
    echo -e "${BOLD}"
    read -e -p "Should we Install Firewall? (This is just for safety, and its optional.) [Y/n] :" install_FW
    if [[ ("$install_FW" == "y" || "$install_FW" == "Y" || "$install_FW" == "") ]]; then
        echo -e "[5/${MAX}] Installing UFW. Please wait..."
        sudo apt-get -y install ufw > /dev/null 2>&1
        sudo ufw default deny incoming > /dev/null 2>&1
        sudo ufw default allow outgoing > /dev/null 2>&1
        sudo ufw allow ssh > /dev/null 2>&1
        sudo ufw limit ssh/tcp > /dev/null 2>&1
        sudo ufw allow $COINPORT/tcp > /dev/null 2>&1
        sudo ufw allow $COINRPCPORT/tcp > /dev/null 2>&1
        sudo ufw logging on > /dev/null 2>&1
        echo "y" | sudo ufw enable > /dev/null 2>&1
        echo -e "${NONE}${GREEN}* Completed${NONE}";
    else
        echo -e "${NONE}[5/${MAX}] Firewall not installed."
    fi
}

installDependencies() {
    echo
    echo -e "[6/${MAX}] gotta Install some dependecies. Please wait..."
    sudo apt-get install git nano rpl wget python-virtualenv -qq -y > /dev/null 2>&1
    sudo apt-get install build-essential libtool automake autoconf -qq -y > /dev/null 2>&1
    sudo apt-get install autotools-dev autoconf pkg-config libssl-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libgmp3-dev libevent-dev bsdmainutils libboost-all-dev -qq -y > /dev/null 2>&1
    sudo apt-get install software-properties-common python-software-properties -qq -y > /dev/null 2>&1
    sudo add-apt-repository ppa:bitcoin/bitcoin -y > /dev/null 2>&1
    sudo apt-get update -qq -y > /dev/null 2>&1
    sudo apt-get install libdb4.8-dev libdb4.8++-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libminiupnpc-dev -qq -y > /dev/null 2>&1
    sudo apt-get install libzmq5 -qq -y > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Completed${NONE}";
}

compileWallet() {
    echo
    echo -e "[7/${MAX}] Compiling wallet. Please wait..."
    git clone $COINGITHUB $COINSRCDIR > /dev/null 2>&1
    cd ~/WorldWideTradeCoinMN/src/leveldb > /dev/null 2>&1
    wget https://github.com/google/leveldb/archive/v1.18.tar.gz > /dev/null 2>&1
    tar xfv v1.18.tar.gz > /dev/null 2>&1
    cp leveldb-1.18/Makefile ~/WorldWideTradeCoinMN/src/leveldb/ > /dev/null 2>&1
    chmod +x build_detect_platform > /dev/null 2>&1
    cd > /dev/null 2>&1
    cd ~/WorldWideTradeCoinMN/src > /dev/null 2>&1
    sudo make -f makefile.unix > /dev/null 2>&1
    echo -e "${NONE}${GREEN}* Completed${NONE}";
}

installWallet() {
    echo
    echo -e "[8/${MAX}] Installing your wallet from source. Please wait..."
    cd ~/$COINSRCDIR/src
    strip $COINDAEMON
    echo -e "${NONE}${GREEN}* Completed${NONE}";
}

configureWallet() {
    echo
    # Create config for WorldWideTradeCoin
echo && echo "shipping all to your .WorldWideTradeCoin.conf file please hold..."
sleep 3
sudo mkdir ~/.WorldWideTradeCoinMN #jm

rpcuser=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
rpcpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
sudo touch ~/.WorldWideTradeCoinMN/WorldWideTradeCoin.conf
echo '
rpcuser='$rpcuser'
rpcpassword='$rpcpassword'
rpcallowip=127.0.0.1
listen=1
server=1
rpcport=3385
daemon=0 # required for systemd
logtimestamps=1
maxconnections=256
externalip='$ip'
masternodeprivkey='$key'
masternode=1
' | sudo -E tee ~/.WorldWideTradeCoinMN/WorldWideTradeCoin.conf

    sleep 10

    echo -e "rpcuser=${rpcuser}\nrpcpassword=${rpcpass}\nrpcallowip=127.0.0.1\nlisten=1\nserver=1\ndaemon=1\nstaking=0\nmaxconnections=64\nlogtimestamps=1\nexternalip=${mnip}:${COINPORT}\nmasternode=1\nmasternodeprivkey=${mnkey}\naddnode=13.58.43.14:1984\naddnode=198.187.30.178:1984" > /$COINCORE/$COINCONFIG
    echo -e "${NONE}${GREEN}* Completed${NONE}";
}


startWallet() {
    echo
    echo -e "[10/${MAX}] Starting wallet daemon..."
    cd ~/$COINSRCDIR/src
    sudo ./$COINDAEMON -daemon > /dev/null 2>&1
    sleep 5
    echo -e "${GREEN}* Completed${NONE}";
}

clear
cd

echo
echo -e "${CYAN}   wwwwwwwwwwwwwwwwwwwwwwwwww       wwwwwwwwwwwwwwwwww  wwwwwwwwwwwwwwwwwwww  wwwwwwwww                                                ${NONE}"

echo -e "${CYAN}                                    wwwwwwwwwwwwwwwwww                                                                        ${NONE}"
echo -e "${CYAN}                                    wwwwwwwwwwwwwwwwww                                                                        ${NONE}"
echo -e "${CYAN}                                    wwwwwwwwwwwwwwwwww                                                                        ${NONE}"

echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwww                        wwwwwwwwwwwwwwwwww                        wwwwwwwww                                                ${NONE}"
echo -e "${CYAN}   wwwwwwwwww     wwwwwwwwww       wwwwwwwwwwwwwwwwwwww     wwwwwwwwww       wwwwwwwwww                                              ${NONE}"
echo -e "${CYAN}    wwwwwwwwww     wwwwwwww       wwwwwwwwwwwwwwwwwwww       wwwwwwww       wwwwwwwwww                                              ${NONE}"
echo -e "${CYAN}     wwwwwwwwww     wwwwww      wwwwwwwwww   wwwwwwwwww       wwwwww      wwwwwwwwww                                      ${NONE}"
echo -e "${CYAN}      wwwwwwwwww     wwwww     wwwwwwwwww     wwwwwwwwww      wwwww     wwwwwwwwww                                         ${NONE}"
echo -e "${CYAN}       wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww       wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww                                   ${NONE}"
echo -e "${CYAN}        wwwwwwwwwwwwwwwwwwwwwwwwwwwwwww         wwwwwwwwwwwwwwwwwwwwwwwwwwwwwww                                     ${NONE}"
echo -e "${CYAN}        Space                                    ${NONE}"
   echo -e "${CYAN}                                            ${NONE}"
echo -e "${CYAN}                                            ${NONE}"
echo -e "${CYAN}                                            ${NONE}"
             
echo -e "${CYAN}        BEFORE YOU START HEAD OVER TO YOUR COLD WALLET (WORLDWIDETRADECOIN-QT) ON YOUR DESKTOP                                    ${NONE}"
echo -e "${CYAN}        HEAD OVER TO HELP / DEBUG WINDOW OR CONSOLE                                    ${NONE}"
echo -e "${CYAN}        TYPE : "masternode genkey" and copy the output looks like this "7edfsdfg46jLCUzGczZi3JQw8Gp434R9kNY33eFyeKRymkBG4324h"    ${NONE}"



echo -e "${BOLD}"
read -p "This script will setup your WorldWideTradeCoin  Masternode. Do you wish to continue? (y/n)?" response
echo -e "${NONE}"

if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    read -e -p "Masternode Private Key (e.g. 7edfsdfg46jLCUzGczZi3JQw8Gp434R9kNY33eFyeKRymkBG4324h) : " key
    if [[ "$key" == "" ]]; then
        echo "WARNING: No private key entered, exiting!!!"
        echo && exit
    fi
    checkForUbuntuVersion
    updateAndUpgrade
    setupSwap
    installFail2Ban
    installFirewall
    installDependencies
    compileWallet
    installWallet
    configureWallet
    startWallet
    echo
    echo -e "${BOLD}The VPS side of your masternode has been installed. Use the following line in your cold wallet masternode.conf and replace the tx and index${NONE}".
    echo
    echo -e "${CYAN}masternode1 ${ip}:${COINPORT} ${key} tx index${NONE}"
    echo
    echo -e "${BOLD}Thank you for your support of WorldWideTradeCoin script made by EmmanuelApp.${NONE}"
    echo
else
    echo && echo "Installation cancelled" && echo
fi
