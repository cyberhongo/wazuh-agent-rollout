# assuming you are inside the repo directory
KEY=~/.ssh/jenkins_id.pub
CSV=csv/linux_targets.csv         # path in the repo

while IFS=',' read -r IP HOST USER GROUP EXTRA; do
  [[ -z "${IP// }" || "$IP" =~ ^# ]] && continue
  ssh-copy-id -o StrictHostKeyChecking=no -i "$KEY" root@"$IP"
done < "$CSV"
