#while IFS=',' read -r IP HOST USER GROUP; do
 # [[ -z "$IP" || "$IP" =~ ^# ]] && continue
 # USER=${USER:-robot}

 # echo ">>> $HOST ($IP)  user=$USER"
  #ssh-copy-id -i ~/.ssh/jenkins_id.pub "${USER}@${IP}"
#done < csv/linux_targets.csv

sudo apt-get install sshpass -y          # on the Jenkins box
export SSHPASS='Eth!0pia747'

while IFS=',' read -r IP HOST USER GROUP; do
  [[ -z "$IP" || "$IP" =~ ^# ]] && continue
  USER=${USER:-robot}

  echo ">>> $HOST ($IP)"
  sshpass -e ssh-copy-id -i ~/.ssh/jenkins_id.pub -o StrictHostKeyChecking=no \
          "${USER}@${IP}"
done < csv/linux_targets.csv
unset SSHPASS
