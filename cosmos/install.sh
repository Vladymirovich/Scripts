#!/bin/bash
# NODE_NAME (NIBIRU, DEFUND, CASCADIA)
# NODE_CHAIN_ID
# NODE_PORT
# BINARY_VERSION_TAG
# CHAIN_DENOM
# BINARY_NAME
# DIRECTORY
# HIDDEN_DIRECTORY


if [ -z "$MONIKER" ]; then
  echo "*********************"
  echo -e "\e[1m\e[34m		Lets's begin\e[0m"
  echo "*********************"
  echo -e "\e[1m\e[32m	Enter your MONIKER:\e[0m"
  echo "_|-_|-_|-_|-_|-_|-_|"
  #read CASCADIA_MONIKER
  read MONIKER
  echo 'export MONIKER='$MONIKER >> $HOME/.bash_profile
  echo "==============================================="
  #MONIKER=$CASCADIA_MONIKER
#else
  #CASCADIA_MONIKER=$MONIKER
fi

#echo 'export CASCADIA_MONIKER='$CASCADIA_MONIKER >> $HOME/.bash_profile
#echo "export ${NODE_NAME}_CHAIN_ID=" >> $HOME/.bash_profile
#echo "export ${NODE_NAME}_PORT=" >> $HOME/.bash_profile
#source $HOME/.bash_profile

#CHAIN_ID=$CASCADIA_CHAIN_ID # specific
#CHAIN_DENOM="aCC"
#BINARY_VERSION_TAG="v0.1.2"
#PORT=$CASCADIA_PORT

# export temporary vars to .bash_profile
#echo 'export BINARY_NAME="cascadiad"' >> $HOME/.bash_profile
#echo 'export DIRECTORY=cascadia' >> $HOME/.bash_profile
#echo 'export HIDDEN_DIRECTORY=".cascadiad"' >> $HOME/.bash_profile
source $HOME/.bash_profile

echo "*****************************"
echo -e "\e[1m\e[32m Node moniker:       $MONIKER \e[0m"
echo -e "\e[1m\e[32m Chain id:           $NODE_CHAIN_ID \e[0m"
echo -e "\e[1m\e[32m Chain demon:        $CHAIN_DENOM \e[0m"
echo -e "\e[1m\e[32m Binary version tag: $BINARY_VERSION_TAG \e[0m"
echo -e "\e[1m\e[32m Binary name: $BINARY_NAME \e[0m"
echo -e "\e[1m\e[32m Directory: $DIRECTORY \e[0m"
echo -e "\e[1m\e[32m Hidden directory: $HIDDEN_DIRECTORY \e[0m"
echo "*****************************"
sleep 1

PS3='Select an action: '
options=("Create a new wallet" "Recover an old wallet" "Exit")
select opt in "${options[@]}"
do
  case $opt in
    "Create a new wallet")
      command="$BINARY_NAME keys add wallet"
      break
      ;;
    "Recover an old wallet")
      command="$BINARY_NAME keys add wallet --recover"
      break
      ;;
    "Exit")
      exit
      ;;
    *) echo "Invalid option. Please try again.";;
  esac
done

echo -e "\e[1m\e[32m1. Updating packages and dependencies--> \e[0m" && sleep 1
#UPDATE APT
sudo apt update && apt upgrade -y
apt install curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y


echo -e "        \e[1m\e[32m2. Installing GO--> \e[0m" && sleep 1
#INSTALL GO
if [ "$(go version)" != "go version go1.20.2 linux/amd64" ]; then \
ver="1.20.2" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile ; \
fi
go version

echo -e "              \e[1m\e[32m3. Downloading and building binaries--> \e[0m" && sleep 1
#INSTALL
cd $HOME
git clone $NODE_URL && cd $DIRECTORY
git fetch --all  # ?(nibiru only)
git checkout $BINARY_VERSION_TAG
make install
TEMP=$(which $BINARY_NAME)
sudo cp $TEMP /usr/local/bin/ && cd $HOME
$BINARY_NAME version --long | grep -e version -e commit

$BINARY_NAME init $MONIKER --chain-id $NODE_CHAIN_ID

wget -O $HOME/$HIDDEN_DIRECTORY/config/genesis.json "https://anode.team/Cascadia/test/genesis.json"


echo -e "                     \e[1m\e[32m4. Set the ports--> \e[0m" && sleep 1

sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${NODE_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${NODE_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${NODE_PORT}061\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${NODE_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${NODE_PORT}660\"%" $HOME/$HIDDEN_DIRECTORY/config/config.toml
sed -i.bak -e "s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${NODE_PORT}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${NODE_PORT}91\"%; s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:1${NODE_PORT}7\"%" $HOME/$HIDDEN_DIRECTORY/config/app.toml
sed -i.bak -e "s%^node = \"tcp://localhost:26657\"%node = \"tcp://localhost:${NODE_PORT}657\"%" $HOME/$HIDDEN_DIRECTORY/config/client.toml
external_address=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:${NODE_PORT}656\"/" $HOME/$HIDDEN_DIRECTORY/config/config.toml


echo -e "                     \e[1m\e[32m5. Setup config--> \e[0m" && sleep 1


# correct config (so we can no longer use the chain-id flag for every CLI command in client.toml)
$BINARY_NAME config chain-id $NODE_CHAIN_ID

# adjust if necessary keyring-backend в client.toml 
$BINARY_NAME config keyring-backend test

$BINARY_NAME config node tcp://localhost:${NODE_PORT}657

# Set the minimum price for gas
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025aCC\"/;" ~/$HIDDEN_DIRECTORY/config/app.toml

# Add seeds/peers в config.toml
peers="001933f36a6ec7c45b3c4cef073d0372daa5344d@194.163.155.84:49656,f78611ffa950efd9ddb4ed8f7bd8327c289ba377@65.109.108.150:46656,783a3f911d98ad2eee043721a2cf47a253f58ea1@65.108.108.52:33656,6c25f7075eddb697cb55a53a73e2f686d58b3f76@161.97.128.243:27656,8757ec250851234487f04466adacd3b1d37375f2@65.108.206.118:61556,df3cd1c84b2caa56f044ac19cf0267a44f2e87da@51.79.27.11:26656,d5519e378247dfb61dfe90652d1fe3e2b3005a5b@65.109.68.190:55656,f075e82ca89acfbbd8ef845c95bd3d50574904f5@159.69.110.238:36656,63cf1e7583eabf365856027815bc1491f2bc7939@65.108.2.41:60556,d5ba7a2288ed176ae2e73d9ae3c0edffec3caed5@65.21.134.202:16756"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/$HIDDEN_DIRECTORY/config/config.toml

seeds=""
sed -i.bak -e "s/^seeds =.*/seeds = \"$seeds\"/" $HOME/$HIDDEN_DIRECTORY/config/config.toml

# Set up filter for "bad" peers
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/$HIDDEN_DIRECTORY/config/config.toml

# Set up pruning
pruning="custom"
pruning_keep_recent="1000"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/$HIDDEN_DIRECTORY/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/$HIDDEN_DIRECTORY/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/$HIDDEN_DIRECTORY/config/app.toml

indexer="null" && \
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/$HIDDEN_DIRECTORY/config/config.toml

echo -e "                     \e[1m\e[32m7. Service File--> \e[0m" && sleep 1

# Create service file (One command)
sudo tee /etc/systemd/system/$BINARY_NAME.service > /dev/null <<EOF
[Unit]
Description=$NODE_NAME Node
After=network.target
 
[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/go/bin
ExecStart=/root/go/bin/$BINARY_NAME start --trace --log_level info --json-rpc.api eth,txpool,personal,net,debug,web3 --api.enable
Restart=on-failure
StartLimitInterval=0
RestartSec=3
LimitNOFILE=65535
LimitMEMLOCK=209715200
 
[Install]
WantedBy=multi-user.target
EOF

# Start the node
systemctl daemon-reload
systemctl enable $BINARY_NAME
systemctl restart $BINARY_NAME

# set up cosmos_autorestart (disabled)
source <(curl -s https://raw.githubusercontent.com/NodersUA/Scripts/main/cosmos_autorestart.sh)

echo '=============== SETUP FINISHED ==================='
echo -e 'Congratulations:        \e[1m\e[32mSUCCESSFUL NODE INSTALLATION\e[0m'
echo -e 'To check logs:        \e[1m\e[33mjournalctl -u ${BINARY_NAME} -f -o cat\e[0m'
echo -e "To check sync status: \e[1m\e[35mcurl localhost:${NODE_PORT}657/status\e[0m"

echo -e "                     \e[1m\e[32m8. Wallet--> \e[0m" && sleep 1

# Execute the saved command
eval "$command"

echo -e "      \e[1m\e[31m!!!!!!!!!SAVE!!!!!!!!!!!!!!!!SAVE YOUR MNEMONIC PHRASE!!!!!!!!!SAVE!!!!!!!!!!!!!!!!\e[0m'"

ADDRESS=$($BINARY_NAME keys show wallet -a)
VALOPER=$($BINARY_NAME keys show wallet --bech val -a)
echo "export ${NODE_NAME}_ADDRESS="${ADDRESS} >> $HOME/.bash_profile
echo "export ${NODE_NAME}_VALOPER="${VALOPER} >> $HOME/.bash_profile
source $HOME/.bash_profile

# Remove temp .bash_profile variables
#sed -i '/BINARY_NAME/d' ~/.bash_profile
#sed -i '/DIRECTORY/d' ~/.bash_profile
#sed -i '/HIDDEN_DIRECTORY/d' ~/.bash_profile